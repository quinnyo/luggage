extends Node3D

const ItemBox := preload("res://experiment/item_box.tscn")
const ItemCapsule := preload("res://experiment/item_capsule.tscn")


@onready var spawn_grid: SpawnGrid = $spawn_grid


func spawn() -> Array:
	var items: Array = []
	for i in range(spawn_grid.points_count()):
		var c := spawn_grid.coord(i)
		var p := spawn_grid.point(i)
		var item := ItemBox.instantiate()
		item.name = "Item_%d_%d-%d-%d" % [ i, c.x, c.y, c.z ]
		add_sibling(item)
		item.global_position = p
		items.push_back(item)
	return items
