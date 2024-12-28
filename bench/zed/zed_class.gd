class_name ZedClass
extends RefCounted


var _type_id: int
var _type_name: StringName


## Get this ZedClass's unique identifier.
func get_type_id() -> int:
	return _type_id


## Get this ZedClass's unique identifier.
func get_type_name() -> StringName:
	return _type_name


func instantiate() -> Node:
	return _zed_instantiate()


func serialise(inst: Node) -> Variant:
	#Dictionary[StringName, Variant]
	return _zed_serialise(inst)


func deserialise(inst: Node, data) -> Error:
	return _zed_deserialise(inst, data)


## The base impl returns the resource UID of the script. If needed, a custom
## [b]unique[/b] identifier can be provided by overriding this method.
func _zed_get_type_id() -> int:
	var s: Script = get_script()
	return ResourceLoader.get_resource_uid(s.resource_path)


## The base impl returns the resource UID of the attached script.
## If needed, a custom [b]unique[/b] identifier can be provided by overriding this method.
func _zed_get_type_name() -> StringName:
	var script: Script = get_script()
	return ResourceUID.id_to_text(ResourceLoader.get_resource_uid(script.resource_path))


func _zed_instantiate() -> Node:
	push_error("Not implemented!")
	return null


@warning_ignore("unused_parameter")
func _zed_serialise(inst: Node) -> Variant:
	push_error("Not implemented!")
	return null


@warning_ignore("unused_parameter")
func _zed_deserialise(inst: Node, data) -> Error:
	push_error("Not implemented!")
	return FAILED


func _init() -> void:
	_type_id = _zed_get_type_id()
	_type_name = _zed_get_type_name()

	#var rexp_type_name := RegEx.new()
	#rexp_type_name.compile("^[a-zA-Z][_a-zA-Z0-9]*(\\.[a-zA-Z][_a-zA-Z0-9]*)*$")
	#var type_name := _zed_get_type_name()
	#if rexp_type_name.search(type_name) != null:
		#_type_name = type_name
	#else:
		#push_error("invalid type name: '%s'" % [ type_name ])


func _to_string() -> String:
	return "<ZedClass:%s>" % [ get_type_name() ]
