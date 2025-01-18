class_name ZedOperation
extends RefCounted


enum BindStatus {
	UNBOUND = -1,
	## successfully bound operation, ready to execute
	OK = 0,
	## binding didn't fail, but executing the operation would have no effect
	NULL_EFFECT,
	## binding failed
	FAILED,
}

var _bind_status: BindStatus = BindStatus.UNBOUND


func bind(bench: Bench) -> void:
	if _bind_status == BindStatus.UNBOUND:
		_bind_status = _bind(bench)
		if _bind_status >= BindStatus.FAILED:
			push_error("binding operation '%s' failed" % [ _get_name() ])
		elif _bind_status < BindStatus.OK:
			push_error("_bind() must return BindStatus.OK or above")
			_bind_status = BindStatus.FAILED
	else:
		push_error("cannot bind operation twice")


func is_ok() -> bool:
	return _bind_status == BindStatus.OK


func get_bind_status() -> BindStatus:
	return _bind_status


## Execute the operation via UndoRedo action.
func commit(unre: UndoRedo) -> void:
	if _bind_status == BindStatus.NULL_EFFECT:
		push_warning("operation '%s' has no effect" % [ _get_name() ])
	elif _bind_status == BindStatus.OK:
		print("commit operation: '%s'" % [ _get_name() ])
		unre.create_action(_get_name())
		unre.add_do_method(_do)
		unre.add_undo_method(_undo)
		unre.commit_action()
	else:
		push_error("operation '%s' is not bound" % [ _get_name() ])



## Bind the operation to the context and lock-in any configurable effects.
## The behaviour of the operation should not change after binding.
## Return BindStatus.OK if successful.
@warning_ignore("unused_parameter")
func _bind(bench: Bench) -> BindStatus:
	push_error("not implemented")
	return BindStatus.FAILED


## Return the name of the operation as it will appear in undo history.
func _get_name() -> String:
	push_error("not implemented")
	return ""


## Implement the 'do' (forwards) part of the operation.
func _do() -> void:
	push_error("not implemented")
	return


## Implement the 'undo' (reverse) part of the operation.
func _undo() -> void:
	push_error("not implemented")
	return
