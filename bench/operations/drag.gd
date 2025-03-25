extends ZedOperation


var _zhost: ZedHost
var _workspace: Workspace
var _pointer_start: Vector3
var _drag_delta: Vector3
var _target_setter: Array[Callable]
var _target_initial_value: PackedVector3Array


## Add a target object to the operation.
## [param initial_value] is the object's current position.
## [param fset] a ([code]func(Vector3) -> void[/code]) that sets the target object's position.
func add_target(initial_value: Vector3, fset: Callable) -> void:
	assert(get_bind_status() == BindStatus.UNBOUND)
	_target_initial_value.push_back(initial_value)
	_target_setter.push_back(fset)


func has_target() -> bool:
	return _target_setter.size()


func _bind(bench: Bench) -> BindStatus:
	_zhost = bench.get_zed_host()
	_workspace = bench.get_workspace()
	_pointer_start = _workspace.pointer_3d_get_position()
	return BindStatus.OK


func _get_name() -> StringName:
	return &"op.drag"


func _do() -> void:
	for i in range(_target_setter.size()):
		var initial_value := _target_initial_value[i]
		var new_value := initial_value + _drag_delta
		_target_setter[i].call(new_value)


func _undo() -> void:
	for i in range(_target_setter.size()):
		_target_setter[i].call(_target_initial_value[i])


func _is_interactive() -> bool:
	return true


func _interactive_update() -> void:
	_drag_delta = _workspace.pointer_3d_get_position() - _pointer_start
