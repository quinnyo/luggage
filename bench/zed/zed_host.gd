class_name ZedHost
extends Node
## Host context & container for part nodes.


const _ZedClass := preload("zed_class.gd")


var _bench: Bench
var _parts: Dictionary[int, PartBox]
var _parts_by_instance_id: Dictionary[int, PartBox]
var _idrng: RandomNumberGenerator = RandomNumberGenerator.new()


func setup_context(bench: Bench) -> void:
	_bench = bench
	_bench.get_workspace().shell_appearing.connect(_on_shell_appearing)
	_bench.get_workspace().shell_disappearing.connect(_on_shell_disappearing)


func get_part_count() -> int:
	return _parts.size()


func get_all_part_ids() -> PackedInt64Array:
	return PackedInt64Array(_parts.keys())


func get_part_instance(part_id: int) -> Node:
	assert(has_part(part_id))
	return _parts[part_id].instance


func has_part(part_id: int) -> bool:
	return _parts.has(part_id)


## callable is func(part_id: int, instance: Node, zed_class: ZedClass)
func for_each_part(callable: Callable) -> void:
	for box in _parts.values():
		callable.call(box.id, box.instance, box.zed_class)


func clear() -> void:
	for part in _parts.values():
		_destroy_part(part)
	_parts.clear()
	_parts_by_instance_id.clear()
	for node in get_children():
		node.queue_free()


## Insert a part with the specified ID. The node will be parented to the host.
func insert_part(id: int, instance: Node, zed_class: _ZedClass) -> void:
	assert(!_parts.has(id))
	assert(id != 0)
	add_child(instance)
	instance.owner = self
	var box := PartBox.new()
	box.id = id
	box.instance = instance
	box.zed_class = zed_class
	_parts[id] = box
	_parts_by_instance_id[instance.get_instance_id()] = box
	zed_class.part_registered(instance, id, self)
	_create_shell(box, _bench.get_workspace().get_active_shell_type())


## Add a part instance to the scene. The node will be parented to the host.
## The return value is a unique ID that can be used to refer to the part.
func add_part(instance: Node, zed_class: _ZedClass) -> int:
	var id := _idrng.randi() # NOTE: randi() value is in 32 bit range
	insert_part(id, instance, zed_class)
	return id


func remove_part(part_id: int) -> void:
	assert(has_part(part_id))
	var part := _parts[part_id]
	_destroy_part(part)
	_parts.erase(part_id)


func notify_part_changed(instance: Node) -> void:
	assert(_parts_by_instance_id.has(instance.get_instance_id()))
	var part := _parts_by_instance_id[instance.get_instance_id()]
	_clear_shell(part)
	_create_shell(part, _bench.get_workspace().get_active_shell_type())


## NOTE: does not remove the part from the `_parts` container!
func _destroy_part(part: PartBox) -> void:
	_clear_shell(part)
	part.instance.queue_free()
	part.id = 0


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
	for part in _parts.values():
		_create_shell(part, type)


func _on_shell_disappearing(_type: Zed.ShellType) -> void:
	for part in _parts.values():
		_clear_shell(part)


class PartBox:
	var id: int
	var instance: Node
	var zed_class: _ZedClass
	var shell_id: int
