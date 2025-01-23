class_name Support3D
extends Area3D


var _volume_id: int


func _enter_tree() -> void:
	var parent := get_parent()
	while parent and parent is not Workspace:
		parent = parent.get_parent()
	var workspace := parent as Workspace
	_volume_id = workspace.register_support_volume(self)
