class_name Workspace
extends Node3D
## Workspace is the spatial part of the bench.


const _WorkspaceShellLayer := preload("shell_layer.gd")

const COLLISION_LAYER_PLACEMENT := 2
const COLLISION_MASK_PLACEMENT := 3


signal shell_appearing(type: int)
signal shell_disappearing(type: int)

signal part_placement_conflict_added(part_id: int, conflict_id: int, data: Dictionary[StringName, Variant])
signal part_placement_conflict_removed(part_id: int, conflict_id: int, data: Dictionary[StringName, Variant])


var _layers: Array[_WorkspaceShellLayer]
var _placement_conflicts: Dictionary[int, Dictionary]


func push_shell_layer(shell_type: int) -> void:
	if has_active_shell():
		_notify_shell_disappearing(_shell_stack_top())
	var layer := _WorkspaceShellLayer.new()
	layer.shell_type = shell_type
	_layers.push_back(layer)
	_notify_shell_appearing(layer)
	add_child(layer)


func pop_shell_layer() -> void:
	if _shell_stack_is_empty():
		push_error("Nothing to pop. Stack is empty.")
		return
	var top := _shell_stack_top()
	_notify_shell_disappearing(top)
	_layers.pop_back()
	top.queue_free()
	if !_shell_stack_is_empty():
		_notify_shell_appearing(_shell_stack_top())


func has_active_shell() -> bool:
	return !_shell_stack_is_empty()


## returns [code]-1[/code] if there is no active shell layer
func get_active_shell_type() -> int:
	if _shell_stack_is_empty():
		return -1
	return _shell_stack_top().shell_type


func shell_create_owner() -> int:
	return _shell_stack_top().create_shell()


func shell_add_node(shell_id: int, shell_node: Node) -> void:
	_shell_stack_top().add_shell_node(shell_id, shell_node)


func shell_get_nodes(shell_id: int) -> Array[Node]:
	return _shell_stack_top().get_shell_nodes(shell_id)


func shell_remove(shell_id: int) -> void:
	_shell_stack_top().remove_shell(shell_id)


## Configures [param volume] as part placement volume for [param part_id].
func register_part_placement_volume(part_id: int, volume: Area3D) -> void:
	volume.collision_layer = COLLISION_LAYER_PLACEMENT
	volume.collision_mask = COLLISION_MASK_PLACEMENT
	volume.monitorable = true
	volume.monitoring = true
	volume.area_entered.connect(_on_part_placement_volume_area_entered.bind(part_id, volume))
	volume.area_exited.connect(_on_part_placement_volume_area_exited.bind(part_id, volume))


func part_placement_conflict_add(part_id: int, conflict_id: int, data: Dictionary[StringName, Variant]) -> void:
	if !_placement_conflicts.has(part_id):
		_placement_conflicts[part_id] = {}
	var dict := _placement_conflicts[part_id]
	dict[conflict_id] = data
	part_placement_conflict_added.emit(part_id, conflict_id, data)


func part_placement_conflict_remove(part_id: int, conflict_id: int) -> void:
	assert(_placement_conflicts.has(part_id))
	var dict := _placement_conflicts[part_id]
	var data = dict[conflict_id]
	dict.erase(conflict_id)
	part_placement_conflict_removed.emit(part_id, conflict_id, data)


func part_placement_conflict_get_data(part_id: int, conflict_id: int) -> Variant:
	assert(_placement_conflicts.has(part_id))
	var dict := _placement_conflicts[part_id]
	assert(dict.has(conflict_id))
	return dict[conflict_id]


func part_has_placement_conflict(part_id: int) -> bool:
	if !_placement_conflicts.has(part_id):
		return false
	return !_placement_conflicts[part_id].is_empty()


func _shell_stack_is_empty() -> bool:
	return _layers.is_empty()


func _shell_stack_top() -> _WorkspaceShellLayer:
	assert(_layers.size() > 0)
	return _layers[-1]


func _notify_shell_appearing(layer: _WorkspaceShellLayer) -> void:
	shell_appearing.emit(layer.shell_type)


func _notify_shell_disappearing(layer: _WorkspaceShellLayer) -> void:
	shell_disappearing.emit(layer.shell_type)
	layer.clear()


func _on_part_placement_volume_area_entered(area: Area3D, part_id: int, volume: Area3D) -> void:
	var conflict_id := hash(area.get_instance_id()) ^ hash(volume.get_instance_id())
	var data: Dictionary[StringName, Variant] = {
		&"volume": volume,
		&"other": area,
	}
	part_placement_conflict_add(part_id, conflict_id, data)


func _on_part_placement_volume_area_exited(area: Area3D, part_id: int, volume: Area3D) -> void:
	var conflict_id := hash(area.get_instance_id()) ^ hash(volume.get_instance_id())
	part_placement_conflict_remove(part_id, conflict_id)
