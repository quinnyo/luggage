class_name Placement3D
extends Area3D
## A 'spatial anchor' shell node that occupies a 3D region in the workspace.
## Registers with the workspace as a part placement volume.


## The ID of the part this belongs to
var part_id: int
## The sub-ID of this placement in the part
var sub_id: int = -1


var _volume_id: int


func _enter_tree() -> void:
	var parent := get_parent()
	while parent and parent is not Workspace:
		parent = parent.get_parent()
	var workspace := parent as Workspace
	_volume_id = workspace.register_part_placement_volume(part_id, self, sub_id)
