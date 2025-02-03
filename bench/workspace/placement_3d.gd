class_name Placement3D
extends Area3D
## A 'spatial anchor' shell node that occupies a 3D region in the workspace.
## Registers with the workspace as a part placement volume.


## The ID of the part this belongs to
var part_id: int
## The sub-ID of this placement in the part
var sub_id: int = -1
## *shrugsss*
var sub_id_is_armature_index: bool = false

var _volume_id: int
var _bench: Bench


func _enter_tree() -> void:
	_bench = Bench.find_bench_parent(self)

	var parent := get_parent()
	while parent and parent is not Workspace:
		parent = parent.get_parent()
	var workspace := parent as Workspace
	_volume_id = workspace.register_part_placement_volume(part_id, self, sub_id)


func _process(_delta: float) -> void:
	if sub_id_is_armature_index:
		transform = _bench.get_zed_host().part_armature_get_transform(part_id, sub_id)
