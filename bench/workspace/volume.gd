class_name WorkspaceVolume
extends Area3D
## A shell node that occupies a 3D region in the workspace.
## Detects placement conflicts with other volumes.


## A workspace placement conflict caused by two volumes intersecting.
class VolumeIntersection:
	var anode: Area3D
	var bnode: Area3D
	var shape_pairs: Dictionary[int, PackedInt64Array]

	func insert_shape_pair(a: int, b: int) -> void:
		var pair := PackedInt64Array([a, b])
		var h := hash(pair)
		if shape_pairs.has(h):
			return
		shape_pairs[h] = PackedInt64Array([a, b])

	func remove_shape_pair(a: int, b: int) -> void:
		var pair := PackedInt64Array([a, b])
		var h := hash(pair)
		if shape_pairs.has(h):
			shape_pairs.erase(h)

	func is_empty() -> bool:
		return shape_pairs.is_empty()


const WORKSPACE_VOLUME_LAYER := 2


var conflicts: Dictionary[RID, VolumeIntersection]
var workspace: Workspace
var kernel: Node


func has_conflicts() -> bool:
	return !conflicts.is_empty()


func _update_debug_color() -> void:
	var color: Color = ProjectSettings.get_setting("debug/shapes/collision/shape_color")
	if has_conflicts():
		color.ok_hsl_h += 0.5
	for child in get_children():
		if child is CollisionShape3D:
			child.debug_color = color


func _on_area_shape_entered(area_rid: RID, area: Area3D, area_shape_index: int, local_shape_index: int) -> void:
	if !conflicts.has(area_rid):
		var conflict := VolumeIntersection.new()
		conflicts[area_rid] = conflict
		conflict.anode = self
		conflict.bnode = area
	conflicts[area_rid].insert_shape_pair(local_shape_index, area_shape_index)
	_update_debug_color()


func _on_area_shape_exited(area_rid: RID, _area: Area3D, area_shape_index: int, local_shape_index: int) -> void:
	if !conflicts.has(area_rid):
		return
	conflicts[area_rid].remove_shape_pair(local_shape_index, area_shape_index)
	if conflicts[area_rid].is_empty():
		conflicts.erase(area_rid)
	_update_debug_color()


func _init() -> void:
	collision_layer = WORKSPACE_VOLUME_LAYER
	collision_mask = WORKSPACE_VOLUME_LAYER
	area_shape_entered.connect(_on_area_shape_entered)
	area_shape_exited.connect(_on_area_shape_exited)


func _enter_tree() -> void:
	var parent := get_parent()
	while parent and parent is not Workspace:
		parent = parent.get_parent()
	workspace = parent as Workspace
