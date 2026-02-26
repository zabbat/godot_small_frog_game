extends Node3D

@export var map_path := "res://maps/test.map"
@export var registry_path := "res://assets/asset_registry.cfg"
@export var npc_registry_path := "res://assets/npc_registry.cfg"
@export var ground_size := 20.0

var _registry := ConfigFile.new()
var _npc_registry := ConfigFile.new()
var _grid_cols := 0
var _grid_rows := 0
var _cell_size := 0.0

@onready var _nav_region: NavigationRegion3D = $NavigationRegion3D
@onready var _ground_mesh: MeshInstance3D = $NavigationRegion3D/Ground/MeshInstance3D


func _ready() -> void:
	_registry.load(registry_path)
	_npc_registry.load(npc_registry_path)
	load_map(map_path)


func load_map(path: String) -> void:
	map_path = path
	_clear_spawned()
	var map_data := _parse_map_file(map_path)

	_apply_ground_shader(map_data.layers.get("ground", []), map_data.legends.get("ground", {}))
	_spawn_grass(map_data.layers.get("decoration", []), map_data.legends.get("decoration", {}))
	_spawn_objects(map_data.layers.get("objects", []), map_data.legends.get("objects", {}))
	_spawn_items(map_data.items)
	_spawn_npcs(map_data.npcs)
	_spawn_confined_walls(map_data.confined)

	_nav_region.bake_navigation_mesh.call_deferred()


func _clear_spawned() -> void:
	# Remove dynamically spawned children (keep static scene nodes)
	for child in get_children():
		if child is Camera3D or child is DirectionalLight3D or child is NavigationRegion3D or child is CharacterBody3D:
			continue
		remove_child(child)
		child.queue_free()

	# Remove spawned objects/portals from nav region (keep Ground)
	for child in _nav_region.get_children():
		if child.name == "Ground":
			continue
		_nav_region.remove_child(child)
		child.queue_free()


func _parse_map_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	var result := {"layers": {}, "legends": {}, "items": [], "npcs": [], "confined": {}}
	var section := ""
	var current_layer := ""
	var current_legend := ""

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		if line.begins_with("["):
			section = line
			# Parse layer/legend names from brackets
			if section.begins_with("[layer:"):
				current_layer = section.trim_prefix("[layer:").trim_suffix("]")
				result.layers[current_layer] = []
			elif section.begins_with("[legend:"):
				current_legend = section.trim_prefix("[legend:").trim_suffix("]")
				result.legends[current_legend] = {}
			continue

		match section:
			"[size]":
				var parts := line.split(",")
				_grid_cols = int(parts[0])
				_grid_rows = int(parts[1])
				_cell_size = ground_size / _grid_cols
			"[items]":
				var item := _parse_item_line(line)
				if item:
					result.items.append(item)
			"[npcs]":
				var npc := _parse_npc_line(line)
				if not npc.is_empty():
					result.npcs.append(npc)
			"[confined]":
				var parts := line.split("=")
				var key := parts[0].strip_edges()
				var value := parts[1].strip_edges()
				result.confined[key] = _parse_confined_value(value)
			_:
				if section.begins_with("[layer:"):
					result.layers[current_layer].append(line)
				elif section.begins_with("[legend:"):
					var parts := line.split("=")
					var key := parts[0].strip_edges()
					var value := parts[1].strip_edges()
					result.legends[current_legend][key] = value

	return result


func _parse_item_line(line: String) -> Dictionary:
	var paren_start := line.find("(")
	var paren_end := line.find(")")
	if paren_start == -1 or paren_end == -1:
		return {}

	var name_part := line.substr(0, paren_start).strip_edges().trim_suffix(",")
	var pos_part := line.substr(paren_start + 1, paren_end - paren_start - 1)
	var model_part := line.substr(paren_end + 1).strip_edges().trim_prefix(",").strip_edges()

	var pos_values := pos_part.split(",")
	var pos := Vector3(
		float(pos_values[0].strip_edges()),
		float(pos_values[1].strip_edges()),
		float(pos_values[2].strip_edges())
	)

	return {"name": name_part, "position": pos, "model_id": model_part}


func grid_to_world(col: int, row: int) -> Vector3:
	var half := ground_size / 2.0
	var x := col * _cell_size - half + _cell_size / 2.0
	var z := row * _cell_size - half + _cell_size / 2.0
	return Vector3(x, 0, z)


# --- Ground layer ---

func _apply_ground_shader(grid: Array, legend: Dictionary) -> void:
	if grid.is_empty():
		return

	var img := Image.create(_grid_cols, _grid_rows, false, Image.FORMAT_R8)

	for row_idx in grid.size():
		var row_str: String = grid[row_idx]
		for col_idx in row_str.length():
			var ch := row_str[col_idx]
			var tile_type: String = legend.get(ch, "none")
			var value := 0.0
			if tile_type == "grass":
				value = 1.0
			img.set_pixel(col_idx, row_idx, Color(value, 0, 0, 1))

	var tile_tex := ImageTexture.create_from_image(img)

	var shader := load("res://assets/shaders/ground.gdshader") as Shader
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("tile_map", tile_tex)
	mat.set_shader_parameter("grid_size", Vector2(_grid_cols, _grid_rows))
	mat.set_shader_parameter("ground_size_world", ground_size)

	_ground_mesh.material_override = mat


# --- Decoration layer ---

func _spawn_grass(grid: Array, legend: Dictionary) -> void:
	if grid.is_empty():
		return

	var grass_script := load("res://scripts/grass_patch.gd")
	var grass_mat := _create_grass_material()

	for row_idx in grid.size():
		var row_str: String = grid[row_idx]
		for col_idx in row_str.length():
			var ch := row_str[col_idx]
			var tile_type: String = legend.get(ch, "none")
			if tile_type != "grass_3d":
				continue
			var world_pos := grid_to_world(col_idx, row_idx)
			var patch := MultiMeshInstance3D.new()
			patch.set_script(grass_script)
			patch.patch_size = Vector2(_cell_size, _cell_size)
			patch.shared_material = grass_mat
			patch.transform.origin = world_pos
			add_child(patch)


func _create_grass_material() -> ShaderMaterial:
	var shader := load("res://assets/shaders/grass.gdshader") as Shader
	var mat := ShaderMaterial.new()
	mat.shader = shader

	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.004
	var noise_tex := NoiseTexture2D.new()
	noise_tex.noise = noise
	noise_tex.width = 256
	noise_tex.height = 256
	noise_tex.seamless = true

	mat.set_shader_parameter("sway_noise", noise_tex)
	mat.set_shader_parameter("sway", 1.32)
	mat.set_shader_parameter("sway_", 0.56)
	mat.set_shader_parameter("sway_pow", 1.25)
	mat.set_shader_parameter("sway_noise_sampling_scale", 0.12)
	mat.set_shader_parameter("sway_time_scale", 0.28)
	mat.set_shader_parameter("sway_dir", Vector3(1.0, 0.0, 1.0))
	mat.set_shader_parameter("grass_roughness", 0.5)
	mat.set_shader_parameter("color_scale", 0.18)
	mat.set_shader_parameter("color_grad_height", -0.87)
	mat.set_shader_parameter("top_color", Color(0.45, 0.8, 0.15))
	mat.set_shader_parameter("bot_color", Color(0.15, 0.35, 0.05))

	return mat


# --- Objects layer ---

func _parse_object_legend(value_str: String) -> Dictionary:
	var result := {"model_id": "", "rotation": 0.0, "portal": {}}

	var paren_start := value_str.find("(")
	var before_paren := value_str
	if paren_start != -1:
		before_paren = value_str.substr(0, paren_start)
		var paren_end := value_str.find(")", paren_start)
		if paren_end != -1:
			var portal_str := value_str.substr(paren_start + 1, paren_end - paren_start - 1)
			var parts := portal_str.split(",")
			if parts.size() >= 5:
				result.portal = {
					"action": parts[0].strip_edges(),
					"map_path": parts[1].strip_edges(),
					"spawn_x": float(parts[2].strip_edges()),
					"spawn_z": float(parts[3].strip_edges()),
					"spawn_rotation": float(parts[4].strip_edges()),
				}

	var value_parts := before_paren.split(",")
	result.model_id = value_parts[0].strip_edges()
	if value_parts.size() > 1 and value_parts[1].strip_edges() != "":
		result.rotation = float(value_parts[1].strip_edges())

	return result


func _spawn_objects(grid: Array, legend: Dictionary) -> void:
	for row_idx in grid.size():
		var row_str: String = grid[row_idx]
		for col_idx in row_str.length():
			var ch := row_str[col_idx]
			if ch == "0":
				continue
			if not legend.has(ch):
				push_warning("Map: unknown object character '%s'" % ch)
				continue

			var parsed := _parse_object_legend(legend[ch])
			var world_pos := grid_to_world(col_idx, row_idx)
			_spawn_object(parsed.model_id, world_pos, parsed.rotation, parsed.portal)


func _spawn_object(model_id: String, world_pos: Vector3, rotation_deg := 0.0, portal := {}) -> void:
	# Invisible portal tile — no model, just the trigger
	if model_id == "none":
		if not portal.is_empty() and portal.action == "TOUCH":
			var tile_size := Vector3(_cell_size, 1.0, _cell_size)
			_spawn_portal_trigger(world_pos, tile_size, 0.0, portal)
		return

	if not _registry.has_section(model_id):
		push_warning("Registry: unknown model '%s'" % model_id)
		return

	var scene_path: String = _registry.get_value(model_id, "scene")
	var mat_path: String = _registry.get_value(model_id, "material", "")
	var collision_str: String = _registry.get_value(model_id, "collision_size", "")
	var collision_offset_y: float = _registry.get_value(model_id, "collision_offset_y", 0.0)

	var scene: PackedScene = load(scene_path)
	var instance := scene.instantiate()
	instance.transform.origin = world_pos
	if rotation_deg != 0.0:
		instance.rotate_y(deg_to_rad(rotation_deg))

	if mat_path != "":
		var mat: Material = load(mat_path)
		_apply_material(instance, mat)

	if collision_str != "":
		_nav_region.add_child(instance)

		var collision_parts := collision_str.split(",")
		var collision_size := Vector3(
			float(collision_parts[0].strip_edges()),
			float(collision_parts[1].strip_edges()),
			float(collision_parts[2].strip_edges())
		)

		var static_body := StaticBody3D.new()
		static_body.transform.origin = Vector3(world_pos.x, collision_offset_y, world_pos.z)

		var collision_shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = collision_size
		collision_shape.shape = box

		static_body.add_child(collision_shape)
		_nav_region.add_child(static_body)

		if not portal.is_empty() and portal.action == "TOUCH":
			_spawn_portal_trigger(world_pos, collision_size, collision_offset_y, portal)
	else:
		add_child(instance)


func _spawn_portal_trigger(world_pos: Vector3, collision_size: Vector3, offset_y: float, portal: Dictionary) -> void:
	var area := Area3D.new()
	area.name = "PortalTrigger"
	area.set_meta("portal", portal)

	var col_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(collision_size.x + 1.0, collision_size.y, collision_size.z + 1.0)
	col_shape.shape = box
	area.add_child(col_shape)

	area.transform.origin = Vector3(world_pos.x, offset_y, world_pos.z)
	area.body_entered.connect(_on_portal_body_entered.bind(portal))
	_nav_region.add_child(area)


func _on_portal_body_entered(body: Node3D, portal: Dictionary) -> void:
	if body is CharacterBody3D:
		var target_path: String = "res://" + str(portal.map_path)
		var spawn_pos := Vector3(float(portal.spawn_x), 0, float(portal.spawn_z))
		var spawn_rot: float = float(portal.spawn_rotation)
		GameManager.transition_to_map(target_path, spawn_pos, spawn_rot)


# --- Items ---

func _spawn_items(items: Array) -> void:
	for item_data in items:
		var model_id: String = item_data.model_id
		if not _registry.has_section(model_id):
			push_warning("Registry: unknown item model '%s'" % model_id)
			continue

		var scene_path: String = _registry.get_value(model_id, "scene")
		var mat_path: String = _registry.get_value(model_id, "material", "")

		var scene: PackedScene = load(scene_path)
		var instance := scene.instantiate()
		instance.transform.origin = item_data.position

		var pickup_script := load("res://scripts/item_pickup.gd")
		instance.set_script(pickup_script)

		if mat_path != "":
			instance.material = load(mat_path)
		instance.item_name = item_data.name

		var area := Area3D.new()
		area.name = "ClickArea"
		var col_shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.6, 1.5, 0.2)
		col_shape.shape = box
		col_shape.transform.origin = Vector3(0, 0.5, 0)
		area.add_child(col_shape)
		instance.add_child(area)

		add_child(instance)


# --- NPCs ---

func _parse_npc_line(line: String) -> Dictionary:
	# Format: id: "name", "info", (col, row), PATTERN
	var colon := line.find(":")
	if colon == -1:
		return {}
	var npc_id := line.substr(0, colon).strip_edges()
	var rest := line.substr(colon + 1).strip_edges()

	# Extract quoted strings
	var name_str := ""
	var info_str := ""
	var quote_idx := rest.find("\"")
	if quote_idx != -1:
		var end_quote := rest.find("\"", quote_idx + 1)
		if end_quote != -1:
			name_str = rest.substr(quote_idx + 1, end_quote - quote_idx - 1)
			rest = rest.substr(end_quote + 1).strip_edges().trim_prefix(",").strip_edges()
	quote_idx = rest.find("\"")
	if quote_idx != -1:
		var end_quote := rest.find("\"", quote_idx + 1)
		if end_quote != -1:
			info_str = rest.substr(quote_idx + 1, end_quote - quote_idx - 1)
			rest = rest.substr(end_quote + 1).strip_edges().trim_prefix(",").strip_edges()

	# Extract (col, row)
	var paren_start := rest.find("(")
	var paren_end := rest.find(")")
	var col := 0
	var row := 0
	if paren_start != -1 and paren_end != -1:
		var coords := rest.substr(paren_start + 1, paren_end - paren_start - 1).split(",")
		col = int(coords[0].strip_edges())
		row = int(coords[1].strip_edges())
		rest = rest.substr(paren_end + 1).strip_edges().trim_prefix(",").strip_edges()

	var pattern := rest.strip_edges()
	if pattern.is_empty():
		pattern = "IDLE"

	return {"id": npc_id, "name": name_str, "info": info_str, "col": col, "row": row, "pattern": pattern}


func _spawn_npcs(npcs: Array) -> void:
	var npc_script := load("res://scripts/npc.gd")

	for npc_data in npcs:
		var npc_id: String = npc_data.id
		if not _npc_registry.has_section(npc_id):
			push_warning("NPC registry: unknown NPC '%s'" % npc_id)
			continue

		var model_path: String = _npc_registry.get_value(npc_id, "model", "")
		var mat_path: String = _npc_registry.get_value(npc_id, "material", "")
		var idle_anim_path: String = _npc_registry.get_value(npc_id, "idle_animation", "")
		var walk_anim_path: String = _npc_registry.get_value(npc_id, "walk_animation", "")

		if model_path.is_empty():
			push_warning("NPC registry: no model for '%s'" % npc_id)
			continue

		var model_scene: PackedScene = load(model_path)
		var model_instance := model_scene.instantiate()

		if mat_path != "":
			var mat: Material = load(mat_path)
			_apply_material(model_instance, mat)

		var npc_node := Node3D.new()
		npc_node.name = "NPC_" + npc_data.name.replace(" ", "_")
		npc_node.set_script(npc_script)
		npc_node.npc_id = npc_data.id
		npc_node.npc_name = npc_data.name
		npc_node.info = npc_data.info
		npc_node.move_pattern = npc_data.pattern

		var world_pos := grid_to_world(npc_data.col, npc_data.row)
		npc_node.transform.origin = world_pos

		add_child(npc_node)
		npc_node.setup(model_instance, idle_anim_path, walk_anim_path)


# --- Confined walls ---

const WALL_HEIGHT := 3.0
const WALL_THICKNESS := 0.1


func _parse_argb_hex(hex: String) -> Color:
	if hex.length() != 8:
		push_warning("Confined: invalid ARGB hex '%s'" % hex)
		return Color.WHITE
	var a := hex.substr(0, 2).hex_to_int() / 255.0
	var r := hex.substr(2, 2).hex_to_int() / 255.0
	var g := hex.substr(4, 2).hex_to_int() / 255.0
	var b := hex.substr(6, 2).hex_to_int() / 255.0
	return Color(r, g, b, a)


func _parse_confined_value(value: String) -> Dictionary:
	var result := {"color": Color.WHITE, "cutouts": []}
	var bracket_start := value.find("[")
	var color_part := value
	if bracket_start != -1:
		color_part = value.substr(0, bracket_start).strip_edges().trim_suffix(",").strip_edges()
		var bracket_end := value.find("]", bracket_start)
		if bracket_end != -1:
			var inner := value.substr(bracket_start + 1, bracket_end - bracket_start - 1).strip_edges()
			if not inner.is_empty():
				for idx in inner.split(","):
					result.cutouts.append(int(idx.strip_edges()))
	if color_part.begins_with("c:"):
		result.color = _parse_argb_hex(color_part.substr(2))
	return result


func _spawn_confined_walls(confined: Dictionary) -> void:
	if confined.is_empty():
		return

	var half := ground_size / 2.0
	var y := WALL_HEIGHT / 2.0

	for side in confined:
		if side not in ["L", "R", "B", "F"]:
			push_warning("Confined: unknown side '%s'" % side)
			continue

		var wall_data: Dictionary = confined[side]
		var color: Color = wall_data.color
		var cutouts: Array = wall_data.cutouts

		# L/R walls run along Z (use _grid_rows), B/F walls run along X (use _grid_cols)
		var is_vertical: bool = side == "L" or side == "R"
		var cell_count := _grid_rows if is_vertical else _grid_cols

		# Build list of solid segments (merging consecutive non-cutout cells)
		var segments: Array = []  # Array of [start_idx, length]
		var seg_start := -1
		for i in cell_count:
			if i in cutouts:
				if seg_start != -1:
					segments.append([seg_start, i - seg_start])
					seg_start = -1
			else:
				if seg_start == -1:
					seg_start = i
		if seg_start != -1:
			segments.append([seg_start, cell_count - seg_start])

		for seg in segments:
			var seg_idx: int = seg[0]
			var seg_len: int = seg[1]
			var seg_world_size := seg_len * _cell_size

			# Calculate segment center along the wall axis
			var seg_center := (seg_idx + seg_len / 2.0) * _cell_size - half

			var pos: Vector3
			var size: Vector3
			if is_vertical:
				var x := -half if side == "L" else half
				pos = Vector3(x, y, seg_center)
				size = Vector3(WALL_THICKNESS, WALL_HEIGHT, seg_world_size)
			else:
				var z := -half if side == "B" else half
				pos = Vector3(seg_center, y, z)
				size = Vector3(seg_world_size, WALL_HEIGHT, WALL_THICKNESS)

			_spawn_wall_segment(side, pos, size, color)


func _spawn_wall_segment(side: String, pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "ConfinedWall_" + side
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	mesh_instance.transform.origin = pos

	var mat_front := StandardMaterial3D.new()
	mat_front.albedo_color = color
	mat_front.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_front.cull_mode = BaseMaterial3D.CULL_BACK

	var back_color := Color(color.r, color.g, color.b, min(color.a, 0.05))
	var mat_back := StandardMaterial3D.new()
	mat_back.albedo_color = back_color
	mat_back.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_back.cull_mode = BaseMaterial3D.CULL_FRONT

	mesh_instance.material_override = mat_front

	var back_mesh := MeshInstance3D.new()
	back_mesh.name = "Back"
	back_mesh.mesh = box_mesh
	back_mesh.material_override = mat_back
	mesh_instance.add_child(back_mesh)

	_nav_region.add_child(mesh_instance)


func _apply_material(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		for i in mesh_instance.get_surface_override_material_count():
			mesh_instance.set_surface_override_material(i, mat)
	for child in node.get_children():
		_apply_material(child, mat)
