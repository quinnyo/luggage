extends CommandImpl


const NOTICE_BUILD_WISH := &"build.wish"


func _cmd_bind(context: Invocation) -> void:
	if context.bench.notices.is_new(NOTICE_BUILD_WISH) && context.bench.notices.read(NOTICE_BUILD_WISH) is ZedClass:
		context.data[NOTICE_BUILD_WISH] = context.bench.notices.read(NOTICE_BUILD_WISH, true)


func _cmd_can_invoke(context: Invocation) -> bool:
	return context.data.has(NOTICE_BUILD_WISH)


func _cmd_invoke(context: Invocation) -> int:
	var op := ZedOperationBuild.new()
	op.buildable = context.data[NOTICE_BUILD_WISH]
	var zedit := ZeditMan.get_instance(context.bench)
	zedit.operation_begin(op)
	return 0
