extends ZedPart


@export var size: Vector3 = Vector3.ONE
@export var density: float = 1.0
@export var position: Vector3:
	set(value):
		position = value.snapped(size / 2.0)


var _part_id: int
var _mesh: BoxMesh
var _material: StandardMaterial3D


func _create_visual() -> Node3D:
	if not _mesh:
		_mesh = BoxMesh.new()
	_mesh.size = size
	if not _material:
		_material = StandardMaterial3D.new()
		_material.albedo_color = Color(0.97, 0.96, 0.94)
	var mi := MeshInstance3D.new()
	mi.mesh = _mesh
	mi.material_override = _material
	return mi


func _create_edit() -> Node3D:
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	var node := Placement3D.new()
	node.part_id = _part_id
	node.armature_index = 0
	node.add_child(collider)
	node.add_child(_create_visual())
	return node


func _create_sim() -> Node3D:
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	var volume := shape.size.x * shape.size.y * shape.size.z
	var node := RigidBody3D.new()
	node.mass = volume * density
	node.add_child(collider)
	node.position = position
	node.add_child(_create_visual())
	return node
