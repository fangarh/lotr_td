extends SceneTree

const DATA_PATH := "res://data/spike_scenario.json"
const ENEMY_SCENE_PATH := "res://scenes/entities/placeholder_enemy.tscn"
const GONDOR_MODEL_PATH := "res://assets/models/enemies/gondor_warrior_proxy.glb"

func _init() -> void:
	var failures: Array[String] = []

	if not FileAccess.file_exists(GONDOR_MODEL_PATH):
		failures.append("Missing Gondor warrior GLB at %s" % GONDOR_MODEL_PATH)
	if not ResourceLoader.exists(GONDOR_MODEL_PATH):
		failures.append("Gondor warrior GLB is not imported as a Godot resource: %s" % GONDOR_MODEL_PATH)
	if FileAccess.file_exists(GONDOR_MODEL_PATH):
		var file_size := FileAccess.get_file_as_bytes(GONDOR_MODEL_PATH).size()
		if file_size < 10_000_000:
			failures.append("Gondor warrior GLB must be refreshed from the user-provided ZIP export, got only %d bytes" % file_size)

	if FileAccess.file_exists(GONDOR_MODEL_PATH) and ResourceLoader.exists(GONDOR_MODEL_PATH):
		var packed_model := load(GONDOR_MODEL_PATH) as PackedScene
		if packed_model == null:
			failures.append("Gondor warrior GLB must load as PackedScene")
		else:
			var model := packed_model.instantiate() as Node3D
			if model == null:
				failures.append("Gondor warrior GLB root must instantiate as Node3D")
			elif _count_mesh_instances(model) < 1:
				failures.append("Gondor warrior GLB must contain at least one MeshInstance3D node")
			model.free()

	_validate_scenario_catalog(failures)
	_validate_placeholder_enemy_attachment(failures)

	if failures.is_empty():
		print("smoke_gondor_enemy_asset: ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _validate_scenario_catalog(failures: Array[String]) -> void:
	if not FileAccess.file_exists(DATA_PATH):
		failures.append("Missing spike scenario data at %s" % DATA_PATH)
		return

	var data_file := FileAccess.open(DATA_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(data_file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		failures.append("Spike scenario data must be a JSON object")
		return

	var data := parsed as Dictionary
	var catalog := ((data.get("enemies", {}) as Dictionary).get("catalog", []) as Array)
	var has_catalog_entry := false
	for entry_variant: Variant in catalog:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry := entry_variant as Dictionary
		if str(entry.get("id", "")) == "gondor-warrior":
			has_catalog_entry = true
			if str(entry.get("modelPath", "")) != GONDOR_MODEL_PATH:
				failures.append("Gondor warrior catalog entry must reference %s" % GONDOR_MODEL_PATH)
			if int(entry.get("reward", 0)) <= 0:
				failures.append("Gondor warrior catalog entry must keep a positive reward for combat adapter tests")
			break
	if not has_catalog_entry:
		failures.append("Spike scenario enemy catalog must include gondor-warrior")

	var waves := data.get("waves", []) as Array
	var has_wave_spawn := false
	for wave_variant: Variant in waves:
		if typeof(wave_variant) != TYPE_DICTIONARY:
			continue
		var wave := wave_variant as Dictionary
		for spawn_variant: Variant in (wave.get("spawns", []) as Array):
			if typeof(spawn_variant) == TYPE_DICTIONARY and str((spawn_variant as Dictionary).get("enemyId", "")) == "gondor-warrior":
				has_wave_spawn = true
	if not has_wave_spawn:
		failures.append("Spike scenario waves must spawn gondor-warrior for the asset pipeline preview")

func _validate_placeholder_enemy_attachment(failures: Array[String]) -> void:
	var packed_enemy := load(ENEMY_SCENE_PATH) as PackedScene
	if packed_enemy == null:
		failures.append("Enemy scene must load as PackedScene")
		return

	var enemy := packed_enemy.instantiate() as Node3D
	if not enemy.has_method("configure_visual"):
		failures.append("PlaceholderEnemy must expose configure_visual(data) for catalog-driven model assets")
	else:
		enemy.call("configure_visual", {
			"modelPath": GONDOR_MODEL_PATH,
			"modelYawDegrees": -35.0,
			"modelLift": 0.0,
			"targetHeight": 1.05,
			"targetFootprint": 0.84,
			"baseMarkerName": "GondorWarriorBaseMarker",
			"baseMarkerColor": { "r": 0.22, "g": 0.26, "b": 0.32, "a": 0.88 },
		})

	var path_points: Array[Vector3] = [
		Vector3(0.0, 0.18, 0.0),
		Vector3(1.0, 0.18, 0.0),
	]
	enemy.call("setup", path_points, 1.2)
	enemy.call("_ready")

	var enemy_model := enemy.get_node_or_null("EnemyModel")
	if enemy_model == null:
		failures.append("PlaceholderEnemy must attach configured Gondor EnemyModel")
	elif enemy_model.scale.x <= 0.0:
		failures.append("Gondor EnemyModel must have a positive fitted scale")
	if enemy.get_node_or_null("GondorWarriorBaseMarker") == null:
		failures.append("PlaceholderEnemy must add a Gondor warrior base readability marker")
	if enemy.get_node_or_null("GondorBody") != null:
		failures.append("Configured Gondor model enemies must not also build the primitive fallback")
	enemy.free()

func _count_mesh_instances(root: Node) -> int:
	var count := 0
	var stack: Array[Node] = [root]

	while not stack.is_empty():
		var node := stack.pop_back() as Node
		for child in node.get_children():
			stack.append(child)
		if node is MeshInstance3D:
			count += 1

	return count
