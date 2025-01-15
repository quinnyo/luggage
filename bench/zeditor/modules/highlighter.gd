extends ZeditorModule


class Highlight:
	var pointer: Node3D


## 3D cursor to indicate active editables
@export var active_pointer_scn: PackedScene


var _editables: Dictionary[int, Highlight]


func _module_registered(id: int, zeditor: Zeditor) -> void:
	zeditor.module_activate(id, zeditor.channel_alloc())


func _module_on_zeditor_editable_activated(editable_id: int) -> void:
	var highlight := Highlight.new()
	highlight.pointer = active_pointer_scn.instantiate()
	add_child(highlight.pointer)
	_editables[editable_id] = highlight


func _module_on_zeditor_editable_deactivated(editable_id: int) -> void:
	var highlight := _editables[editable_id]
	highlight.pointer.queue_free()
	_editables.erase(editable_id)


func _process(_delta: float) -> void:
	for editable_id in _editables:
		var placement := _zeditor.get_active_placement(editable_id)
		var highlight := _editables[editable_id]
		highlight.pointer.global_position = placement.global_position
