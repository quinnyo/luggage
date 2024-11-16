class_name Selection extends RefCounted
## Object selection state


signal selection_changed()


var _selected: Dictionary = {}


func add_node(node: Node) -> void:
	_remove_node(node)
	_add_node(node)
	selection_changed.emit()


func remove_node(node: Node) -> void:
	_remove_node(node)
	selection_changed.emit()


func clear() -> void:
	if _selected.size() != 0:
		_selected = {}
		selection_changed.emit()


func get_selected_nodes() -> Array[Node]:
	var nodes: Array[Node] = []
	for node in _selected:
		if node is Node:
			nodes.push_back(node)
	return nodes


func _add_node(node: Node) -> void:
	_selected[node] = true


func _remove_node(node: Node) -> void:
	_selected.erase(node)
