extends RefCounted

signal volumes_overlapping(pair_id: int, a_volume_id: int, b_volume_id: int)
signal volumes_separated(pair_id: int, a_volume_id: int, b_volume_id: int)

const ID_NONE := -1

const K_NODE := &"node"
const K_RID := &"rid"


var _volumes: Dictionary[int, Dictionary]
var _volumes_by_rid: Dictionary[RID, int]
var _overlapping: Dictionary[int, Dictionary]

var _id_next := 100


## Register an Area3D as a new volume.
func register_area_3d(area: Area3D) -> int:
	var id := _alloc_id()
	var area_rid := area.get_rid()
	var vol: Dictionary[StringName, Variant] = {
		K_NODE: area,
		K_RID: area_rid,
	}
	_volumes[id] = vol
	_volumes_by_rid[area_rid] = id
	area.area_entered.connect(_on_volume_area_entered.bind(id))
	area.area_exited.connect(_on_volume_area_exited.bind(id))
	return id


## Find a volume registered with [param area_rid] and no shapes.
func find_volume_with_area(area_rid: RID) -> int:
	return _volumes_by_rid.get(area_rid, ID_NONE)


func volume_get_area_node(volume_id: int) -> Area3D:
	assert(_volumes.has(volume_id))
	return _volumes[volume_id][K_NODE]


func volume_get_area_rid(volume_id: int) -> RID:
	assert(_volumes.has(volume_id))
	return _volumes[volume_id][K_RID]


func _add_overlapping_pair(a: int, b: int) -> void:
	assert(a != b)
	var pair := PackedInt64Array([b, a] if b < a else [a, b])
	var h := hash(pair)
	if !_overlapping.has(h):
		volumes_overlapping.emit(h, pair[0], pair[1])
		_overlapping[h] = {}


func _remove_overlapping_pair(a: int, b: int) -> void:
	assert(a != b)
	var pair := PackedInt64Array([b, a] if b < a else [a, b])
	var h := hash(pair)
	if _overlapping.has(h):
		volumes_separated.emit(h, pair[0], pair[1])
		_overlapping.erase(h)


func _alloc_id() -> int:
	var id := maxi(1, _id_next)
	_id_next = id + 1
	return id


func _on_volume_area_entered(area: Area3D, volume_id: int) -> void:
	var area_rid := area.get_rid()
	var b_volume_id := find_volume_with_area(area_rid)
	if b_volume_id != ID_NONE:
		_add_overlapping_pair(volume_id, b_volume_id)


func _on_volume_area_exited(area: Area3D, volume_id: int) -> void:
	var area_rid := area.get_rid()
	var b_volume_id := find_volume_with_area(area_rid)
	if b_volume_id != ID_NONE:
		_remove_overlapping_pair(volume_id, b_volume_id)
