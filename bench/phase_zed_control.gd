extends Node


## The shell type to use when parent phase is activated.
@export var shell_type: ZedHost.ShellType


var _pushed := false


func _phase_exiting(phase: BenchPhase) -> void:
	if _pushed:
		phase.get_bench().get_zed_host().pop_shell()
		_pushed = false


func _phase_enter(phase: BenchPhase) -> void:
	if !_pushed:
		_pushed = phase.get_bench().get_zed_host().push_shell(shell_type)
