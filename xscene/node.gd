class_name XNode extends Node


signal context_entered()
signal context_exiting()


enum Message {
	## Node has entered the scene tree as a descendant of a context.
	## [code]ENTER_CONTEXT[/code] is sent after the node has been registered.
	ENTER_CONTEXT,
	## Registered node is exiting the scene tree and the context.
	## [code]EXIT_CONTEXT[/code] is sent before the node has been deregistered.
	EXIT_CONTEXT,
}


## The node this node is a shell for.
var kernel: XNode:
	set(value):
		if _kernel_set:
			push_error("no allow change kernel")
			return
		if value:
			_kernel_set = true
			kernel = value
			kernel.context_exiting.connect(_on_kernel_context_exiting)
## Parent context node
var context: XSceneContext

var _kernel_set: bool = false


## Handle internal messages
@warning_ignore("unused_parameter")
func _v_message(what: Message) -> void:
	return


## Return true if this node is a kernel element of the design.
func _v_is_kernel_element() -> bool:
	return false


## Return serialisable kernel state, to be saved as part of the design.
## This method is only called if [method _is_kernel_element] returns [code]true[/code].
func _v_get_kernel_data() -> Dictionary[StringName, Variant]:
	return {}


## Set kernel state from data as previously provided by [method _get_kernel_data].
## This method is only called if [method _is_kernel_element] returns [code]true[/code].
@warning_ignore("unused_parameter")
func _v_set_kernel_data(data: Dictionary[StringName, Variant]) -> void:
	return


func _send_message(what: Message) -> void:
	_v_message(what)


func _find_context_parent() -> void:
	var node := get_parent()
	while node && node is not XSceneContext:
		node = node.get_parent()
	context = node


func _on_kernel_context_exiting() -> void:
	queue_free()


func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		_find_context_parent()
		if context:
			context.register_node(self)
			_send_message(Message.ENTER_CONTEXT)
			context_entered.emit()
	elif what == NOTIFICATION_EXIT_TREE:
		if context:
			_send_message(Message.EXIT_CONTEXT)
			context_exiting.emit()
			context.deregister_node(self)
			context = null
