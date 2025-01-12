class_name ItemPicker
extends Control
## Displays a set of items for user to pick from...


signal item_selected(item_id: int)
signal aborted()


class Group:
	var id: int
	var text: String:
		get:
			return label.text
		set(value):
			label.text = value
			label.visible = !label.text.is_empty()
	var container: Container
	var label: Label
	var item_container: Container

	func _init(p_id: int) -> void:
		id = p_id
		container = VBoxContainer.new()
		label = Label.new()
		container.add_child(label)
		item_container = FlowContainer.new()
		container.add_child(item_container)


const _Item := preload("item_picker_item.gd")


const GROUP_DEFAULT := 0


@onready var item_list_container: Control = %ItemListContainer

var _groups: Dictionary[int, Group]
var _items: Dictionary[int, _Item]
var _current: _Item


func clear() -> void:
	for key in _groups.keys():
		var g := _groups[key]
		g.container.queue_free()
	_groups.clear()
	_items.clear()
	_current = null
	_reset()


func add_item(text: String, icon: Texture2D, group_id: int = GROUP_DEFAULT) -> int:
	var g := _groups[group_id]
	var item_id := randi()
	assert(!_items.has(item_id))
	var item := _Item.new()
	item.setup(item_id, group_id)
	item.text = text
	item.icon = icon
	item.pressed.connect(_selected.bind(item))
	_items[item_id] = item
	g.item_container.add_child(item)
	return item_id


func item_set_disabled(item_id: int, disabled: bool) -> void:
	var item := _items[item_id]
	item.disabled = disabled


func item_set_selected(item_id: int, selected: bool) -> void:
	var item := _items[item_id]
	item.set_pressed_no_signal(selected)
	if selected:
		_current = item


func item_set_userdata(item_id: int, data: Variant) -> void:
	var item := _items[item_id]
	item.userdata = data


func item_get_userdata(item_id: int) -> Variant:
	return _items[item_id].userdata


func group_create(text: String) -> int:
	var id := randi()
	return _group_create(id, text)


func group_set_text(id: int, text: String) -> void:
	_groups[id].text = text


func open() -> void:
	show()


func abort() -> void:
	hide()
	aborted.emit()


func _group_create(group_id: int, text: String) -> int:
	assert(!_groups.has(group_id))
	var g := Group.new(group_id)
	g.text = text
	if item_list_container:
		item_list_container.add_child(g.container)
	_groups[group_id] = g
	return g.id


func _selected(item: _Item) -> void:
	item.set_pressed_no_signal(true)
	if _current != item:
		if _current:
			_current.set_pressed_no_signal(false)
		_current = item
	hide()
	item_selected.emit(item.id)


func _reset() -> void:
	_group_create(GROUP_DEFAULT, "")
	hide()


func _init() -> void:
	_reset()


func _ready() -> void:
	for g in _groups.values():
		if !g.container.is_inside_tree():
			item_list_container.add_child.call_deferred(g.container)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mbev := event as InputEventMouseButton
		# FIXME: hard-coded input mapping
		if !mbev.pressed && mbev.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			abort()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		abort()
