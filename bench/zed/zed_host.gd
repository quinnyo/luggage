class_name ZedHost
extends Node
## Host context & container for part nodes.


signal part_added(part_id: int)
signal part_removed(part_id: int)


const _ZedClass := preload("zed_class.gd")


var _bench: Bench
var _parts: Dictionary[int, PartBox]
var _id_next: int = 1


func setup_context(bench: Bench) -> void:
	_bench = bench
	_bench.get_workspace().shell_appearing.connect(_on_shell_appearing)
	_bench.get_workspace().shell_disappearing.connect(_on_shell_disappearing)


func get_part_count() -> int:
	return _parts.size()


func get_all_part_ids() -> PackedInt64Array:
	return PackedInt64Array(_parts.keys())


func get_part_instance(part_id: int) -> ZedPart:
	return _get_part(part_id).instance


func get_part_class(part_id: int) -> ZedClass:
	return _get_part(part_id).zed_class


## Get the Workspace shell owner ID allocated to the part with ID [param part_id].
func get_part_shell_id(part_id: int) -> int:
	return _get_part(part_id).shell_id


func has_part(part_id: int) -> bool:
	return _parts.has(part_id)


## callable is func(part_id: int, instance: ZedPart, zed_class: ZedClass)
func for_each_part(callable: Callable) -> void:
	for box in _parts.values():
		callable.call(box.id, box.instance, box.zed_class)


func clear() -> void:
	for part_id in _parts.keys():
		remove_part(part_id)


## Allocate a unique part ID
func alloc_part_id() -> int:
	var id := _id_next
	_id_next += 1
	return id


## Insert a part with the specified ID.
func insert_part(id: int, instance: ZedPart, zed_class: _ZedClass) -> void:
	assert(!_parts.has(id))
	assert(id != 0)
	_id_next = maxi(_id_next, id + 1)
	instance.id = id
	var box := PartBox.new()
	box.id = id
	box.instance = instance
	box.zed_class = zed_class
	_parts[id] = box
	zed_class.part_registered(instance, id)
	_create_shell(box, _bench.get_workspace().get_active_shell_type())
	part_added.emit(id)


## Add a part instance to the scene.
## The return value is a unique ID that can be used to refer to the part.
func add_part(instance: ZedPart, zed_class: _ZedClass) -> int:
	var id := alloc_part_id()
	insert_part(id, instance, zed_class)
	return id


func remove_part(part_id: int) -> void:
	var part := _get_part(part_id)
	_clear_shell(part)
	part.id = 0
	_parts.erase(part_id)
	part_removed.emit(part_id)


func is_part_player_owned(part_id: int) -> bool:
	return _get_part(part_id).is_player_owned


func notify_part_changed(part_id: int) -> void:
	var part := _get_part(part_id)
	_clear_shell(part)
	_create_shell(part, _bench.get_workspace().get_active_shell_type())


func part_has_pose(part_id: int) -> bool:
	return part_get_datum_count(part_id) > 0


func part_get_transform(part_id: int, index: int) -> Transform3D:
	return Transform3D(Basis.IDENTITY, _get_part(part_id).instance.get_position(index))


func part_set_transform(part_id: int, index: int, value: Transform3D) -> void:
	_get_part(part_id).instance.set_position(index, value.origin)
	_get_part(part_id).instance.set_euler(index, value.basis.get_euler())


func part_get_datum_count(part_id: int) -> int:
	return _get_part(part_id).instance.get_datum_count()


func _get_part(part_id: int) -> PartBox:
	if !has_part(part_id):
		push_error("Part not found (0x%X)" % [ part_id ])
		return null
	return _parts[part_id]


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
	var instance: ZedPart
	var zed_class: _ZedClass
	var shell_id: int
	var is_player_owned: bool = true
