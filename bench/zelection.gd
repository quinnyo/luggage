class_name Zelection
extends RefCounted
## A container for use in common item selection and operation targeting scenarios.
##
## The identity of a selectable/item is fully defined by its Type-Context-Item ([i]TCI[/i]) triplet:
##
## [br][br][i][u]Type[/u][/i]: A primary class identified by a [StringName] selected by the user.
## [br][br][i][u]Context[/u][/i]: A division of a Type identified by a [Variant].
## [br][br][i][u]Item[/u][/i]: Individual item provided by the user as a [Variant].
##
## [br][br][b]Identifier Data Requirements[/b]:
## There are no enforced restrictions on the data/encoding scheme used for Item and Context values.
## However, as this data is kept exactly as provided, it's critical that the state of these fields
## remains constant. The hash of an identifier is expected to follow this rule as well.
## Godot and GDScript make it trivially easy to achieve this, but care must be taken, particularly
## if using a [Variant] type that can be referenced from multiple sites.



## Emitted when the selection is modified i.e. when items are added or removed.
signal changed()


var _tc_cells: Dictionary[int, Selcell]


## Create a clone instance with an identical set of items to this one.
func clone() -> Zelection:
	var o := Zelection.new()
	for tc in _tc_cells:
		o._tc_cells[tc] = _tc_cells[tc].clone()
	return o


## Add an item to the selection.
## Returns [code]true[/code] if successul or [code]false[/code] otherwise.
func add(type: StringName, context: Variant, item: Variant) -> bool:
	var tc := Selcell.tc_key(type, context)
	# Merge if TC exists
	var other := _get_cell(tc)
	if other:
		if !other.has_item(item):
			other.add_item(item)
			_notify_changed()
			return true
		return false
	# No merge...
	var selcell := Selcell.create_single(type, context, item)
	_tc_cells[tc] = selcell
	_notify_changed()
	return true


## If the selection contains a matching item, remove it.
## Returns [code]true[/code] if an item was removed or [code]false[/code] otherwise.
func remove(type: StringName, context: Variant, item: Variant) -> bool:
	var tc := Selcell.tc_key(type, context)
	var selcell := _get_cell(tc)
	if selcell && selcell.has_item(item):
		selcell.remove_item(item)
		if selcell.size() == 0:
			selcell.free()
			_tc_cells.erase(tc)
		_notify_changed()
		return true
	return false


## Remove all items matching TC.
func remove_all(type: StringName, context: Variant) -> int:
	var tc := Selcell.tc_key(type, context)
	var selcell := _get_cell(tc)
	if selcell:
		var n := selcell.size()
		selcell.free()
		_tc_cells.erase(tc)
		_notify_changed()
		return n
	return 0


## Check if the selection contains a matching item.
## Returns [code]true[/code] if a match was found or [code]false[/code] otherwise.
func has(type: StringName, context: Variant, item: Variant) -> bool:
	var selcell := _get_cell(Selcell.tc_key(type, context))
	if selcell:
		return selcell.has_item(item)
	return false


## Check if at least one item is selected with the given [param type].
## Returns [code]true[/code] if a match was found or [code]false[/code] otherwise.
func has_type(type: StringName) -> bool:
	for selcell in _tc_cells.values():
		if selcell.type == type && selcell.size():
			return true
	return false


## Count the number of items selected and return the result.
func size() -> int:
	var n := 0
	for selcell in _tc_cells.values():
		n += selcell.size()
	return n


## Returns [code]true[/code] if zero items are selected or [code]false[/code] otherwise.
func is_empty() -> bool:
	for selcell in _tc_cells.values():
		if selcell.size():
			return false
	return true


func for_each_selection(callable: Callable) -> void:
	for tc in _tc_cells:
		var selcell := _tc_cells[tc]
		callable.call(selcell.type, selcell.context, selcell.items.values())


## Find all selection-contexts matching [param type] and call [param callable] for each one.
## [param callable] signature: [code]func(type: StringName, context: Variant, items: Array)[/code]
func for_each_selection_where_type(type: StringName, callable: Callable) -> void:
	for tc in _tc_cells:
		var selcell := _tc_cells[tc]
		if selcell.type == type:
			callable.call(selcell.type, selcell.context, selcell.items.values())


## Iterate over the entire selection, calling [param callable] for each item.
## [param callable] signature: [code]func(type: StringName, context: Variant, item: Variant)[/code]
func for_each_item(callable: Callable) -> void:
	for tc in _tc_cells:
		var selcell := _tc_cells[tc]
		for item in selcell.items.values():
			callable.call(selcell.type, selcell.context, item)


## Find all selected items matching [param type] and call [param callable] for each one.
## [param callable] signature: [code]func(type: StringName, context: Variant, item: Variant)[/code]
func for_each_item_where_type(type: StringName, callable: Callable) -> void:
	for tc in _tc_cells:
		var selcell := _tc_cells[tc]
		if selcell.type == type:
			for item in selcell.items.values():
				callable.call(selcell.type, selcell.context, item)


func dump_str() -> String:
	var lines := PackedStringArray(["%3d cells, %3d items" % [ _tc_cells.size(), size() ]])
	for tc in _tc_cells:
		var selcell := _tc_cells[tc]
		lines.push_back("  cell %8X (%s, %s), %d items:" % [ tc, selcell.type, selcell.context, selcell.size() ])
		lines.push_back("         TCI: VALUE")
		for tci in selcell.items:
			lines.push_back("    %8X: %s" % [ tci, selcell.items[tci] ])
	return "\n".join(lines)


func _get_cell(p_tc: int) -> Selcell:
	if _tc_cells.has(p_tc):
		var selcell: Selcell = _tc_cells[p_tc]
		assert(is_instance_valid(selcell))
		return selcell
	return null


func _notify_changed() -> void:
	changed.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for selcell in _tc_cells.values():
			selcell.free()
		_tc_cells.clear()


## [b][u]This class is not intended for outside use.[/u][/b]
##
## An "atomic" selection container for use by [Zelection].
class Selcell extends Object:
	var type: StringName
	var context: Variant
	var items: Dictionary

	func add_item(p_item: Variant) -> void:
		items[tci_key(type, context, p_item)] = p_item

	func remove_item(p_item: Variant) -> void:
		var tci := tci_key(type, context, p_item)
		if items.has(tci):
			items.erase(tci)

	func has_item(p_item: Variant) -> bool:
		return items.has(tci_key(type, context, p_item))

	func size() -> int:
		return items.size()

	func match_tci(p_type: StringName, p_context: Variant, p_item: Variant) -> bool:
		return items.has(tci_key(p_type, p_context, p_item))

	func get_tc() -> int:
		return tc_key(type, context)

	func clone() -> Selcell:
		return Selcell.new(type, context, items.duplicate())

	static func tc_key(p_type: StringName, p_context: Variant) -> int:
		return hash([p_type, p_context])

	static func tci_key(p_type: StringName, p_context: Variant, p_item: Variant) -> int:
		return hash([p_type, p_context, p_item])

	static func create_single(p_type: StringName, p_context: Variant, p_item: Variant) -> Selcell:
		return new(p_type, p_context, { tci_key(p_type, p_context, p_item): p_item } )

	func _init(p_type: StringName, p_context: Variant, p_items: Dictionary = {}) -> void:
		type = p_type
		context = p_context
		items = p_items
