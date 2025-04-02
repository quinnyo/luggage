extends Node
## Tracks all part instances in the context and provides basic pose visualisation.
## For each tracked part,
## - draw an indicator at every datum point


const _ZedShapes := preload("shapes.gd")

enum IndicatorClass {
	GENERIC,
	OBJECT,
	CONTROL_POINT,
}

enum HighlightClass {
	NONE,
	SELECTED,
	DISABLED,
}


@export var color_1a := Color(0.29, 0.787, 0.895)
@export var color_1b := Color(0.156, 0.322, 0.344)
@export var color_2a := Color(0.975, 0.569, 0.822)
@export var color_2b := Color(0.486, 0.361, 0.732)
@export var color_3a := Color(0.986, 0.758, 0.34)
@export var color_3b := Color(0.521, 0.283, 0.228)


@export var highlight_colors: Dictionary[HighlightClass, PackedColorArray]


var targets: Dictionary[int, Dictionary]

var _indicator_meshes: Dictionary[IndicatorClass, Mesh]
var _highlight_materials: Dictionary[HighlightClass, Material]

var _vis_available_index: int
var _vis_nodes: Array[MeshInstance3D]

var bench: Bench
var zhost: ZedHost


func draw_indicator(transform: Transform3D, indicator_class: IndicatorClass, highlight_class: HighlightClass) -> void:
	var mi := _next_vis()
	if _indicator_meshes.has(indicator_class):
		mi.mesh = _indicator_meshes[indicator_class]
	if _highlight_materials.has(highlight_class):
		mi.material_override = _highlight_materials[highlight_class]

	mi.global_transform = transform
	mi.show()


func _draw_part_datum(part_id: int, idatum: int) -> void:
	var datum_class := zhost.part_get_datum_class(part_id, idatum)
	var indicator_class := IndicatorClass.GENERIC
	match datum_class:
		Zed.DatumClass.VOID: return
		Zed.DatumClass.OBJECT: indicator_class = IndicatorClass.OBJECT
		Zed.DatumClass.ARMATURE: indicator_class = IndicatorClass.CONTROL_POINT
	var highlight_class := HighlightClass.NONE
	if bench.selection.has(Zed.TYPE_ARMATURE_POINT, part_id, idatum):
		highlight_class = HighlightClass.SELECTED
	draw_indicator(zhost.part_get_transform(part_id, idatum), indicator_class, highlight_class)


func _next_vis() -> MeshInstance3D:
	var mi: MeshInstance3D
	if _vis_available_index < _vis_nodes.size():
		mi = _vis_nodes[_vis_available_index]
	else:
		mi = MeshInstance3D.new()
		#mi.mesh = _needle_mesh
		#if mi.get_surface_override_material_count():
		#mi.material_override = _needle_material[0]
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
	bench = Bench.find_bench_parent(self)
	zhost = bench.get_zed_host()
	zhost.part_added.connect(_on_part_added)
	zhost.part_removed.connect(_on_part_removed)

	_indicator_meshes[IndicatorClass.GENERIC] = _ZedShapes.mesh_indicator_point()
	_indicator_meshes[IndicatorClass.OBJECT] = _ZedShapes.mesh_indicator_cross()
	_indicator_meshes[IndicatorClass.CONTROL_POINT] = _ZedShapes.mesh_indicator_pin()
	for highlight_class in HighlightClass.values():
		var color_a := Color.MAGENTA
		var color_b := Color(color_a.darkened(0.5), 0.5)
		if highlight_colors.has(highlight_class):
			var colors := highlight_colors[highlight_class]
			if !colors.is_empty():
				color_a = colors[0]
			if colors.size() > 1:
				color_b = colors[1]
			else:
				color_b = Color.from_ok_hsl(color_a.ok_hsl_h - 0.12, color_a.ok_hsl_s - 0.36, color_a.ok_hsl_l - 0.39, 0.5)
		_highlight_materials[highlight_class] = _create_material(color_a, color_b)


func _process(_delta: float) -> void:
	_vis_available_index = 0

	for part_id: int in targets: #zhost.get_all_part_ids():
		for idatum in range(zhost.part_get_datum_count(part_id)):
			_draw_part_datum(part_id, idatum)

	while _vis_available_index < _vis_nodes.size():
		_vis_nodes[_vis_available_index].hide()
		_vis_available_index += 1
