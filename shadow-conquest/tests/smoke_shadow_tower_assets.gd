extends SceneTree

const DATA_PATH := "res://data/spike_scenario.json"
const TOWER_SCENE_PATH := "res://scenes/entities/placeholder_tower.tscn"
const B2_MODEL_PATH := "res://assets/models/towers/shadow_tower_b2.glb"
const B3_MESH_PATH := "res://assets/models/towers/shadow_tower_b3_textured/base.obj"
const B3_DIFFUSE_PATH := "res://assets/models/towers/shadow_tower_b3_textured/texture_diffuse.png"
const B3_NORMAL_PATH := "res://assets/models/towers/shadow_tower_b3_textured/texture_normal.png"
const B3_METALLIC_PATH := "res://assets/models/towers/shadow_tower_b3_textured/texture_metallic.png"
const B3_ROUGHNESS_PATH := "res://assets/models/towers/shadow_tower_b3_textured/texture_roughness.png"
const B4_MODEL_PATH := "res://assets/models/towers/shadow_tower_b4.glb"

func _init() -> void:
	var failures: Array[String] = []

	_validate_tower_model(B2_MODEL_PATH, "B2", failures)
	_validate_tower_mesh_with_textures(B3_MESH_PATH, "B3", [
		B3_DIFFUSE_PATH,
		B3_NORMAL_PATH,
		B3_METALLIC_PATH,
		B3_ROUGHNESS_PATH,
	], failures)
	_validate_tower_model(B4_MODEL_PATH, "B4", failures)
	_validate_scenario_catalog(failures)
	_validate_placeholder_tower_attachment(B2_MODEL_PATH, "B2", failures)
	_validate_placeholder_tower_mesh_attachment(B3_MESH_PATH, "B3", failures)
	_validate_placeholder_tower_attachment(B4_MODEL_PATH, "B4", failures)

	if failures.is_empty():
		print("smoke_shadow_tower_assets: ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _validate_tower_model(model_path: String, label: String, failures: Array[String]) -> void:
	if not FileAccess.file_exists(model_path):
		failures.append("Missing %s tower GLB at %s" % [label, model_path])
	if not ResourceLoader.exists(model_path):
		failures.append("%s tower GLB is not imported as a Godot resource: %s" % [label, model_path])

	if FileAccess.file_exists(model_path) and ResourceLoader.exists(model_path):
		var packed_model := load(model_path) as PackedScene
		if packed_model == null:
			failures.append("%s tower GLB must load as PackedScene" % label)
		else:
			var model := packed_model.instantiate() as Node3D
			if model == null:
				failures.append("%s tower GLB root must instantiate as Node3D" % label)
			elif _count_mesh_instances(model) < 1:
				failures.append("%s tower GLB must contain at least one MeshInstance3D" % label)
			model.free()

func _validate_tower_mesh_with_textures(mesh_path: String, label: String, texture_paths: Array[String], failures: Array[String]) -> void:
	if not FileAccess.file_exists(mesh_path):
		failures.append("Missing %s textured tower OBJ at %s" % [label, mesh_path])
	if not ResourceLoader.exists(mesh_path):
		failures.append("%s textured tower OBJ is not imported as a Godot resource: %s" % [label, mesh_path])

	for texture_path in texture_paths:
		if not FileAccess.file_exists(texture_path):
			failures.append("Missing %s tower texture at %s" % [label, texture_path])
		if not ResourceLoader.exists(texture_path):
			failures.append("%s tower texture is not imported as a Godot resource: %s" % [label, texture_path])

	if FileAccess.file_exists(mesh_path) and ResourceLoader.exists(mesh_path):
		var mesh := load(mesh_path) as Mesh
		if mesh == null:
			failures.append("%s textured tower OBJ must load as Mesh" % label)
		elif mesh.get_surface_count() < 1:
			failures.append("%s textured tower OBJ must contain at least one mesh surface" % label)

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
	var towers := data.get("towers", {}) as Dictionary
	_expect_tower_catalog_entry(towers, "shadow-tower-b2", B2_MODEL_PATH, failures)
	_expect_textured_tower_catalog_entry(towers, "shadow-tower-b3", B3_MESH_PATH, B3_DIFFUSE_PATH, failures)
	_expect_tower_catalog_entry(towers, "shadow-tower-b4", B4_MODEL_PATH, failures)
	_expect_tower_placement(towers, "shadow-tower-b2", failures)
	_expect_tower_placement(towers, "shadow-tower-b3", failures)
	_expect_tower_placement(towers, "shadow-tower-b4", failures)

func _expect_tower_catalog_entry(towers: Dictionary, type_id: String, model_path: String, failures: Array[String]) -> void:
	var catalog := towers.get("catalog", []) as Array
	for entry_variant: Variant in catalog:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue

		var entry := entry_variant as Dictionary
		if str(entry.get("id", "")) != type_id:
			continue

		if str(entry.get("modelPath", "")) != model_path:
			failures.append("%s tower catalog entry must reference %s" % [type_id, model_path])
		return

	failures.append("Spike scenario tower catalog must include %s" % type_id)

func _expect_textured_tower_catalog_entry(towers: Dictionary, type_id: String, mesh_path: String, diffuse_path: String, failures: Array[String]) -> void:
	var catalog := towers.get("catalog", []) as Array
	for entry_variant: Variant in catalog:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue

		var entry := entry_variant as Dictionary
		if str(entry.get("id", "")) != type_id:
			continue

		if str(entry.get("meshPath", "")) != mesh_path:
			failures.append("%s tower catalog entry must reference meshPath %s" % [type_id, mesh_path])
		if str(entry.get("textureDiffusePath", "")) != diffuse_path:
			failures.append("%s tower catalog entry must reference textureDiffusePath %s" % [type_id, diffuse_path])
		return

	failures.append("Spike scenario tower catalog must include %s" % type_id)

func _expect_tower_placement(towers: Dictionary, type_id: String, failures: Array[String]) -> void:
	var placements := towers.get("placements", []) as Array
	for placement_variant: Variant in placements:
		if typeof(placement_variant) == TYPE_DICTIONARY and str((placement_variant as Dictionary).get("typeId", "")) == type_id:
			return

	failures.append("Spike scenario tower placements must include %s" % type_id)

func _validate_placeholder_tower_attachment(model_path: String, label: String, failures: Array[String]) -> void:
	var packed_tower := load(TOWER_SCENE_PATH) as PackedScene
	if packed_tower == null:
		failures.append("Tower scene must load as PackedScene")
		return

	var tower := packed_tower.instantiate() as Node3D
	if not tower.has_method("configure_visual"):
		failures.append("PlaceholderTower must expose configure_visual(data) for catalog-driven tower assets")
	else:
		tower.call("configure_visual", {
			"modelPath": model_path,
			"modelYawDegrees": -45.0,
			"modelLift": 0.02,
			"targetHeight": 1.35,
			"targetFootprint": 0.9,
		})

	tower.call("setup", Vector3.ZERO)
	tower.call("_ready")

	var tower_model := tower.get_node_or_null("TowerModel")
	if tower_model == null:
		failures.append("PlaceholderTower must attach configured %s TowerModel" % label)
	elif tower_model.scale.x <= 0.0:
		failures.append("%s TowerModel must have a positive fitted scale" % label)
	if tower.get_node_or_null("TowerBaseMarker") == null:
		failures.append("Configured %s tower must keep a base readability marker" % label)
	if tower.get_node_or_null("TowerEmberBeacon") == null:
		failures.append("Configured %s tower must keep an ember readability beacon" % label)
	if tower.get_node_or_null("BasaltBase") != null:
		failures.append("Configured %s tower must not also build the primitive fallback" % label)
	tower.free()

func _validate_placeholder_tower_mesh_attachment(mesh_path: String, label: String, failures: Array[String]) -> void:
	var packed_tower := load(TOWER_SCENE_PATH) as PackedScene
	if packed_tower == null:
		failures.append("Tower scene must load as PackedScene")
		return

	var tower := packed_tower.instantiate() as Node3D
	if not tower.has_method("configure_visual"):
		failures.append("PlaceholderTower must expose configure_visual(data) for catalog-driven tower mesh assets")
	else:
		tower.call("configure_visual", {
			"meshPath": mesh_path,
			"textureDiffusePath": B3_DIFFUSE_PATH,
			"textureNormalPath": B3_NORMAL_PATH,
			"textureMetallicPath": B3_METALLIC_PATH,
			"textureRoughnessPath": B3_ROUGHNESS_PATH,
			"modelYawDegrees": -45.0,
			"modelLift": 0.02,
			"targetHeight": 1.35,
			"targetFootprint": 0.9,
		})

	tower.call("setup", Vector3.ZERO)
	tower.call("_ready")

	var tower_model := tower.get_node_or_null("TowerModel") as MeshInstance3D
	if tower_model == null:
		failures.append("PlaceholderTower must attach configured textured %s TowerModel" % label)
	elif tower_model.mesh == null:
		failures.append("Configured textured %s TowerModel must have mesh content" % label)
	elif tower_model.material_override == null:
		failures.append("Configured textured %s TowerModel must apply a material override" % label)
	if tower.get_node_or_null("TowerBaseMarker") == null:
		failures.append("Configured textured %s tower must keep a base readability marker" % label)
	if tower.get_node_or_null("BasaltBase") != null:
		failures.append("Configured textured %s tower must not also build the primitive fallback" % label)
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
