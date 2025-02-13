class_name ZedOperationBuild
extends ZedOperation


var buildable: ZedClass

var zhost: ZedHost
var _bind_part_id: int
var _bind_instance: ZedPart
var _bind_zclass: ZedClass


func _bind(bench: Bench) -> BindStatus:
	zhost = bench.get_zed_host()
	_bind_part_id = zhost.alloc_part_id()
	_bind_instance = buildable.instantiate()
	_bind_zclass = buildable
	return BindStatus.OK


func _get_name() -> StringName:
	return &"op.build"


func _do() -> void:
	zhost.insert_part(_bind_part_id, _bind_instance, _bind_zclass)
	get_selection().clear()
	if zhost.part_armature_get_size(_bind_part_id) > 0:
		var sel := ZeditorSelection.Selectable.create_indexed(Zed.ItemType.ARMATURE_POINT, _bind_part_id, [ 0 ])
		get_selection().add_selectable(sel)


func _undo() -> void:
	zhost.remove_part(_bind_part_id)
