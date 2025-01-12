extends Button


var id: int
var group_id: int
var userdata: Variant


func setup(p_id: int, p_group_id: int) -> void:
	id = p_id
	group_id = p_group_id


func _init() -> void:
	toggle_mode = true
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
