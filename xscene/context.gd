class_name XSceneContext extends Node
## XScene instance, context & root node.


var _nodes: Array[XNode]


func something_to_do_with_saving() -> void:
	return


func something_to_do_with_loading() -> void:
	return


func register_node(node: XNode) -> void:
	assert(is_ancestor_of(node))
	_nodes.push_back(node)


func deregister_node(node: XNode) -> void:
	var idx := _nodes.find(node)
	if idx != -1:
		_nodes[idx] = _nodes[-1]
		_nodes.pop_back()
