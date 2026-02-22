extends CharacterBody3D

const SPEED := 5.0
const ARRIVAL_THRESHOLD := 0.2

var _target_position: Vector3
var _has_target := false

@onready var _camera: Camera3D = get_viewport().get_camera_3d()


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
		move_and_slide()
		return

	var to_target := _target_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()

	if distance < ARRIVAL_THRESHOLD:
		_has_target = false
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var direction := to_target.normalized()
	velocity = direction * SPEED

	# Rotate to face movement direction
	look_at(global_position + direction, Vector3.UP)

	move_and_slide()
