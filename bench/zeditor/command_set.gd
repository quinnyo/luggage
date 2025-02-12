@tool
class_name CommandSet
extends Resource


@export var _data: Dictionary[StringName, CommandBox]:
	set(value):
		_data = value
		emit_changed()


func has_command_impl(ident: StringName) -> bool:
	if !_data.has(ident):
		return false
	var box := _data[ident]
	return box && box.has_command_impl()


func get_command_impl(ident: StringName) -> CommandImpl:
	return get_command_box(ident).get_command_impl()


func get_command_name(ident: StringName) -> String:
	return get_command_box(ident).name


func get_command_box(ident: StringName) -> CommandBox:
	return _data[ident]
