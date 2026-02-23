extends Node3D

@export var map_path := "res://maps/test.map"
@export var registry_path := "res://assets/asset_registry.cfg"
@export var ground_size := 20.0

var _registry := ConfigFile.new()
var _grid_cols := 0
var _grid_rows := 0
var _cell_size := 0.0

@onready var _nav_region: NavigationRegion3D = $NavigationRegion3D
@onready var _ground_mesh: MeshInstance3D = $NavigationRegion3D/Ground/MeshInstance3D


func _ready() -> void:
	_registry.load(registry_path)
	var map_data := _parse_map_file(map_path)

	_apply_ground_shader(map_data.layers.get("ground", []), map_data.legends.get("ground", {}))
	_spawn_grass(map_data.layers.get("decoration", []), map_data.legends.get("decoration", {}))
	_spawn_objects(map_data.layers.get("objects", []), map_data.legends.get("objects", {}))
	_spawn_items(map_data.items)

	_nav_region.bake_navigation_mesh.call_deferred()


func _parse_map_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	var result := {"layers": {}, "legends": {}, "items": []}
	var section := ""
	var current_layer := ""
	var current_legend := ""

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty():
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


func _grid_to_world(col: int, row: int) -> Vector3:
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
			var world_pos := _grid_to_world(col_idx, row_idx)
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

			var value_str: String = legend[ch]
			var value_parts := value_str.split(",")
			var model_id := value_parts[0].strip_edges()
			var rotation_deg := 0.0
			if value_parts.size() > 1:
				rotation_deg = float(value_parts[1].strip_edges())

			var world_pos := _grid_to_world(col_idx, row_idx)
			_spawn_object(model_id, world_pos, rotation_deg)


func _spawn_object(model_id: String, world_pos: Vector3, rotation_deg := 0.0) -> void:
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
	else:
		add_child(instance)


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


func _apply_material(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		for i in mesh_instance.get_surface_override_material_count():
			mesh_instance.set_surface_override_material(i, mat)
	for child in node.get_children():
		_apply_material(child, mat)
