class_name Workplane
extends Node3D


const ACTION_PUSH := &"workplane_push"
const ACTION_PULL := &"workplane_pull"

enum Axis { X, Y, Z }


@export var axis: Axis = Axis.Y

@export var d: float = 0.0

@export var d_step: float = 1.0


var _pointer_intersection_point: Vector3
var _pointer_vis: Node3D
var _plane_vis: Node3D


func get_plane_basis() -> Basis:
	if axis == Axis.X:
		return Basis(-basis.y, basis.x, basis.z)
	elif axis == Axis.Y:
		return Basis(basis.x, basis.y, basis.z)
	elif axis == Axis.Z:
		return Basis(basis.x, basis.z, -basis.y)
	return Basis.IDENTITY


func has_valid_plane() -> bool:
	if !is_finite(d):
		return false
	return true


func get_local_normal() -> Vector3:
	var normal := Vector3()
	if axis < 3:
		normal[axis] = 1.0
	return normal


func get_normal() -> Vector3:
	return global_basis * get_local_normal()


func get_point() -> Vector3:
	return global_transform * (get_local_normal() * snappedf(d, d_step))


func get_plane() -> Plane:
	return Plane(get_normal(), get_point())


func ctl_push(step: float) -> void:
	var vp := get_viewport()
	if not vp:
		return
	var cam := vp.get_camera_3d()
	if not cam:
		return
	if absf(step) < 1.0:
		step = signf(step)
	var look_dir := -cam.global_basis.z
	var look_sign := signf(look_dir.dot(get_normal()))
	d += step * look_sign


func ctl_pull(step: float) -> void:
	ctl_push(-step)


func _update_pointer() -> bool:
	var vp := get_viewport()
	if not vp:
		return false
	var cam := vp.get_camera_3d()
	if not cam:
		return false

	var screen_point := vp.get_mouse_position()
	var result := _intersect_camera_ray(screen_point, cam)
	if result.size() == 1:
		_pointer_intersection_point = result[0]
		return true

	return false


func _intersect_camera_ray(screen_point: Vector2, cam: Camera3D) -> PackedVector3Array:
	var ray_origin := cam.project_ray_origin(screen_point)
	var ray_normal := cam.project_ray_normal(screen_point)
	if !cam.is_position_in_frustum(ray_origin + ray_normal):
		return PackedVector3Array()

	var plane := get_plane()
	var result = plane.intersects_ray(ray_origin, ray_normal)
	if result != null:
		return PackedVector3Array([result])
	return PackedVector3Array()


static func create_color_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission = color.darkened(0.75)
	mat.emission_enabled = true
	return mat


static func create_vis(mesh: Mesh, material: Material) -> MeshInstance3D:
	var vis := MeshInstance3D.new()
	vis.mesh = mesh
	vis.material_override = material
	return vis


func _init() -> void:
	var pointer_mesh := BoxMesh.new()
	pointer_mesh.size = Vector3(0.2, 0.8, 0.2)
	_pointer_vis = create_vis(pointer_mesh, create_color_material(Color(0.94, 0.92, 0.99)))
	_pointer_vis.top_level = true
	add_child(_pointer_vis)

	var plane_mesh := PlaneMesh.new()
	plane_mesh.orientation = PlaneMesh.FACE_Y
	var plane_mat_a := create_color_material(Color(0.89, 0.94, 0.94))
	var plane_mat_b := plane_mat_a.duplicate() as StandardMaterial3D
	plane_mat_b.albedo_color = plane_mat_b.albedo_color.darkened(0.3)
	plane_mat_b.cull_mode = BaseMaterial3D.CULL_FRONT
	plane_mat_a.next_pass = plane_mat_b
	_plane_vis = create_vis(plane_mesh, plane_mat_a)
	_plane_vis.top_level = true
	add_child(_plane_vis)


func _process(_delta: float) -> void:
	if _update_pointer():
		_pointer_vis.visible = true
		_pointer_vis.global_basis = global_basis * get_plane_basis()
		_pointer_vis.global_position = _pointer_intersection_point
	else:
		_pointer_vis.visible = false

	_plane_vis.visible = false
	if has_valid_plane():
		_plane_vis.global_basis = global_basis * get_plane_basis()
		_plane_vis.global_position = get_point()
		_plane_vis.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION_PUSH):
		ctl_push(event.get_action_strength(ACTION_PUSH))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(ACTION_PULL):
		ctl_pull(event.get_action_strength(ACTION_PULL))
		get_viewport().set_input_as_handled()
