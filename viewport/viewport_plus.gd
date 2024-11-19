class_name ViewportPlus extends Viewport

signal camera_3d_changed()

var _camera_3d: Camera3D

var _selection: Selection = Selection.new()
var _picking: Picking = Picking.new()


func get_selection() -> Selection:
	return _selection


func get_picking() -> Picking:
	return _picking


static func get_viewport_plus(node: Node) -> ViewportPlus:
	assert(node && node.is_inside_tree())
	var vp := node.get_viewport()
	if vp is ViewportPlus:
		return vp
	if vp.get_script():
		push_error("viewport %s has script (%s)" % [ vp, vp.get_script() ])
		return null
	vp.set_script(ViewportPlus)
	return vp


func _ready() -> void:
	add_child(_picking)


func _process(_delta: float) -> void:
	var cam := get_camera_3d()
	if cam != _camera_3d:
		_camera_3d = cam
		camera_3d_changed.emit()
