class_name ZeditorTool
extends RefCounted
## ZeditorTool is a base class for implementing tools for Zeditor.
## A tool is a thing that does something to the Zed scene state, usually in response to user input.


## Tool activation context
class Context:
	signal tool_activated(tool: ZeditorTool)
	signal tool_deactivating(tool: ZeditorTool)
	signal operation_started(op: ZedOperation)
	signal operation_ending(op: ZedOperation, cancelled: bool)

	var bench: Bench
	var selection: ZeditorSelection.State

	var _tool: ZeditorTool
	var _operation: ZedOperation

	func has_active_tool() -> bool:
		return _tool != null

	func get_active_tool() -> ZeditorTool:
		return _tool

	## Returns [code]true[/code] if tool was activated.
	func try_activate(tool: ZeditorTool) -> bool:
		tool_deactivate()
		if tool && tool._tool_can_activate(self):
			_tool = tool
			_tool._tool_activate(self)
			tool_activated.emit(_tool)
			return true
		return false

	func tool_deactivate() -> void:
		if has_active_tool():
			if has_live_operation():
				operation_cancel()
			tool_deactivating.emit(_tool)
			_tool._tool_deactivate(self)
		_reset_activation_state()

	func tool_process() -> void:
		if has_active_tool():
			_tool._tool_process(self)
		if _operation && _operation.can_interactive_update():
			_operation.interactive_update()

	func tool_input(event: InputEvent) -> bool:
		if has_active_tool() && _tool._tool_input(self, event):
			return true
		elif event.is_action_pressed(&"tool_cancel"):
			if has_live_operation():
				operation_cancel()
				return true
			elif has_active_tool():
				tool_deactivate()
				return true
		elif event.is_action_pressed(&"tool_commit"):
			if has_live_operation():
				operation_commit()
				return true
		return false

	func operation_begin(op: ZedOperation) -> void:
		assert(!has_live_operation())
		_operation = op
		_operation.bind(bench)
		operation_started.emit(_operation)

	func operation_commit() -> void:
		assert(has_live_operation())
		operation_ending.emit(_operation, false)
		_operation.commit(bench.get_undo_redo())

	func operation_cancel() -> void:
		assert(has_live_operation())
		operation_ending.emit(_operation, true)
		_operation.interactive_cancel()

	func has_live_operation() -> bool:
		return has_active_tool() && _operation && _operation.is_ok()

	func _reset_activation_state() -> void:
		if _tool:
			_tool._tool_reset()
		_tool = null
		_operation = null


func get_name() -> StringName:
	return _tool_get_name()


func _tool_get_name() -> StringName:
	return str(self)


@warning_ignore("unused_parameter")
func _tool_can_activate(context: Context) -> bool:
	push_error("not implemented")
	return false


@warning_ignore("unused_parameter")
func _tool_activate(context: Context) -> void:
	return


@warning_ignore("unused_parameter")
func _tool_deactivate(context: Context) -> void:
	return


@warning_ignore("unused_parameter")
func _tool_process(context: Context) -> void:
	return


@warning_ignore("unused_parameter")
func _tool_input(context: Context, event: InputEvent) -> bool:
	return false


func _tool_reset() -> void:
	return
