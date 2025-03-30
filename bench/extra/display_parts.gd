extends Node
## Tracks all part instances in the context and provides basic pose visualisation.
## For each tracked part,
## - draw an indicator at every datum point

@export var color_1a := Color(0.29, 0.787, 0.895)
@export var color_1b := Color(0.156, 0.322, 0.344)
@export var color_2a := Color(0.975, 0.569, 0.822)
@export var color_2b := Color(0.486, 0.361, 0.732)
@export var color_3a := Color(0.986, 0.758, 0.34)
@export var color_3b := Color(0.521, 0.283, 0.228)


var targets: Dictionary[int, Dictionary]

var _needle_mesh: Mesh
var _needle_material: Array[StandardMaterial3D]

var _vis_available_index
var _vis_nodes: Array[MeshInstance3D]


func draw_thing(transform: Transform3D, material_idx: int, _likely_some_other_stuff = null) -> void:
	var mi := _next_vis()
	mi.material_override = _needle_material[material_idx]
	mi.global_transform = transform
	mi.show()


func _next_vis() -> MeshInstance3D:
	var mi: MeshInstance3D
	if _vis_available_index < _vis_nodes.size():
		mi = _vis_nodes[_vis_available_index]
	else:
		mi = MeshInstance3D.new()
		mi.mesh = _needle_mesh
		mi.material_override = _needle_material[0]
		add_child(mi)
		_vis_nodes.push_back(mi)

	_vis_available_index += 1
	return mi


func _create_material(color_a: Color, color_b: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.no_depth_test = true
	mat.albedo_color = color_b

	var overmat := StandardMaterial3D.new()
	overmat.vertex_color_use_as_albedo = true
	overmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	overmat.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	overmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	overmat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	overmat.render_priority = 1
	overmat.albedo_color = color_a
	mat.next_pass = overmat
	return mat


func _on_part_added(part_id: int) -> void:
	targets[part_id] = {}


func _on_part_removed(part_id: int) -> void:
	if targets.has(part_id):
		targets.erase(part_id)


func _ready() -> void:
	var bench := Bench.find_bench_parent(self)
	bench.get_zed_host().part_added.connect(_on_part_added)
	bench.get_zed_host().part_removed.connect(_on_part_removed)

	_needle_mesh = ZedShapes.build_needle_wire_mesh()

	_needle_material = [
		_create_material(color_1a, color_1b),
		_create_material(color_2a, color_2b),
		_create_material(color_3a, color_3b),
	]


func _process(_delta: float) -> void:
	_vis_available_index = 0
	var bench := Bench.find_bench_parent(self)
	var zhost := bench.get_zed_host()
	for part_id: int in targets:
		for idatum in range(zhost.part_get_datum_count(part_id)):
			draw_thing(zhost.part_get_transform(part_id, idatum), 0)

	while _vis_available_index < _vis_nodes.size():
		_vis_nodes[_vis_available_index].hide()
		_vis_available_index += 1
