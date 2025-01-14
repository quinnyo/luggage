class_name Zeditor
extends Node


class ModuleInfo:
	var id: int
	var node: Node


class EditableInfo:
	var id: int
	var placement: Placement3D


class LRMap:
	var lpairs: Dictionary[int, Dictionary]
	var rpairs: Dictionary[int, Dictionary]

	func has_left(l: Variant) -> bool:
		return lpairs.has(l) && lpairs[l].size()

	func has_right(r: Variant) -> bool:
		return rpairs.has(r) && rpairs[r].size()

	func get_partners_left(l: Variant) -> Array:
		assert(has_left(l))
		return lpairs[l].keys()

	func get_partners_right(r: Variant) -> Array:
		assert(has_right(r))
		return rpairs[r].keys()

	func insert(l: Variant, r: Variant, data: Variant = null) -> void:
		lpairs.get_or_add(l, {})[r] = data
		rpairs.get_or_add(r, {})[l] = data

	func has_pair(l: Variant, r: Variant) -> bool:
		return lpairs.has(l) && lpairs[l].has(r)

	func get_data(l: Variant, r: Variant) -> Variant:
		assert(has_pair(l, r))
		return lpairs[l][r]

	func erase(l: Variant, r: Variant) -> void:
		assert(lpairs.has(l) && lpairs[l].has(r))
		assert(rpairs.has(r) && rpairs[r].has(l))
		lpairs[l].erase(r)
		rpairs[r].erase(l)

	func erase_left(l: Variant) -> void:
		for r in get_partners_left(l):
			erase(l, r)

	func erase_right(r: Variant) -> void:
		for l in get_partners_right(r):
			erase(l, r)


class ActivateRequest:
	enum Outcome {
		PENDING,
		ACCEPTED,
		DENIED_LOCKED,
		DENIED_CHANNEL_CONFLICT,
		DENIED_PRIORITY,
	}

	signal processed(accepted: bool)

	var module: int:
		set(value):
			assert(!_initialised)
			module = value
	var channel: int:
		set(value):
			assert(!_initialised)
			channel = value
	var editable: int:
		set(value):
			assert(!_initialised)
			editable = value
	var priority: int:
		set(value):
			assert(!_initialised)
			priority = value
	var state: Outcome:
		set(value):
			assert(state == Outcome.PENDING)
			assert(value != Outcome.PENDING)
			state = value
	var _initialised: bool = false

	func is_accepted() -> bool:
		return state == Outcome.ACCEPTED

	func get_outcome_string() -> String:
		return Outcome.keys()[state]

	func _finalise(outcome: Outcome) -> void:
		state = outcome
		processed.emit(is_accepted())

	func _init(p_module: int, p_channel: int, p_editable: int, p_priority: int = 0) -> void:
		module = p_module
		channel = p_channel
		editable = p_editable
		priority = p_priority
		_initialised = true

	static func sort_priority(lhs: ActivateRequest, rhs: ActivateRequest) -> bool:
		return lhs.priority < rhs.priority


const ACTION_POINTER_ACTIVATE := &"pointer_activate"
const ACTION_BUILD_MENU := &"build_menu"


signal launching()
signal halting()
signal editable_activated(editable_id: int)
signal editable_deactivated(editable_id: int)


## Pointer to move to indicate the active object
@export var active_pointer: Node3D
@export var toolbag: Toolbag
@export var item_tray: ItemPicker


var _bench: Bench
var _workspace: Workspace

var _picked: Placement3D
var _active: Dictionary[int, EditableInfo]
var _builder_requests: Array[ActivateRequest] = []

var modules: Dictionary[int, ModuleInfo]
var channels: LRMap = LRMap.new()
var locks: LRMap = LRMap.new()


func setup_context(bench: Bench) -> void:
	_bench = bench
	_workspace = _bench.get_workspace()

	# NOTE: Cheating here for testing -- toolbag is to be initialised externally and passed to Zeditor.
	for zc in _bench.get_zed_class_table().get_classes():
		toolbag.add_buildable(zc)


func launch() -> void:
	assert(toolbag)
	assert(item_tray)
	item_tray.clear()
	_populate_item_picker()
	item_tray.item_selected.connect(_on_item_tray_item_selected)
	launching.emit()
	process_mode = Node.PROCESS_MODE_INHERIT


func halt() -> void:
	clear_active()
	if item_tray && item_tray.item_selected.is_connected(_on_item_tray_item_selected):
		item_tray.item_selected.disconnect(_on_item_tray_item_selected)
	halting.emit()
	process_mode = Node.PROCESS_MODE_DISABLED


func get_active_placement(editable_id: int) -> Placement3D:
	assert(has_active(editable_id))
	var placement := _active[editable_id].placement
	if not placement || placement.is_queued_for_deletion():
		return null
	return placement


func has_active(editable_id: int) -> bool:
	return _active.has(editable_id)


func add_active(placement: Placement3D) -> int:
	var id := placement.get_instance_id()
	assert(!has_active(id))
	var editable := EditableInfo.new()
	editable.id = id
	editable.placement = placement
	_active[id] = editable
	placement.activate()
	editable_activated.emit(id)
	_process_builder_requests()
	placement.tree_exiting.connect(_on_placement_tree_exiting.bind(placement))
	return id


func remove_active(editable_id: int) -> void:
	assert(has_active(editable_id))
	var editable := _active[editable_id]
	if editable.placement && !editable.placement.is_queued_for_deletion():
		editable.placement.deactivate()
		editable.placement.tree_exiting.disconnect(_on_placement_tree_exiting)
	if editable_is_locked(editable.id):
		editable_unlock(editable.id)
	editable_deactivated.emit(editable.id)
	_active.erase(editable_id)


func clear_active() -> void:
	for k in _active.keys():
		remove_active(k)
	_active.clear()


func get_first_active() -> Placement3D:
	return get_active_placement(_active.keys()[0]) if _active.size() else null


func editable_is_locked(editable: int) -> bool:
	return locks.has_left(editable)


func editable_unlock(editable: int) -> void:
	assert(editable_is_locked(editable))
	locks.erase_left(editable)


func channel_has(channel: int, module: int) -> bool:
	return channels.has_pair(channel, module)


func channel_is_empty(channel: int) -> bool:
	return !channels.has_left(channel)


func module_register(node: Node) -> int:
	var id := randi()
	var module := ModuleInfo.new()
	module.id = id
	module.node = node
	modules[id] = module
	return id


func module_deregister(id: int) -> void:
	assert(modules.has(id))
	if module_is_active(id):
		module_deactivate(id)
	modules.erase(id)


func module_activate(id: int, channel: int) -> void:
	assert(channel >= 0)
	assert(!module_is_active(id))
	assert(channel_is_empty(channel))
	channels.insert(channel, id)


func module_deactivate(id: int) -> void:
	if channels.has_right(id):
		channels.erase_right(id)
	module_release_all(id)


func module_is_active(id: int) -> bool:
	return channels.has_right(id)


func module_grab(id: int, editable_id: int) -> void:
	assert(!editable_is_locked(editable_id))
	locks.insert(editable_id, id)


func module_release(id: int, editable_id: int) -> void:
	assert(module_has_lock(id, editable_id))
	locks.erase(editable_id, id)


func module_has_lock(module: int, editable: int) -> bool:
	return locks.has_pair(editable, module)


func module_get(id: int) -> ModuleInfo:
	assert(modules.has(id))
	return modules[id]


func module_release_all(id: int) -> void:
	if locks.has_right(id):
		locks.erase_right(id)


func request_activate_builder(module: int, channel: int, editable: int, priority: int = 0) -> ActivateRequest:
	var req := ActivateRequest.new(module, channel, editable, priority)
	_builder_requests.push_back(req)
	return req


func _process_builder_requests() -> void:
	var by_editable: Dictionary[int, Array]
	for req in _builder_requests:
		if editable_is_locked(req.editable):
			req._finalise(ActivateRequest.Outcome.DENIED_LOCKED)
		elif !channel_is_empty(req.channel):
			req._finalise(ActivateRequest.Outcome.DENIED_CHANNEL_CONFLICT)
		else:
			if !by_editable.has(req.editable):
				var arr: Array[ActivateRequest] = []
				by_editable[req.editable] = arr
			var edreqs := by_editable[req.editable]
			var idx := edreqs.bsearch_custom(req, ActivateRequest.sort_priority)
			edreqs.insert(idx, req)
	for editable_id in by_editable:
		var edreqs := by_editable[editable_id] as Array[ActivateRequest]
		_accept_activate_request(edreqs[0])
		for i in range(1, edreqs.size()):
			edreqs[i]._finalise(ActivateRequest.Outcome.DENIED_PRIORITY)

	_builder_requests.clear()


func _accept_activate_request(req: ActivateRequest) -> void:
		module_activate(req.module, req.channel)
		req._finalise(ActivateRequest.Outcome.ACCEPTED)


func _populate_item_picker() -> void:
	var group_buildables := ItemPicker.GROUP_DEFAULT
	item_tray.group_set_text(group_buildables, "Buildable")
	for buildable in toolbag.get_buildables():
		var item_id := item_tray.add_item(buildable.label, buildable.icon, group_buildables)
		item_tray.item_set_userdata(item_id, buildable)


func _pointer_activate() -> void:
	clear_active()
	if _picked:
		add_active(_picked)


func _build_menu() -> void:
	assert(item_tray)
	item_tray.open()


func _init() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED


func _ready() -> void:
	var vpp := ViewportPlus.get_viewport_plus(self)
	vpp.get_picking().picked.connect(_on_picking_picked)


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


func _on_placement_tree_exiting(placement: Placement3D) -> void:
	var id := placement.get_instance_id()
	if has_active(id):
		remove_active(id)


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
