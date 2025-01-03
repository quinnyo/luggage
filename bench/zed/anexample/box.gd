extends Node


@export var size: Vector3 = Vector3.ONE
@export var density: float = 1.0
@export var position: Vector3


var _part_id: int
var _mesh: BoxMesh


func _create_visual() -> Node3D:
	if not _mesh:
		_mesh = BoxMesh.new()
	_mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = _mesh
	return mi


func _create_edit() -> Node3D:
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	var node := WorkspaceVolume.new()
	node.part_id = _part_id
	node.add_child(collider)
	node.position = position
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
