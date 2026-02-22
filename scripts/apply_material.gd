extends Node3D

@export var material: Material


func _ready() -> void:
	if material:
		_apply_to_children(self)


func _apply_to_children(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		for i in mesh_instance.get_surface_override_material_count():
			mesh_instance.set_surface_override_material(i, material)
	for child in node.get_children():
		_apply_to_children(child)
