extends MultiMeshInstance3D

## Number of grass blades per patch
@export var blade_count := 200
## Size of the patch area (width x depth)
@export var patch_size := Vector2(2.0, 2.0)
## Height range of grass blades
@export var blade_height_min := 0.15
@export var blade_height_max := 0.35
## Width range of grass blades
@export var blade_width_min := 0.04
@export var blade_width_max := 0.08
## Shared material (set by map_loader to avoid duplicating per patch)
var shared_material: ShaderMaterial


func _ready() -> void:
	_build()


func _build() -> void:
	var cross_mesh := _create_cross_blade_mesh()
	cross_mesh.surface_set_material(0, shared_material)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = blade_count
	mm.mesh = cross_mesh

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var half_w := patch_size.x / 2.0
	var half_d := patch_size.y / 2.0

	for i in blade_count:
		var x := rng.randf_range(-half_w, half_w)
		var z := rng.randf_range(-half_d, half_d)
		var rot := rng.randf_range(0.0, TAU)
		var height := rng.randf_range(blade_height_min, blade_height_max)
		var width := rng.randf_range(blade_width_min, blade_width_max)

		var t := Transform3D()
		# Non-uniform scale: thin X/Z, tall Y
		t = t.scaled(Vector3(width, height, width))
		t = t.rotated(Vector3.UP, rot)
		t.origin = Vector3(x, 0, z)
		mm.set_instance_transform(i, t)

	multimesh = mm


func _create_cross_blade_mesh() -> ArrayMesh:
	# Blade shape: tapered quad from base (y=0) to tip (y=4)
	var blade_verts := [
		Vector3(-0.5, 0.0, 0.0), Vector3(0.5, 0.0, 0.0), Vector3(-0.375, 1.0, 0.0),
		Vector3(0.5, 0.0, 0.0), Vector3(0.375, 1.0, 0.0), Vector3(-0.375, 1.0, 0.0),
		Vector3(-0.375, 1.0, 0.0), Vector3(0.375, 1.0, 0.0), Vector3(-0.25, 2.0, 0.0),
		Vector3(0.375, 1.0, 0.0), Vector3(0.25, 2.0, 0.0), Vector3(-0.25, 2.0, 0.0),
		Vector3(-0.25, 2.0, 0.0), Vector3(0.25, 2.0, 0.0), Vector3(-0.125, 3.0, 0.0),
		Vector3(0.25, 2.0, 0.0), Vector3(0.125, 3.0, 0.0), Vector3(-0.125, 3.0, 0.0),
		Vector3(-0.125, 3.0, 0.0), Vector3(0.125, 3.0, 0.0), Vector3(0.0, 4.0, 0.0),
	]

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var up := Vector3(0, 1, 0)

	# Plane 1: facing Z
	for v in blade_verts:
		vertices.append(v)
		normals.append(up)

	# Plane 2: rotated 90° around Y (facing X)
	for v in blade_verts:
		vertices.append(Vector3(v.z, v.y, v.x))
		normals.append(up)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
