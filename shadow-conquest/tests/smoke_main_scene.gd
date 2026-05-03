extends SceneTree

const SCENE_PATH := "res://scenes/main.tscn"
const DATA_PATH := "res://data/spike_scenario.json"
const SCENARIO_INDEX_PATH := "res://data/scenario_index.json"
const MVP_MAP_1_PATH := "res://data/scenarios/mvp_map_1.json"
const MVP_MAP_2_PATH := "res://data/scenarios/mvp_map_2.json"

func _init() -> void:
	var failures: Array[String] = []

	if not FileAccess.file_exists(DATA_PATH):
		failures.append("Missing spike scenario data at %s" % DATA_PATH)
	else:
		var data_file := FileAccess.open(DATA_PATH, FileAccess.READ)
		var parsed: Variant = JSON.parse_string(data_file.get_as_text())
		if typeof(parsed) != TYPE_DICTIONARY:
			failures.append("Spike scenario data is not a JSON object")
		else:
			var data := parsed as Dictionary
			_validate_catalog_shape(data, failures)
			if str(data.get("id", "")) == "":
				failures.append("Default spike scenario data must include a scenario id")
			if str(data.get("name", "")) == "":
				failures.append("Default spike scenario data must include a scenario name")

	_validate_mvp_scenario_index(failures)
	if not ResourceLoader.exists(SCENE_PATH):
		failures.append("Missing main scene at %s" % SCENE_PATH)
	else:
		var packed_scene := load(SCENE_PATH) as PackedScene
		var scene := packed_scene.instantiate()
		if not scene is Node3D:
			failures.append("Main scene root must be Node3D")
		if scene.get_script() == null:
			failures.append("Main scene root must have a valid script")
		if scene.get_node_or_null("Camera3D") == null:
			failures.append("Main scene must include Camera3D")
		if scene.get_node_or_null("World") == null:
			failures.append("Main scene must include World node")
		else:
			get_root().add_child(scene)
			scene.call("_ready")
			var tower_root := scene.get_node_or_null("World/Towers")
			var obstacle_root := scene.get_node_or_null("World/Obstacles")
			var terrain_prop_root := scene.get_node_or_null("World/TerrainProps")
			var enemy_root := scene.get_node_or_null("World/Enemies")
			var combat_adapter := scene.get_node_or_null("CombatAdapter")
			if tower_root == null or tower_root.get_child_count() < 1:
				failures.append("Main scene must spawn at least one tower from catalog placements")
			if obstacle_root == null or obstacle_root.get_child_count() < 1:
				failures.append("Main scene must spawn at least one obstacle from catalog placements")
			if terrain_prop_root == null or terrain_prop_root.get_child_count() < 1:
				failures.append("Main scene must spawn at least one terrain prop from catalog placements")
			if enemy_root == null or enemy_root.get_child_count() < 1:
				failures.append("Main scene must spawn at least one enemy from catalog waves")
			if combat_adapter == null:
				failures.append("Main scene must include a scene-level CombatAdapter")
			elif not combat_adapter.has_method("get_tracked_enemy_count"):
				failures.append("Main CombatAdapter must expose get_tracked_enemy_count()")
			elif enemy_root != null and int(combat_adapter.call("get_tracked_enemy_count")) < enemy_root.get_child_count():
				failures.append("Main CombatAdapter must register spawned enemies")
		scene.free()

	if failures.is_empty():
		print("smoke_main_scene: ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _validate_catalog_shape(data: Dictionary, failures: Array[String]) -> void:
	for key in ["board", "gameState", "path", "towers", "obstacles", "terrainProps", "enemies", "waves"]:
		if not data.has(key):
			failures.append("Spike scenario data must include %s" % key)

	if data.has("tower") or data.has("enemy"):
		failures.append("Spike scenario data must use plural catalog keys, not legacy tower/enemy keys")

	var path: Variant = data.get("path", {})
	if typeof(path) != TYPE_DICTIONARY or typeof(path.get("points", [])) != TYPE_ARRAY:
		failures.append("Spike scenario path must be an object with points array")

	var towers: Variant = data.get("towers", {})
	if typeof(towers) != TYPE_DICTIONARY:
		failures.append("Spike scenario towers must be a catalog object")
	else:
		if typeof(towers.get("catalog", [])) != TYPE_ARRAY:
			failures.append("Spike scenario towers.catalog must be an array")
		if typeof(towers.get("placements", [])) != TYPE_ARRAY:
			failures.append("Spike scenario towers.placements must be an array")

	var enemies: Variant = data.get("enemies", {})
	if typeof(enemies) != TYPE_DICTIONARY:
		failures.append("Spike scenario enemies must be a catalog object")
	elif typeof(enemies.get("catalog", [])) != TYPE_ARRAY:
		failures.append("Spike scenario enemies.catalog must be an array")

	var obstacles: Variant = data.get("obstacles", {})
	if typeof(obstacles) != TYPE_DICTIONARY:
		failures.append("Spike scenario obstacles must be a catalog object")
	else:
		if typeof(obstacles.get("catalog", [])) != TYPE_ARRAY:
			failures.append("Spike scenario obstacles.catalog must be an array")
		if typeof(obstacles.get("placements", [])) != TYPE_ARRAY:
			failures.append("Spike scenario obstacles.placements must be an array")

	var terrain_props: Variant = data.get("terrainProps", {})
	if typeof(terrain_props) != TYPE_DICTIONARY:
		failures.append("Spike scenario terrainProps must be a catalog object")
	else:
		if typeof(terrain_props.get("catalog", [])) != TYPE_ARRAY:
			failures.append("Spike scenario terrainProps.catalog must be an array")
		if typeof(terrain_props.get("placements", [])) != TYPE_ARRAY:
			failures.append("Spike scenario terrainProps.placements must be an array")

	if typeof(data.get("waves", [])) != TYPE_ARRAY:
		failures.append("Spike scenario waves must be an array")

	var game_state: Variant = data.get("gameState", {})
	if typeof(game_state) != TYPE_DICTIONARY:
		failures.append("Spike scenario gameState must be an object")
	else:
		var game_state_data := game_state as Dictionary
		if int(game_state_data.get("baseLives", 0)) < 1:
			failures.append("Spike scenario gameState.baseLives must be at least 1")

func _validate_mvp_scenario_index(failures: Array[String]) -> void:
	if not FileAccess.file_exists(SCENARIO_INDEX_PATH):
		failures.append("Missing MVP scenario index at %s" % SCENARIO_INDEX_PATH)
		return

	var index_file := FileAccess.open(SCENARIO_INDEX_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(index_file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		failures.append("MVP scenario index must be a JSON object")
		return

	var index := parsed as Dictionary
	if str(index.get("defaultScenarioId", "")) != "mvp-map-1":
		failures.append("MVP scenario index must default to mvp-map-1")
	var scenarios_variant: Variant = index.get("scenarios", [])
	if typeof(scenarios_variant) != TYPE_ARRAY:
		failures.append("MVP scenario index scenarios must be an array")
		return

	var ids: Dictionary = {}
	for scenario_variant: Variant in scenarios_variant:
		if typeof(scenario_variant) != TYPE_DICTIONARY:
			failures.append("MVP scenario index entries must be objects")
			continue
		var scenario := scenario_variant as Dictionary
		var id := str(scenario.get("id", ""))
		var path := str(scenario.get("path", ""))
		ids[id] = true
		if id == "":
			failures.append("MVP scenario index entry must include id")
		if str(scenario.get("name", "")) == "":
			failures.append("MVP scenario index entry %s must include name" % id)
		if path == "" or not FileAccess.file_exists(path):
			failures.append("MVP scenario index entry %s must point to an existing file" % id)

	if not ids.has("mvp-map-1"):
		failures.append("MVP scenario index must include mvp-map-1")
	if not ids.has("mvp-map-2"):
		failures.append("MVP scenario index must include mvp-map-2")
