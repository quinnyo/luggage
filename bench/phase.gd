class_name BenchPhase extends Node


## Called on children when phase is first registered.
const METHOD_PHASE_INIT := &"_phase_init"
## Called on children when phase activation is started.
const METHOD_PHASE_ENTERING := &"_phase_entering"
## Called on children when phase deactivation is started.
const METHOD_PHASE_EXITING := &"_phase_exiting"
## Called on children when phase activation is complete.
const METHOD_PHASE_ENTER := &"_phase_enter"
## Called on children when phase deactivation is complete.
const METHOD_PHASE_EXIT := &"_phase_exit"

enum State {
	INIT,
	INACTIVE,
	ACTIVE,
}


var _state: State = State.INIT
var _dest_state: State = State.INIT
var _bench: Bench
var _registered_name: StringName


func get_bench() -> Bench:
	return _bench if is_registered() else null


## Returns true if this phase is registered in a Bench.
func is_registered() -> bool:
	return _bench && _bench.get_phase_named(_registered_name) == self


## Returns the name used to refer to this phase in the Bench.
## If this phase is not registered, returns an empty string.
func get_registered_name() -> StringName:
	return _registered_name if is_registered() else &""


## Returns true if a phase activation state transition is underway.
func is_changing_state() -> bool:
	return _dest_state != _state


## Returns true if this phase is active.
## With [param allow_transition] set to false (the default),
## if a state change is underway the result will be false.
func is_active(allow_transition: bool = false) -> bool:
	return _state == State.ACTIVE && (allow_transition || !is_changing_state())


func phase_activate() -> void:
	if _state != State.ACTIVE:
		_do_phase_entering()


func phase_deactivate() -> void:
	if _state == State.ACTIVE:
		_do_phase_exiting()


## Called by parent context after this phase is added.
func _phase_registered(bench: Bench, registered_name: StringName) -> void:
	_bench = bench
	_registered_name = registered_name
	_do_phase_init()


func _do_phase_init() -> void:
	propagate_call(METHOD_PHASE_INIT, [ self ])
	_state = State.INACTIVE
	_dest_state = State.INACTIVE


func _do_phase_entering() -> void:
	_dest_state = State.ACTIVE
	propagate_call(METHOD_PHASE_ENTERING, [ self ])


func _do_phase_exiting() -> void:
	_dest_state = State.INACTIVE
	propagate_call(METHOD_PHASE_EXITING, [ self ])


func _do_phase_enter() -> void:
	_state = State.ACTIVE
	propagate_call(METHOD_PHASE_ENTER, [ self ])


func _do_phase_exit() -> void:
	_state = State.INACTIVE
	propagate_call(METHOD_PHASE_EXIT, [ self ])


func _finalise_state_change() -> void:
	if _dest_state == State.ACTIVE:
		_do_phase_enter()
	elif _dest_state == State.INACTIVE:
		_do_phase_exit()


func _process(_delta: float) -> void:
	if is_changing_state():
		_finalise_state_change()
