extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const FIXTURE_INDEX_PATH := "res://tests/fixtures/scenario_index_fixture.json"

func _init() -> void:
	var failures: Array[String] = []

	if not ResourceLoader.exists(MAIN_SCENE_PATH):
		failures.append("Missing main scene at %s" % MAIN_SCENE_PATH)
	elif not FileAccess.file_exists(FIXTURE_INDEX_PATH):
		failures.append("Missing scenario index fixture at %s" % FIXTURE_INDEX_PATH)
	else:
		var packed_main := load(MAIN_SCENE_PATH) as PackedScene
		var main := packed_main.instantiate() as Node
		main.set("scenario_index_path", FIXTURE_INDEX_PATH)
		get_root().add_child(main)
		main.call("_ready")

		if not main.has_method("available_scenarios"):
			failures.append("Main must expose available_scenarios()")
		if not main.has_method("load_scenario_by_id"):
			failures.append("Main must expose load_scenario_by_id()")
		if not main.has_method("active_scenario_id"):
			failures.append("Main must expose active_scenario_id()")
		if not main.has_method("active_scenario_name"):
			failures.append("Main must expose active_scenario_name()")

		if failures.is_empty():
			var entries := main.call("available_scenarios") as Array
			if entries.size() != 2:
				failures.append("Main must expose two fixture scenarios")
			if str(main.call("active_scenario_id")) != "fixture-map-1":
				failures.append("Main must load the catalog default scenario first")
			if str(main.call("active_scenario_name")) != "Fixture Map One":
				failures.append("Main must expose the active scenario display name")
			var game_state := main.get_node_or_null("GameStateAdapter")
			if game_state == null:
				failures.append("Scenario selection requires GameStateAdapter")
			elif int(game_state.call("get_base_lives")) != 2:
				failures.append("Default fixture map should start with two lives")

			if not bool(main.call("load_scenario_by_id", "fixture-map-2")):
				failures.append("Main must load fixture-map-2 by id")
			if str(main.call("active_scenario_id")) != "fixture-map-2":
				failures.append("Main active id must update after scenario switch")
			if str(main.call("active_scenario_name")) != "Fixture Map Two":
				failures.append("Main active name must update after scenario switch")
			if game_state != null and int(game_state.call("get_base_lives")) != 3:
				failures.append("Scenario switch must rebuild runtime with second map lives")
			if bool(main.call("load_scenario_by_id", "missing-map")):
				failures.append("Main must reject unknown scenario ids")

		main.free()

	if failures.is_empty():
		print("smoke_scenario_selection: ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
