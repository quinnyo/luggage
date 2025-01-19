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


class Page:
	var control: Control
	var title: String


var target: int
var zeditor: Zeditor
var bench: Bench

var _pages: Dictionary[int, Page]
@onready var _page_container := %PageContainer


func setup(p_target: int) -> void:
	clear()
	target = p_target


func has_page(page_id: int) -> bool:
	return _pages.has(page_id)


func add_page(page_id: int, title: String, control: Control = null) -> int:
	assert(!has_page(page_id))
	var page := Page.new()
	page.title = title
	if control == null:
		control = BoxContainer.new()
		control.vertical = true
		control.name = title
	page.control = control
	_page_container.add_child(page.control)
	_pages[page_id] = page
	show_page(page_id)
	return page_id


func add_layout_area(loc: int) -> int:
	var title := "%d" % [ loc ]
	match loc:
		LayoutArea.PAGE_BUILD:
			title = "Build"
		LayoutArea.PAGE_SETTINGS:
			title = "Settings"
		LayoutArea.PAGE_INFO:
			title = "Info"
	return add_page(loc, title)


## Add a control to the inspector in the [param loc] area.
## [param loc] can be a custom page ID or a builtin location from [enum LayoutArea].
func add_control(loc: int, control: Control) -> void:
	if !has_page(loc):
		add_layout_area(loc)
	_pages[loc].control.add_child(control)
	_call_inspector_entered(control)


func show_page(page_id: int) -> void:
	_pages[page_id].control.show()


func clear() -> void:
	for page in _pages.values():
		page.control.queue_free()
		_page_container.remove_child(page.control)
	_pages.clear()


func _call_inspector_entered(node: Node) -> void:
	node.propagate_call(METHOD_INSPECTOR_ENTERED, [ self ])
