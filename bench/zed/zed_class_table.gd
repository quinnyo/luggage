#class_name ZedClassTable
extends RefCounted


const _ZedClass := preload("zed_class.gd")


class Entry:
	var type: _ZedClass
	#var shells: Array[_ZedShell]


var _table: Dictionary[StringName, Entry] = {}


func add_type(type: _ZedClass) -> void:
	if has_type(type.get_type_name()):
		push_error("Cannot add type (%s): type with ID already exists" % [ type ])
		return
	else:
		_get_create(type.get_type_name()).type = type
		#_table[type.get_type_name()] = type


func has_type(id: StringName) -> bool:
	return _table.has(id) && _table[id].type


func get_type(id: StringName) -> _ZedClass:
	return _table[id].type


#func add_shell(type_id: StringName,



#func get_types() -> Array[_ZedClass]:
	#return _table.values()


func _has_entry(id: StringName) -> bool:
	return _table.has(id)


func _get_create(id: StringName) -> Entry:
	if _table.has(id):
		return _table[id]
	else:
		var entry := Entry.new()
		_table[id] = entry
		return entry
