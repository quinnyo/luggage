extends CommandImpl


func _cmd_can_invoke(context: Invocation) -> bool:
	return context.selection.has_type(Zed.TYPE_ARMATURE_POINT)


func _cmd_invoke(context: Invocation) -> int:
	var op_drag := preload("res://bench/operations/drag.gd").new()
	var zhost := context.bench.get_zed_host()
	context.selection.for_each_selection_where_type(Zed.TYPE_ARMATURE_POINT,
		func(_t: StringName, sel_context: Variant, items: Array):
			var part_id: int = sel_context
			for i in range(items.size()):
				var index: int = items[i]
				var initial_position := zhost.part_armature_get_transform(part_id, index).origin
				op_drag.add_target(initial_position, func(value: Vector3):
					var xf := zhost.part_armature_get_transform(part_id, index)
					xf.origin = value
					zhost.part_armature_set_transform(part_id, index, xf)
				)
	)
	if op_drag.has_target():
		var zedit := ZeditMan.get_instance(context.bench)
		zedit.operation_begin(op_drag)
	return 0
