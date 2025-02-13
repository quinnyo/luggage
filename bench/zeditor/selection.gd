class_name ZeditorSelection
extends RefCounted


signal changed()


const SEL_ITEM_TYPE := &"item_type"
const SEL_ITEMS := &"items"
const SEL_INDEXED_ITEM := &"indexed_item"
const SEL_INDEXED_INDICES := &"indices"


class Selectable:
	var _data: Dictionary

	func has_item(item: Variant) -> bool:
		return indexed_get_item() == item if is_indexed() else get_items().has(item)

	func remove_item(item: Variant) -> void:
		assert(has_item(item))
		if is_indexed():
			_data.clear()
		else:
			_data[SEL_ITEMS].erase(item)

	func get_item_type() -> Variant:
		return _data[SEL_ITEM_TYPE] if _data.has(SEL_ITEM_TYPE) else null

	func get_items() -> Array:
		return _data[SEL_ITEMS] if _data.has(SEL_ITEMS) else []

	func set_items(items: Array) -> void:
		_data[SEL_ITEMS] = items

	func is_indexed() -> bool:
		var has_indexed_data := _data.has_all([ SEL_INDEXED_ITEM, SEL_INDEXED_INDICES ])
		return has_indexed_data

	func indexed_get_item() -> Variant:
		assert(is_indexed())
		return _data[SEL_INDEXED_ITEM]

	func indexed_get_indices() -> PackedInt64Array:
		assert(is_indexed())
		return _data[SEL_INDEXED_INDICES]

	func indexed_set_indices(indices: PackedInt64Array) -> void:
		assert(is_indexed())
		_data[SEL_INDEXED_INDICES] = indices

	func size() -> int:
		if is_indexed():
			return _data[SEL_INDEXED_INDICES].size()
		else:
			return get_items().size()

	func is_empty() -> bool:
		return size() == 0

	func can_merge(other: Selectable) -> bool:
		if get_item_type() != other.get_item_type() || is_indexed() != other.is_indexed():
			return false
		elif is_indexed():
			return indexed_get_item() == other.indexed_get_item()
		else:
			return true

	func merge(other: Selectable) -> void:
		assert(can_merge(other))
		if is_indexed():
			var indices: Dictionary[int, int] = {}
			for idx in indexed_get_indices():
				indices[idx] = 1
			for idx in other.indexed_get_indices():
				indices[idx] = 1
			indexed_set_indices(indices.keys())
		else:
			var items := {}
			for item in get_items():
				items[item] = 1
			for item in other.get_items():
				items[item] = 1
			set_items(items.keys())

	func clone() -> Selectable:
		var o := Selectable.new()
		o._data = _data.duplicate(true)
		return o

	static func create(item_type: Variant, items: Array[Variant]) -> Selectable:
		var o := Selectable.new()
		o._data[SEL_ITEM_TYPE] = item_type
		o._data[SEL_ITEMS] = items
		return o

	static func create_indexed(item_type: Variant, indexed_item: Variant, indices: PackedInt64Array) -> Selectable:
		var o := Selectable.new()
		o._data[SEL_ITEM_TYPE] = item_type
		o._data[SEL_INDEXED_ITEM] = indexed_item
		o._data[SEL_INDEXED_INDICES] = indices
		return o


class State:
	var _selectables: Array[Selectable]
	var _invalidated: bool

	func add(sel: Selectable) -> void:
		assert(_invalidated == false)
		for existing in _selectables:
			if existing.can_merge(sel):
				existing.merge(sel)
				return
		_selectables.push_back(sel)

	func remove_item(item_type: Variant, item: Variant) -> bool:
		var result := false
		for sel in _selectables:
			if sel.get_item_type() == item_type && sel.has_item(item):
				sel.remove_item(item)
				result = true
		if result:
			_selectables = _selectables.filter(func(sel): return !sel.is_empty())
		return result

	func has_item_type(item_type: Variant) -> bool:
		assert(_invalidated == false)
		for sel in _selectables:
			if sel.get_item_type() == item_type:
				return true
		return false

	func get_selectables_with_item_type(item_type: Variant) -> Array[Selectable]:
		assert(_invalidated == false)
		var result: Array[Selectable] = []
		for sel in _selectables:
			if sel.get_item_type() == item_type:
				result.push_back(sel.clone())
		return result

	func size() -> int:
		assert(_invalidated == false)
		var total := 0
		for sel in _selectables:
			total += sel.size()
		return total

	func is_empty() -> bool:
		assert(_invalidated == false)
		return size() == 0

	func clear() -> void:
		_selectables.clear()

	func clone() -> State:
		assert(_invalidated == false)
		var o := State.new()
		for sel in _selectables:
			o._selectables.push_back(sel.clone())
		return o

	func invalidate() -> void:
		clear()
		_invalidated = true


var _state: State = State.new()


func add_selectable(selectable: Selectable) -> void:
	_state.add(selectable)
	changed.emit()


func remove_item(item_type: Variant, item: Variant) -> bool:
	var result := _state.remove_item(item_type, item)
	if result:
		changed.emit()
	return result


func has_item_type(item_type: Variant) -> bool:
	return _state.has_item_type(item_type)


func get_selectables_with_item_type(item_type: Variant) -> Array[Selectable]:
	return _state.get_selectables_with_item_type(item_type)


func size() -> int:
	return _state.size()


func is_empty() -> bool:
	return _state.is_empty() if _state else true


func clear() -> void:
	if _state:
		_state.invalidate()
		_state = State.new()
	changed.emit()


func restore(state: State) -> void:
	_state = state.clone()
	changed.emit()


func get_state_copy() -> State:
	return _state.clone() if _state else State.new()
