extends CommandImpl


func _cmd_can_invoke(context: Invocation) -> bool:
	var unre := context.bench.get_undo_redo()
	return unre.has_redo()


func _cmd_invoke(context: Invocation) -> int:
	var unre := context.bench.get_undo_redo()
	print("redo '%s'" % [ unre.get_action_name(unre.get_current_action() + 1) ])
	unre.redo()
	return OK
