extends Node

const IMPACT_EPSILON := 0.75

enum Field {
	CENTER_OF_MASS,
	INVERSE_INERTIA,
	INVERSE_INERTIA_TENSOR,
	PRINCIPAL_INERTIA_AXES,
	INVERSE_MASS,
	CONSTANT_FORCE,
	CONSTANT_TORQUE,
	TOTAL_ANGULAR_DAMP,
	TOTAL_GRAVITY,
	TOTAL_LINEAR_DAMP,
	ANGULAR_VELOCITY,
	LINEAR_VELOCITY,
	SLEEPING,
	TRANSFORM,

	CONTACTS,

	SHOCK,
}


@export var id: String = ""
@export var target_node: PhysicsBody3D


var rolling: bool = false
var target: RID
var frame: int = 0
var samplon: Samplon
var _label: Label3D
var _sum_shock: float


func start() -> void:
	_sum_shock = 0.0
	if not _label:
		_label = Label3D.new()
		_label.fixed_size = true
		_label.pixel_size = 0.001
		_label.font_size = 24
		_label.outline_size = 6
		_label.line_spacing = -16
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		_label.no_depth_test = true
		_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(_label)
	_label.text = ""
	if target_node:
		target = target_node.get_rid()
		if target_node is ItemBody:
			target_node.shock_received.connect(_on_target_shock_received)
	if !target.is_valid():
		return
	frame = 0
	rolling = true
	samplon = Samplon.new(Field)
	samplon.set_field_compare_func(Field.CONTACTS, _contacts_compare)


func stop() -> void:
	rolling = false


func sample(state: PhysicsDirectBodyState3D) -> void:
	for field in range(Field.CONTACTS):
		var value = state.get(Field.keys()[field].to_lower())
		samplon.append_sample(field, frame, value)

	var contacts := ContactInfo.all_from_state(state)
	samplon.append_sample(Field.CONTACTS, frame, contacts)


func _contacts_compare(a: Array[ContactInfo], b: Array[ContactInfo]) -> bool:
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if !a[i].is_equal_approx(b[i]):
			return false
	return true


func _on_target_shock_received(s: float) -> void:
	_sum_shock += s
	samplon.append_sample(Field.SHOCK, frame, s)
	if _label:
		_label.text = "%3.1f (+%3.1f)" % [ _sum_shock, s ]
		var state := PhysicsServer3D.body_get_direct_state(target)
		_label.global_position = state.transform.origin


func _physics_process(_delta: float) -> void:
	if rolling && target.is_valid():
		var state := PhysicsServer3D.body_get_direct_state(target)
		sample(state)
		frame += 1
