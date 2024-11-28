class_name ItemBody extends RigidBody3D


signal shock_received(s: float)


## Shock contributions will be chopped (zeroed) below this value.
@export var shock_chop_threshold: float = 2.5


var _applied_shock: float
var _total_shock: float


func apply_shock(s: float) -> void:
	if s > shock_chop_threshold:
		_applied_shock += s


func _init() -> void:
	contact_monitor = true
	max_contacts_reported = 30


func _physics_process(_delta: float) -> void:
	# calc shock contrib from contacts/impacts (collision velocity)
	var state := PhysicsServer3D.body_get_direct_state(get_rid())
	var collision_shock := 0.0
	for i in range(state.get_contact_count()):
		var locvel := state.get_contact_local_velocity_at_position(i)
		var colvel := state.get_contact_collider_velocity_at_position(i)
		var dv := locvel - colvel
		collision_shock += dv.length() / float(state.get_contact_count())

	apply_shock(collision_shock)

	if _applied_shock > shock_chop_threshold:
		_total_shock += _applied_shock
		shock_received.emit(_applied_shock)
	_applied_shock = 0.0
