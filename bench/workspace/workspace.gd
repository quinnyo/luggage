class_name Workspace
extends Node3D
## Workspace is the spatial part of the bench.


const _WorkspaceShellLayer := preload("shell_layer.gd")
const VolumeManager := preload("volume_manager.gd")

const COLLISION_LAYER_PLACEMENT := 2
const COLLISION_MASK_PLACEMENT := 3

const K_PLACEMENT_PART_ID := &"part_id"
const K_PLACEMENT_SUB_ID := &"sub_id"

const K_SUPPORT_CLIENTS := &"clients"


signal shell_appearing(type: int)
signal shell_disappearing(type: int)

signal part_placement_conflict_added(part_id: int, conflict_id: int, data: Dictionary[StringName, Variant])
signal part_placement_conflict_removed(part_id: int, conflict_id: int, data: Dictionary[StringName, Variant])

## Added a support-placement [param pair] to part [param part_id].
## [br][param count] is the updated number of supports the part has.
signal part_support_added(part_id: int, pair: int, count: int)
## Removed a support-placement [param pair] from part [param part_id].
## [br][param count] is the updated number of supports the part has.
signal part_support_removed(part_id: int, pair: int, count: int)

signal part_supported(part_id: int)
signal part_unsupported(part_id: int)

signal pointer_3d_entered(pos: Vector3)
signal pointer_3d_exited()
signal pointer_3d_moved(pos: Vector3, delta: Vector3)


var _pointer_3d_position: Vector3
var _pointer_3d_is_present: bool = false
var _layers: Array[_WorkspaceShellLayer]
var _placement_conflicts: Dictionary[int, Dictionary]
var _volumes: VolumeManager = VolumeManager.new()
var _placement_volumes: Dictionary[int, Dictionary]
var _support_volumes: Dictionary[int, Dictionary]
var _part_supports: Dictionary[int, Dictionary]


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


## Configures [param volume] as a support volume.
func register_support_volume(volume: Area3D) -> int:
	volume.collision_layer = 0
	volume.collision_mask = COLLISION_MASK_PLACEMENT
	volume.monitorable = false
	volume.monitoring = true
	var id := _volumes.register_area_3d(volume)
	var data: Dictionary[StringName, Variant] = {
		K_SUPPORT_CLIENTS: {},
	}
	_support_volumes[id] = data
	return id


## Configures [param volume] as part placement volume for [param part_id].
func register_part_placement_volume(part_id: int, volume: Area3D, sub_id: int = -1) -> int:
	volume.collision_layer = COLLISION_LAYER_PLACEMENT
	volume.collision_mask = COLLISION_MASK_PLACEMENT
	volume.monitorable = true
	volume.monitoring = true
	volume.area_entered.connect(_on_part_placement_volume_area_entered.bind(part_id, volume))
	volume.area_exited.connect(_on_part_placement_volume_area_exited.bind(part_id, volume))
	var id := _volumes.register_area_3d(volume)
	var data: Dictionary[StringName, Variant] = {
		K_PLACEMENT_PART_ID: part_id,
		K_PLACEMENT_SUB_ID: sub_id,
	}
	_placement_volumes[id] = data
	return id


func placement_get_part_id(volume_id: int) -> int:
	assert(_placement_volumes.has(volume_id))
	return _placement_volumes[volume_id][K_PLACEMENT_PART_ID]


func placement_set_sub_id(volume_id: int, sub_id: int) -> void:
	var data: Dictionary[StringName, Variant] = _placement_volumes[volume_id]
	data[K_PLACEMENT_SUB_ID] = sub_id


func placement_get_sub_id(volume_id: int) -> int:
	var data: Dictionary[StringName, Variant] = _placement_volumes[volume_id]
	return data[K_PLACEMENT_SUB_ID]


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


func part_support_add(part_id: int, pair: int, support_volume_id: int) -> void:
	if _support_is_occupied(support_volume_id):
		push_warning("support overloaded (part_id=%d, pair=%d, support_volume_id=%d)" % [ part_id, pair, support_volume_id ])
	_support_volumes[support_volume_id][K_SUPPORT_CLIENTS][pair] = part_id
	var supports := _part_supports[part_id]
	supports[pair] = 1
	part_support_added.emit(part_id, pair, supports.size())
	if supports.size() == 1:
		part_supported.emit(part_id)


func part_support_remove(part_id: int, pair: int, support_volume_id: int) -> void:
	_support_volumes[support_volume_id][K_SUPPORT_CLIENTS].erase(pair)
	var supports := _part_supports[part_id]
	supports.erase(pair)
	part_support_removed.emit(part_id, pair, supports.size())
	if supports.size() == 0:
		part_unsupported.emit(part_id)


func pointer_3d_set_position(pos: Vector3) -> void:
	var delta := pos - _pointer_3d_position
	_pointer_3d_position = pos
	if !pointer_3d_is_present():
		pointer_3d_set_presence(true)
	elif !delta.is_zero_approx():
		pointer_3d_moved.emit(_pointer_3d_position, delta)


func pointer_3d_set_presence(is_present: bool) -> void:
	if _pointer_3d_is_present != is_present:
		_pointer_3d_is_present = is_present
		if is_present:
			pointer_3d_entered.emit(_pointer_3d_position)
		else:
			pointer_3d_exited.emit()


func pointer_3d_get_position() -> Vector3:
	return _pointer_3d_position


func pointer_3d_is_present() -> bool:
	return _pointer_3d_is_present


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


func _support_is_occupied(support_volume_id: int) -> bool:
	return _support_volumes[support_volume_id][K_SUPPORT_CLIENTS].size()


func _init() -> void:
	_volumes.volumes_overlapping.connect(_on_volumes_overlapping)
	_volumes.volumes_separated.connect(_on_volumes_separated)


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


func _on_support_volume_entered(pair: int, support_volume_id: int, other_volume_id: int) -> void:
	if other_volume_id in _placement_volumes:
		var part_id := placement_get_part_id(other_volume_id)
		if !_part_supports.has(part_id):
			_part_supports[part_id] = {}
		part_support_add(part_id, pair, support_volume_id)


func _on_support_volume_exited(pair: int, support_volume_id: int, other_volume_id: int) -> void:
	if other_volume_id in _placement_volumes:
		var part_id := placement_get_part_id(other_volume_id)
		if !_part_supports.has(part_id):
			return
		part_support_remove(part_id, pair, support_volume_id)


func _on_volumes_overlapping(pair: int, a_volume_id: int, b_volume_id) -> void:
	if a_volume_id in _support_volumes:
		_on_support_volume_entered(pair, a_volume_id, b_volume_id)
	elif b_volume_id in _support_volumes:
		_on_support_volume_entered(pair, b_volume_id, a_volume_id)
	else:
		# TODO: move placement conflict stuff here?
		pass


func _on_volumes_separated(pair: int, a_volume_id: int, b_volume_id) -> void:
	if a_volume_id in _support_volumes:
		_on_support_volume_exited(pair, a_volume_id, b_volume_id)
	elif b_volume_id in _support_volumes:
		_on_support_volume_exited(pair, b_volume_id, a_volume_id)
	else:
		# TODO: move placement conflict stuff here?
		pass
