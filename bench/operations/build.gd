class_name ZedOperationBuild
extends ZedOperation


var buildable: Toolbag.Buildable

var zhost: ZedHost
var _bind_part_id: int
var _bind_instance: ZedPart
var _bind_zclass: ZedClass


func _bind(bench: Bench) -> BindStatus:
	zhost = bench.get_zed_host()
	_bind_part_id = zhost.alloc_part_id()
	_bind_instance = buildable.zed_class.instantiate()
	_bind_zclass = buildable.zed_class
	return BindStatus.OK


func _get_name() -> String:
	return "Build %s" % [ _bind_zclass ]


func _do() -> void:
	zhost.insert_part(_bind_part_id, _bind_instance, _bind_zclass)


func _undo() -> void:
	zhost.remove_part(_bind_part_id)
