class_name ZedOperationSceneRestore
extends ZedOperation

## Clear everything before restoring
var clean_slate: bool = true
## The scene to restore
var dest: ZedScene

var _bind_zhost: ZedHost
var _bind_old_parts: Dictionary[int, Array]
var _bind_clean_slate: bool
var _bind_new_parts: Dictionary[int, Array]


func _bind(bench: Bench) -> BindStatus:
	_bind_zhost = bench.get_zed_host()
	_bind_clean_slate = clean_slate
	if _bind_clean_slate:
		_bind_zhost.for_each_part(func(id, instance, zclass):
			_bind_old_parts[id] = [instance, zclass]
		)
	for i in range(dest.part_count()):
		var id := dest.get_part_id(i)
		_bind_new_parts[id] = [dest.get_part_instance(i), dest.get_part_class(i)]
	if _bind_old_parts.is_empty() && _bind_new_parts.is_empty():
		return BindStatus.NULL_EFFECT
	return BindStatus.OK


func _get_name() -> String:
	return "SceneRestore"


func _do() -> void:
	for id in _bind_old_parts:
		_bind_zhost.remove_part(id)
	for id in _bind_new_parts:
		_bind_zhost.insert_part(id, _bind_new_parts[id][0], _bind_new_parts[id][1])


func _undo() -> void:
	for id in _bind_new_parts:
		_bind_zhost.remove_part(id)
	for id in _bind_old_parts:
		_bind_zhost.insert_part(id, _bind_old_parts[id][0], _bind_old_parts[id][1])
