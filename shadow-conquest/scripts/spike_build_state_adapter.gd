extends Node
class_name SpikeBuildStateAdapter

var _gold := 0
var _build_spots: Array = []
var _tower_options: Array = []
var _tower_options_by_id: Dictionary = {}
var _occupied_cells: Dictionary = {}
var _occupied_spot_ids: Dictionary = {}

func configure(build_spots: Array, tower_catalog: Dictionary, starting_gold: int, occupied_cells: Array = []) -> void:
	_gold = maxi(starting_gold, 0)
	_build_spots = []
	_tower_options = []
	_tower_options_by_id = {}
	_occupied_cells = {}
	_occupied_spot_ids = {}

	for spot_variant: Variant in build_spots:
		if typeof(spot_variant) != TYPE_DICTIONARY:
			continue
		var spot := (spot_variant as Dictionary).duplicate(true)
		if str(spot.get("id", "")) == "":
			continue
		_build_spots.append(spot)

	for tower_key_variant: Variant in tower_catalog.keys():
		var tower_variant: Variant = tower_catalog[tower_key_variant]
		if typeof(tower_variant) != TYPE_DICTIONARY:
			continue

		var tower := (tower_variant as Dictionary).duplicate(true)
		var tower_id := str(tower.get("id", str(tower_key_variant)))
		if tower_id == "":
			continue

		tower["id"] = tower_id
		tower["cost"] = maxi(int(tower.get("cost", 0)), 0)
		_tower_options.append(tower)
		_tower_options_by_id[tower_id] = tower

	for cell_variant: Variant in occupied_cells:
		if typeof(cell_variant) != TYPE_DICTIONARY:
			continue
		var key := _cell_key(cell_variant as Dictionary)
		if key != "":
			_occupied_cells[key] = true

func get_gold() -> int:
	return _gold

func get_build_spots() -> Array:
	return _build_spots.duplicate(true)

func get_available_build_spots() -> Array:
	var available: Array = []
	for spot_variant: Variant in _build_spots:
		var spot := spot_variant as Dictionary
		if not _is_spot_occupied(spot):
			available.append(spot.duplicate(true))
	return available

func get_tower_options() -> Array:
	return _tower_options.duplicate(true)

func can_build_at(spot_id: String, tower_type_id: String) -> bool:
	var spot := _find_spot(spot_id)
	if spot.is_empty():
		return false
	if not _tower_options_by_id.has(tower_type_id):
		return false
	if _is_spot_occupied(spot):
		return false
	if not _is_tower_allowed_at_spot(spot, tower_type_id):
		return false

	var tower := _tower_options_by_id[tower_type_id] as Dictionary
	return _gold >= int(tower.get("cost", 0))

func build_at(spot_id: String, tower_type_id: String) -> Dictionary:
	var spot := _find_spot(spot_id)
	if spot.is_empty():
		return _build_result(false, "unknown_spot", {}, {}, _gold)
	if not _tower_options_by_id.has(tower_type_id):
		return _build_result(false, "unknown_tower", spot, {}, _gold)
	if _is_spot_occupied(spot):
		return _build_result(false, "occupied", spot, _tower_options_by_id[tower_type_id] as Dictionary, _gold)
	if not _is_tower_allowed_at_spot(spot, tower_type_id):
		return _build_result(false, "type_not_allowed", spot, _tower_options_by_id[tower_type_id] as Dictionary, _gold)

	var tower := _tower_options_by_id[tower_type_id] as Dictionary
	var cost := int(tower.get("cost", 0))
	if _gold < cost:
		return _build_result(false, "insufficient_gold", spot, tower, _gold)

	_gold -= cost
	_occupied_spot_ids[spot_id] = true
	var key := _cell_key(spot)
	if key != "":
		_occupied_cells[key] = true

	return _build_result(true, "", spot, tower, _gold)

func _find_spot(spot_id: String) -> Dictionary:
	for spot_variant: Variant in _build_spots:
		var spot := spot_variant as Dictionary
		if str(spot.get("id", "")) == spot_id:
			return spot
	return {}

func _is_spot_occupied(spot: Dictionary) -> bool:
	var spot_id := str(spot.get("id", ""))
	if spot_id != "" and _occupied_spot_ids.has(spot_id):
		return true

	var key := _cell_key(spot)
	return key != "" and _occupied_cells.has(key)

func _is_tower_allowed_at_spot(spot: Dictionary, tower_type_id: String) -> bool:
	if not spot.has("allowedTypeIds"):
		return true
	if typeof(spot.get("allowedTypeIds")) != TYPE_ARRAY:
		return true

	var allowed_type_ids := spot.get("allowedTypeIds") as Array
	if allowed_type_ids.is_empty():
		return true

	for allowed_variant: Variant in allowed_type_ids:
		if str(allowed_variant) == tower_type_id:
			return true
	return false

func _cell_key(cell: Dictionary) -> String:
	if not cell.has("x") or not cell.has("z"):
		return ""
	return "%d:%d" % [int(cell.get("x", 0)), int(cell.get("z", 0))]

func _build_result(ok: bool, reason: String, spot: Dictionary, tower: Dictionary, gold: int) -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
		"spot": spot.duplicate(true),
		"tower": tower.duplicate(true),
		"gold": gold,
	}
