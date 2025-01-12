extends Node


@onready var item_tray: ItemPicker = get_parent() as ItemPicker


var _active_group := 0

var _groups: Array[int]


func _on_item_tray_selected(item_id: int) -> void:
	return


func _init() -> void:
	_groups.resize(10)
	_groups.fill(-1)
	_groups[0] = ItemPicker.GROUP_DEFAULT


func _ready() -> void:
	item_tray.add_item("Asdf", preload("res://icon.svg"))
	item_tray.add_item("Qwer", preload("res://icon.svg"))
	item_tray.add_item("Zxcv", preload("res://icon.svg"))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey && event.is_pressed():
		var kev := event as InputEventKey

		var num := -1
		if kev.keycode >= KEY_KP_0 && kev.keycode <= KEY_KP_9:
			num = kev.keycode - KEY_KP_0
		elif kev.keycode >= KEY_0 && kev.keycode <= KEY_9:
			num = kev.keycode - KEY_0

		if num >= 0 && num <= 9:
			if _groups[num] == -1:
				_groups[num] = item_tray.group_create("Ggggggroup #%d" % [ num ])
			_active_group = num
		elif kev.keycode == KEY_HOME:
			item_tray.clear()
		elif OS.is_keycode_unicode(kev.keycode):
			if kev.ctrl_pressed:
				var text := kev.as_text_key_label()
				var id := item_tray.add_item(text, preload("res://icon.svg"), _groups[_active_group])
				item_tray.item_set_disabled(id, kev.alt_pressed)
