class_name Picking extends Node
## Object picking manager


var pointer: Vector2
var ray_origin: Vector3
var ray_normal: Vector3

var result: Dictionary
var object: CollisionObject3D
var position: Vector3
var normal: Vector3


## Return true if a 3D object is picked.
func has_object_3d() -> bool:
	return object != null


func get_object() -> Node:
	return object


func get_intersection_point_3d() -> Vector3:
	return position


func get_intersection_normal_3d() -> Vector3:
	return normal


func update_pointer(screen_point: Vector2) -> void:
	pointer = screen_point
	ray_origin = Vector3.ZERO
	ray_normal = Vector3.ZERO
	var cam := get_viewport().get_camera_3d()
	if not cam:
		return
	ray_origin = cam.project_ray_origin(screen_point)
	ray_normal = cam.project_ray_normal(screen_point)


func update_result_3d(new_result: Dictionary) -> void:
	result = new_result
	var new_object: CollisionObject3D = null
	position = Vector3.ZERO
	normal = Vector3.ZERO
	if result.size():
		new_object = result["collider"]
		position = result["position"]
		normal = result["normal"]
	if new_object != object:
		object = new_object


func _physics_process(_delta: float):
	update_pointer(get_viewport().get_mouse_position())
	if ray_normal.is_zero_approx():
		update_result_3d({})
		return
	var space_state := get_viewport().world_3d.direct_space_state
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_normal * 500.0)
	update_result_3d(space_state.intersect_ray(query))
