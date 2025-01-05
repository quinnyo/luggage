extends Label


func _enter_tree() -> void:
	var vpp := ViewportPlus.get_viewport_plus(self)
	var picking := vpp.get_picking()
	picking.query_completed.connect(_on_picking_query_completed.bind(picking))


func _on_picking_query_completed(picking: Picking) -> void:
	var result := picking.get_result()
	var lines := PackedStringArray()
	lines.push_back("results (%d) @%d:" % [ result.size(), Engine.get_physics_frames() ])
	for cand in result:
		lines.push_back("  " + str(cand))
	text = "\n".join(lines)
