class_name ZedArmature
extends RefCounted
## An armature is an interface to a part's pose -- its spatial configuration.


enum ChannelMode {
	NONE,
	INTERNAL,
	EDITABLE,
}


func has_channel(channel: int) -> bool:
	return _get_channel_mode(channel) != ChannelMode.NONE


## if the number of pose points can be changed (added/removed)
func is_size_fixed() -> bool:
	return _is_size_fixed()


func size() -> int:
	return _size()


func resize(count: int) -> void:
	_resize(count)


func insert(index: int, values: Dictionary[int, Variant] = {}) -> void:
	_insert(index, values)


func remove(index: int) -> void:
	_remove(index)


func get_transform(index: int) -> Transform3D:
	return _get_transform(index)


func set_transform(index: int, value: Transform3D) -> void:
	_set_transform(index, value)


func constrain_value(channel: int, index: int, value: Variant) -> Variant:
	return _constrain_value(channel, index, value)


func set_value(channel: int, index: int, value: Variant) -> void:
	_set_value(channel, index, constrain_value(channel, index, value))


func get_value(channel: int, index: int) -> Variant:
	return _get_value(channel, index)


@warning_ignore("unused_parameter")
func _get_channel_mode(channel: int) -> ChannelMode:
	push_error("not implemented")
	return ChannelMode.NONE


func _is_size_fixed() -> bool:
	push_error("not implemented")
	return false


func _size() -> int:
	push_error("not implemented")
	return -1


@warning_ignore("unused_parameter")
func _resize(count: int) -> void:
	push_error("not implemented")


@warning_ignore("unused_parameter")
func _insert(index: int, values: Dictionary[int, Variant]) -> void:
	push_error("not implemented")


@warning_ignore("unused_parameter")
func _remove(index: int) -> void:
	push_error("not implemented")


@warning_ignore("unused_parameter")
func _get_transform(index: int) -> Transform3D:
	push_error("not implemented")
	return Transform3D()


@warning_ignore("unused_parameter")
func _set_transform(index: int, value: Transform3D) -> void:
	push_error("not implemented")
	return


@warning_ignore("unused_parameter")
func _constrain_value(channel: int, index: int, value: Variant) -> Variant:
	push_error("not implemented")
	return value


@warning_ignore("unused_parameter")
func _set_value(channel: int, index: int, value: Variant) -> void:
	push_error("not implemented")
	return


@warning_ignore("unused_parameter")
func _get_value(channel: int, index: int) -> Variant:
	push_error("not implemented")
	return null
