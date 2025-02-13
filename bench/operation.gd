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

enum Status {
	NONE,
	READY,
	INTERACTIVE,
	COMMITTED,
	CANCELLED,
}


var do_restore_selection: bool = true

var _bench: Bench
var _bind_status: BindStatus = BindStatus.UNBOUND
var _status: Status = Status.NONE
var _bind_selection: ZeditorSelection.State


func get_bench() -> Bench:
	return _bench


func get_selection() -> ZeditorSelection:
	return _bench.selection


func get_name() -> StringName:
	return _get_name()


func bind(bench: Bench) -> void:
	_bench = bench
	_bind_selection = get_selection().get_state_copy()
	if _bind_status == BindStatus.UNBOUND:
		_bind_status = _bind(bench)
		if _bind_status >= BindStatus.FAILED:
			push_error("binding operation '%s' failed" % [ _get_name() ])
		elif _bind_status < BindStatus.OK:
			push_error("_bind() must return BindStatus.OK or above")
			_bind_status = BindStatus.FAILED
		else:
			_status = Status.INTERACTIVE if _is_interactive() else Status.READY
	else:
		push_error("cannot bind operation twice")


func is_ok() -> bool:
	return _bind_status == BindStatus.OK && (_status == Status.INTERACTIVE || _status == Status.READY)


func get_bind_status() -> BindStatus:
	return _bind_status


## Execute the operation via UndoRedo action.
func commit(unre: UndoRedo) -> void:
	if is_ok():
		print("commit operation: '%s'" % [ _get_name() ])
		_status = Status.COMMITTED
		unre.create_action(_get_name())
		unre.add_do_method(_do)
		unre.add_undo_method(_undo)
		if do_restore_selection:
			unre.add_undo_method(get_selection().restore.bind(_bind_selection))
		unre.commit_action()
	elif _bind_status == BindStatus.NULL_EFFECT:
		push_warning("operation '%s' has no effect" % [ _get_name() ])
	else:
		push_error("operation '%s' is not bound" % [ _get_name() ])


func can_interactive_update() -> bool:
	return _bind_status == BindStatus.OK && _status == Status.INTERACTIVE


func interactive_update() -> void:
	assert(can_interactive_update())
	_interactive_update()
	_do()


func interactive_cancel() -> void:
	assert(can_interactive_update())
	_status = Status.CANCELLED
	_undo()


## Bind the operation to the context and lock-in any configurable effects.
## The behaviour of the operation should not change after binding.
## Return BindStatus.OK if successful.
@warning_ignore("unused_parameter")
func _bind(bench: Bench) -> BindStatus:
	push_error("not implemented")
	return BindStatus.FAILED


## Return the name of the operation as it will appear in undo history.
func _get_name() -> StringName:
	push_error("not implemented")
	return &""


## Implement the 'do' (forwards) part of the operation.
func _do() -> void:
	push_error("not implemented")
	return


## Implement the 'undo' (reverse) part of the operation.
func _undo() -> void:
	push_error("not implemented")
	return


## Return true if interactive editing is supported.
## If true, [method _interactive_update] must be implemented.
func _is_interactive() -> bool:
	return false


## For interactive operations, update the result state.
## You do not need to apply state to the target as the [method _do] method will be called after this.
func _interactive_update() -> void:
	push_error("not implemented")
	return
