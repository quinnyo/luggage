class_name Placement3D
extends Area3D
## A 'spatial anchor' shell node that occupies a 3D region in the workspace.
## Registers with the workspace as a part placement volume.


signal pointer_entered
signal pointer_exited
signal activated
signal deactivated


enum ActiveState {
	## Not activated
	IDLE,
	## Activated
	ACTIVE,
	## Not able to activate
	DISABLED,
}


## The ID of the part this belongs to
var part_id: int

var active_state: ActiveState:
	set(value):
		if active_state != value:
			var prev := active_state
			active_state = value
			if prev == ActiveState.ACTIVE:
				deactivated.emit()
			elif value == ActiveState.ACTIVE:
				activated.emit()

var hovered: bool:
	set(value):
		if value != hovered:
			hovered = value
			if hovered:
				pointer_entered.emit()
			else:
				pointer_exited.emit()


func is_active() -> bool:
	return active_state == ActiveState.ACTIVE


func is_disabled() -> bool:
	return active_state == ActiveState.DISABLED


func activate() -> void:
	if is_disabled():
		return
	active_state = ActiveState.ACTIVE


func deactivate() -> void:
	if is_disabled():
		return
	active_state = ActiveState.IDLE


func _enter_tree() -> void:
	var parent := get_parent()
	while parent and parent is not Workspace:
		parent = parent.get_parent()
	var workspace := parent as Workspace
	workspace.register_part_placement_volume(part_id, self)
