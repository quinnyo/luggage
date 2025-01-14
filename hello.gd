extends Node


const PHASE_NAME_DEFAULT := &"Default"
const PHASE_NAME_EDIT := &"Edit"
const PHASE_NAME_RUN := &"Run"


@export var types: Array[Script] = []

@onready var bench: Bench = $Bench

var _build_types: Array[StringName]
var _data
var _parts: PackedInt64Array


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
	var host := bench.get_zed_host()
	if host.get_part_count():
		_clear()
	var scene := ZedScene.new()
	scene.class_table = bench.get_zed_class_table()
	scene.deserialise(_data)
	print("----------------------------------------")
	print("restoring scene...")
	scene.restore(host)
	_parts = host.get_all_part_ids()
	print("================================================================================")


func _clear() -> void:
	print("clearing...")
	bench.get_zed_host().clear()
	_parts.clear()


func _make_overlap() -> void:
	var host := bench.get_zed_host()
	if host.get_part_count() >= 2:
		var box0 := host.get_part_instance(_parts[0])
		var box1 := host.get_part_instance(_parts[1])
		box1.position = box0.position
		host.notify_part_changed(box1)


func _break_overlap() -> void:
	var host := bench.get_zed_host()
	if host.get_part_count() >= 2:
		var box0 := host.get_part_instance(_parts[0])
		var box1 := host.get_part_instance(_parts[1])
		box1.position = box0.position - box0.size - box1.size
		host.notify_part_changed(box1)


func _delete_one() -> void:
	if _parts.size():
		var id := _parts[-1]
		_parts.remove_at(_parts.size() - 1)
		var host := bench.get_zed_host()
		host.remove_part(id)


func _build(idx: int) -> void:
	var table := bench.get_zed_class_table()
	var zed := table.get_type(_build_types[idx])
	var node := zed.instantiate()
	var id := bench.get_zed_host().add_part(node, zed)
	_parts.push_back(id)


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
			_build_types.push_back(zed.get_type_name())
		elif o:
			push_error("not good: ", o)


func _unhandled_input(event: InputEvent) -> void:
	if bench.get_active_phase_name() == PHASE_NAME_DEFAULT:
		if event.is_action_pressed(&"ui_accept"):
			bench.change_phase_named(PHASE_NAME_EDIT)
	elif bench.get_active_phase_name() == PHASE_NAME_EDIT:
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
		elif event.is_action_pressed(&"ui_text_delete"):
			_delete_one()
		elif event is InputEventKey:
			var kev := event as InputEventKey
			if kev.keycode >= KEY_0 && kev.keycode <= KEY_9 && kev.pressed:
				var idx := kev.keycode - KEY_0
				if idx < _build_types.size():
					_build(idx)
	elif bench.get_active_phase_name() == PHASE_NAME_RUN:
		if event.is_action_pressed(&"ui_cancel"):
			bench.change_phase_named(PHASE_NAME_EDIT)
