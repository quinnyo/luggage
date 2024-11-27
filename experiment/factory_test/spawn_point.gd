extends Node3D


@export var factory: ItemFactory
## Item body initial linear velocity
@export var linear_velocity: Vector3
## Item body initial angular velocity in radians per second
@export var angular_velocity: Vector3


var _serial_id: int = 0


func _ready() -> void:
	if factory && factory.can_build(_serial_id):
		var item := factory.build(_serial_id, global_transform)
		item.get_body().linear_velocity = linear_velocity
		item.get_body().angular_velocity = angular_velocity
		var man := ItemManager.get_item_manager(self)
		man.add_item_to_scene(item)
