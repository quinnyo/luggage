class_name ZeditorSelection
extends RefCounted


const CONTEXT_DEFAULT := &"~"


signal changed()


var _state: Zelection:
	set(value):
		if _state && _state.changed.is_connected(_on_zelection_changed):
			_state.changed.disconnect(_on_zelection_changed)
		_state = value
		if _state:
			_state.changed.connect(_on_zelection_changed)


func add(type: StringName, context: Variant, item: Variant) -> void:
	_state.add(type, context, item)


func remove(type: StringName, context: Variant, item: Variant) -> void:
	_state.remove(type, context, item)


func remove_all(type: StringName, context: Variant) -> void:
	_state.remove_all(type, context)


func has(type: StringName, context: Variant, item: Variant) -> bool:
	var result := _state.has(type, context, item)
	if result:
		changed.emit()
	return result


func has_type(type: StringName) -> bool:
	return _state.has_type(type)


func is_empty() -> bool:
	return _state.is_empty() if _state else true


func clear() -> void:
	_state = Zelection.new()
	_notify_changed()


## Restore selection from [param state]
func restore(state: Zelection) -> void:
	_state = state.clone()
	_notify_changed()


func get_state_copy() -> Zelection:
	return _state.clone() if _state else Zelection.new()


func get_direct_state() -> Zelection:
	return _state


func for_each_selection_where_type(type: StringName, callable: Callable) -> void:
	_state.for_each_selection_where_type(type, callable)


func for_each_item_where_type(type: StringName, callable: Callable) -> void:
	_state.for_each_item_where_type(type, callable)


func _notify_changed() -> void:
	changed.emit()


func _on_zelection_changed() -> void:
	_notify_changed()


func _init() -> void:
	_state = Zelection.new()
