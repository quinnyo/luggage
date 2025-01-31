class_name Bench extends Node


const _ZedClassTable := preload("zed/zed_class_table.gd")
const _ZedHost := preload("zed/zed_host.gd")


signal phase_change_started(from: BenchPhase, to: BenchPhase)
signal phase_change_completed(to: BenchPhase)


@export var workspace: Workspace
@export var phases: Array[BenchPhase]


var _zed_class_table: _ZedClassTable
var _zed_host: _ZedHost

var _active_phase: BenchPhase
var _dest_phase: BenchPhase
var _phases: Dictionary[StringName, BenchPhase]


static func find_bench_parent(node: Node) -> Bench:
	var parent := node.get_parent()
	while parent && parent is not Bench:
		parent = parent.get_parent()
	return parent


func get_zed_class_table() -> _ZedClassTable:
	if not _zed_class_table:
		_zed_class_table = _ZedClassTable.new()
	return _zed_class_table


func get_zed_host() -> _ZedHost:
	if not _zed_host:
		_zed_host = _ZedHost.new()
		_zed_host.name = "ZedHost"
		add_child(_zed_host)
		_zed_host.setup_context(self)
	return _zed_host


func get_workspace() -> Workspace:
	return workspace


func add_phase(phase_name: StringName, phase: BenchPhase) -> void:
	assert(!_phases.has(phase_name))
	_phases[phase_name] = phase
	phase._phase_registered(self, phase_name)


## Get the active phase.
func get_active_phase() -> BenchPhase:
	return _active_phase


func get_active_phase_name() -> StringName:
	return _phases.find_key(_active_phase) if _active_phase else &""


func get_phase_named(phase_name: StringName) -> BenchPhase:
	return _phases[phase_name] if _phases.has(phase_name) else null


func has_phase_named(phase_name: StringName) -> bool:
	return _phases.has(phase_name)


func is_phase_in_transition() -> bool:
	return _active_phase != _dest_phase


## Begin phase transition to phase with name [param to_name].
func change_phase_named(to_name: StringName) -> void:
	assert(has_phase_named(to_name))
	if has_phase_named(to_name):
		_start_phase_change(_phases[to_name])


func get_phase_string(phase: BenchPhase) -> String:
	var parts = ["Phase"]
	if phase:
		var key = _phases.find_key(phase)
		if not key:
			parts.push_back("UNREG")
		else:
			parts.push_back("%s" % [ key ])
		if phase.name != key:
			parts.push_back(phase.name)
	else:
		parts.push_back("NULL")
	return "%s" % [ ":".join(parts) ]


func _start_phase_change(to: BenchPhase) -> void:
	if is_phase_in_transition():
		push_warning("transition in progress")
		return
	if _active_phase == to:
		push_warning("cannot change to current phase")
		return
	#print("[Bench] changing %s --> %s" % [ get_phase_string(_active_phase), get_phase_string(to) ])
	if _active_phase:
		_active_phase.phase_deactivate()
	_dest_phase = to
	if _dest_phase:
		_dest_phase.phase_activate()
	phase_change_started.emit(_active_phase, _dest_phase)


func _end_phase_change() -> void:
	_active_phase = _dest_phase
	phase_change_completed.emit(_active_phase)
	print("[Bench] changed to %s" % [ get_phase_string(_active_phase) ])
	var vpp := ViewportPlus.get_viewport_plus(self)
	vpp.get_picking().request_update()


func _ready() -> void:
	for phase in phases:
		if phase:
			add_phase(phase.name, phase)
	if _phases.size():
		_start_phase_change(_phases.values()[0])


func _process(_delta: float) -> void:
	if is_phase_in_transition():
		_end_phase_change()
