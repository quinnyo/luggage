extends CommandImpl


func _cmd_can_invoke(context: Invocation) -> bool:
	return context.selection.has_item_type(Zed.ItemType.ARMATURE_POINT)


func _cmd_invoke(context: Invocation) -> int:
	var op_drag := preload("res://bench/operations/drag.gd").new()
	var selected_armature := context.selection.get_selectables_with_item_type(Zed.ItemType.ARMATURE_POINT)
	if selected_armature.size():
		var zhost := context.bench.get_zed_host()
		for sel in selected_armature:
			var part_id: int = sel.indexed_get_item()
			var points := sel.indexed_get_indices()
			for i in range(points.size()):
				var index := points[i]
				var initial_position := zhost.part_armature_get_transform(part_id, index).origin
				op_drag.add_target(initial_position, func(value: Vector3):
					var xf := zhost.part_armature_get_transform(part_id, index)
					xf.origin = value
					zhost.part_armature_set_transform(part_id, index, xf)
				)
		var zedit := ZeditMan.get_instance(context.bench)
		zedit.operation_begin(op_drag)
	return 0
