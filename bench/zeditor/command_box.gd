@tool
class_name CommandBox
extends Resource
## A Resource to package a command implementation script with metadata for [class CommandSet].


## The Command implementation -- this must be a script that inherits [class Command].
@export var impl: Script:
	set(value):
		impl = value
		emit_changed()

## User-facing name
@export var name: String = "":
	set(value):
		name = value
		emit_changed()
@export var icon: Texture2D:
	set(value):
		icon = value
		emit_changed()


func has_command_impl() -> bool:
	return impl && Qb.script_has_base_script(impl, CommandImpl)


func get_command_impl() -> CommandImpl:
	if not impl || !has_command_impl():
		return null
	return impl.new()
