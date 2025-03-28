class_name ZedPart
extends RefCounted


var id: int = 0


## Return the number of datums (control points) in use by the part.
func get_datum_count() -> int:
	return 0


## Constrains [param p_position] to the ultimate value of the datum's position
## following a call to [method set_position] with the same arguments.
## [br][br]The constrained value is returned without modifying the datum.
@warning_ignore("unused_parameter")
func constrain_position(p_index: int, p_position: Vector3) -> Vector3:
	return Vector3()


## Constrains [param p_euler] to the ultimate value of the datum's rotation
## following a call to [method set_euler] with the same arguments.
## [br][br]The constrained value is returned without modifying the datum.
@warning_ignore("unused_parameter")
func constrain_euler(p_index: int, p_euler: Vector3) -> Vector3:
	return Vector3()


## Assign [param p_position] to the datum at [param p_index] after applying constraints.
@warning_ignore("unused_parameter")
func set_position(p_index: int, p_position: Vector3) -> void:
	return


## Assign [param p_euler] to the datum at [param p_index] after applying constraints.
## [param p_euler] is rotation as euler angles, in radians.
@warning_ignore("unused_parameter")
func set_euler(p_index: int, p_euler: Vector3) -> void:
	return


## Return the position of the datum at [param p_index].
@warning_ignore("unused_parameter")
func get_position(p_index: int) -> Vector3:
	return Vector3()


## Return the rotation of the datum at [param p_index].
## [br][br]The result is provided as euler angles in radians.
@warning_ignore("unused_parameter")
func get_euler(p_index: int) -> Vector3:
	return Vector3()
