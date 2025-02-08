extends Label


const TOOL_NONE := "--"
const OPERATION_NONE := "--"


var _need_update: bool = true
var _tool_name: String = TOOL_NONE
var _operation_name: String = OPERATION_NONE
var _operation_status: String


func update_text() -> void:
	_need_update = false
	text = "Zeditor tool: %s | %s %s" % [ _tool_name, _operation_name, _operation_status ]


func _process(_delta: float) -> void:
	if _need_update:
		update_text()


func _on_zeditor_tool_activated(tool: ZeditorTool) -> void:
	_tool_name = tool.get_name()
	_need_update = true


func _on_zeditor_tool_deactivating(tool: ZeditorTool) -> void:
	_tool_name = "(%s)" % [ tool.get_name() ]
	_need_update = true


func _on_zeditor_tool_operation_started(op: ZedOperation) -> void:
	_operation_name = op.get_name()
	_operation_status = "…"
	_need_update = true


func _on_zeditor_tool_operation_ending(op: ZedOperation, cancelled: bool) -> void:
	_operation_name = "(%s)" % [ op.get_name() ]
	_operation_status = "✗" if cancelled else "✓"
	_need_update = true
