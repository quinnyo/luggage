extends Node

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
}


@export var use_target_node: bool = false
@export var target_node: PhysicsBody3D

var rolling: bool = false
var target: RID
var frame: int = 0
var samplon: Samplon


func set_target_node(node: PhysicsBody3D) -> void:
	target = node.get_rid()


func start() -> void:
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


func _ready() -> void:
	if use_target_node && target_node:
		set_target_node(target_node)
		start()


func _physics_process(_delta: float) -> void:
	if use_target_node && target_node && target_node.get_rid() != target:
		set_target_node(target_node)
		start()

	if rolling && target.is_valid():
		var state := PhysicsServer3D.body_get_direct_state(target)
		sample(state)
		frame += 1
