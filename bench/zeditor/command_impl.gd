class_name CommandImpl
extends RefCounted
## Base class for Zeditor command implementation


class Invocation:
	var bench: Bench
	var selection: Zelection
	var data: Dictionary[StringName, Variant]
	var impl: CommandImpl

	func can_invoke() -> bool:
		return impl._cmd_can_invoke(self)

	func invoke() -> void:
		var error := impl._cmd_invoke(self)
		if error:
			push_error("invocation failed")


func bind(bench: Bench, selection: Zelection, data: Dictionary[StringName, Variant] = {}) -> Invocation:
	var context := Invocation.new()
	context.bench = bench
	context.selection = selection.clone()
	context.data = data.duplicate()
	context.impl = self
	_cmd_bind(context)
	context.data.make_read_only()
	return context


@warning_ignore("unused_parameter")
func _cmd_bind(context: Invocation) -> void:
	return


@warning_ignore("unused_parameter")
func _cmd_can_invoke(context: Invocation) -> bool:
	push_error("not implemented")
	return false


@warning_ignore("unused_parameter")
func _cmd_invoke(context: Invocation) -> int:
	push_error("not implemented")
	return 1
