class_name Samplon extends RefCounted


const EQUAL_APPROX_METHOD := [
	TYPE_AABB,
	TYPE_BASIS,
	TYPE_COLOR,
	TYPE_PLANE,
	TYPE_QUATERNION,
	TYPE_RECT2,
	TYPE_TRANSFORM2D,
	TYPE_TRANSFORM3D,
	TYPE_VECTOR2,
	TYPE_VECTOR3,
	TYPE_VECTOR4,
]
const I64_MAX: int = 0x7FFF_FFFF_FFFF_FFFF
const I64_MIN: int = 1 << 63


var _fields: Dictionary
var _field_compare_func: Dictionary

var _samples: Array[Array]
var _times: Array[PackedInt64Array]
var _t_start: int = I64_MAX
var _t_end: int = I64_MIN


func set_field_compare_func(field: int, cmp: Callable) -> void:
	_field_compare_func[field] = cmp


func get_field_count() -> int:
	return _fields.size()


func get_field_id(field: int) -> String:
	return str(_fields.keys()[field])


func get_start_time() -> int:
	return _t_start


func get_end_time() -> int:
	return _t_end


## Attempt to add a sample at the end of [param field].
## If the field has one or more sample stored, the new sample will only be added if
## [param t] is greater than the most recent stored sample time, [bold]and[/bold] either:
## [param value] is not equal to the most recent stored sample value [bold]or[/bold]
## [param force] is [code]true[/code].
func append_sample(field: int, t: int, value: Variant, force: bool = false) -> bool:
	if get_sample_count(field) > 0:
		if _times[field][-1] >= t:
			push_error("can only append sample at 't' greater than last")
			return false
		if !force:
			var last_value = get_sample(field, -1)
			if _field_compare(last_value, value, field):
				return false
	_t_start = mini(t, _t_start)
	_t_end = maxi(t, _t_end)
	_times[field].push_back(t)
	_samples[field].push_back(value)
	return true


func get_sample_count(field: int) -> int:
	return _samples[field].size()


func get_sample_time(field: int, idx: int) -> int:
	return _times[field][idx]


func get_sample(field: int, idx: int) -> Variant:
	if idx >= 0 && get_sample_count(field) <= idx:
		return null
	elif idx < 0 && get_sample_count(field) + idx < 0:
		return null
	return _samples[field][idx]


func get_sample_at(field: int, t: int) -> Variant:
	var idx := _times[field].bsearch(t, false) - 1
	if _times[field][idx] > t:
		return null
	return get_sample(field, idx)


func _field_compare(a: Variant, b: Variant, field: int) -> bool:
	if _field_compare_func.has(field):
		return _field_compare_func[field].call(a, b)
	return _value_compare(a, b)


func _value_compare(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b):
		return false
	var type := typeof(a)
	if type in EQUAL_APPROX_METHOD:
		return a.is_equal_approx(b)
	elif type == TYPE_FLOAT:
		return is_equal_approx(a, b)
	elif type == TYPE_DICTIONARY:
		if a.size() != b.size():
			return false
		elif !a.has_all(b.keys()) || !b.has_all(a.keys()):
			return false
		for k in a:
			if !_value_compare(a[k], b[k]):
				return false
		return true
	elif type >= TYPE_ARRAY && type <= TYPE_PACKED_VECTOR4_ARRAY:
		if a.size() != b.size():
			return false
		for i in range(a.size()):
			if !_value_compare(a[i], b[i]):
				return false
		return true
	else:
		return a == b


func _init(fields: Dictionary) -> void:
	_fields = fields
	var field_count := fields.size()
	_samples.resize(field_count)
	_times.resize(field_count)
