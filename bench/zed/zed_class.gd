class_name ZedClass
extends RefCounted
## A base class for design part class definitions.
## New part classes are created by inheriting ZedClass and implementing the `_zed` methods.
## The main reason this exists is to provide a standard interface for instantiating parts
## while keeping the part data types & implementation hidden from the host context.


const TYPE_INFO_UID := &"uid"
const TYPE_INFO_PATH := &"path"
const TYPE_INFO_GLOBAL_NAME := &"global_name"
const TYPE_INFO_TYPE_NAME := &"type_name"


var _type_name: StringName
var _type_info: Dictionary[StringName, Variant]


func get_type_info() -> Dictionary[StringName, Variant]:
	return _type_info.duplicate()


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


func part_registered(inst: Node, part_id: int, host: ZedHost) -> void:
	_zed_part_registered(inst, part_id, host)


func create_shell(inst: Node, shell_type: Zed.ShellType) -> Array[Node]:
	return _zed_create_shell(inst, shell_type)


func get_buildable_name() -> String:
	return _zed_get_buildable_name()


func get_buildable_icon() -> Texture2D:
	return _zed_get_buildable_icon()


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


@warning_ignore("unused_parameter")
func _zed_part_registered(inst: Node, part_id: int, host: ZedHost) -> void:
	return


@warning_ignore("unused_parameter")
func _zed_create_shell(inst: Node, shell_type: Zed.ShellType) -> Array[Node]:
	push_error("Not implemented!")
	return []


func _zed_get_buildable_name() -> String:
	return get_type_name()


func _zed_get_buildable_icon() -> Texture2D:
	return preload("../icons/zed_buildable.svg")


func _init() -> void:
	_type_name = _zed_get_type_name()
	var s: Script = get_script()
	_type_info = {
		TYPE_INFO_UID: ResourceLoader.get_resource_uid(s.resource_path),
		TYPE_INFO_PATH: s.resource_path,
		TYPE_INFO_GLOBAL_NAME: s.get_global_name(),
		TYPE_INFO_TYPE_NAME: _zed_get_type_name(),
	}


func _to_string() -> String:
	return "<ZedClass:%s>" % [ get_type_name() ]
