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
	var zhost := get_bench().get_zed_host()
	for editable_id in _editables:
		if zhost.has_part(editable_id) && zhost.part_get_datum_count(editable_id):
			var xf := zhost.part_get_transform(editable_id, 0)
			var highlight := _editables[editable_id]
			highlight.pointer.global_position = xf.origin
