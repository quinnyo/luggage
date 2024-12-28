class_name ZedHost
extends Node


const _ZedClass := preload("zed_class.gd")


enum ShellType {
	NONE,
	EDIT,
	SIM,
}


const METHOD_ZED_REGISTER := &"_zed_register"
const METHOD_ZED_SHELL_TYPE_CHANGING := &"_zed_shell_type_changing"


var _boxed: Array[ZedBox]
var _shell_stack: Array[ShellLayer]


func serialise(context) -> Variant:
	return null


func deserialise(context, data) -> Error:
	return FAILED


func clear() -> void:
	_boxed.clear()
	for node in get_children():
		node.queue_free()


func add_node(instance: Node, zed_class: _ZedClass) -> void:
	add_child(instance)
	register(instance, zed_class)


func register(instance: Node, zed_class: _ZedClass) -> void:
	assert(is_ancestor_of(instance))
	instance.owner = self
	instance.propagate_call(METHOD_ZED_REGISTER, [ self ], true)
	var box := ZedBox.new()
	box.instance = instance
	box.zed_class = zed_class
	_boxed.push_back(box)


func get_shell_type() -> ShellType:
	if _shell_stack.size() > 0:
		return _shell_stack[-1].type
	return ShellType.NONE


## Push a new shell layer onto the stack.
## Returns true on success, or false if no change was made.
func push_shell(type: ShellType) -> bool:
	if get_shell_type() == type:
		return false
	var layer := ShellLayer.new()
	layer.type = type
	layer.shell_root_is_internal = true
	layer.shell_root = Node.new()
	add_sibling(layer.shell_root)
	_shell_stack.push_back(layer)
	propagate_call(METHOD_ZED_SHELL_TYPE_CHANGING, [ self, type ])
	return true


## Clear and remove the topmost shell layer.
func pop_shell() -> void:
	assert(_shell_stack.size() > 0)
	var layer := _shell_stack[-1]
	layer.clear()
	if layer.shell_root_is_internal:
		layer.shell_root.queue_free()
	_shell_stack.pop_back()


## Add a shell node to the current shell layer.
func add_shell_node(node: Node, _dtor: Callable = Callable()) -> void:
	assert(_shell_stack.size() > 0)
	_shell_stack[-1].add_shell_node(node)


class ZedBox:
	var instance: Node
	var zed_class: _ZedClass

	func serialise() -> Variant:
		return zed_class.serialise(instance)

	func deserialise(data) -> Error:
		return zed_class.deserialise(instance, data)


class ShellLayer:
	var type: ShellType
	var shell_root: Node
	## Set true if shell_root created by host, for this layer.
	var shell_root_is_internal: bool = false

	func add_shell_node(shell_node: Node) -> void:
		shell_root.add_child(shell_node)

	func clear() -> void:
		for child in shell_root.get_children():
			child.queue_free()
