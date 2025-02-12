class_name Notices
extends RefCounted


class Notice:
	var value: Variant

	func _init(p_value: Variant) -> void:
		value = p_value


var _new: Dictionary[StringName, Notice]
var _notices: Dictionary[StringName, Notice]


## If a notice named [param key] is present, return true if it is new/unmarked.
## Returns false if no notice was found.
func is_new(key: StringName) -> bool:
	return _new.has(key)


func has(key: StringName) -> bool:
	return _notices.has(key)


func read(key: StringName, apply_mark: bool = false) -> Variant:
	if apply_mark:
		mark(key)
	return _notices[key].value


func mark(key: StringName) -> void:
	if _new.has(key):
		_new.erase(key)


func add(key: StringName, value: Variant) -> void:
	var notice := Notice.new(value)
	_notices[key] = notice
	_new[key] = notice

func remove(key: StringName) -> void:
	if _new.has(key):
		_new.erase(key)
	_notices.erase(key)
