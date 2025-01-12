extends Node


@export var zeditor: Zeditor

var _launched: Zeditor


func _phase_entering(phase: BenchPhase) -> void:
	if zeditor:
		zeditor.setup_context(phase.get_bench())
		zeditor.launch()
		_launched = zeditor
	else:
		_launched = null


func _phase_exiting(_phase: BenchPhase) -> void:
	if _launched:
		_launched.halt()
		_launched = null
