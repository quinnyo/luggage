class_name ZedInspector
extends Control


const METHOD_INSPECTOR_ENTERED := &"_zed_inspector_entered"


enum LayoutArea {
	TOOLBAR_LEFT,
	TOOLBAR_RIGHT,

	PAGE_BUILD,
	PAGE_SETTINGS,
	PAGE_INFO,
}


class Section:
	var id: int
	var parent: Control
	var keep_parent: bool = false


var target: int
var zeditor: Zeditor
var bench: Bench

var _sections: Dictionary[int, Section]
@onready var _page_container := %PageContainer


func setup(p_target: int) -> void:
	target = p_target
	_call_inspector_entered(self)


## Add a control to the inspector in the [param loc] area.
## [param loc] can be a custom page ID or a builtin location from [enum LayoutArea].
func add_control(section_id: int, control: Control) -> void:
	var section := _get_section(section_id)
	if not section:
		push_error("invalid section id (%d)" % [ section_id ])
		return
	section.parent.add_child(control)
	_call_inspector_entered(control)


func show_section(section_id: int) -> void:
	var section := _get_section(section_id)
	if not section:
		push_error("invalid section id (%d)" % [ section_id ])
		return
	section.parent.show()


func clear_sections() -> void:
	for section in _sections.values():
		if section.keep_parent:
			for control in section.parent.get_children():
				control.queue_free()
				section.parent.remove_child(control)
		else:
			section.parent.queue_free()
			section.parent.get_parent().remove_child(section.parent)
	_sections.clear()


func _get_section(section_id: int) -> Section:
	if _sections.has(section_id):
		return _sections[section_id]
	else:
		match section_id:
			LayoutArea.TOOLBAR_LEFT:
				var section := _create_section(section_id, %ToolbarLeft)
				section.keep_parent = true
				return section
			LayoutArea.TOOLBAR_RIGHT:
				var section := _create_section(section_id, %ToolbarRight)
				section.keep_parent = true
				return section
			LayoutArea.PAGE_BUILD:
				return _create_section(section_id, _create_page_control("Build"))
			LayoutArea.PAGE_SETTINGS:
				return _create_section(section_id, _create_page_control("Settings"))
			LayoutArea.PAGE_INFO:
				return _create_section(section_id, _create_page_control("Info"))
		return null


func _create_page_control(title: String) -> Control:
	var control := BoxContainer.new()
	control.vertical = true
	control.name = title
	_page_container.add_child(control)
	return control


func _create_section(id: int, control: Control) -> Section:
	var section := Section.new()
	section.id = id
	section.parent = control
	_sections[id] = section
	show_section(id)
	_sort_pages()
	return section


func _sort_pages() -> void:
	var index := 0
	for id in [ LayoutArea.PAGE_BUILD, LayoutArea.PAGE_SETTINGS, LayoutArea.PAGE_INFO ]:
		if _sections.has(id):
			_page_container.move_child(_sections[id].parent, index)
			index += 1


func _call_inspector_entered(node: Node) -> void:
	node.propagate_call(METHOD_INSPECTOR_ENTERED, [ self ])
