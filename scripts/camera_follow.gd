extends Camera3D

const ZOOM_SPEED := 1.0
const ZOOM_MIN := 5.0
const ZOOM_MAX := 20.0
# Vector3(0, 1, 1).normalized()
const OFFSET_DIRECTION := Vector3(0, 0.707107, 0.707107)

var _zoom_distance := 14.14  # Default: length of Vector3(0, 10, 10)

@onready var _player: Node3D = get_parent().get_node("Player")


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_distance = max(_zoom_distance - ZOOM_SPEED, ZOOM_MIN)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_distance = min(_zoom_distance + ZOOM_SPEED, ZOOM_MAX)


func _physics_process(_delta: float) -> void:
	global_position = _player.global_position + OFFSET_DIRECTION * _zoom_distance
