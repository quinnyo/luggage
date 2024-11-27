class_name ItemManager extends Node


const VPP_ITEM_MANAGER := "ItemManager"


var _items: Array[Item] = []


func get_items() -> Array[Item]:
	return _items.duplicate()


func add_item_to_scene(item: Item) -> void:
	add_child(item)
	item.add_child(item.get_body())
	_items.push_back(item)


static func get_item_manager(node: Node) -> ItemManager:
	var vpp := ViewportPlus.get_viewport_plus(node)
	if vpp.has_node(VPP_ITEM_MANAGER):
		return vpp.get_node(VPP_ITEM_MANAGER)
	else:
		var im := ItemManager.new()
		im.name = VPP_ITEM_MANAGER
		vpp.add_child.call_deferred(im)
		return im
