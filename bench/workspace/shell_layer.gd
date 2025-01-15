extends Node3D
## Shell layer for Workspace -- a Node container.


class ShellState:
	var shell_nodes: Array[Node]


var shell_type: int


var _shells: Dictionary[int, ShellState]


func clear() -> void:
	for shell in _shells.values():
		_clear_shell(shell)
	_shells.clear()


func create_shell() -> int:
	var id := rid_allocate_id()
	var box := ShellState.new()
	_shells[id] = box
	return id


func add_shell_node(shell_id: int, shell_node: Node) -> void:
	assert(_shells.has(shell_id))
	var shell := _shells[shell_id]
	shell.shell_nodes.push_back(shell_node)
	add_child(shell_node)


func get_shell_nodes(shell_id: int) -> Array[Node]:
	assert(_shells.has(shell_id))
	return _shells[shell_id].shell_nodes.duplicate()


func remove_shell(shell_id: int) -> void:
	assert(_shells.has(shell_id))
	_clear_shell(_shells[shell_id])
	_shells.erase(shell_id)


func _clear_shell(shell: ShellState) -> void:
	for shell_node in shell.shell_nodes:
		shell_node.queue_free()
