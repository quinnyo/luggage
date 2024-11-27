class_name ItemManager extends Node


const VPP_ITEM_MANAGER := "ItemManager"


func add_item_to_scene(item: Item) -> void:
	add_child(item)
	item.add_child(item.get_body())


static func get_item_manager(node: Node) -> ItemManager:
	var vpp := ViewportPlus.get_viewport_plus(node)
	if vpp.has_node(VPP_ITEM_MANAGER):
		return vpp.get_node(VPP_ITEM_MANAGER)
	else:
		var im := ItemManager.new()
		im.name = VPP_ITEM_MANAGER
		vpp.add_child.call_deferred(im)
		return im
