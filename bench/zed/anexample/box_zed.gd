extends ZedClass

const TYPE_NAME := &"zed.example.Box"

const _Box := preload("box.gd")


func randf3() -> Vector3:
	return Vector3(randf(), randf(), randf())


func _zed_get_type_name() -> StringName:
	return TYPE_NAME


func _zed_instantiate() -> ZedPart:
	var inst := _Box.new()
	inst.size = Vector3.ONE * 0.25 + randf3()
	inst.position = randf3() * 5.0 - randf3() * 10.0
	return inst


func _zed_serialise(inst: ZedPart) -> Variant:
	var box := inst as _Box
	var dict: Dictionary[StringName, Variant] = {
		&"size": box.size,
		&"density": box.density,
		&"position": box.position,
	}
	return dict


func _zed_deserialise(inst: ZedPart, data) -> Error:
	var box := inst as _Box
	var dict: Dictionary[StringName, Variant] = data
	box.size = dict[&"size"]
	box.density = dict[&"density"]
	box.position = dict[&"position"]
	return OK


func _zed_part_registered(inst: ZedPart, part_id: int) -> void:
	var box := inst as _Box
	box._part_id = part_id


func _zed_create_shell(inst: ZedPart, shell_type: Zed.ShellType) -> Array[Node]:
	var box := inst as _Box
	if shell_type == Zed.ShellType.EDIT:
		return [ box._create_edit() ]
	elif shell_type == Zed.ShellType.SIM:
		return [ box._create_sim() ]
	return []


func _zed_get_buildable_name() -> String:
	return "Box (an example)"
