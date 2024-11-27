class_name ItemFactorySimple extends ItemFactory


## ItemBody to instantiate
@export var body_scn: PackedScene

@export_category("Body Transform")
## Translation part of item body transform, in spawn point space
@export var body_translation: Vector3
## Rotation part of item body transform, in spawn point space
@export var body_rotation: Vector3
@export_enum("XYZ", "XZY", "YXZ", "YZX", "ZXY", "ZYX") var body_rotation_order: int = EULER_ORDER_YXZ


func _can_build(_serial_id: int) -> bool:
	return body_scn.can_instantiate()


func _build_body(_serial_id: int, spawn_xf: Transform3D) -> ItemBody:
	var body: ItemBody = body_scn.instantiate()
	body.global_transform = spawn_xf * Transform3D(Basis.from_euler(body_rotation, body_rotation_order), body_translation)
	return body
