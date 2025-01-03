class_name ZedScene
extends RefCounted


const _ZedClassTable := preload("zed_class_table.gd")

const OBJ_TYPE := &"type"
const OBJ_ID := &"id"
const OBJ_DATA := &"data"
const OBJ_KEYS := [OBJ_TYPE, OBJ_DATA]
const OBJ_VALUE_TYPES := [TYPE_INT, TYPE_DICTIONARY]
enum FieldInfo {
	NAME,
	TYPE,
	DICT,
}
const OBJ_FIELD_INFO: Dictionary[FieldInfo, Variant] = {
	FieldInfo.NAME: "obj",
	FieldInfo.TYPE: TYPE_DICTIONARY,
	FieldInfo.DICT: {
		OBJ_TYPE: {
			FieldInfo.TYPE: TYPE_INT,
		},
		OBJ_ID: {
			FieldInfo.TYPE: TYPE_INT,
		},
		OBJ_DATA: {
			FieldInfo.TYPE: TYPE_DICTIONARY,
		},
	}
}


var class_table: _ZedClassTable

var _used_types: Dictionary[int, ZedClass]
var _types: Dictionary[int, Dictionary]
var _objects: Array[Dictionary]
var _types_not_found: Dictionary[int, Dictionary]


func reset() -> void:
	_used_types = {}
	_types = {}
	_objects = []
	_types_not_found = {}


func serialise() -> Dictionary[StringName, Variant]:
	var dict: Dictionary[StringName, Variant] = {
		&"types": _types.duplicate(true),
		&"objects": _objects.duplicate(true),
	}
	return dict


func deserialise(dict: Dictionary[StringName, Variant]) -> void:
	reset()
	var types: Dictionary[int, Dictionary] = dict[&"types"]
	for id in types:
		var ti := types[id]
		var zc := class_table.lookup_type_info(ti)
		if not zc:
			_types_not_found[id] = ti
			push_error("Type %s not found in class table. Dumping type info dict:\n%s" % [ id, ti ])
			continue
		_used_types[id] = zc
		_types[id] = ti

	var objects: Array[Dictionary] = dict[&"objects"]
	for obj in objects:
		if !_field_check(obj, OBJ_FIELD_INFO):
			continue
		var type: int = obj[OBJ_TYPE]
		var obj_id: int = obj[OBJ_ID]
		var data: Dictionary[StringName, Variant] = obj[OBJ_DATA]
		if _used_types.has(type):
			_objects.push_back({
				OBJ_TYPE: type,
				OBJ_ID: obj_id,
				OBJ_DATA: data.duplicate(true),
			})
		elif _types_not_found.has(type):
			push_error("object type (%s) cannot be resolved. Object data:\n%s" % [ type, data ])
		else:
			push_error("object with unknown type (%s). Object data:\n%s" % [ type, data ])


func capture(host: ZedHost) -> void:
	reset()
	host.for_each_part(add_part)


func restore(host: ZedHost) -> void:
	for obj in _objects:
		_restore_part(host, _used_types[obj[OBJ_TYPE]], obj[OBJ_DATA], obj[OBJ_ID])


func add_part(part_id: int, instance: Node, type: ZedClass) -> void:
	assert(type)
	var type_id := use_type(type)
	_objects.push_back({
		OBJ_TYPE: type_id,
		OBJ_ID: part_id,
		OBJ_DATA: type.serialise(instance),
	})


func use_type(type: ZedClass) -> int:
	var h := hash_type(type)
	if !_used_types.has(h):
		_used_types[h] = type
	else:
		assert(_used_types[h] == type)
	_types[h] = type.get_type_info()
	return h


func hash_type(type: ZedClass) -> int:
	return hash(type.get_type_info())


func _restore_part(host: ZedHost, zed: ZedClass, data: Dictionary[StringName, Variant], part_id: int) -> void:
	var inst := zed.instantiate()
	var err := zed.deserialise(inst, data)
	if err != OK:
		push_error("zed deserialise failed: %s" % [ error_string(err) ])
		return
	host.insert_part(part_id, inst, zed)


func _field_check(value: Variant, field_info: Dictionary[FieldInfo, Variant]) -> bool:
	var errors := __field_check(value, field_info, [field_info.get(FieldInfo.NAME, "")])
	if errors.size():
		push_error("field check failed")
		for err in errors:
			push_error(err)
		return false
	return true


func __field_check(value: Variant, field_info: Dictionary, field_path: Array) -> Array:
	var errors := []
	if field_info.has(FieldInfo.TYPE):
		if typeof(value) != field_info[FieldInfo.TYPE]:
			errors.push_back("incorrect type")
	if field_info.has(FieldInfo.DICT) && typeof(value) == TYPE_DICTIONARY:
		var missing := []
		var dict: Dictionary = value
		var dict_field_info: Dictionary = field_info[FieldInfo.DICT]
		for key in dict_field_info:
			if !dict.has(key):
				missing.push_back(key)
				errors.push_back("missing key: %s" % [ key ])
			else:
				var sub_errors := __field_check(dict[key], dict_field_info[key], field_path + [key])
				for err in sub_errors:
					errors.push_back("error in %s: %s" % [ key, err ])
		if missing.size():
			errors.push_back("missing keys: %s" % [ missing ])
	return errors
