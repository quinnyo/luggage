@tool
class_name ZedShapes
extends RefCounted


static func build_needle_wire_mesh(vertex_color: Color = Color.WHITE, xf: Transform3D = Transform3D.IDENTITY) -> Mesh:
	xf = xf * Transform3D(Basis.from_scale(Vector3.ONE * 0.002), Vector3())

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array()
	arrays[Mesh.ARRAY_COLOR] = PackedColorArray()

	var nreps := 3
	for i: int in range(nreps):
		var alpha := i / float(nreps - 1)
		var col := Color(vertex_color, 1.0 - alpha * 0.8)
		mesh_arrays_add_needle_wire(arrays, col, xf.translated(Vector3(0.0, alpha * 0.02, 0.0)))

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return mesh


static func mesh_arrays_add_needle_wire(arrays: Array, vertex_color: Color, xf: Transform3D) -> void:
	var points_pivot_0 := PackedVector3Array([Vector3(0, 0, -50), Vector3(-50, 0, 0), Vector3(0, 0, 50), Vector3(50, 0, 0)])
	mesh_arrays_add_polyline(arrays, points_pivot_0, true, xf)
	var points_back := PackedVector3Array([Vector3(15, 0, -35), Vector3(20, 0, -250), Vector3(-20, 0, -250), Vector3(-15, 0, -35)])
	mesh_arrays_add_polyline(arrays, points_back, false, xf)
	var points_fore := PackedVector3Array([Vector3(-15, 0, 35), Vector3(-5, 0, 500), Vector3(5, 0, 500), Vector3(15, 0, 35)])
	mesh_arrays_add_polyline(arrays, points_fore, false, xf)

	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var add_colors := PackedColorArray()
	add_colors.resize(arrays[Mesh.ARRAY_VERTEX].size() - colors.size())
	add_colors.fill(vertex_color)
	colors.append_array(add_colors)


static func mesh_arrays_add_polyline(arrays: Array, vertices: PackedVector3Array, close: bool, xf: Transform3D) -> void:
	assert(arrays.size() == Mesh.ARRAY_MAX)
	assert(arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array)
	assert(arrays[Mesh.ARRAY_INDEX] is PackedInt32Array)

	var indices := index_polyline(vertices.size(), close, arrays[Mesh.ARRAY_VERTEX].size())
	arrays[Mesh.ARRAY_VERTEX].append_array(xf * vertices)
	arrays[Mesh.ARRAY_INDEX].append_array(indices)


static func index_polyline(point_count: int, close: bool = false, offset: int = 0, stride: int = 1) -> PackedInt32Array:
	var indices := PackedInt32Array()
	var segment_count := point_count + 1 if close else point_count
	var index_count := segment_count * 2
	indices.resize(index_count)
	for i: int in range(segment_count - 1):
		var v0i := offset + (i * stride) % point_count
		var v1i := offset + ((i + 1) * stride) % point_count
		indices[i * 2] = v0i
		indices[i * 2 + 1] = v1i
	return indices
