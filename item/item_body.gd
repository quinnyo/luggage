class_name ItemBody extends RigidBody3D


func _init() -> void:
	contact_monitor = true
	max_contacts_reported = 30
