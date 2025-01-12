class_name Zeditor
extends Node


const ACTION_POINTER_ACTIVATE := &"pointer_activate"
const ACTION_BUILD_MENU := &"build_menu"


## Pointer to move to indicate the active object
@export var active_pointer: Node3D

@export var toolbag: Toolbag

@export var item_tray: ItemPicker

var _bench: Bench
var _workspace: Workspace
var _picking: Picking

var _picked: Placement3D
var _active: Array[Placement3D] = []


func setup_context(bench: Bench) -> void:
	_bench = bench
	_workspace = _bench.get_workspace()

	# NOTE: Cheating here for testing -- toolbag is to be initialised externally and passed to Zeditor.
	for zc in _bench.get_zed_class_table().get_classes():
		toolbag.add_buildable(zc)

	assert(toolbag)
	assert(item_tray)
	item_tray.clear()
	_populate_item_picker()


func launch() -> void:
	return


func halt() -> void:
	return


func add_active(placement: Placement3D) -> void:
	_active.push_back(placement)
	placement.activate()


func clear_active() -> void:
	for placement in _active:
		placement.deactivate()
	_active.clear()


func get_first_active() -> Placement3D:
	return _active[0] if _active.size() else null


func _populate_item_picker() -> void:
	var group_buildables := ItemPicker.GROUP_DEFAULT
	item_tray.group_set_text(group_buildables, "Buildable")
	for buildable in toolbag.get_buildables():
		var item_id := item_tray.add_item(buildable.label, buildable.icon, group_buildables)
		item_tray.item_set_userdata(item_id, buildable)
		item_tray.item_selected.connect(_on_item_tray_item_selected.bind())


func _pointer_activate() -> void:
	clear_active()
	if _picked:
		add_active(_picked)


func _build_menu() -> void:
	assert(item_tray)
	item_tray.open()


func _enter_tree() -> void:
	var vpp := ViewportPlus.get_viewport_plus(self)
	_picking = vpp.get_picking()
	_picking.picked.connect(_on_picking_picked)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION_POINTER_ACTIVATE, false, true):
		_pointer_activate()
	elif event.is_action_pressed(ACTION_BUILD_MENU, false, true):
		_build_menu()


func _process(_delta: float) -> void:
	var placement := get_first_active()
	if active_pointer:
		if placement:
			active_pointer.global_position = placement.global_position
			active_pointer.show()
		else:
			active_pointer.hide()


func _on_picking_picked(object: Node) -> void:
	if _picked:
		_picked.hovered = false
		_picked = null

	if object is Placement3D:
		var placement := object as Placement3D
		placement.hovered = true
		_picked = placement


func _on_item_tray_item_selected(item_id: int) -> void:
	var data := item_tray.item_get_userdata(item_id) as Toolbag.BaseItem
	if data is Toolbag.Buildable:
		var buildable := data as Toolbag.Buildable
		print("Buildable selected: %s" % [ buildable.zed_class ])
