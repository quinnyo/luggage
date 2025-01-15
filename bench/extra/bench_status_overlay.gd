extends BoxContainer


@onready var phase_label: Label = %PhaseLabel


var _bench: Bench:
	set(value):
		if _bench:
			_bench.phase_change_started.disconnect(_on_bench_phase_change_started)
			_bench.phase_change_completed.disconnect(_on_bench_phase_change_completed)
		_bench = value
		if _bench:
			_bench.phase_change_started.connect(_on_bench_phase_change_started)
			_bench.phase_change_completed.connect(_on_bench_phase_change_completed)


func _enter_tree() -> void:
	var parent := get_parent()
	while parent && parent is not Bench:
		parent = parent.get_parent()
	_bench = parent as Bench


func _exit_tree() -> void:
	_bench = null


func _on_bench_phase_change_started(from: BenchPhase, to: BenchPhase) -> void:
	phase_label.text = "%s --> %s" % [ _bench.get_phase_string(from), _bench.get_phase_string(to) ]


func _on_bench_phase_change_completed(to: BenchPhase) -> void:
	phase_label.text = "%s" % [ _bench.get_phase_string(to) ]
