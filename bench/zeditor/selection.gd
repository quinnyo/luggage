class_name ZeditorSelection
extends RefCounted


signal changed()


enum SelectableType {
	NONE,
	PART_ARMATURE_POINTS,
}


class State:
	var _invalidated: bool
	var _type: SelectableType
	var _items: Array
	var _part_id: int


	func get_type() -> SelectableType:
		assert(_invalidated == false)
		return _type


	func get_part_id() -> int:
		assert(_invalidated == false)
		return _part_id


	func get_items() -> Array:
		assert(_invalidated == false)
		return _items.duplicate()


	func is_empty() -> bool:
		assert(_invalidated == false)
		return _items.is_empty() || _type == SelectableType.NONE


	func clear() -> void:
		_type = SelectableType.NONE
		_items.clear()
		_part_id = 0


	func clone() -> State:
		assert(_invalidated == false)
		var o := State.new()
		o._type = _type
		o._items = _items.duplicate(true)
		o._part_id = _part_id
		return o


	func invalidate() -> void:
		clear()
		_invalidated = true


	static func select_part_armature(part_id: int, points: Array[int]) -> State:
		assert(part_id != 0)
		var o := State.new()
		o._type = SelectableType.PART_ARMATURE_POINTS
		o._items = points.duplicate()
		o._part_id = part_id
		return o


var _state: State


func get_active_type() -> SelectableType:
	return _state.get_type() if _state else SelectableType.NONE


func has_active_part() -> bool:
	return get_active_type() == SelectableType.PART_ARMATURE_POINTS


func get_active_part() -> int:
	return _state.get_part_id() if _state else 0


func get_active_items() -> Array:
	return _state.get_items() if _state else []


func is_empty() -> bool:
	return _state.is_empty() if _state else true


func clear() -> void:
	if _state:
		_state.invalidate()
		_state = null
	changed.emit()


func get_state_copy() -> State:
	return _state.clone() if _state else State.new()


func select_part_armature_points(part_id: int, points: Array[int]) -> void:
	if _state:
		_state.invalidate()
	_state = State.select_part_armature(part_id, points)
	changed.emit()
