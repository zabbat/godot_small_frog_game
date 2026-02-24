extends Node

var _fade_rect: ColorRect
var _is_transitioning := false


func _ready() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.anchors_preset = Control.PRESET_FULL_RECT
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(_fade_rect)


func transition_to_map(target_map_path: String, spawn_pos: Vector3, spawn_rotation_deg: float) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	# Fade out
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, 0.3)
	await tween.finished

	# Get references
	var main := get_tree().current_scene
	var player: CharacterBody3D = main.get_node("Player")
	var nav_region: NavigationRegion3D = main.get_node("NavigationRegion3D")

	# Reset and reposition player before loading (so portal triggers don't re-fire)
	player.reset_state()
	player.set_physics_process(false)
	player.set_process_input(false)

	# Load new map
	main.load_map(target_map_path)

	# Convert grid coords (col, row) to world position
	var world_pos: Vector3 = main.grid_to_world(int(spawn_pos.x), int(spawn_pos.z))
	player.global_position = world_pos
	player.rotation.y = deg_to_rad(spawn_rotation_deg)

	await nav_region.bake_finished

	# Snap player Y to nav mesh surface so the nav agent can find paths
	var nav_map := player.get_world_3d().navigation_map
	var snapped := NavigationServer3D.map_get_closest_point(nav_map, player.global_position)
	player.global_position = snapped

	# Re-enable player
	player.set_physics_process(true)
	player.set_process_input(true)

	# Fade in
	var tween_in := create_tween()
	tween_in.tween_property(_fade_rect, "color:a", 0.0, 0.3)
	await tween_in.finished
	_is_transitioning = false
