class_name ZedPart
extends RefCounted


var id: int = 0


## Return the number of control points in this Part's armature.
func armature_get_size() -> int:
	return 0


## Constrains [param p_position] to the ultimate value of the control point's position
## following a call to [method armature_set_position] with the same arguments.
## [br][br]The constrained value is returned without modifying the control point.
@warning_ignore("unused_parameter")
func armature_constrain_position(p_index: int, p_position: Vector3) -> Vector3:
	return Vector3()


## Constrains [param p_euler] to the ultimate value of the control point's rotation
## following a call to [method armature_set_rotation] with the same arguments.
## [br][br]The constrained value is returned without modifying the control point.
@warning_ignore("unused_parameter")
func armature_constrain_euler(p_index: int, p_euler: Vector3) -> Vector3:
	return Vector3()


## Assign [param p_position] to control point [param p_index] after applying constraints.
@warning_ignore("unused_parameter")
func armature_set_position(p_index: int, p_position: Vector3) -> void:
	return


## Assign [param p_euler] to control point [param p_index] after applying constraints.
## [param p_euler] is rotation as euler angles, in radians.
@warning_ignore("unused_parameter")
func armature_set_euler(p_index: int, p_euler: Vector3) -> void:
	return


## Return the position of control point [param p_index].
@warning_ignore("unused_parameter")
func armature_get_position(p_index: int) -> Vector3:
	return Vector3()


## Return the rotation of control point [param p_index].
## [br][br]The result is provided as euler angles in radians.
@warning_ignore("unused_parameter")
func armature_get_euler(p_index: int) -> Vector3:
	return Vector3()
