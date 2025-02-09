extends ZedOperation


const PROP_POSITION := &"position"
const PROP_SIZE := &"size"


var target: int

var _bind_zhost: ZedHost
var _bind_target: int
var _bind_old_state: Dictionary[StringName, Variant]
var _bind_new_state: Dictionary[StringName, Variant]


func randf3() -> Vector3:
	return Vector3(randf(), randf(), randf())


func _bind(bench: Bench) -> BindStatus:
	_bind_zhost = bench.get_zed_host()
	if !_bind_zhost.has_part(target):
		return BindStatus.FAILED
	_bind_target = target
	_bind_new_state[PROP_POSITION] = randf3() * 5.0 - randf3() * 10.0
	_bind_new_state[PROP_SIZE] = Vector3.ONE * 0.25 + randf3()
	var instance := _bind_zhost.get_part_instance(_bind_target)
	for prop in _bind_new_state:
		_bind_old_state[prop] = instance.get(prop)
	return BindStatus.OK


func _get_name() -> StringName:
	return &"op.anexample.box_randomise"


func _do() -> void:
	var instance := _bind_zhost.get_part_instance(_bind_target)
	for prop in _bind_new_state:
		instance.set(prop, _bind_new_state[prop])
	_bind_zhost.notify_part_changed(_bind_target)


func _undo() -> void:
	var instance := _bind_zhost.get_part_instance(_bind_target)
	for prop in _bind_new_state:
		instance.set(prop, _bind_old_state[prop])
	_bind_zhost.notify_part_changed(_bind_target)
