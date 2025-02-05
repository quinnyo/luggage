extends ZeditorTool


var _orig_cursor: int
var _travel: float


func _tool_can_activate(context: Context) -> bool:
	return context.selection.is_empty()


func _tool_activate(_context: Context) -> void:
	print("~ activating annoying example tool ~")
	_orig_cursor = Input.get_current_cursor_shape()


func _tool_deactivate(_context: Context) -> void:
	print("~ deactivating annoying example tool ~")
	Input.set_default_cursor_shape(_orig_cursor)


func _tool_input(_context: Context, event: InputEvent) -> bool:
	if event is InputEventMouseMotion:
		_travel += event.relative.length()
		Input.set_default_cursor_shape(int(_travel / 8.0) % 16)
		return true
	return false


func _tool_reset() -> void:
	_orig_cursor = 0
	_travel = 0.0
