class_name WorkspaceVolume
extends Area3D
## A shell node that occupies a 3D region in the workspace.
## Detects placement conflicts with other volumes.


var part_id: int


func _enter_tree() -> void:
	var parent := get_parent()
	while parent and parent is not Workspace:
		parent = parent.get_parent()
	var workspace := parent as Workspace
	workspace.register_part_placement_volume(part_id, self)
