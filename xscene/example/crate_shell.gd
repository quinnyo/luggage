class_name EgCrateShell extends XNode


const PICK_TARGET_SCALE := 1.1

var _game: EgGame
var _shell_root: Node3D


func _v_message(what: Message) -> void:
	if what == Message.ENTER_CONTEXT:
		_game = EgGame.find_game_context_parent(context)
		if _game:
			_game.phase_transition_started.connect(_on_game_phase_transition_started)
			_clear()
			_build(_game.phase)


func _clear() -> void:
	if _shell_root:
		_shell_root.queue_free()
		_shell_root = null


func _build(phase: EgGame.Phase) -> void:
	assert(_shell_root == null)
	if phase == EgGame.Phase.EDIT:
		_shell_root = _create_edit_root(kernel)
	elif phase == EgGame.Phase.SIM:
		_shell_root = _create_sim_root(kernel)
	else:
		return
	var visual := _create_visual(kernel)
	_shell_root.add_child(visual)
	add_child(_shell_root)


func _create_visual(xnode: EgCrateKernel) -> Node3D:
	var mesh := BoxMesh.new()
	mesh.size = xnode.size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	return mi


func _create_edit_root(xnode: EgCrateKernel) -> Node3D:
	# build a pick target for editor
	var shape := BoxShape3D.new()
	shape.size = xnode.size * PICK_TARGET_SCALE
	var collider := CollisionShape3D.new()
	collider.shape = shape
	var area := Area3D.new()
	area.add_child(collider)
	area.position = xnode.position
	return area


func _create_sim_root(xnode: EgCrateKernel) -> Node3D:
	# build a rigid body for sim
	var shape := BoxShape3D.new()
	shape.size = xnode.size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	var volume := shape.size.x * shape.size.y * shape.size.z
	var body := RigidBody3D.new()
	body.mass = volume * xnode.density
	body.add_child(collider)
	body.position = xnode.position
	return body


func _on_game_phase_transition_started(trans: EgGame.PhaseTransition) -> void:
	_clear()
	_build(trans.to)
