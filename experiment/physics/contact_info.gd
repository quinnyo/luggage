class_name ContactInfo extends RefCounted


var collider: RID
var collider_id: int
var collider_object: Object
var collider_position: Vector3
var collider_shape: int
var collider_velocity_at_position: Vector3
var impulse: Vector3
var local_normal: Vector3
var local_position: Vector3
var local_shape: int
var local_velocity_at_position: Vector3


func get_relative_velocity_at_position() -> Vector3:
	return local_velocity_at_position - collider_velocity_at_position


func is_equal_approx(other: ContactInfo) -> bool:
	if collider != other.collider || collider_id != other.collider_id:
		return false
	if collider_shape != other.collider_shape:
		return false
	if local_shape != other.local_shape:
		return false
	if !collider_position.is_equal_approx(other.collider_position):
		return false
	if !collider_velocity_at_position.is_equal_approx(other.collider_velocity_at_position):
		return false
	if !impulse.is_equal_approx(other.impulse):
		return false
	if !local_normal.is_equal_approx(other.local_normal):
		return false
	if !local_position.is_equal_approx(other.local_position):
		return false
	if !local_velocity_at_position.is_equal_approx(other.local_velocity_at_position):
		return false
	return true


static func from_state(state: PhysicsDirectBodyState3D, idx: int) -> ContactInfo:
	var ct := ContactInfo.new()
	ct.collider = state.get_contact_collider(idx)
	ct.collider_id = state.get_contact_collider_id(idx)
	ct.collider_object = state.get_contact_collider_object(idx)
	ct.collider_position = state.get_contact_collider_position(idx)
	ct.collider_shape = state.get_contact_collider_shape(idx)
	ct.collider_velocity_at_position = state.get_contact_collider_velocity_at_position(idx)
	ct.impulse = state.get_contact_impulse(idx)
	ct.local_normal = state.get_contact_local_normal(idx)
	ct.local_position = state.get_contact_local_position(idx)
	ct.local_shape = state.get_contact_local_shape(idx)
	ct.local_velocity_at_position = state.get_contact_local_velocity_at_position(idx)
	return ct


static func all_from_state(state: PhysicsDirectBodyState3D) -> Array[ContactInfo]:
	var all: Array[ContactInfo] = []
	for i in state.get_contact_count():
		all.push_back(ContactInfo.from_state(state, i))
	return all
