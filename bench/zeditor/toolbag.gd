class_name Toolbag
extends Node
## Tool & parts inventory for Zeditor.


## Base class for Tools, Brushes, Parts, ... (?)
class BaseItem:
	var label: String
	var icon: Texture2D


class Tool extends BaseItem:
	pass


class Buildable extends BaseItem:
	var zed_class: ZedClass


var _buildables: Array[Buildable]


func add_buildable(zed_class: ZedClass) -> void:
	var tool := Buildable.new()
	tool.zed_class = zed_class
	tool.label = zed_class.get_buildable_name()
	tool.icon = zed_class.get_buildable_icon()
	_buildables.push_back(tool)


func get_buildables(begin: int = 0, end: int = 0x7FFF_FFFF) -> Array[Buildable]:
	return _buildables.slice(begin, end)


func get_buildables_count() -> int:
	return _buildables.size()
