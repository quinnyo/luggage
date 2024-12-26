@tool
class_name SectionSpline extends Resource
## A parametric spline for conveyor sections.


@export_range(1, 20) var run: int = 4:
	set(value):
		run = value
		_parameter_changed()
@export_range(-20, 20) var rise: int = 0:
	set(value):
		rise = value
		_parameter_changed()
@export_range(-20, 20) var shift_x: int = 0:
	set(value):
		shift_x = value
		_parameter_changed()
@export var turn_degrees: int = 0:
	set(value):
		turn_degrees = value
		_parameter_changed()


var _gen_dirty: bool = true


func get_span_delta() -> Vector3i:
	var dz := absi(run)
	var dy := signi(rise) * mini(absi(rise), dz)
	var dx := shift_x if dz > 2 else 0
	return Vector3i(dx, dy, dz)


func get_turn_angle() -> float:
	return deg_to_rad(turn_degrees)


func get_exit_offset() -> Vector3:
	return get_span_delta()


func get_exit_rotation() -> Basis:
	return Basis.from_euler(Vector3(0, get_turn_angle(), 0))


func _parameter_changed() -> void:
	_gen_dirty = true
	emit_changed()


func _regen_if_needed() -> void:
	if _gen_dirty:
		_generate()


func _generate() -> void:
	_gen_dirty = false
