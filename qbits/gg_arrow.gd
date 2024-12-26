@tool
class_name GenGeomArrow extends Resource


@export var head_length: float = 1.0:
	set(value):
		head_length = value
		_changed()
@export var head_waist: float = 0.5:
	set(value):
		head_waist = value
		_changed()
@export var head_waist_slide: float = 0.7:
	set(value):
		head_waist_slide = value
		_changed()
@export var head_aspect: float = 0.45:
	set(value):
		head_aspect = value
		_changed()
@export var neck_frac: float = 0.2:
	set(value):
		neck_frac = value
		_changed()
@export var sweep: float = 0.5:
	set(value):
		sweep = value
		_changed()

@export var basis: Basis = Basis.IDENTITY:
	set(value):
		basis = value
		_changed()

@export_storage var _head_vertices: PackedVector3Array

var _head_dirty: bool = true


func get_head_vertices() -> PackedVector3Array:
	if _head_dirty:
		_gen_head()
	return _head_vertices.duplicate()


func get_head_indices() -> PackedInt32Array:
	return arrow_head_filled_indices()


func _gen_head() -> void:
	_head_vertices = arrow_head_outline(basis, head_length, head_waist, head_waist_slide, head_aspect, sweep, neck_frac)
	_head_dirty = false


func _changed() -> void:
	_gen_head()
	emit_changed()



enum {
	VIDX_HEAD_BASE,
	VIDX_HEAD_BASE_R,
	VIDX_HEAD_WING_R,
	VIDX_HEAD_WAIST_R,
	VIDX_HEAD_TIP,
	VIDX_HEAD_WAIST_L,
	VIDX_HEAD_WING_L,
	VIDX_HEAD_BASE_L,
}

const ARROW_HEAD_INDICES := [
	VIDX_HEAD_TIP, VIDX_HEAD_BASE, VIDX_HEAD_WAIST_R,
	VIDX_HEAD_BASE_R, VIDX_HEAD_WAIST_R, VIDX_HEAD_BASE,
	VIDX_HEAD_WAIST_R, VIDX_HEAD_BASE_R, VIDX_HEAD_WING_R,

	VIDX_HEAD_TIP, VIDX_HEAD_WAIST_L, VIDX_HEAD_BASE,
	VIDX_HEAD_BASE_L, VIDX_HEAD_BASE, VIDX_HEAD_WAIST_L,
	VIDX_HEAD_WAIST_L, VIDX_HEAD_WING_L, VIDX_HEAD_BASE_L,
]


static func arrow_head_outline(basis: Basis, length: float, waist: float = 0.6, waist_slide: float = 0.5, aspect: float = 0.3, sweep: float = 0.5, neck_frac: float = 0.2) -> PackedVector3Array:
	var left := -basis.x * length * aspect
	var stem_base_left := left * neck_frac
	var wing_sweep := -basis.z * length * sweep
	var tip := basis.z * length
	var waist_mid := tip * waist_slide

	var vertices := PackedVector3Array([
		Vector3.ZERO,
		-stem_base_left,
		-left + wing_sweep,
		-left * waist + waist_mid,
		tip,
		left * waist + waist_mid,
		left + wing_sweep,
		stem_base_left,
	])
	return vertices


static func arrow_head_filled_indices() -> PackedInt32Array:
	return PackedInt32Array(ARROW_HEAD_INDICES)
