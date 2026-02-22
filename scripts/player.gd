extends CharacterBody3D

const SPEED := 5.0
const ARRIVAL_THRESHOLD := 0.2

var _target_position: Vector3
var _has_target := false
var _anim_player: AnimationPlayer

@onready var _camera: Camera3D = get_viewport().get_camera_3d()


func _ready() -> void:
	_anim_player = _find_animation_player($KnightModel)

	if not _anim_player:
		_anim_player = AnimationPlayer.new()
		_anim_player.name = "AnimationPlayer"
		$KnightModel.add_child(_anim_player)
		_anim_player.root_node = _anim_player.get_path_to($KnightModel)

	_load_animation_library("res://assets/animations/Rig_Medium_General.glb", "general")
	_load_animation_library("res://assets/animations/Rig_Medium_MovementBasic.glb", "movement")
	_play_animation("idle")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var from := _camera.project_ray_origin(event.position)
		var dir := _camera.project_ray_normal(event.position)

		# Intersect ray with the XZ plane (y = 0)
		if dir.y != 0.0:
			var t := -from.y / dir.y
			if t > 0.0:
				_target_position = from + dir * t
				_target_position.y = global_position.y
				_has_target = true


func _physics_process(_delta: float) -> void:
	if not _has_target:
		velocity = Vector3.ZERO
		_play_animation("idle")
		move_and_slide()
		return

	var to_target := _target_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()

	if distance < ARRIVAL_THRESHOLD:
		_has_target = false
		velocity = Vector3.ZERO
		_play_animation("idle")
		move_and_slide()
		return

	var direction := to_target.normalized()
	velocity = direction * SPEED

	# Rotate to face movement direction (KayKit models face +Z, look_at faces -Z)
	look_at(global_position - direction, Vector3.UP)

	_play_animation("walk")
	move_and_slide()


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
		push_warning("Could not load animation scene: %s" % path)
		return
	var instance := scene.instantiate()
	var source_player := _find_animation_player(instance)
	if not source_player:
		push_warning("No AnimationPlayer found in: %s" % path)
		instance.queue_free()
		return
	var lib := AnimationLibrary.new()
	for source_lib_name in source_player.get_animation_library_list():
		var source_lib := source_player.get_animation_library(source_lib_name)
		for anim_name in source_lib.get_animation_list():
			lib.add_animation(anim_name, source_lib.get_animation(anim_name))
	_anim_player.add_animation_library(lib_name, lib)
	instance.queue_free()


func _play_animation(type: String) -> void:
	if not _anim_player:
		return

	var anim_name := ""
	match type:
		"idle":
			anim_name = _find_anim_by_keywords(["idle"])
		"walk":
			anim_name = _find_anim_by_keywords(["walk", "run", "moving"])

	if anim_name != "" and _anim_player.current_animation != anim_name:
		_anim_player.play(anim_name)


func _find_anim_by_keywords(keywords: Array[String]) -> String:
	# Search all libraries for an animation matching keywords
	for lib_name in _anim_player.get_animation_library_list():
		var lib := _anim_player.get_animation_library(lib_name)
		for anim_name in lib.get_animation_list():
			var lower := anim_name.to_lower()
			for keyword in keywords:
				if lower.contains(keyword):
					return "%s/%s" % [lib_name, anim_name] if lib_name != "" else anim_name
	return ""
