extends Control


const _ZedOperationBoxRandomise := preload("box_operation_randomise.gd")


var _inspector: ZedInspector


func _zed_inspector_entered(inspector: ZedInspector) -> void:
	_inspector = inspector


func _on_randomise_pressed() -> void:
	var op := _ZedOperationBoxRandomise.new()
	op.target = _inspector.target
	var zedit := ZeditMan.get_instance(_inspector.bench)
	zedit.operation_begin(op)
