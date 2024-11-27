class_name ItemBody extends RigidBody3D


var prev_linear_velocity: Vector3
var prev_angular_velocity: Vector3
var linear_accel: Vector3
var angular_accel: Vector3
var impact_force: Vector3
var impact_torque: Vector3

var impact: float


func _init() -> void:
	contact_monitor = true
	max_contacts_reported = 30


func _ready() -> void:
	prev_linear_velocity = linear_velocity
	prev_angular_velocity = angular_velocity


func _physics_process(delta: float) -> void:
	var linear_delta := linear_velocity - prev_linear_velocity
	var angular_delta := angular_velocity - prev_angular_velocity
	linear_accel = linear_delta / delta
	angular_accel = angular_delta / delta
	impact_force = linear_accel * mass
	impact_torque = get_inverse_inertia_tensor().inverse() * angular_accel

	impact = 0.0
	var linear_impact := linear_accel.length() / 500.0
	if linear_impact > 0.5:
		impact += linear_impact
	#var angular_impact := impact_torque.length() / 200.0
	#if angular_impact > 0.1:
		#impact += angular_impact

	prev_linear_velocity = linear_velocity
	prev_angular_velocity = angular_velocity
