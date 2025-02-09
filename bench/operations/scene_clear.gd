class_name ZedOperationSceneClear
extends ZedOperation


var zhost: ZedHost
var parts: Dictionary[int, Array]


func _bind(bench: Bench) -> BindStatus:
	zhost = bench.get_zed_host()
	zhost.for_each_part(func(id, instance, zclass):
		parts[id] = [instance, zclass]
	)
	if parts.is_empty():
		return BindStatus.NULL_EFFECT
	return BindStatus.OK


func _get_name() -> StringName:
	return &"op.scene_clear"


func _do() -> void:
	for id in parts:
		zhost.remove_part(id)


func _undo() -> void:
	for id in parts:
		zhost.insert_part(id, parts[id][0], parts[id][1])
