extends MeshInstance3D

var patch_size := Vector2(2.0, 2.0)
var peak_height := 1.0
var shared_material: ShaderMaterial
var ring_material: ShaderMaterial
# Neighbor presence per vertex: [SE, S, SW, W, NW, N, NE, E]
var neighbors_8: Array = [0, 0, 0, 0, 0, 0, 0, 0]


func _ready() -> void:
	_build()


# Simple deterministic hash for vertex perturbation
func _hash(x: float, y: float) -> float:
	return fmod(abs(sin(x * 127.1 + y * 311.7) * 43758.5453), 1.0)


func _build() -> void:
	var sides := 16
	var base_radius := patch_size.x / 2.0 * 1.15
	var total_neighbors := 0
	for n in neighbors_8:
		if n > 0.5:
			total_neighbors += 1
	var scaled_peak_height := peak_height * (1.0 + total_neighbors * 0.05)
	var angle_offset := PI / 4.0
	var extend_step := patch_size.x * 0.1

	# Seed for noise — use world position so each mountain looks unique
	var seed_x := transform.origin.x * 7.3
	var seed_z := transform.origin.z * 13.1

	# Build rings from base to near-peak, then add peak vertex
	# Each ring: [height_fraction, radius_fraction, noise_amount]
	var ring_defs := [
		[0.0, 1.0, 0.0],      # base — no noise, keep clean shape
		[0.25, 0.75, 0.18],   # lower slope
		[0.50, 0.50, 0.20],   # mid slope
		[0.75, 0.28, 0.15],   # upper slope
	]

	# Generate vertex rings
	var rings: Array[Array] = []
	for ri in ring_defs.size():
		var h_frac: float = ring_defs[ri][0]
		var r_frac: float = ring_defs[ri][1]
		var noise_amt: float = ring_defs[ri][2]
		var ring_verts: Array[Vector3] = []

		for i in sides:
			var angle := i * TAU / sides + angle_offset
			var r := base_radius * r_frac

			# Base ring: extend toward neighbors (16 sides = 2 per neighbor direction)
			if ri == 0:
				var nb_idx := i / 2  # 0-1→nb0, 2-3→nb1, ..., 14-15→nb7
				if nb_idx < 8 and neighbors_8[nb_idx] > 0.5:
					r += extend_step * total_neighbors

			# Noise perturbation (skip base ring)
			if ri > 0:
				var h_noise := _hash(seed_x + i * 3.7, seed_z + ri * 5.3)
				var r_noise := _hash(seed_x + i * 11.3, seed_z + ri * 7.1)
				var a_noise := _hash(seed_x + i * 2.1, seed_z + ri * 9.7)
				r *= 1.0 + (r_noise - 0.5) * noise_amt * 2.0
				angle += (a_noise - 0.5) * 0.15
				h_frac = ring_defs[ri][0] + (h_noise - 0.5) * noise_amt * 0.3

			var y := h_frac * scaled_peak_height
			ring_verts.append(Vector3(cos(angle) * r, y, sin(angle) * r))

		rings.append(ring_verts)

	# Peak vertex with slight random offset
	var peak_offset_x := (_hash(seed_x + 100.0, seed_z) - 0.5) * base_radius * 0.1
	var peak_offset_z := (_hash(seed_x, seed_z + 100.0) - 0.5) * base_radius * 0.1
	var peak_vertex := Vector3(peak_offset_x, scaled_peak_height, peak_offset_z)

	# Build indexed mesh for smooth normals
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Add all unique vertices: rings + peak + base center
	# Ring vertices: ring_index * sides + vert_index
	for ri in rings.size():
		for i in sides:
			st.add_vertex(rings[ri][i])
	# Peak vertex index = rings.size() * sides
	var peak_idx := rings.size() * sides
	st.add_vertex(peak_vertex)
	# Base center index = peak_idx + 1
	var base_center_idx := peak_idx + 1
	st.add_vertex(Vector3.ZERO)

	# Connect adjacent rings with quad strips
	for ri in rings.size() - 1:
		for i in sides:
			var i_next := (i + 1) % sides
			var bl := ri * sides + i
			var br := ri * sides + i_next
			var tl := (ri + 1) * sides + i
			var tr := (ri + 1) * sides + i_next
			# Triangle 1
			st.add_index(bl)
			st.add_index(br)
			st.add_index(tl)
			# Triangle 2
			st.add_index(br)
			st.add_index(tr)
			st.add_index(tl)

	# Connect top ring to peak (triangle fan)
	var top_ring_start := (rings.size() - 1) * sides
	for i in sides:
		st.add_index(top_ring_start + i)
		st.add_index(top_ring_start + (i + 1) % sides)
		st.add_index(peak_idx)

	# Base faces (triangle fan, facing down — separate smooth group)
	for i in sides:
		st.add_index(base_center_idx)
		st.add_index((i + 1) % sides)
		st.add_index(i)

	# Generate smooth normals from shared vertex positions
	st.generate_normals()

	mesh = st.commit()

	# Per-instance material with peak_height
	var mat := shared_material.duplicate() as ShaderMaterial
	mat.set_shader_parameter("peak_height", scaled_peak_height)
	material_override = mat

	# Collision to block navigation
	var box_height := scaled_peak_height
	var static_body := StaticBody3D.new()
	static_body.transform.origin = Vector3(0, box_height / 2.0, 0)

	var col_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(patch_size.x, box_height, patch_size.y)
	col_shape.shape = box

	static_body.add_child(col_shape)
	add_child(static_body)

	# Ground ring — flat transparent circle blending into ground
	var ring := MeshInstance3D.new()
	var ring_plane := PlaneMesh.new()
	ring_plane.size = patch_size * 1.8
	ring.mesh = ring_plane
	ring.material_override = ring_material
	ring.position.y = 0.01
	add_child(ring)
