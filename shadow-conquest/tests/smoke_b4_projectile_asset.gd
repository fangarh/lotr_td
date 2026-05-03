extends SceneTree

const DATA_PATH := "res://data/spike_scenario.json"
const TOWER_SCENE_PATH := "res://scenes/entities/placeholder_tower.tscn"
const PROJECTILE_MODEL_PATH := "res://assets/models/projectiles/shadow_tower_b4_shot.glb"

func _init() -> void:
	var failures: Array[String] = []

	if not FileAccess.file_exists(PROJECTILE_MODEL_PATH):
		failures.append("Missing B4 projectile GLB at %s" % PROJECTILE_MODEL_PATH)
	if not ResourceLoader.exists(PROJECTILE_MODEL_PATH):
		failures.append("B4 projectile GLB is not imported as a Godot resource: %s" % PROJECTILE_MODEL_PATH)
	if FileAccess.file_exists(PROJECTILE_MODEL_PATH):
		var file_size := FileAccess.get_file_as_bytes(PROJECTILE_MODEL_PATH).size()
		if file_size < 10_000_000:
			failures.append("B4 projectile GLB must come from the user-provided shoot.zip PBR export, got only %d bytes" % file_size)

	if FileAccess.file_exists(PROJECTILE_MODEL_PATH) and ResourceLoader.exists(PROJECTILE_MODEL_PATH):
		var packed_model := load(PROJECTILE_MODEL_PATH) as PackedScene
		if packed_model == null:
			failures.append("B4 projectile GLB must load as PackedScene")
		else:
			var model := packed_model.instantiate() as Node3D
			if model == null:
				failures.append("B4 projectile GLB root must instantiate as Node3D")
			elif _count_mesh_instances(model) < 1:
				failures.append("B4 projectile GLB must contain MeshInstance3D content")
			model.free()

	_validate_scenario_catalog(failures)
	_validate_placeholder_tower_attachment(failures)

	if failures.is_empty():
		print("smoke_b4_projectile_asset: ok")
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
	var catalog := ((data.get("towers", {}) as Dictionary).get("catalog", []) as Array)
	var has_catalog_entry := false
	for entry_variant: Variant in catalog:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry := entry_variant as Dictionary
		if str(entry.get("id", "")) == "shadow-tower-b4":
			has_catalog_entry = true
			if str(entry.get("projectileModelPath", "")) != PROJECTILE_MODEL_PATH:
				failures.append("B4 catalog entry must reference projectileModelPath %s" % PROJECTILE_MODEL_PATH)
			if not bool(entry.get("showProjectilePreview", false)):
				failures.append("B4 catalog entry must enable showProjectilePreview for asset review")
			break
	if not has_catalog_entry:
		failures.append("Spike scenario tower catalog must include shadow-tower-b4")

func _validate_placeholder_tower_attachment(failures: Array[String]) -> void:
	var packed_tower := load(TOWER_SCENE_PATH) as PackedScene
	if packed_tower == null:
		failures.append("Tower scene must load as PackedScene")
		return

	var tower := packed_tower.instantiate() as Node3D
	if not tower.has_method("configure_visual"):
		failures.append("PlaceholderTower must expose configure_visual(data)")
	else:
		tower.call("configure_visual", {
			"modelPath": "res://assets/models/towers/shadow_tower_b4.glb",
			"projectileModelPath": PROJECTILE_MODEL_PATH,
			"showProjectilePreview": true,
			"projectilePreviewOffset": { "x": 0.42, "y": 0.82, "z": -0.42 },
			"projectilePreviewScale": 0.22,
		})
	tower.call("setup", Vector3.ZERO)
	tower.call("_ready")

	if tower.get_node_or_null("ProjectilePreview") == null:
		failures.append("PlaceholderTower must add a ProjectilePreview node when showProjectilePreview is enabled")
	if tower.get_node_or_null("ProjectilePreview/ProjectileModel") == null:
		failures.append("PlaceholderTower must attach the configured B4 projectile model under ProjectilePreview")
	tower.free()

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
