class_name ZedOperationErase
extends ZedOperation


var targets: PackedInt64Array

var zhost: ZedHost
var _bind_targets: Dictionary[int, Array]


func _bind(bench: Bench) -> BindStatus:
	zhost = bench.get_zed_host()
	for id in targets:
		if !zhost.has_part(id):
			return BindStatus.FAILED
		var inst := zhost.get_part_instance(id)
		var zclass := zhost.get_part_class(id)
		_bind_targets[id] = [inst, zclass]
	if _bind_targets.is_empty():
		return BindStatus.NULL_EFFECT
	return BindStatus.OK


func _get_name() -> StringName:
	return &"op.erase"


func _do() -> void:
	for id in _bind_targets:
		zhost.remove_part(id)
		# yes, the selection thing is this stupid
		get_selection().remove_item(Zed.ItemType.PART, id)
		get_selection().remove_item(Zed.ItemType.ARMATURE_POINT, id)


func _undo() -> void:
	for id in _bind_targets:
		zhost.insert_part(id, _bind_targets[id][0], _bind_targets[id][1])
