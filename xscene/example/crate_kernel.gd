class_name EgCrateKernel extends XNode

const DATA_FORMAT_1 := 1

const FIELD_META_FORMAT := &"format"
const FIELD_POSITION := &"position"
const FIELD_SIZE := &"size"
const FIELD_DENSITY := &"density"


@export var position: Vector3
@export var size: Vector3 = Vector3.ONE
@export var density: float = 1.0


func _v_is_kernel_element() -> bool:
	return true


func _v_get_kernel_data() -> Dictionary[StringName, Variant]:
	return {
		FIELD_META_FORMAT: DATA_FORMAT_1,

		FIELD_POSITION: position,
		FIELD_SIZE: size,
		FIELD_DENSITY: density,
	}


func _v_set_kernel_data(data: Dictionary[StringName, Variant]) -> void:
	if !data.has(FIELD_META_FORMAT):
		push_error("data format missing")
		return
	if data[FIELD_META_FORMAT] == DATA_FORMAT_1:
		var script: Script = get_script() as Script
		for field in [FIELD_POSITION, FIELD_SIZE, FIELD_DENSITY]:
			set(field, data.get(field, script.get_property_default_value(field)))
	else:
		push_error("unexpected data format (%s)" % [data[FIELD_META_FORMAT]])
		return
