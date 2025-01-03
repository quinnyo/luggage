class_name ZedHost
extends Node
## Host context & container for part nodes.


const _ZedClass := preload("zed_class.gd")


var _bench: Bench
var _parts: Array[PartBox]
var _parts_by_instance_id: Dictionary[int, PartBox]


func setup_context(bench: Bench) -> void:
	_bench = bench
	_bench.get_workspace().shell_appearing.connect(_on_shell_appearing)
	_bench.get_workspace().shell_disappearing.connect(_on_shell_disappearing)


func get_part_count() -> int:
	return _parts.size()


func get_part_instance(index: int) -> Node:
	return _parts[index].instance


## callable is func(instance: Node, zed_class: ZedClass)
func for_each_part(callable: Callable) -> void:
	for box in _parts:
		callable.call(box.instance, box.zed_class)


func clear() -> void:
	var workspace := _bench.get_workspace()
	for part in _parts:
		workspace.shell_remove(part.shell_id)
		part.shell_id = 0
	_parts.clear()
	for node in get_children():
		node.queue_free()


func add_part(instance: Node, zed_class: _ZedClass) -> void:
	add_child(instance)
	instance.owner = self
	var box := PartBox.new()
	box.instance = instance
	box.zed_class = zed_class
	_parts.push_back(box)
	_parts_by_instance_id[instance.get_instance_id()] = box
	_create_shell(box, _bench.get_workspace().get_active_shell_type())


func notify_part_changed(instance: Node) -> void:
	assert(_parts_by_instance_id.has(instance.get_instance_id()))
	var part := _parts_by_instance_id[instance.get_instance_id()]
	_clear_shell(part)
	_create_shell(part, _bench.get_workspace().get_active_shell_type())


func _create_shell(part: PartBox, type: Zed.ShellType) -> void:
	var workspace := _bench.get_workspace()
	assert(part.shell_id == 0, "part has non-zero shell_id")
	part.shell_id = workspace.shell_create_owner()
	for shell_node in part.zed_class.create_shell(part.instance, type):
		workspace.shell_add_node(part.shell_id, shell_node)


func _clear_shell(part: PartBox) -> void:
	var workspace := _bench.get_workspace()
	if part.shell_id:
		workspace.shell_remove(part.shell_id)
		part.shell_id = 0


func _on_shell_appearing(type: Zed.ShellType) -> void:
	for part in _parts:
		_create_shell(part, type)


func _on_shell_disappearing(_type: Zed.ShellType) -> void:
	for part in _parts:
		_clear_shell(part)


class PartBox:
	var instance: Node
	var zed_class: _ZedClass
	var shell_id: int
