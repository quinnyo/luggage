extends Node


const PHASE_NAME_DEFAULT := &"Default"
const PHASE_NAME_EDIT := &"Edit"
const PHASE_NAME_RUN := &"Run"


@export var types: Array[Script] = []

@onready var bench: Bench = $Bench
@onready var zeditor: Zeditor = $Bench/Zeditor

var _data
var _op: ZedOperation


func _pack() -> void:
	print("================================================================================")
	print("packing ZedScene...")
	var scene := ZedScene.new()
	scene.class_table = bench.get_zed_class_table()
	scene.capture(bench.get_zed_host())
	_data = scene.serialise()
	print_rich(_data)
	print("================================================================================")


func _unpack() -> void:
	print("================================================================================")
	print("unpacking ZedScene...")
	print_rich(_data)
	var scene := ZedScene.new()
	scene.class_table = bench.get_zed_class_table()
	scene.deserialise(_data)
	print("----------------------------------------")
	print("restoring scene...")
	var op := ZedOperationSceneRestore.new()
	op.dest = scene
	op.bind(bench)
	if op.is_ok():
		zeditor.execute_operation(op)
	print("================================================================================")


func _clear() -> void:
	var op := ZedOperationSceneClear.new()
	op.bind(bench)
	if op.is_ok():
		zeditor.execute_operation(op)


func _make_overlap() -> void:
	var host := bench.get_zed_host()
	if host.get_part_count() >= 2:
		var parts := bench.get_zed_host().get_all_part_ids()
		var box0 := host.get_part_instance(parts[0])
		var box1 := host.get_part_instance(parts[1])
		box1.position = box0.position
		host.notify_part_changed(parts[1])


func _break_overlap() -> void:
	var host := bench.get_zed_host()
	if host.get_part_count() >= 2:
		var parts := bench.get_zed_host().get_all_part_ids()
		var box0 := host.get_part_instance(parts[0])
		var box1 := host.get_part_instance(parts[1])
		box1.position = box0.position - box0.size - box1.size
		host.notify_part_changed(parts[1])


func _make_support() -> void:
	var boxes := _find_boxes()
	if boxes.is_empty():
		return
	var pos: Vector3 = %HelloSupport3D.global_position
	boxes[0][1].position = pos
	bench.get_zed_host().notify_part_changed(boxes[0][0])


func _find_boxes() -> Array:
	var result := []
	var host := bench.get_zed_host()
	host.for_each_part(func(part_id, zpart, zclass):
		if zclass.get_type_name() == &"zed.example.Box":
			result.push_back([part_id, zpart, zclass])
	)
	return result


func _delete_one() -> void:
	var parts := bench.get_zed_host().get_all_part_ids()
	if parts.is_empty():
		return
	var id := parts[randi() % parts.size()]
	var op := ZedOperationErase.new()
	op.targets = PackedInt64Array([id])
	op.bind(bench)
	if op.is_ok():
		zeditor.execute_operation(op)


func _test_activate_tool() -> void:
	var tool := preload("res://bench/zeditor/tools/move.gd").new()
	zeditor.activate_tool(tool)


func _start_interactive_op() -> void:
	var op_drag := preload("res://bench/operations/drag.gd").new()
	var host := bench.get_zed_host()
	var parts := host.get_all_part_ids()
	if parts.is_empty():
		return
	for part_id in parts:
		var initial_position := host.part_armature_get_transform(part_id, 0).origin
		op_drag.add_target(initial_position, func(value: Vector3):
			var xf := host.part_armature_get_transform(part_id, 0)
			xf.origin = value
			host.part_armature_set_transform(part_id, 0, xf)
		)
	op_drag.bind(bench)
	_op = op_drag


func _end_interactive_op(cancel: bool) -> void:
	if cancel:
		_op.interactive_cancel()
	else:
		_op.commit(zeditor.unre)


func _operation_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mbev := event as InputEventMouseButton
		if mbev.pressed && mbev.button_index == MOUSE_BUTTON_LEFT:
			_end_interactive_op(false)
		elif mbev.pressed && mbev.button_index == MOUSE_BUTTON_RIGHT:
			_end_interactive_op(true)
	elif event.is_action_pressed(&"ui_cancel"):
		_end_interactive_op(true)


func _edit_phase_input(event: InputEvent) -> void:
	if _op && _op.can_interactive_update():
		_operation_input(event)
	else:
		if event.is_action_pressed(&"ui_copy"):
			_pack()
		elif event.is_action_pressed(&"ui_paste"):
			_unpack()
		elif event.is_action_pressed(&"ui_home"):
			_clear()
		elif event.is_action_pressed(&"ui_accept"):
			bench.change_phase_named(PHASE_NAME_RUN)
		elif event.is_action_pressed(&"ui_cancel"):
			bench.change_phase_named(PHASE_NAME_DEFAULT)
		elif event.is_action_pressed(&"ui_page_down"):
			_make_overlap()
		elif event.is_action_pressed(&"ui_page_up"):
			_break_overlap()
		elif event.is_action_pressed(&"ui_text_toggle_insert_mode"):
			_make_support()
		elif event.is_action_pressed(&"ui_text_delete"):
			_delete_one()
		elif event.is_action_pressed(&"ui_down"):
			print("clearing unre history... (%d)" % [ zeditor.unre.get_history_count() ])
			zeditor.unre.clear_history()
		elif event is InputEventKey:
			var kev := event as InputEventKey
			if kev.pressed && kev.ctrl_pressed:
				if kev.keycode == KEY_1:
					_test_activate_tool()
				elif kev.keycode == KEY_2:
					_start_interactive_op()


func _on_part_placement_conflict_added(_part_id: int, conflict_id: int, data: Dictionary[StringName, Variant]) -> void:
	var volume: Area3D = data[&"volume"]
	var marker: Node3D = preload("res://doodads/utility/problem_marker_3d.tscn").instantiate()
	marker.name = str("marker_", conflict_id)
	volume.add_child(marker)
	data[&"marker"] = marker


func _on_part_placement_conflict_removed(_part_id: int, _conflict_id: int, data: Dictionary[StringName, Variant]) -> void:
	data[&"marker"].queue_free()


func _ready() -> void:
	bench.get_workspace().part_placement_conflict_added.connect(_on_part_placement_conflict_added)
	bench.get_workspace().part_placement_conflict_removed.connect(_on_part_placement_conflict_removed)
	var table := bench.get_zed_class_table()
	for o in types:
		if o && Qb.script_has_base_script(o, ZedClass):
			var zed: ZedClass = o.new()
			table.add_type(zed)
		elif o:
			push_error("not good: ", o)


func _process(_delta: float) -> void:
	if _op && _op.can_interactive_update():
		_op.interactive_update()


func _unhandled_input(event: InputEvent) -> void:
	if bench.get_active_phase_name() == PHASE_NAME_DEFAULT:
		if event.is_action_pressed(&"ui_accept"):
			bench.change_phase_named(PHASE_NAME_EDIT)
	elif bench.get_active_phase_name() == PHASE_NAME_EDIT:
		_edit_phase_input(event)
	elif bench.get_active_phase_name() == PHASE_NAME_RUN:
		if event.is_action_pressed(&"ui_cancel"):
			bench.change_phase_named(PHASE_NAME_EDIT)
