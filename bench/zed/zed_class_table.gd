#class_name ZedClassTable
extends RefCounted
## A container of (ZedClass) part class definitions.


class Entry:
	var type: ZedClass
	var type_info: Dictionary[StringName, Variant]
	var uid: int:
		get:
			return type_info.get(ZedClass.TYPE_INFO_UID, ResourceUID.INVALID_ID)

	func setup(p_type: ZedClass) -> void:
		type = p_type
		type_info = type.get_type_info()


var _table: Dictionary[StringName, Entry] = {}
var _uid_table: Dictionary[int, Entry] = {}


func add_type(type: ZedClass) -> void:
	if has_type(type.get_type_name()):
		push_error("Cannot add type (%s): type with ID already exists" % [ type ])
		return
	else:
		var entry := _get_create(type.get_type_name())
		entry.setup(type)
		if entry.uid != ResourceUID.INVALID_ID:
			if _uid_table.has(entry.uid):
				assert(_uid_table[entry.uid] == entry, "UID conflict!?")
			else:
				_uid_table[entry.uid] = entry


func has_type(id: StringName) -> bool:
	return _table.has(id) && _table[id].type


func get_type(id: StringName) -> ZedClass:
	return _table[id].type


func has_type_uid(uid: int) -> bool:
	return _uid_table.has(uid)


func get_type_uid(uid: int) -> ZedClass:
	return _uid_table[uid].type


func lookup_type_info(ti: Dictionary[StringName, Variant]) -> ZedClass:
	var uid: int = ti.get(ZedClass.TYPE_INFO_UID)
	if has_type_uid(uid):
		return get_type_uid(uid)
	var type_name: StringName = ti.get(ZedClass.TYPE_INFO_TYPE_NAME)
	if has_type(type_name):
		return get_type(type_name)
	# TODO: recovery attempt? -- try load resource
	#var uid: int = types[id][ZedClass.TYPE_INFO_UID]
	#if ResourceUID.has_id(uid):
		#var path := ResourceUID.get_id_path(uid)
	return null


func get_classes() -> Array[ZedClass]:
	var result: Array[ZedClass] = []
	for entry in _table.values():
		result.push_back(entry.type)
	return result


func _has_entry(id: StringName) -> bool:
	return _table.has(id)


func _get_create(id: StringName) -> Entry:
	if _table.has(id):
		return _table[id]
	else:
		var entry := Entry.new()
		_table[id] = entry
		return entry
