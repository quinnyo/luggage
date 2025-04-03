extends Node
## A Bench module for submitting ZedPart/datum picking candidates to ViewportPlus/Picking.


const PICKING_PROVIDER_IDENT := &"ZedPart/Datum"


var bench: Bench


func _enter_tree() -> void:
	bench = Bench.find_bench_parent(self)
	var picking := ViewportPlus.get_viewport_plus(self).get_picking()
	picking.query_started.connect(_on_picking_query_started)


func _exit_tree() -> void:
	bench = null
	var picking := ViewportPlus.get_viewport_plus(self).get_picking()
	picking.query_started.disconnect(_on_picking_query_started)


func _on_picking_query_started(query: Picking.Query) -> void:
	if not bench:
		return

	var radius := 0.5

	if query.ray.is_valid():
		var zhost := bench.get_zed_host()
		for part_id: int in zhost.get_all_part_ids():
			for datum_idx: int in range(zhost.part_get_datum_count(part_id)):
				var xf := zhost.part_get_transform(part_id, datum_idx)
				var dz := query.ray.get_depth_closest_to_point(xf.origin)
				var dxy := (query.ray.origin + query.ray.normal * dz).distance_to(xf.origin) - radius
				if dxy <= 0.0:
					var central := absf(dxy) / radius
					dz -= dz_centre_boost(central, radius * 5.0)
				var zel := Zelection.new()
				zel.add(Zed.TYPE_ARMATURE_POINT, part_id, datum_idx)
				var candidate := Picking.Candidate.create(PICKING_PROVIDER_IDENT, zel, dxy, dz - radius)
				query.submit_candidate(candidate)


static func dz_centre_boost(central: float, zmagnitude: float):
	var cc := central * central
	var ccc := cc * central
	var v := cc / (ccc + 1) * 2.0
	return v * zmagnitude
