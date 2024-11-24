class_name SpawnGrid extends Node3D


@export var spacing := Vector3(10.0, 10.0, 10.0)
@export var size: Vector3i = Vector3i(8, 1, 8)


var _generated_hash: int = 0
var _points := PackedVector3Array()
var _coords: Array[Vector3i] = []


func config_hash() -> int:
	return hash(spacing) ^ hash(size)


func generate() -> void:
	_generated_hash = config_hash()
	var n := points_count()
	_points.resize(n)
	_coords.resize(n)
	for i in range(n):
		_coords[i] = coord(i)
		_points[i] = point(i)


func coord(i: int) -> Vector3i:
	var x := i % size.x
	var y := i
	@warning_ignore("integer_division")
	var z := i / size.x
	return Vector3i(x, y, z)


func point(i: int) -> Vector3:
	return to_global(Vector3(coord(i)) * spacing)


func points_count() -> int:
	return size.x * size.y * size.z


func get_coords() -> Array[Vector3i]:
	if config_hash() != _generated_hash:
		generate()
	return _coords.duplicate()


func get_points() -> PackedVector3Array:
	if config_hash() != _generated_hash:
		generate()
	return _points.duplicate()
