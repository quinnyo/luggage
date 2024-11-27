extends Node3D


const BodyMonitor := preload("res://experiment/physics/body_monitor.gd")
const ItemSpawn := preload("res://experiment/item_spawn.gd")

const MAX_FRAMES: int = 1000

@export var experiment_name := "item-drop"


var items: Array[Item]
var monitors: Array[BodyMonitor] = []
var rolling: bool = false
var frame: int = 0


func all_sleeping() -> bool:
	for item in items:
		if !item.get_body().sleeping:
			return false
	return true


func stop() -> void:
	if !rolling:
		return
	rolling = false
	print("STOP @ %d" % [ frame ])

	var samp := monitors[0].samplon
	print("samplon t[%d .. %d]" % [ samp.get_start_time(), samp.get_end_time() ])
	for field in range(samp.get_field_count()):
		var field_name := samp.get_field_id(field)
		var nsamples := samp.get_sample_count(field)
		var t_range := ""
		if nsamples == 1:
			t_range = " @ t=%d" % [ samp.get_sample_time(field, 0) ]
		elif nsamples > 1:
			var field_t_start := samp.get_sample_time(field, 0)
			var field_t_end := samp.get_sample_time(field, -1)
			t_range = " @ t[%d .. %d]" % [ field_t_start, field_t_end ]
		print("  %22s: %d" % [ field_name, nsamples ], t_range )

	for mon in monitors:
		print(mon.id)
		var impacts := mon.samplon.get_all_samples(BodyMonitor.Field.IMPACT)
		print("impacts: ", ", ".join(_fmt_each("%5.2f", impacts)))


func _fmt_each(fmt: String, arr) -> PackedStringArray:
	var out := PackedStringArray()
	for val in arr:
		out.push_back(fmt % [ val ])
	return out


func _ready() -> void:
	rolling = true

	#var datetimestamp := Time.get_datetime_string_from_system().replace(":", "").replace("-", "")
	#var data_dir := "user://experiment/%s_%s" % [ experiment_name, datetimestamp ]
	#DirAccess.make_dir_recursive_absolute(data_dir)

	var spawners: Array[ItemSpawn] = []
	for child in get_children():
		if child is ItemSpawn:
			spawners.push_back(child)

	for spawner in spawners:
		for item in spawner.spawn():
			items.push_back(item)
			var monitor := BodyMonitor.new()
			monitor.target_node = item.get_body()
			monitor.id = item.name
			monitors.push_back(monitor)
			add_child(monitor)


func _physics_process(_delta: float) -> void:
	if !rolling:
		return

	if frame == 1:
		for monitor in monitors:
			monitor.start()
	elif all_sleeping():
		stop()

	frame += 1
	if frame > MAX_FRAMES:
		stop()
