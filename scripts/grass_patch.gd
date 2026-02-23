extends MultiMeshInstance3D

## Number of grass blades per patch
@export var blade_count := 80
## Size of the patch area (width x depth)
@export var patch_size := Vector2(2.0, 2.0)
## Min/max scale of grass blades
@export var blade_scale_min := 0.15
@export var blade_scale_max := 0.25
## Shared material (set by map_loader to avoid duplicating per patch)
var shared_material: ShaderMaterial


func _ready() -> void:
	_build()


func _build() -> void:
	var blade_mesh: Mesh = load("res://assets/models/grass/grass.obj")

	var mat_mesh := blade_mesh.duplicate() as Mesh
	mat_mesh.surface_set_material(0, shared_material)

	# Create MultiMesh
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = blade_count
	mm.mesh = mat_mesh

	# Scatter blades randomly within the patch
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var half_w := patch_size.x / 2.0
	var half_d := patch_size.y / 2.0

	for i in blade_count:
		var x := rng.randf_range(-half_w, half_w)
		var z := rng.randf_range(-half_d, half_d)
		var rot := rng.randf_range(0.0, TAU)
		var scale_val := rng.randf_range(blade_scale_min, blade_scale_max)

		var t := Transform3D()
		t = t.scaled(Vector3(scale_val, scale_val, scale_val))
		t = t.rotated(Vector3.UP, rot)
		t.origin = Vector3(x, 0, z)
		mm.set_instance_transform(i, t)

	multimesh = mm
