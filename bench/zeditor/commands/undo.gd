extends CommandImpl


func _cmd_can_invoke(context: Invocation) -> bool:
	var unre := context.bench.get_undo_redo()
	return unre.has_undo()


func _cmd_invoke(context: Invocation) -> int:
	var unre := context.bench.get_undo_redo()
	print("undo '%s'" % [ unre.get_current_action_name() ])
	unre.undo()
	return OK
