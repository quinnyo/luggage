class_name Zeditor
extends Node


class ModuleInfo:
	var id: int
	var node: Node
	## func(msg: Message) -> void
	var fn_message: Callable

	func send_message(msg: Message) -> void:
		if fn_message.is_valid():
			fn_message.call(msg)


class EditableInfo:
	## Zed/Workspace part ID
	var id: int


class LRMap:
	var lpairs: Dictionary[int, Dictionary]
	var rpairs: Dictionary[int, Dictionary]

	func has_left(l: int) -> bool:
		return lpairs.has(l) && lpairs[l].size()

	func has_right(r: int) -> bool:
		return rpairs.has(r) && rpairs[r].size()

	func get_partners_left(l: int) -> Array[int]:
		assert(has_left(l))
		return lpairs[l].keys()

	func get_partners_right(r: int) -> Array[int]:
		assert(has_right(r))
		return rpairs[r].keys()

	func insert(l: int, r: int, data: Variant = null) -> void:
		lpairs.get_or_add(l, _create_value_dict())[r] = data
		rpairs.get_or_add(r, _create_value_dict())[l] = data

	func has_pair(l: int, r: int) -> bool:
		return lpairs.has(l) && lpairs[l].has(r)

	func get_data(l: int, r: int) -> Variant:
		assert(has_pair(l, r))
		return lpairs[l][r]

	func erase(l: int, r: int) -> void:
		assert(lpairs.has(l) && lpairs[l].has(r))
		assert(rpairs.has(r) && rpairs[r].has(l))
		lpairs[l].erase(r)
		rpairs[r].erase(l)

	func erase_left(l: int) -> void:
		for r in get_partners_left(l):
			erase(l, r)

	func erase_right(r: int) -> void:
		for l in get_partners_right(r):
			erase(l, r)

	static func _create_value_dict() -> Dictionary[int, Variant]:
		var dict: Dictionary[int, Variant] = {}
		return dict


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

const METHOD_MESSAGE := &"_zeditor_message"

enum Message {
	MODULE_REGISTERED,
	MODULE_DEREGISTERED,
	MODULE_ACTIVATED,
	MODULE_DEACTIVATED,
}

signal launching()
signal halting()
signal editable_activated(editable_id: int)
signal editable_deactivated(editable_id: int)
signal inspector_opening(inspector: ZedInspector)


@export var toolbag: Toolbag
@export var item_tray: ItemPicker

var unre: UndoRedo = UndoRedo.new()

var _bench: Bench
var _workspace: Workspace
var _inspector_man: ZedInspectorManager = ZedInspectorManager.new()

var _picked: Placement3D
var _active: Dictionary[int, EditableInfo]
var _builder_requests: Array[ActivateRequest] = []

var modules: Dictionary[int, ModuleInfo]
var channels: LRMap = LRMap.new()
var locks: LRMap = LRMap.new()


func setup_context(bench: Bench) -> void:
	_bench = bench
	_workspace = _bench.get_workspace()
	_inspector_man.setup(_bench, self)

	# NOTE: Cheating here for testing -- toolbag is to be initialised externally and passed to Zeditor.
	for zc in _bench.get_zed_class_table().get_classes():
		toolbag.add_buildable(zc)


func launch() -> void:
	assert(toolbag)
	assert(item_tray)
	item_tray.clear()
	_populate_item_picker()
	item_tray.item_selected.connect(_on_item_tray_item_selected)
	_bench.get_zed_host().part_removed.connect(_on_zed_host_part_removed)
	launching.emit()
	process_mode = Node.PROCESS_MODE_INHERIT


func halt() -> void:
	clear_active()
	if item_tray && item_tray.item_selected.is_connected(_on_item_tray_item_selected):
		item_tray.item_selected.disconnect(_on_item_tray_item_selected)
	_bench.get_zed_host().part_removed.disconnect(_on_zed_host_part_removed)
	halting.emit()
	process_mode = Node.PROCESS_MODE_DISABLED


func get_active_placement(editable_id: int) -> Placement3D:
	assert(has_active(editable_id))
	var zhost := _bench.get_zed_host()
	var shell_id := zhost.get_part_shell_id(editable_id)
	for node in _workspace.shell_get_nodes(shell_id):
		if node is Placement3D:
			return node as Placement3D
	return null


func has_active(editable_id: int) -> bool:
	return _active.has(editable_id)


func add_active(id: int) -> void:
	assert(!has_active(id))
	var editable := EditableInfo.new()
	editable.id = id
	_active[id] = editable
	open_part_inspector(id)
	editable_activated.emit(id)
	_process_builder_requests()


func remove_active(editable_id: int) -> void:
	assert(has_active(editable_id))
	close_part_inspector(editable_id)
	if editable_is_locked(editable_id):
		editable_unlock(editable_id)
	editable_deactivated.emit(editable_id)
	_active.erase(editable_id)


func clear_active() -> void:
	for k in _active.keys():
		remove_active(k)
	_active.clear()


func replace_active_array(array: PackedInt64Array) -> void:
	clear_active()
	for id in array:
		add_active(id)


func editable_is_locked(editable: int) -> bool:
	return locks.has_left(editable)


func editable_unlock(editable: int) -> void:
	assert(editable_is_locked(editable))
	locks.erase_left(editable)


func channel_has(channel: int, module: int) -> bool:
	return channels.has_pair(channel, module)


func channel_is_empty(channel: int) -> bool:
	return !channels.has_left(channel)


func channel_alloc() -> int:
	var channel := randi()
	while !channel_is_empty(channel):
		channel = randi()
	return channel


## Register a node as a module. Returns module ID.
func module_register(node: Node) -> int:
	var id := randi()
	var module := ModuleInfo.new()
	module.id = id
	module.node = node
	if node.has_method(METHOD_MESSAGE):
		assert(node.get_method_argument_count(METHOD_MESSAGE) == 1)
		module.fn_message = Callable(node, METHOD_MESSAGE)
	modules[id] = module
	module.node.process_mode = Node.PROCESS_MODE_DISABLED
	module.send_message.call_deferred(Message.MODULE_REGISTERED)
	return id


func module_deregister(id: int) -> void:
	assert(modules.has(id))
	if module_is_active(id):
		module_deactivate(id)
	module_get(id).send_message(Message.MODULE_DEREGISTERED)
	modules.erase(id)


func module_is_registered(id: int) -> bool:
	return modules.has(id)


func module_activate(id: int, channel: int) -> void:
	assert(channel >= 0)
	assert(!module_is_active(id))
	assert(channel_is_empty(channel))
	channels.insert(channel, id)
	var module := module_get(id)
	module.send_message(Message.MODULE_ACTIVATED)
	module.node.process_mode = Node.PROCESS_MODE_INHERIT


## removes the module from any channel it's active on
## and release all locks held by the module
func module_deactivate(id: int) -> void:
	if channels.has_right(id):
		channels.erase_right(id)
	module_release_all(id)
	var module := module_get(id)
	module.send_message(Message.MODULE_DEACTIVATED)
	module.node.process_mode = Node.PROCESS_MODE_DISABLED


## check if the module is active on any channel
func module_is_active(id: int) -> bool:
	return channels.has_right(id)


## take exclusive control of the editable
func module_grab(id: int, editable_id: int) -> void:
	assert(!editable_is_locked(editable_id))
	locks.insert(editable_id, id)


## release module's lock on editable
func module_release(id: int, editable_id: int) -> void:
	assert(module_has_lock(id, editable_id))
	locks.erase(editable_id, id)


## check if the module holds a lock on the editable
func module_has_lock(module: int, editable_id: int) -> bool:
	return locks.has_pair(editable_id, module)


## release all locks held by the module
func module_release_all(id: int) -> void:
	if locks.has_right(id):
		locks.erase_right(id)


func module_get(id: int) -> ModuleInfo:
	assert(modules.has(id))
	return modules[id]


func request_activate_builder(module: int, channel: int, editable: int, priority: int = 0) -> ActivateRequest:
	var req := ActivateRequest.new(module, channel, editable, priority)
	_builder_requests.push_back(req)
	return req


func pointer_activate() -> void:
	if _picked:
		replace_active_array(PackedInt64Array([_picked.part_id]))
	else:
		replace_active_array(PackedInt64Array())


## Create a new instance of the buildable part
func build(buildable: Toolbag.Buildable) -> void:
	var op := ZedOperationBuild.new()
	op.buildable = buildable
	op.bind(_bench)
	if op.is_ok():
		execute_operation(op)


func open_toolbag() -> void:
	assert(item_tray)
	item_tray.open()


func undo() -> void:
	if unre.has_undo():
		print("undo '%s'" % [ unre.get_current_action_name() ])
		unre.undo()
	else:
		print("nothing to undo")


func redo() -> void:
	if unre.has_redo():
		print("redo '%s'" % [ unre.get_action_name(unre.get_current_action() + 1) ])
		unre.redo()
	else:
		print("nothing to redo")


## commit an operation immediately.
func execute_operation(op: ZedOperation) -> void:
	assert(op.is_ok())
	op.commit(unre)


func open_part_inspector(editable_id: int) -> ZedInspector:
	var inspector := _inspector_man.open_part_inspector(editable_id)

	var erase_button := Button.new()
	erase_button.text = "Erase"
	erase_button.pressed.connect(func():
		var op := ZedOperationErase.new()
		op.targets = [ editable_id ]
		op.bind(_bench)
		execute_operation(op)
	)
	inspector.add_control(ZedInspector.LayoutArea.TOOLBAR_RIGHT, erase_button)

	inspector_opening.emit(inspector)
	return inspector


func close_part_inspector(editable_id: int) -> void:
	_inspector_man.close_part_inspector(editable_id)


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


func _set_picked(object: Node) -> void:
	if _picked == object:
		return

	if _picked:
		_picked.hovered = false
		_picked = null

	if object is Placement3D:
		var placement := object as Placement3D
		placement.hovered = true
		_picked = placement


func _init() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED


func _process(_delta: float) -> void:
	var vpp := ViewportPlus.get_viewport_plus(self)
	_set_picked(vpp.get_picking().get_object())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION_POINTER_ACTIVATE, false, true):
		pointer_activate()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(ACTION_BUILD_MENU, false, true):
		open_toolbag()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_undo"):
		undo()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_redo"):
		redo()
		get_viewport().set_input_as_handled()


func _on_zed_host_part_removed(part_id: int) -> void:
	if has_active(part_id):
		remove_active(part_id)


func _on_item_tray_item_selected(item_id: int) -> void:
	var data := item_tray.item_get_userdata(item_id) as Toolbag.BaseItem
	if data is Toolbag.Buildable:
		build(data as Toolbag.Buildable)
