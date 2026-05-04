extends SceneTree

const BUILD_STATE_ADAPTER_PATH := "res://scripts/spike_build_state_adapter.gd"

func _init() -> void:
	var failures: Array[String] = []

	if not ResourceLoader.exists(BUILD_STATE_ADAPTER_PATH):
		failures.append("Missing build state adapter script at %s" % BUILD_STATE_ADAPTER_PATH)

	if failures.is_empty():
		_validate_build_state_adapter(failures)

	if failures.is_empty():
		print("smoke_build_state_adapter: ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _validate_build_state_adapter(failures: Array[String]) -> void:
	var build_state_script := load(BUILD_STATE_ADAPTER_PATH)
	var build_state := build_state_script.new() as Node
	get_root().add_child(build_state)

	for method_name in [
		"configure",
		"get_gold",
		"get_build_spots",
		"get_available_build_spots",
		"get_tower_options",
		"can_build_at",
		"build_at",
	]:
		if not build_state.has_method(method_name):
			failures.append("Build state adapter must expose %s()" % method_name)

	if failures.is_empty():
		_validate_gold_and_cost_clamps(build_state, failures)
		_validate_availability_and_allowed_types(build_state, failures)
		_validate_successful_build_mutates_state(build_state, failures)
		_validate_refusals_do_not_mutate_state(build_state, failures)
		_validate_defensive_outputs(build_state, failures)

	build_state.free()

func _validate_gold_and_cost_clamps(build_state: Node, failures: Array[String]) -> void:
	build_state.call("configure", [
		{"id": "spot-a", "x": 1, "z": 2},
	], {
		"shadow-tower": {"id": "shadow-tower", "name": "Shadow Tower", "cost": -25},
	}, -50)

	if int(build_state.call("get_gold")) != 0:
		failures.append("Starting gold must clamp to zero or above")

	var options := build_state.call("get_tower_options") as Array
	if options.size() != 1:
		failures.append("Tower options must include configured catalog entries")
	elif int((options[0] as Dictionary).get("cost", -1)) != 0:
		failures.append("Tower cost must clamp to zero or above")

	if not bool(build_state.call("can_build_at", "spot-a", "shadow-tower")):
		failures.append("Zero-cost tower must be buildable with clamped zero gold")

func _validate_availability_and_allowed_types(build_state: Node, failures: Array[String]) -> void:
	build_state.call("configure", [
		{"id": "spot-open", "x": 0, "z": 0, "allowedTypeIds": ["eye"]},
		{"id": "spot-any", "x": 1, "z": 0, "allowedTypeIds": []},
		{"id": "spot-missing-allowed", "x": 2, "z": 0},
		{"id": "spot-occupied", "x": 3, "z": 0},
	], {
		"eye": {"id": "eye", "name": "Eye", "cost": 30},
		"forge": {"id": "forge", "name": "Forge", "cost": 25},
	}, 100, [
		{"x": 3, "z": 0},
	])

	var available := build_state.call("get_available_build_spots") as Array
	if available.size() != 3:
		failures.append("Occupied cells must be unavailable")
	if bool(build_state.call("can_build_at", "spot-occupied", "eye")):
		failures.append("Occupied build spot must refuse building")

	if not bool(build_state.call("can_build_at", "spot-open", "eye")):
		failures.append("Allowed tower id must be buildable at a restricted spot")
	if bool(build_state.call("can_build_at", "spot-open", "forge")):
		failures.append("Disallowed tower id must not be buildable at a restricted spot")
	if not bool(build_state.call("can_build_at", "spot-any", "forge")):
		failures.append("Empty allowedTypeIds must allow any tower option")
	if not bool(build_state.call("can_build_at", "spot-missing-allowed", "forge")):
		failures.append("Missing allowedTypeIds must allow any tower option")

func _validate_successful_build_mutates_state(build_state: Node, failures: Array[String]) -> void:
	build_state.call("configure", [
		{"id": "spot-a", "x": 0, "z": 0},
		{"id": "spot-b", "x": 1, "z": 0},
	], {
		"eye": {"id": "eye", "name": "Eye", "cost": 40},
	}, 90)

	var result := build_state.call("build_at", "spot-a", "eye") as Dictionary
	if not bool(result.get("ok", false)):
		failures.append("Affordable valid build must succeed")
	if str(result.get("reason", "")) != "":
		failures.append("Successful build must return an empty reason")
	if int(result.get("gold", -1)) != 50:
		failures.append("Successful build must report remaining gold")
	if int(build_state.call("get_gold")) != 50:
		failures.append("Successful build must spend tower cost")
	if bool(build_state.call("can_build_at", "spot-a", "eye")):
		failures.append("Successful build must mark the spot occupied")
	if not bool(build_state.call("can_build_at", "spot-b", "eye")):
		failures.append("Successful build must not occupy unrelated spots")

	var result_spot := result.get("spot", {}) as Dictionary
	var result_tower := result.get("tower", {}) as Dictionary
	if str(result_spot.get("id", "")) != "spot-a":
		failures.append("Successful build result must include the built spot")
	if str(result_tower.get("id", "")) != "eye":
		failures.append("Successful build result must include the built tower")

func _validate_refusals_do_not_mutate_state(build_state: Node, failures: Array[String]) -> void:
	build_state.call("configure", [
		{"id": "spot-a", "x": 0, "z": 0, "allowedTypeIds": ["eye"]},
		{"id": "spot-occupied", "x": 1, "z": 0},
	], {
		"eye": {"id": "eye", "name": "Eye", "cost": 80},
		"forge": {"id": "forge", "name": "Forge", "cost": 20},
	}, 50, [
		{"x": 1, "z": 0},
	])

	var initial_gold := int(build_state.call("get_gold"))
	var initial_available := (build_state.call("get_available_build_spots") as Array).size()

	var insufficient := build_state.call("build_at", "spot-a", "eye") as Dictionary
	if bool(insufficient.get("ok", true)):
		failures.append("Unaffordable build must fail")
	if str(insufficient.get("reason", "")) != "insufficient_gold":
		failures.append("Unaffordable build must return reason=insufficient_gold")
	_expect_unchanged(build_state, initial_gold, initial_available, "insufficient gold refusal", failures)

	var unknown_spot := build_state.call("build_at", "missing-spot", "forge") as Dictionary
	if bool(unknown_spot.get("ok", true)):
		failures.append("Unknown spot build must fail")
	if str(unknown_spot.get("reason", "")) != "unknown_spot":
		failures.append("Unknown spot build must return reason=unknown_spot")
	_expect_unchanged(build_state, initial_gold, initial_available, "unknown spot refusal", failures)

	var unknown_tower := build_state.call("build_at", "spot-a", "missing-tower") as Dictionary
	if bool(unknown_tower.get("ok", true)):
		failures.append("Unknown tower build must fail")
	if str(unknown_tower.get("reason", "")) != "unknown_tower":
		failures.append("Unknown tower build must return reason=unknown_tower")
	_expect_unchanged(build_state, initial_gold, initial_available, "unknown tower refusal", failures)

	var occupied := build_state.call("build_at", "spot-occupied", "forge") as Dictionary
	if bool(occupied.get("ok", true)):
		failures.append("Occupied spot build must fail")
	if str(occupied.get("reason", "")) != "occupied":
		failures.append("Occupied spot build must return reason=occupied")
	_expect_unchanged(build_state, initial_gold, initial_available, "occupied spot refusal", failures)

	var disallowed := build_state.call("build_at", "spot-a", "forge") as Dictionary
	if bool(disallowed.get("ok", true)):
		failures.append("Disallowed tower build must fail")
	if str(disallowed.get("reason", "")) != "type_not_allowed":
		failures.append("Disallowed tower build must return reason=type_not_allowed")
	_expect_unchanged(build_state, initial_gold, initial_available, "disallowed tower refusal", failures)

func _validate_defensive_outputs(build_state: Node, failures: Array[String]) -> void:
	build_state.call("configure", [
		{"id": "spot-a", "x": 0, "z": 0, "tags": ["edge"]},
	], {
		"eye": {"id": "eye", "name": "Eye", "cost": 10, "effects": [{"type": "burn"}]},
	}, 20)

	var spots := build_state.call("get_build_spots") as Array
	var options := build_state.call("get_tower_options") as Array
	var available := build_state.call("get_available_build_spots") as Array
	((spots[0] as Dictionary).get("tags") as Array).append("mutated")
	(options[0] as Dictionary)["cost"] = 999
	(available[0] as Dictionary)["id"] = "mutated-spot"

	var fresh_spots := build_state.call("get_build_spots") as Array
	var fresh_options := build_state.call("get_tower_options") as Array
	var fresh_available := build_state.call("get_available_build_spots") as Array

	if ((fresh_spots[0] as Dictionary).get("tags") as Array).has("mutated"):
		failures.append("get_build_spots must return defensive deep-ish copies")
	if int((fresh_options[0] as Dictionary).get("cost", -1)) != 10:
		failures.append("get_tower_options must return defensive deep-ish copies")
	if str((fresh_available[0] as Dictionary).get("id", "")) != "spot-a":
		failures.append("get_available_build_spots must return defensive deep-ish copies")

func _expect_unchanged(build_state: Node, expected_gold: int, expected_available: int, context: String, failures: Array[String]) -> void:
	if int(build_state.call("get_gold")) != expected_gold:
		failures.append("%s must not mutate gold" % context)
	if (build_state.call("get_available_build_spots") as Array).size() != expected_available:
		failures.append("%s must not mutate spot availability" % context)
