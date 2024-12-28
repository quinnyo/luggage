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
var _shell_type: ShellType
var _shell_root: Node


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


func set_shell_type(to: ShellType) -> void:
	propagate_call(METHOD_ZED_SHELL_TYPE_CHANGING, [ self, to ])
	_shell_type = to


func get_shell_type() -> ShellType:
	return _shell_type


func add_shell_node(node: Node) -> void:
	if not _shell_root:
		_shell_root = Node.new()
		add_sibling(_shell_root)
	_shell_root.add_child(node)


class ZedBox:
	var instance: Node
	var zed_class: _ZedClass

	func serialise() -> Variant:
		return zed_class.serialise(instance)

	func deserialise(data) -> Error:
		return zed_class.deserialise(instance, data)
