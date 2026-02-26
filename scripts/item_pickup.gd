extends Node3D

@export var material: Material
@export var item_name := "Item"
@export var highlight_color := Color(1.0, 0.9, 0.3)
@export var highlight_energy := 2.0

var _highlighted := false
var _normal_material: Material
var _highlight_material: StandardMaterial3D


func _ready() -> void:
	if material:
		_apply_to_children(self)
	_normal_material = material

	_highlight_material = StandardMaterial3D.new()
	if material is StandardMaterial3D:
		var src := material as StandardMaterial3D
		_highlight_material.albedo_texture = src.albedo_texture
	_highlight_material.albedo_color = Color(1.0, 1.0, 1.0)
	_highlight_material.emission_enabled = true
	_highlight_material.emission = highlight_color
	_highlight_material.emission_energy_multiplier = 0.05


func highlight() -> void:
	if _highlighted:
		return
	_highlighted = true
	_apply_material_to_children(self, _highlight_material)


func unhighlight() -> void:
	if not _highlighted:
		return
	_highlighted = false
	_apply_material_to_children(self, _normal_material)


func _apply_to_children(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		for i in mesh_instance.get_surface_override_material_count():
			mesh_instance.set_surface_override_material(i, material)
	for child in node.get_children():
		_apply_to_children(child)


func _apply_material_to_children(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		for i in mesh_instance.get_surface_override_material_count():
			mesh_instance.set_surface_override_material(i, mat)
	for child in node.get_children():
		_apply_material_to_children(child, mat)
