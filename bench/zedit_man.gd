class_name ZeditMan
extends Node
## Interface for performing edit operations


signal operation_started(op: ZedOperation)
signal operation_ending(op: ZedOperation, cancelled: bool)


var bench: Bench
var _operation: ZedOperation


static var _instances: Dictionary[Bench, ZeditMan]


static func get_instance(parent: Bench) -> ZeditMan:
	if _instances.has(parent):
		return _instances[parent]
	push_error("ZeditMan not found")
	return null


func operation_begin(op: ZedOperation) -> void:
	assert(!has_live_operation())
	op.bind(bench)
	if !op.is_ok():
		return
	_operation = op
	operation_started.emit(_operation)
	if op.can_interactive_update():
		return
	operation_commit()


func operation_commit() -> void:
	assert(has_live_operation())
	operation_ending.emit(_operation, false)
	_operation.commit(bench.get_undo_redo())


func operation_cancel() -> void:
	assert(has_live_operation())
	operation_ending.emit(_operation, true)
	if _operation.can_interactive_update():
		_operation.interactive_cancel()


func has_live_operation() -> bool:
	return _operation && _operation.is_ok()


func _reset_activation_state() -> void:
	_operation = null


func _zdit_process() -> void:
	if _operation && _operation.can_interactive_update():
		_operation.interactive_update()


func _zdit_input(event: InputEvent) -> bool:
	if event.is_action_pressed(&"tool_cancel"):
		if has_live_operation():
			operation_cancel()
			return true
	elif event.is_action_pressed(&"tool_commit"):
		if has_live_operation():
			operation_commit()
			return true
	return false


func _enter_tree() -> void:
	bench = Bench.find_bench_parent(self)
	assert(!_instances.has(bench))
	_instances[bench] = self


func _exit_tree() -> void:
	_instances.erase(bench)
	bench = null


func _process(_delta: float) -> void:
	_zdit_process()


func _input(event: InputEvent) -> void:
	if _zdit_input(event):
		get_viewport().set_input_as_handled()
