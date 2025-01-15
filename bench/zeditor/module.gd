class_name ZeditorModule
extends Node


## The channel that this module occupies when activated.
@export_range(0, 31) var activation_channel: int = 0

@export var activation_priority: int = 0


var _zeditor: Zeditor
var _id: int
var _holding: Dictionary[int, Placement3D]


func is_registered() -> bool:
	return _zeditor && _id


func get_bench() -> Bench:
	return _zeditor._bench


## Override this and return true if module should activate
@warning_ignore("unused_parameter")
func _module_handles_editable(editable_id: int) -> bool:
	return false


@warning_ignore("unused_parameter")
func _module_registered(id: int, zeditor: Zeditor) -> void:
	return


func _module_activated() -> void:
	return


func _module_deactivated() -> void:
	return


@warning_ignore("unused_parameter")
func _module_editable_grabbed(editable_id: int) -> void:
	return


@warning_ignore("unused_parameter")
func _module_editable_released(editable_id: int) -> void:
	return


@warning_ignore("unused_parameter")
func _module_on_zeditor_editable_activated(editable_id: int) -> void:
	var placement := _zeditor.get_active_placement(editable_id)
	if _module_handles_editable(editable_id):
		var req := _zeditor.request_activate_builder(_id, activation_channel, editable_id, activation_priority)
		req.processed.connect(func(accepted: bool):
			if accepted:
				_module_activated()
				_zeditor.module_grab(_id, editable_id)
				_holding[editable_id] = placement
				_module_editable_grabbed(editable_id)
		)


@warning_ignore("unused_parameter")
func _module_on_zeditor_editable_deactivated(editable_id: int) -> void:
	if !_holding.has(editable_id):
		return
	_holding.erase(editable_id)
	_module_editable_released(editable_id)
	if _holding.is_empty():
		_zeditor.module_deactivate(_id)
		_module_deactivated()


func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		_zeditor = get_parent() as Zeditor
		_id = _zeditor.module_register(self)
		_zeditor.editable_activated.connect(_module_on_zeditor_editable_activated)
		_zeditor.editable_deactivated.connect(_module_on_zeditor_editable_deactivated)
		_module_registered(_id, _zeditor)
	elif what == NOTIFICATION_EXIT_TREE:
		if _zeditor && _id:
			_zeditor.module_deregister(_id)
			_zeditor.editable_activated.disconnect(_module_on_zeditor_editable_activated)
			_zeditor.editable_deactivated.disconnect(_module_on_zeditor_editable_deactivated)
			_zeditor = null
			_id = 0
