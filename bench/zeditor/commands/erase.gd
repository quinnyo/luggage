extends CommandImpl


func _cmd_can_invoke(context: Invocation) -> bool:
	return context.selection.has_item_type(Zed.ItemType.PART)


func _cmd_invoke(context: Invocation) -> int:
	var op := ZedOperationErase.new()
	var selected_parts := context.selection.get_selectables_with_item_type(Zed.ItemType.PART)
	for sel in selected_parts:
		for part_id in sel.get_items():
			op.targets.push_back(part_id)
	var zedit := ZeditMan.get_instance(context.bench)
	zedit.operation_begin(op)
	return 0
