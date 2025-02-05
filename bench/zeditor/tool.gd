class_name ZeditorTool
extends RefCounted


class Action:
	enum ActionState { INIT, RUNNING, DONE, }

	var _state: ActionState

	func begin() -> void:
		_state = ActionState.RUNNING

	func is_running() -> bool:
		return _state == ActionState.RUNNING


## Tool activation context
class Context:
	var bench: Bench
	var selection: ZeditorSelection.State

	var _tool: ZeditorTool
	var _action: Action

	func has_active_tool() -> bool:
		return _tool != null

	## Returns [code]true[/code] if tool was activated.
	func try_activate(tool: ZeditorTool) -> bool:
		_reset_activation_state()
		if tool && tool._tool_can_activate(self):
			tool._tool_activate(self)
			_tool = tool
			return true
		return false

	func tool_deactivate() -> void:
		if has_active_tool():
			_tool._tool_deactivate(self)
		_reset_activation_state()

	func tool_process() -> void:
		if has_active_tool():
			_tool._tool_process(self)

	func tool_input(event: InputEvent) -> bool:
		if has_active_tool():
			return _tool._tool_input(self, event)
		return false

	func begin_action(action: Action) -> void:
		_action = action

	func has_running_action() -> bool:
		return has_active_tool() && _action && _action.is_running()

	func _reset_activation_state() -> void:
		if _tool:
			_tool._tool_reset()
		_tool = null
		_action = null


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
