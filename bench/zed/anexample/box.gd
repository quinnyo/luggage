extends Node


@export var size: Vector3 = Vector3.ONE
@export var density: float = 1.0
@export var position: Vector3


var _mesh: BoxMesh


func _create_visual() -> Node3D:
	if not _mesh:
		_mesh = BoxMesh.new()
	_mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = _mesh
	return mi


func _create_edit_root() -> Node3D:
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	var area := Area3D.new()
	area.add_child(collider)
	area.position = position
	return area


func _create_sim_root() -> Node3D:
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	var volume := shape.size.x * shape.size.y * shape.size.z
	var body := RigidBody3D.new()
	body.mass = volume * density
	body.add_child(collider)
	body.position = position
	return body


func _build_shell(host: ZedHost, shell_type: ZedHost.ShellType) -> void:
	var node: Node3D
	if shell_type == ZedHost.ShellType.EDIT:
		node = _create_edit_root()
	elif shell_type == ZedHost.ShellType.SIM:
		node = _create_sim_root()

	if node:
		node.add_child(_create_visual())
		host.add_shell_node(node)


func _zed_register(host: ZedHost) -> void:
	_build_shell(host, host.get_shell_type())


func _zed_shell_type_changing(host: ZedHost, shell_type: ZedHost.ShellType) -> void:
	_build_shell(host, shell_type)
