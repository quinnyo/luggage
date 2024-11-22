extends Node3D


const POINT_GAP := 0.1
const POINT_RADIUS := 0.3


@export var base_material: Material
@export var draw_persist: int = 9
@export var enable_break: bool = true
@export var camera: CameraPlus3D
@export var watch_object: PhysicsBody3D
var watch_body: RID:
	get:
		if watch_object:
			return watch_object.get_rid()
		else:
			return watch_body


var _paused: bool = false
var _skip: int = 0
var _draw_nodes: Array[MeshInstance3D] = []
var _next_draw_node: int = 0


func push_contacts(state: PhysicsDirectBodyState3D) -> void:
	_draw_prepare()
	var contacts := ContactInfo.all_from_state(state)

	var mi := _draw_nodes[_next_draw_node % _draw_nodes.size()]
	_next_draw_node += 1
	var im := mi.mesh as ImmediateMesh
	if not im:
		im = ImmediateMesh.new()
		mi.mesh = im
	else:
		im.clear_surfaces()

	for ct in contacts:
		draw_point(im, ct.local_position, Color(1.0, 1.0, 0.0, 0.75), 0.02, 0.15, state.transform.basis)
		#draw_point(im, ct.collider_position, Color(0.0, 0.25, 1.0, 0.75), 0.02, 0.15, state.transform.basis.scaled(Vector3(-1.0, -1.0, -1.0)))
		var relvel := ct.local_velocity_at_position - ct.collider_velocity_at_position
		draw_vector(im, ct.local_position, relvel, Color(1.0, 0.0, 0.0))
		draw_vector(im, ct.local_position, ct.impulse, Color(1.0, 0.5, 0.0))

	if enable_break && !state.sleeping && !get_tree().paused && contacts.size():
		pause()


func draw_point(im: ImmediateMesh, p: Vector3, color: Color, gap: float = POINT_GAP, radius: float = POINT_RADIUS, xf: Basis = Basis.IDENTITY, material: Material = null) -> void:
	im.surface_begin(Mesh.PRIMITIVE_LINES, material)
	im.surface_set_color(color)
	im.surface_add_vertex(p + xf * Vector3(gap, 0.0, 0.0))
	im.surface_add_vertex(p + xf * Vector3(radius, 0.0, 0.0))
	im.surface_add_vertex(p + xf * Vector3(0.0, gap, 0.0))
	im.surface_add_vertex(p + xf * Vector3(0.0, radius, 0.0))
	im.surface_add_vertex(p + xf * Vector3(0.0, 0.0, gap))
	im.surface_add_vertex(p + xf * Vector3(0.0, 0.0, radius))
	im.surface_end()


func draw_vector(im: ImmediateMesh, origin: Vector3, vec: Vector3, color: Color, material: Material = null) -> void:
	im.surface_begin(Mesh.PRIMITIVE_LINES, material)
	im.surface_set_color(color)
	im.surface_add_vertex(origin)
	im.surface_add_vertex(origin + vec)
	im.surface_end()


func pause() -> void:
	get_tree().paused = true
	_paused = true


func resume() -> void:
	get_tree().paused = false
	_paused = false


func _draw_prepare() -> void:
	while _draw_nodes.size() > draw_persist:
		_draw_nodes.pop_front().queue_free()
	while _draw_nodes.size() < draw_persist:
		var mi := MeshInstance3D.new()
		mi.material_override = base_material.duplicate()
		add_child(mi)
		_draw_nodes.push_back(mi)

	var step := 1.0 / float(_draw_nodes.size())
	var alpha := step
	for i in range(_draw_nodes.size()):
		var mi := _draw_nodes[(1 + i + _next_draw_node) % _draw_nodes.size()]
		mi.material_override.albedo_color.a = alpha
		alpha += step


func _init() -> void:
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS
	process_physics_priority = 9


func _physics_process(_delta: float) -> void:
	if !get_tree().paused && _skip > 0:
		_skip -= 1
	elif !get_tree().paused && watch_body.is_valid():
		var state := PhysicsServer3D.body_get_direct_state(watch_body)
		push_contacts(state)


func _unhandled_key_input(event: InputEvent) -> void:
	var kev := event as InputEventKey
	if kev.pressed && kev.keycode == KEY_P:
		enable_break = !enable_break
	if _paused && kev.pressed && kev.keycode == KEY_SPACE:
		resume()
		_skip = 1


func _unhandled_input(event: InputEvent) -> void:
	if camera:
		if event is InputEventMouseMotion && event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			camera.orbit_latitude += event.relative.y * 0.004
			camera.orbit_longitude += event.relative.x * -0.004
