extends Node3D

var npc_id := ""
var npc_name := ""
var info := ""
var move_pattern := "IDLE"

var _anim_player: AnimationPlayer
var _model: Node3D
var _highlighted := false
var _mesh_data: Array[Array] = []  # [[MeshInstance3D, [orig_mat0, ...], [highlight_mat0, ...]], ...]


func setup(model: Node3D, idle_anim_path: String) -> void:
	_model = model
	add_child(_model)

	# Collision body so the player can't walk through
	var body := StaticBody3D.new()
	var col_shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.0
	col_shape.shape = capsule
	col_shape.transform.origin = Vector3(0, 0.5, 0)
	body.add_child(col_shape)
	add_child(body)

	_anim_player = _find_animation_player(_model)
	if not _anim_player:
		_anim_player = AnimationPlayer.new()
		_anim_player.name = "AnimationPlayer"
		_model.add_child(_anim_player)
		_anim_player.root_node = _anim_player.get_path_to(_model)

	# Click detection area (larger than collision capsule for easy clicking)
	var area := Area3D.new()
	area.name = "ClickArea"
	var area_shape := CollisionShape3D.new()
	var area_capsule := CapsuleShape3D.new()
	area_capsule.radius = 0.5
	area_capsule.height = 1.6
	area_shape.shape = area_capsule
	area_shape.transform.origin = Vector3(0, 0.8, 0)
	area.add_child(area_shape)
	add_child(area)

	# Store original materials and build per-surface highlight materials
	_build_material_data(_model)

	if idle_anim_path != "":
		_load_animation_library(idle_anim_path, "general")
		_play_idle()


func highlight() -> void:
	if _highlighted:
		return
	_highlighted = true
	for entry in _mesh_data:
		var mesh: MeshInstance3D = entry[0]
		var hi_mats: Array = entry[2]
		for i in mesh.get_surface_override_material_count():
			mesh.set_surface_override_material(i, hi_mats[i])


func unhighlight() -> void:
	if not _highlighted:
		return
	_highlighted = false
	for entry in _mesh_data:
		var mesh: MeshInstance3D = entry[0]
		var orig_mats: Array = entry[1]
		for i in mesh.get_surface_override_material_count():
			mesh.set_surface_override_material(i, orig_mats[i] if i < orig_mats.size() else null)


func _build_material_data(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		var orig_mats: Array = []
		var hi_mats: Array = []
		for i in mesh.get_surface_override_material_count():
			var orig := mesh.get_active_material(i)
			orig_mats.append(mesh.get_surface_override_material(i))
			var hi := StandardMaterial3D.new()
			if orig is StandardMaterial3D:
				var src := orig as StandardMaterial3D
				hi.albedo_texture = src.albedo_texture
			hi.albedo_color = Color(1.0, 1.0, 1.0)
			hi.emission_enabled = true
			hi.emission = Color(1.0, 0.9, 0.3)
			hi.emission_energy_multiplier = 0.05
			hi_mats.append(hi)
		_mesh_data.append([mesh, orig_mats, hi_mats])
	for child in node.get_children():
		_build_material_data(child)


func _play_idle() -> void:
	if not _anim_player:
		return
	var anim_name := _find_anim_by_keywords(["idle"])
	if anim_name != "":
		_anim_player.play(anim_name)


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result := _find_animation_player(child)
		if result:
			return result
	return null


func _load_animation_library(path: String, lib_name: String) -> void:
	var scene := load(path) as PackedScene
	if not scene:
		push_warning("NPC: could not load animation scene: %s" % path)
		return
	var instance := scene.instantiate()
	var source_player := _find_animation_player(instance)
	if not source_player:
		push_warning("NPC: no AnimationPlayer found in: %s" % path)
		instance.queue_free()
		return
	var lib := AnimationLibrary.new()
	for source_lib_name in source_player.get_animation_library_list():
		var source_lib := source_player.get_animation_library(source_lib_name)
		for anim_name in source_lib.get_animation_list():
			lib.add_animation(anim_name, source_lib.get_animation(anim_name))
	_anim_player.add_animation_library(lib_name, lib)
	instance.queue_free()


func _find_anim_by_keywords(keywords: Array[String]) -> String:
	for lib_name in _anim_player.get_animation_library_list():
		var lib := _anim_player.get_animation_library(lib_name)
		for anim_name in lib.get_animation_list():
			var lower := anim_name.to_lower()
			for keyword in keywords:
				if lower.contains(keyword):
					return "%s/%s" % [lib_name, anim_name] if lib_name != "" else anim_name
	return ""
