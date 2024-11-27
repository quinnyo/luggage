class_name ItemFactory extends Resource


const _ERR_NOT_IMPLEMENTED := &"not implemented"


func can_build(serial_id: int) -> bool:
	return _can_build(serial_id)


func build(serial_id: int, spawn_xf: Transform3D) -> Item:
	var body := _build_body(serial_id, spawn_xf)
	if not body:
		return null
	return Item.new(body, self, serial_id)


func _can_build(serial_id: int) -> bool:
	push_error(_ERR_NOT_IMPLEMENTED)
	var _used := serial_id
	return false


func _build_body(serial_id: int, spawn_xf: Transform3D) -> ItemBody:
	push_error(_ERR_NOT_IMPLEMENTED)
	var _used := [ serial_id, spawn_xf ]
	return null
