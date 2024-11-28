extends Node3D


@export var enable: bool = true
@export var tag: String = ""
@export var factory: ItemFactory


@onready var spawn_grid: SpawnGrid = $spawn_grid


func spawn() -> Array[Item]:
	if tag == "":
		tag = name
	var items: Array[Item] = []
	var item_man := ItemManager.get_item_manager(self)
	for i in range(spawn_grid.points_count()):
		var c := spawn_grid.coord(i)
		var p := spawn_grid.point(i)
		var item := factory.build(items.size(), Transform3D(Basis.IDENTITY, p))
		item.name = "%s_%d-%d-%d" % [ tag, c.x, c.y, c.z ]
		item_man.add_item_to_scene(item)
		items.push_back(item)
	return items
