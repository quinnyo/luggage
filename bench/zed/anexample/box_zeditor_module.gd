extends ZeditorModule


const _BoxZed := preload("box_zed.gd")
const BoxInspectorBuildPanel := preload("box_inspector_build_panel.tscn")


func _module_handles_editable(editable_id: int) -> bool:
	var zhost := get_bench().get_zed_host()
	if !zhost.has_part(editable_id):
		return false
	var zed := zhost.get_part_class(editable_id)
	return zed.get_type_name() == _BoxZed.TYPE_NAME


func _module_activated() -> void:
	return


func _module_deactivated() -> void:
	return


func _module_editable_grabbed(editable_id: int) -> void:
	print("BoxZeditorModule: grabbed(%s)" % [ editable_id ])
	var inspector := _zeditor.open_part_inspector(editable_id)
	inspector.add_control(ZedInspector.LayoutArea.PAGE_BUILD, BoxInspectorBuildPanel.instantiate())


func _module_editable_released(editable_id: int) -> void:
	print("BoxZeditorModule: released(%s)" % [ editable_id ])
