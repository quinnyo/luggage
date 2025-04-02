@tool
extends RefCounted


class Zgon:
	var _vertices: PackedVector3Array
	var _transform: Transform3D
	var _colors: PackedColorArray
	var _close: bool
	var _children: Array[Zgon]

	func build(arrays: Array, vertex_color: Color, xf: Transform3D) -> void:
		if get_individual_vertex_count():
			var verts := xf * build_vertex()
			var indices := build_index(arrays[Mesh.ARRAY_VERTEX].size())
			var colors := build_color(vertex_color)
			arrays[Mesh.ARRAY_VERTEX].append_array(verts)
			arrays[Mesh.ARRAY_INDEX].append_array(indices)
			arrays[Mesh.ARRAY_COLOR].append_array(colors)
		for child: Zgon in _children:
			child.build(arrays, vertex_color, xf * _transform)

	func build_vertex() -> PackedVector3Array:
		return _transform * _vertices

	func build_index(offset: int = 0) -> PackedInt32Array:
		var point_count := get_individual_vertex_count()
		var stride := 1
		var indices := PackedInt32Array()
		var segment_count := point_count + 1 if _close else point_count
		var index_count := segment_count * 2
		indices.resize(index_count)
		for i: int in range(segment_count - 1):
			var v0i := offset + (i * stride) % point_count
			var v1i := offset + ((i + 1) * stride) % point_count
			indices[i * 2] = v0i
			indices[i * 2 + 1] = v1i
		return indices

	func build_color(mod_color: Color) -> PackedColorArray:
		var result := PackedColorArray()
		var n := get_individual_vertex_count()
		var src := PackedColorArray([Color.WHITE]) if _colors.is_empty() else _colors
		result.resize(n)
		if src.size() == 1:
			result.fill(mod_color * src[0])
		else:
			for i: int in range(n):
				result[i] = mod_color * src[i % src.size()]
		return result

	func get_individual_vertex_count() -> int:
		return _vertices.size()

	func get_total_vertex_count() -> int:
		var n := get_individual_vertex_count()
		for child: Zgon in _children:
			n += child.get_total_vertex_count()
		return n

	func vertices(value: PackedVector3Array) -> Zgon:
		_vertices = value.duplicate()
		return self

	func transform(xf: Transform3D) -> Zgon:
		_transform = xf * _transform
		return self

	func rotate(axis: Vector3, angle: float) -> Zgon:
		return transform(Transform3D(Basis(axis, angle), Vector3()))

	func close() -> Zgon:
		_close = true
		return self

	func color(value: Color) -> Zgon:
		_colors = PackedColorArray([value])
		return self

	func fork() -> Zgon:
		var child := clone()
		_children.push_back(child)
		return child

	func combi(others: Array[Zgon]) -> Zgon:
		_children.append_array(others)
		return self

	func clone() -> Zgon:
		var zgon := Zgon.new()
		zgon._vertices = _vertices.duplicate()
		zgon._transform = _transform
		zgon._colors = _colors.duplicate()
		zgon._close = _close
		for child in _children:
			zgon._children.push_back(child.clone())
		return zgon


const ZGON_UNIT := 200.0
const ZGON_SCALE := Vector3.ONE / ZGON_UNIT


static func indicator_pivot(radius: float) -> Zgon:
	var vertices := PackedVector3Array([Vector3(0, 0, -radius), Vector3(-radius, 0, 0), Vector3(0, 0, radius), Vector3(radius, 0, 0)])
	return Zgon.new().vertices(vertices).close()


static func indicator_arm(length: float, width_inner: float, vee_inner: float, width_outer: float, vee_outer: float) -> Zgon:
	var x_outer := width_outer / 2.0
	var x_inner := width_inner / 2.0
	# TODO: slide inner points along pivot
	var vertices := PackedVector3Array([Vector3(-x_inner, 0, 35), Vector3(-x_outer, 0, length), Vector3(0, 0, length + vee_outer), Vector3(x_outer, 0, length), Vector3(x_inner, 0, 35), Vector3(0, 0, vee_inner)])
	return Zgon.new().vertices(vertices).close()


static func mesh_indicator_point(vertex_color: Color = Color.WHITE, xf: Transform3D = Transform3D.IDENTITY) -> Mesh:
	xf = xf * Transform3D(Basis.from_scale(ZGON_SCALE), Vector3())
	var zgons: Array[Zgon] = [
		Zgon.new().combi([
			indicator_pivot(15),
			indicator_pivot(30),
			indicator_pivot(50).rotate(Vector3.UP, PI / 4.0),
		]),
	]
	return build_zgons_wire_mesh(zgons, vertex_color, xf)


static func mesh_indicator_pin(vertex_color: Color = Color.WHITE, xf: Transform3D = Transform3D.IDENTITY) -> Mesh:
	xf = xf * Transform3D(Basis.from_scale(ZGON_SCALE), Vector3())
	var zgons: Array[Zgon] = [
		Zgon.new().combi([
			indicator_pivot(40),
			indicator_arm(400, 30, 50, 20, 30),
		]),
	]
	return build_zgons_wire_mesh(zgons, vertex_color, xf)


static func mesh_indicator_cross(vertex_color: Color = Color.WHITE, xf: Transform3D = Transform3D.IDENTITY) -> Mesh:
	xf = xf * Transform3D(Basis.from_scale(ZGON_SCALE), Vector3())
	var zgons: Array[Zgon] = [
		Zgon.new().combi([
			indicator_arm(150, 30, 50, 40, -20),
			indicator_arm(150, 30, 50, 40, -20).rotate(Vector3.UP, PI),
			indicator_arm(150, 30, 50, 40, -20).rotate(Vector3.UP, PI / 2.0),
			indicator_arm(150, 30, 50, 40, -20).rotate(Vector3.UP, -PI / 2.0),
		]),
	]
	return build_zgons_wire_mesh(zgons, vertex_color, xf)


static func mesh_indicator_dagger(vertex_color: Color = Color.WHITE, xf: Transform3D = Transform3D.IDENTITY) -> Mesh:
	xf = xf * Transform3D(Basis.from_scale(ZGON_SCALE), Vector3())
	var zgons: Array[Zgon] = [
		indicator_arm(460, 30, 50, 20, 40),
		indicator_arm(250, 30, 50, 40, 20).rotate(Vector3.UP, PI),
		Zgon.new().combi([
			indicator_pivot(45),
			indicator_arm(150, 30, 50, 25, 15).rotate(Vector3.UP, PI / 2.0),
			indicator_arm(150, 30, 50, 25, 15).rotate(Vector3.UP, -PI / 2.0)
		]),
	]
	return build_zgons_wire_mesh(zgons, vertex_color, xf)


static func build_zgons_wire_mesh(zgons: Array[Zgon], vertex_color: Color = Color.WHITE, xf: Transform3D = Transform3D.IDENTITY) -> Mesh:
	var mesh := ArrayMesh.new()
	for zgon in zgons:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array()
		arrays[Mesh.ARRAY_INDEX] = PackedInt32Array()
		arrays[Mesh.ARRAY_COLOR] = PackedColorArray()

		var nreps := 3
		for i: int in range(nreps):
			var alpha := i / float(nreps - 1)
			var col := Color(vertex_color, 1.0 - alpha * 0.8)
			zgon.build(arrays, col, xf.translated(Vector3(0.0, alpha * 0.02, 0.0)))

		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return mesh
