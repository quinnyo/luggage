extends Node


@onready var x_scene_context: XSceneContext = $"../XSceneContext"
@onready var _game: EgGame = get_parent()

var _count: int = 0
var _kernels: Array[XNode]


func randf3() -> Vector3:
	return Vector3(randf(), randf(), randf())


func randsize() -> Vector3:
	return Vector3.ONE * 0.25 + randf3()


func randposition() -> Vector3:
	return randf3() * 5.0 - randf3() * 10.0


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_accept"):
		print("crate!")
		var kernel := EgCrateKernel.new()
		kernel.position = randposition()
		kernel.size = randsize()
		kernel.name = "Crate-%d" % [ _count ]
		x_scene_context.add_child(kernel)
		_kernels.push_back(kernel)
		var shell := EgCrateShell.new()
		shell.kernel = kernel
		shell.name = "CrateShell-%d" % [ _count ]
		x_scene_context.add_child(shell)
		_count += 1
	elif event.is_action_pressed(&"ui_down"):
		print("sim!")
		_game.change_phase(EgGame.Phase.SIM)
	elif event.is_action_pressed(&"ui_up"):
		print("edit!")
		_game.change_phase(EgGame.Phase.EDIT)
	elif event.is_action_pressed(&"ui_cancel"):
		print("none!")
		_game.change_phase(EgGame.Phase.NONE)
	elif event.is_action_pressed(&"ui_text_delete"):
		print("delete!")
		if _kernels.size():
			var idx := randi_range(0, _kernels.size() - 1)
			var xn := _kernels[idx]
			_kernels[idx] = _kernels[-1]
			_kernels.pop_back()
			print("\tlater, %s!" % [xn.name])
			xn.queue_free()
		else:
			print("\tnothing to delete...")
