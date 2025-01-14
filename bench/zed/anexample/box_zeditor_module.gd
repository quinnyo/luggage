extends ZeditorModule


const _BoxZed := preload("box_zed.gd")


func _module_handles_placement(placement: Placement3D) -> bool:
	var zhost := get_bench().get_zed_host()
	var zed := zhost.get_part_class(placement.part_id)
	if zed.get_type_name() == _BoxZed.TYPE_NAME:
		return true
	return false


func _module_activated() -> void:
	return


func _module_deactivated() -> void:
	return


func _module_editable_grabbed(editable_id: int) -> void:
	print("BoxZeditorModule: grabbed(%s)" % [ editable_id ])
	return


func _module_editable_released(editable_id: int) -> void:
	print("BoxZeditorModule: released(%s)" % [ editable_id ])
	return
