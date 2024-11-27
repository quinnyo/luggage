class_name Item extends Node
## An Item instance.


var _body: ItemBody
var _factory: ItemFactory
var _serial_id: int


## The item's physics body node in the scene tree
func get_body() -> ItemBody:
	return _body


## The factory that created this item
func get_factory() -> ItemFactory:
	return _factory


## Serial number assigned by the factory
func get_serial_id() -> int:
	return _serial_id


func _init(p_body: ItemBody, p_factory: ItemFactory, p_serial_id: int) -> void:
	_body = p_body
	_factory = p_factory
	_serial_id = p_serial_id
