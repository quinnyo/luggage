class_name Picking extends Node
## Object picking manager


class Ray:
	var origin: Vector3:
		get:
			return _origin
		set(_value):
			push_error("origin is read-only")
	var normal: Vector3:
		get:
			return _normal
		set(_value):
			push_error("normal is read-only")
	var length: float:
		get:
			return _length
		set(_value):
			push_error("length is read-only")

	var _origin: Vector3
	var _normal: Vector3
	var _length: float
	var _valid: bool


	## [b]Note:[/b] This function can return values outside the range (0.0 .. [member length]).
	func get_depth_closest_to_point(p: Vector3) -> float:
		var v := p - origin
		return v.dot(normal)


	func is_valid() -> bool:
		return _valid


	func is_equal_approx(other: Ray) -> bool:
		if not other:
			return false
		if !is_valid() && !other.is_valid():
			return true
		if is_valid() != other.is_valid():
			return false
		if !origin.is_equal_approx(other.origin):
			return false
		if !normal.is_equal_approx(other.normal):
			return false
		if !is_equal_approx(length, other.length):
			return false
		return true


	static func create(screen_point: Vector2, cam: Camera3D) -> Ray:
		var ray_origin := cam.project_ray_origin(screen_point)
		var ray_normal := cam.project_ray_normal(screen_point)
		var ray_length := cam.far - cam.near
		return Ray.new(ray_origin, ray_normal, ray_length)


	static func invalid() -> Ray:
		return Ray.new(Vector3.ZERO, Vector3.ZERO, 0.0)


	func _init(p_origin: Vector3, p_normal: Vector3, p_length: float) -> void:
		_origin = p_origin
		_normal = p_normal
		_length = p_length
		var diff := _normal * _length
		_valid = diff.is_finite() && !diff.is_zero_approx() && _origin.is_finite()



class Candidate:
	## The candidate object node
	var object: Node
	## Distance between target and pointer
	var dxy: float
	## Distance from ray origin to closest ray point
	var dz: float
	## Client-use field
	var userdata: Variant

	func _to_string() -> String:
		return "Picking.Candidate: object=%s, dxy=%0.2f, dz=%0.2f, userdata=%s" % [ object, dxy, dz, userdata ]

	static func create(p_object: Node, p_dxy: float, p_dz: float, p_userdata: Variant = null) -> Candidate:
		var cand := Candidate.new()
		cand.object = p_object
		cand.dxy = p_dxy
		cand.dz = p_dz
		cand.userdata = p_userdata
		return cand

	static func sort_dz(a: Candidate, b: Candidate) -> bool:
		return a.dz < b.dz

	static func sort_dxy(a: Candidate, b: Candidate) -> bool:
		return a.dxy < b.dxy


class Query:
	var ray: Ray:
		set(_value):
			push_error("ray nay")
		get:
			return _ray
	var _ray: Ray
	var _candidates: Array[Candidate]

	func submit_candidate_3d(object: Node, dxy: float, dz: float, userdata: Variant = null) -> void:
		var candidate := Candidate.create(object, dxy, dz, userdata)
		_candidates.insert(_candidates.bsearch_custom(candidate, Candidate.sort_dxy), candidate)

	## Get the candidates with a dxy score no greater than [param max_dxy].
	## If [param depth_sort] is true, those candidates are then sorted by dz.
	func get_result(max_dxy: float, depth_sort: bool = true) -> Array[Candidate]:
		var result: Array[Candidate] = []
		for cand in _candidates:
			if cand.dxy > max_dxy:
				break
			else:
				result.push_back(cand)
		if depth_sort:
			result.sort_custom(Candidate.sort_dz)
		return result

	func get_candidates() -> Array[Candidate]:
		return _candidates.duplicate()


signal picked(object: Node)
signal query_started(query: Query)
signal query_completed()


@export var query_physics_space_3d: bool = true
@export var include_areas_3d: bool = true
@export var include_bodies_3d: bool = true
@export_flags_3d_physics var collision_mask_3d: int = 0xFFFF_FFFF


var _ray: Ray
var _result: Array[Candidate]
var _request_update: bool = false


func get_object() -> Node:
	if _result.size():
		var o := _result[0].object
		return o if o && !o.is_queued_for_deletion() else null
	return null


## Return true if a 3D object is picked.
func has_object_3d() -> bool:
	var o := get_object()
	return o && o is Node3D


func get_object_3d() -> Node3D:
	assert(has_object_3d())
	return get_object() as Node3D


func get_intersection_point_3d() -> Vector3:
	assert(has_object_3d())
	return get_object_3d().global_position


func request_update() -> void:
	_request_update = true


func get_result() -> Array[Candidate]:
	return _result.duplicate()


func _invert_collision_mask_3d() -> void:
	collision_mask_3d = ~collision_mask_3d


func _update_pointer(screen_point: Vector2) -> bool:
	var new_ray := Ray.invalid()
	var cam := get_viewport().get_camera_3d()
	if cam:
		new_ray = Ray.create(screen_point, cam)
	if !new_ray.is_equal_approx(_ray):
		_ray = new_ray
		return true
	return false


func _update() -> void:
	_request_update = false
	var query := Query.new()
	query._ray = _ray
	query_started.emit(query)
	if query_physics_space_3d:
		_do_physics_space_3d_query(query)
	_result = query.get_result(0.01)
	query_completed.emit()


func _do_physics_space_3d_query(query: Query) -> void:
	if !query.ray.is_valid():
		return
	var ray := query.ray
	var space_state := get_viewport().world_3d.direct_space_state
	var params := PhysicsRayQueryParameters3D.create(ray.origin, ray.origin + ray.normal * ray.length)
	params.collide_with_areas = include_areas_3d
	params.collide_with_bodies = include_bodies_3d
	params.collision_mask = collision_mask_3d
	var result := space_state.intersect_ray(params)
	if result.size():
		var collider: CollisionObject3D = result["collider"]
		var target_position: Vector3 = result["position"]
		var dz := ray.get_depth_closest_to_point(target_position)
		var dxy := (ray.origin + ray.normal * dz).distance_to(target_position)
		query.submit_candidate_3d(collider, dxy, dz)


func _physics_process(_delta: float):
	var prev_object := get_object()
	if _update_pointer(get_viewport().get_mouse_position()) || _request_update:
		_update()
	if prev_object != get_object():
		picked.emit(get_object())
