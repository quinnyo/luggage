extends Node3D

const Pointer3D := preload("res://doodads/utility/pointer_3d.tscn")

@onready var pointer_3d: Node3D = Pointer3D.instantiate()
@onready var selection_pointer_3d: Node3D = Pointer3D.instantiate()

var vpp: ViewportPlus


func _on_selection_changed() -> void:
	var selected := vpp.get_selection().get_selected_nodes()
	var new_target: Node3D = null
	for node in selected:
		if node is Node3D:
			new_target = node as Node3D
			break
	%ItemCamera.target_node = new_target


func _ready() -> void:
	add_child(pointer_3d)
	add_child(selection_pointer_3d)


func _enter_tree() -> void:
	vpp = ViewportPlus.get_viewport_plus(self)
	var selection := vpp.get_selection()
	selection.selection_changed.connect(_on_selection_changed)


func _exit_tree() -> void:
	vpp = null


func _process(_delta: float) -> void:
	var selection := vpp.get_selection()
	selection_pointer_3d.hide()
	for node in selection.get_selected_nodes():
		if node is Node3D:
			selection_pointer_3d.show()
			selection_pointer_3d.global_transform = node.global_transform
			break
	var picking := vpp.get_picking()
	if picking.has_object_3d():
		pointer_3d.global_position = picking.get_intersection_point_3d()
		pointer_3d.show()
	else:
		pointer_3d.hide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_LEFT:
				var selection := vpp.get_selection()
				selection.clear()
				selection.add_node(vpp.get_picking().get_object())
	elif event is InputEventKey:
		if event.pressed && event.key_label == KEY_V:
			%ItemCamera.current = !%ItemCamera.current
