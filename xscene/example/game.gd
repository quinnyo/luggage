class_name EgGame extends Node


signal phase_transition_started(trans: PhaseTransition)


enum Phase {
	NONE,
	EDIT,
	SIM,
}


class PhaseTransition:
	signal completed

	var from: Phase:
		get:
			return _from
	var to: Phase:
		get:
			return _to

	var _from: Phase
	var _to: Phase
	var _completed: bool = false

	func _init(p_from: Phase, p_to: Phase) -> void:
		_from = p_from
		_to = p_to

	func mark_as_completed() -> void:
		_completed = true
		completed.emit()

	func is_active() -> bool:
		return !_completed


var phase: Phase = Phase.NONE
var _phase_trans: PhaseTransition


func change_phase(to: Phase) -> void:
	if _phase_trans && _phase_trans.is_active():
		push_warning("Cannot change phase, transition in progress.")
		return
	_phase_trans = PhaseTransition.new(phase, to)
	_phase_trans.completed.connect(func(): phase = to)
	phase_transition_started.emit(_phase_trans)
	_phase_trans.mark_as_completed()


static func find_game_context_parent(node: Node) -> EgGame:
	node = node.get_parent()
	while node and node is not EgGame:
		node = node.get_parent()
	return node
