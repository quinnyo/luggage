class_name ZedOperationErase
extends ZedOperation


const SUPPORTED_TYPES := [ Zed.TYPE_PART, ]


var targets: Zelection

var zhost: ZedHost
var _bind_targets: Dictionary[int, Array]


func _bind(bench: Bench) -> BindStatus:
	if not targets:
		return BindStatus.NULL_EFFECT
	zhost = bench.get_zed_host()
	targets.for_each_item_where_type(Zed.TYPE_PART,
		func(_sel_type: StringName, _sel_context: Variant, sel_item: Variant):
			if zhost.has_part(sel_item) && zhost.is_part_player_owned(sel_item):
				var inst := zhost.get_part_instance(sel_item)
				var zclass := zhost.get_part_class(sel_item)
				_bind_targets[sel_item] = [inst, zclass]
	)
	if _bind_targets.is_empty():
		return BindStatus.NULL_EFFECT
	return BindStatus.OK


func _get_name() -> StringName:
	return &"op.erase"


func _do() -> void:
	for id in _bind_targets:
		zhost.remove_part(id)
		# ensure erased objects are not selected (in the live selection)
		if get_selection().has(Zed.TYPE_PART, ZeditorSelection.CONTEXT_DEFAULT, id):
			get_selection().remove(Zed.TYPE_PART, ZeditorSelection.CONTEXT_DEFAULT, id)
		get_selection().remove_all(Zed.TYPE_ARMATURE_POINT, id)


func _undo() -> void:
	for id in _bind_targets:
		zhost.insert_part(id, _bind_targets[id][0], _bind_targets[id][1])
