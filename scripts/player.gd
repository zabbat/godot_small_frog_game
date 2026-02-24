extends CharacterBody3D

const SPEED := 5.0
const ARRIVAL_THRESHOLD := 0.5
const INTERACT_DISTANCE := 1.5

enum State { IDLE, WALK }

var _state: State = State.IDLE
var _anim_player: AnimationPlayer
var _target: Vector3
var _selected_item: Node3D

@onready var _camera: Camera3D = get_viewport().get_camera_3d()
@onready var _nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var _dialog: PanelContainer = $CanvasLayer/DialogUI


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

		# Raycast to check if we clicked on an item
		var space := get_world_3d().direct_space_state
		var ray := PhysicsRayQueryParameters3D.create(from, from + dir * 100.0)
		ray.collide_with_areas = true
		var result := space.intersect_ray(ray)

		# Hide dialog and unhighlight previously selected item
		_hide_dialog()
		if _selected_item and _selected_item.has_method("unhighlight"):
			_selected_item.unhighlight()
			_selected_item = null

		if result and _find_pickup(result.collider):
			var pickup := _find_pickup(result.collider)
			if pickup.has_method("highlight"):
				pickup.highlight()
				_selected_item = pickup

		# Intersect ray with the XZ plane (y = 0)
		if dir.y != 0.0:
			var t := -from.y / dir.y
			if t > 0.0:
				var target := from + dir * t
				target.y = global_position.y
				var nav_map := get_world_3d().navigation_map
				var closest := NavigationServer3D.map_get_closest_point(nav_map, target)
				_nav_agent.target_position = closest
				_target = target
				_state = State.WALK


func _physics_process(_delta: float) -> void:
	match _state:
		State.IDLE:
			velocity = Vector3.ZERO
			_play_animation("idle")
			move_and_slide()
		State.WALK:
			_process_walk()


func _process_walk() -> void:
	var to_target := _target - global_position
	to_target.y = 0.0

	# Check if we reached a highlighted item
	if _selected_item:
		var dist_to_item := (_selected_item.global_position - global_position)
		dist_to_item.y = 0.0
		if dist_to_item.length() < INTERACT_DISTANCE:
			_show_dialog(_selected_item.item_name)
			_state = State.IDLE
			return

	if to_target.length() < ARRIVAL_THRESHOLD:
		_state = State.IDLE
		return

	var next_point := _nav_agent.get_next_path_position()
	var direction := (next_point - global_position)
	direction.y = 0.0

	if direction.length() < 0.01:
		_state = State.IDLE
		return

	direction = direction.normalized()
	velocity = direction * SPEED

	# Rotate to face movement direction (KayKit models face +Z, look_at faces -Z)
	look_at(global_position - direction, Vector3.UP)

	_play_animation("walk")
	move_and_slide()


func reset_state() -> void:
	_state = State.IDLE
	velocity = Vector3.ZERO
	if _selected_item and _selected_item.has_method("unhighlight"):
		_selected_item.unhighlight()
	_selected_item = null
	_hide_dialog()


func _show_dialog(text: String) -> void:
	_dialog.get_node("Label").text = text
	_dialog.visible = true


func _hide_dialog() -> void:
	_dialog.visible = false


func _find_pickup(node: Node) -> Node3D:
	# Walk up the tree to find a node with item_pickup.gd script
	var current := node
	while current:
		if current.has_method("highlight"):
			return current as Node3D
		current = current.get_parent()
	return null


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
