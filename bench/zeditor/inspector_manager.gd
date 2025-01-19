class_name ZedInspectorManager
extends RefCounted


const ZedInspectorDefault := preload("gui/zed_inspector.tscn")


class BoxedInspector:
	var inspector: ZedInspector
	var host: Node
	var fn_show: Callable
	var fn_hide: Callable

	func show() -> void:
		if fn_show.is_valid():
			fn_show.call()

	func hide() -> void:
		if fn_hide.is_valid():
			fn_hide.call()


var zeditor: Zeditor
var bench: Bench
var inspectors: Dictionary[int, BoxedInspector]


func setup(p_bench: Bench, p_zeditor: Zeditor) -> void:
	bench = p_bench
	zeditor = p_zeditor


func has_part_inspector(part_id: int) -> bool:
	return inspectors.has(part_id)


func open_part_inspector(part_id: int) -> ZedInspector:
	var boxed := _get_or_create_part_inspector(part_id)
	boxed.inspector.setup(part_id)
	boxed.show()
	return boxed.inspector


func close_part_inspector(part_id: int) -> void:
	assert(has_part_inspector(part_id))
	var boxed := _get_part_inspector(part_id)
	boxed.hide()


func _get_part_inspector(part_id: int) -> BoxedInspector:
	if inspectors.has(part_id):
		return inspectors[part_id]
	return null


func _get_or_create_part_inspector(part_id: int) -> BoxedInspector:
	if inspectors.has(part_id):
		return inspectors[part_id]
	else:
		var inst: ZedInspector = ZedInspectorDefault.instantiate()
		inst.bench = bench
		inst.zeditor = zeditor
		var boxed := BoxedInspector.new()
		boxed.inspector = inst
		var window := Window.new()
		window.position = Vector2i(80, 60)
		window.unresizable = true
		window.wrap_controls = true
		window.close_requested.connect(_on_window_close_requested.bind(part_id))
		window.add_child(inst)
		bench.add_child(window)
		boxed.host = window
		boxed.fn_show = window.popup
		boxed.fn_hide = window.hide
		inspectors[part_id] = boxed
		return boxed


func _on_window_close_requested(part_id: int) -> void:
	close_part_inspector(part_id)
