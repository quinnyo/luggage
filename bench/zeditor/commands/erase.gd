extends CommandImpl


func _cmd_can_invoke(context: Invocation) -> bool:
	for type in ZedOperationErase.SUPPORTED_TYPES:
		if context.selection.has_type(type):
			return true
	return false


func _cmd_invoke(context: Invocation) -> int:
	var zhost := context.bench.get_zed_host()
	var targets := Zelection.new()
	context.selection.for_each_item_where_type(Zed.TYPE_PART,
		func(sel_type: StringName, sel_context: Variant, sel_item: Variant):
			if zhost.has_part(sel_item):
				if zhost.is_part_player_owned(sel_item):
					targets.add(sel_type, sel_context, sel_item)
	)
	var op := ZedOperationErase.new()
	op.targets = targets

	var zedit := ZeditMan.get_instance(context.bench)
	zedit.operation_begin(op)
	return 0
