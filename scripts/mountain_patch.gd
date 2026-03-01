extends MeshInstance3D

var patch_size := Vector2(2.0, 2.0)
var shared_material: ShaderMaterial
var ring_material: ShaderMaterial
var neighbors := Vector4(0, 0, 0, 0) # right, left, down, up


func _ready() -> void:
	_build()


func _build() -> void:
	var plane := PlaneMesh.new()
	plane.size = patch_size
	plane.subdivide_width = 24
	plane.subdivide_depth = 24
	mesh = plane

	# Per-instance material — only neighbors differ per tile
	var mat := shared_material.duplicate() as ShaderMaterial
	mat.set_shader_parameter("neighbors", neighbors)
	material_override = mat

	# Collision to block navigation
	var box_height := 2.0
	var static_body := StaticBody3D.new()
	static_body.transform.origin = Vector3(0, box_height / 2.0, 0)

	var col_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(patch_size.x, box_height, patch_size.y)
	col_shape.shape = box

	static_body.add_child(col_shape)
	add_child(static_body)

	# Sink the mountain mesh slightly so the base meets the ground
	position.y = -0.05

	# Ground ring — flat transparent circle blending into ground
	var ring := MeshInstance3D.new()
	var ring_plane := PlaneMesh.new()
	ring_plane.size = patch_size * 1.8
	ring.mesh = ring_plane
	ring.material_override = ring_material
	ring.position.y = 0.07  # slightly above ground to cover seam
	add_child(ring)
