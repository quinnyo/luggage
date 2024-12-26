@tool
class_name ConveyorSectionDebugMesh
extends ArrayMesh


@export var spline: SectionSpline:
	set(value):
		connect_resource_changed(spline, value, _build)
		spline = value
		_build()
@export var arrow: GenGeomArrow = GenGeomArrow.new():
	set(value):
		connect_resource_changed(arrow, value, _build)
		arrow = value
		_build()


static func connect_resource_changed(res_old: Resource, res_new: Resource, callable: Callable) -> void:
	if res_old && res_old.changed.is_connected(callable):
		res_old.changed.disconnect(callable)
	if res_new:
		res_new.changed.connect(callable)


func with_spline(section: SectionSpline) -> void:
	if not arrow:
		arrow = GenGeomArrow.new()

	var arrays := []
	arrays.resize(ARRAY_MAX)
	var entry_xf := Transform3D(Basis.IDENTITY, Vector3(0.0, 0.5, 0.0))
	arrays[ARRAY_VERTEX] = entry_xf * arrow.get_head_vertices()
	arrays[ARRAY_INDEX] = arrow.get_head_indices()
	add_surface_from_arrays(PRIMITIVE_TRIANGLES, arrays)

	var exit_xf := Transform3D(section.get_exit_rotation(), section.get_exit_offset() + Vector3(0.0, 0.5, 0.0))
	arrays[ARRAY_VERTEX] = exit_xf * arrow.get_head_vertices()
	add_surface_from_arrays(PRIMITIVE_TRIANGLES, arrays)


func _build() -> void:
	clear_surfaces()
	if spline:
		with_spline(spline)
