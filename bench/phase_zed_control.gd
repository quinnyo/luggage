extends Node


## The shell type to use during the parent phase.
@export var shell_type: Zed.ShellType


var _pushed := false


func _phase_exiting(phase: BenchPhase) -> void:
	if _pushed:
		phase.get_bench().get_workspace().pop_shell_layer()
		_pushed = false


func _phase_enter(phase: BenchPhase) -> void:
	if !_pushed:
		phase.get_bench().get_workspace().push_shell_layer(shell_type)
		_pushed = true
