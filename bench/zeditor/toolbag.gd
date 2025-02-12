class_name Toolbag
extends Node
## Tool & parts inventory for Zeditor.


## Base class for Tools, Brushes, Parts, ... (?)
class BaseItem:
	var label: String
	var icon: Texture2D


class Tool extends BaseItem:
	var tool: ZeditorTool


class Buildable extends BaseItem:
	var zed_class: ZedClass


var _items: Array[BaseItem]


func add_buildable(zed_class: ZedClass) -> void:
	var tool := Buildable.new()
	tool.zed_class = zed_class
	tool.label = zed_class.get_buildable_name()
	tool.icon = zed_class.get_buildable_icon()
	_items.push_back(tool)


func get_items(begin: int = 0, end: int = 0x7FFF_FFFF) -> Array[BaseItem]:
	return _items.slice(begin, end)


func get_buildables() -> Array[BaseItem]:
	return _items.filter(func(it: BaseItem) -> bool: return it is Buildable)
