class_name Workspace
extends Node3D
## Workspace is the spatial part of the bench.


const _WorkspaceShellLayer := preload("shell_layer.gd")


signal shell_appearing(type: int)
signal shell_disappearing(type: int)


var _shells: Array[_WorkspaceShellLayer]


func push_shell(shell_type: int) -> void:
	if _shells.size() > 0:
		_notify_shell_disappearing(_shell_top())
	var layer := _WorkspaceShellLayer.new()
	layer.shell_type = shell_type
	_shells.push_back(layer)
	_notify_shell_appearing(layer)
	add_child(layer)


func pop_shell() -> void:
	assert(has_shell())
	var top := _shell_top()
	_notify_shell_disappearing(top)
	_shells.pop_back()
	top.queue_free()
	if has_shell():
		_notify_shell_appearing(_shell_top())


func get_active_shell_type() -> int:
	if _shells.is_empty():
		return -1
	return _shell_top().shell_type


func shell_create_owner() -> int:
	assert(has_shell())
	return _shell_top().create_shell()


func shell_add_node(shell_id: int, shell_node: Node) -> void:
	assert(has_shell())
	_shell_top().add_shell_node(shell_id, shell_node)


func shell_remove(shell_id: int) -> void:
	assert(has_shell())
	_shell_top().remove_shell(shell_id)


func has_shell() -> bool:
	return _shells.size() > 0


func _shell_top() -> _WorkspaceShellLayer:
	assert(_shells.size() > 0)
	return _shells[-1]


func _notify_shell_appearing(layer: _WorkspaceShellLayer) -> void:
	shell_appearing.emit(layer.shell_type)


func _notify_shell_disappearing(layer: _WorkspaceShellLayer) -> void:
	shell_disappearing.emit(layer.shell_type)
	layer.clear()
