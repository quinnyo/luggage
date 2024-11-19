@tool
class_name CameraPlus3D extends Camera3D

const GROUP := &"CameraPlus3D"

enum ViewMode {
	MANUAL,
	ORBIT,
}

enum ProcessCallback {
	IDLE,
	PHYSICS,
}

const CameraDoodad := preload("res://doodads/debug/camera.blend")

@export var view_mode: ViewMode
@export_range(-179, 179, 0.001, "radians_as_degrees") var orbit_latitude: float = PI / 6.0
@export_range(-180, 180, 0.001, "radians_as_degrees", "or_greater", "or_less") var orbit_longitude: float = PI / 4.0
@export var orbit_altitude: float = 10.0
@export var target_offset: Vector3
@export var target_node: Node3D
@export var process_callback: ProcessCallback


func _camera_update(_delta: float) -> void:
	if view_mode == ViewMode.MANUAL:
		return
	elif view_mode == ViewMode.ORBIT:
		var orbit_origin := target_offset
		if target_node:
			orbit_origin = target_node.global_position + target_offset
		var orbit_xf := orbit_transform(orbit_latitude, orbit_longitude, orbit_altitude)
		var xf := orbit_xf.translated(orbit_origin)
		if !xf.is_equal_approx(global_transform):
			global_transform = xf


func _init() -> void:
	top_level = true
	add_to_group(GROUP, true)


func _ready() -> void:
	var doodad := CameraDoodad.instantiate()
	add_child(doodad, false, Node.INTERNAL_MODE_BACK)


func _process(delta: float) -> void:
	if process_callback == ProcessCallback.IDLE:
		_camera_update(delta)


func _physics_process(delta: float) -> void:
	if process_callback == ProcessCallback.PHYSICS:
		_camera_update(delta)


static func orbit_transform(latitude: float, longitude: float, altitude: float) -> Transform3D:
	var rot := Basis.from_euler(Vector3(clampf(-latitude, -PI * 0.95, PI * 0.95), longitude, 0.0))
	return Transform3D(rot, rot * Vector3(0, 0, altitude))
