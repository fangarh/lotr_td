extends SceneTree

const CATALOG_SCRIPT_PATH := "res://scripts/spike_scenario_catalog.gd"
const FIXTURE_INDEX_PATH := "res://tests/fixtures/scenario_index_fixture.json"

func _init() -> void:
	var failures: Array[String] = []

	if not ResourceLoader.exists(CATALOG_SCRIPT_PATH):
		failures.append("Missing scenario catalog script at %s" % CATALOG_SCRIPT_PATH)
	elif not FileAccess.file_exists(FIXTURE_INDEX_PATH):
		failures.append("Missing scenario index fixture at %s" % FIXTURE_INDEX_PATH)
	else:
		var catalog_script := load(CATALOG_SCRIPT_PATH) as Script
		var catalog = catalog_script.new()
		if not bool(catalog.call("load_from_path", FIXTURE_INDEX_PATH)):
			failures.append("Scenario catalog should load the fixture index")
		if str(catalog.call("default_scenario_id")) != "fixture-map-1":
			failures.append("Scenario catalog must expose fixture default scenario id")
		if not bool(catalog.call("has_scenario", "fixture-map-2")):
			failures.append("Scenario catalog must find fixture-map-2 by id")
		if str(catalog.call("path_for_id", "fixture-map-1")) != "res://tests/fixtures/two_wave_scenario.json":
			failures.append("Scenario catalog must return the configured map path")
		var entries := catalog.call("entries") as Array
		if entries.size() != 2:
			failures.append("Scenario catalog must expose two entries, got %d" % entries.size())
		else:
			var first := entries[0] as Dictionary
			if str(first.get("name", "")) != "Fixture Map One":
				failures.append("Scenario catalog entries must keep display names")
			first["name"] = "Mutated"
			var fresh_entries := catalog.call("entries") as Array
			var fresh_first := fresh_entries[0] as Dictionary
			if str(fresh_first.get("name", "")) != "Fixture Map One":
				failures.append("Scenario catalog entries() must return defensive copies")
		if str(catalog.call("path_for_id", "missing-map")) != "":
			failures.append("Scenario catalog must return an empty path for unknown ids")

	if failures.is_empty():
		print("smoke_scenario_catalog: ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
