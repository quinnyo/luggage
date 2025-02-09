extends ZeditorTool


func _tool_get_name() -> StringName:
	return &"tool.move"


func _tool_can_activate(context: Context) -> bool:
	return context.selection.is_empty() || context.selection.has_item_type(Zed.ItemType.ARMATURE_POINT)


func _tool_activate(context: Context) -> void:
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

		context.operation_begin(op_drag)
