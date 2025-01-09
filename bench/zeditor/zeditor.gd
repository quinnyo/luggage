extends Node


## Pointer to move to indicate the active object
@export var active_pointer: Node3D


var _bench: Bench
var _workspace: Workspace
var _picking: Picking

var _picked: Placement3D
var _active: Array[Placement3D] = []


func setup_context(bench: Bench) -> void:
	_bench = bench
	_workspace = _bench.get_workspace()


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


func _pointer_activate() -> void:
	clear_active()
	if _picked:
		add_active(_picked)


func _enter_tree() -> void:
	var vpp := ViewportPlus.get_viewport_plus(self)
	_picking = vpp.get_picking()
	_picking.picked.connect(_on_picking_picked)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pointer_activate", false, true):
		_pointer_activate()


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
