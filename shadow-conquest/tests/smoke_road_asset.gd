extends SceneTree

const DATA_PATH := "res://data/spike_scenario.json"
const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const ROAD_MODEL_PATH := "res://assets/models/terrain/ash_road_surface.glb"

func _init() -> void:
	var failures: Array[String] = []

	if not FileAccess.file_exists(ROAD_MODEL_PATH):
		failures.append("Missing road surface GLB at %s" % ROAD_MODEL_PATH)
	if not ResourceLoader.exists(ROAD_MODEL_PATH):
		failures.append("Road surface GLB is not imported as a Godot resource: %s" % ROAD_MODEL_PATH)
	if FileAccess.file_exists(ROAD_MODEL_PATH):
		var file_size := FileAccess.get_file_as_bytes(ROAD_MODEL_PATH).size()
		if file_size < 8_000_000:
			failures.append("Road surface GLB must come from the user-provided land.zip PBR export, got only %d bytes" % file_size)

	if FileAccess.file_exists(ROAD_MODEL_PATH) and ResourceLoader.exists(ROAD_MODEL_PATH):
		var packed_model := load(ROAD_MODEL_PATH) as PackedScene
		if packed_model == null:
			failures.append("Road surface GLB must load as PackedScene")
		else:
			var model := packed_model.instantiate() as Node3D
			if model == null:
				failures.append("Road surface GLB root must instantiate as Node3D")
			elif _count_mesh_instances(model) < 1:
				failures.append("Road surface GLB must contain MeshInstance3D content")
			model.free()

	_validate_scenario_path(failures)
	_validate_main_scene_spawns_road_surfaces(failures)

	if failures.is_empty():
		print("smoke_road_asset: ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _validate_scenario_path(failures: Array[String]) -> void:
	if not FileAccess.file_exists(DATA_PATH):
		failures.append("Missing spike scenario data at %s" % DATA_PATH)
		return

	var data_file := FileAccess.open(DATA_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(data_file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		failures.append("Spike scenario data must be a JSON object")
		return

	var path_data := (parsed as Dictionary).get("path", {}) as Dictionary
	if str(path_data.get("surfaceModelPath", "")) != ROAD_MODEL_PATH:
		failures.append("Spike scenario path.surfaceModelPath must reference %s" % ROAD_MODEL_PATH)
	if float(path_data.get("surfaceTargetFootprint", 0.0)) <= 0.0:
		failures.append("Spike scenario path must configure surfaceTargetFootprint")

func _validate_main_scene_spawns_road_surfaces(failures: Array[String]) -> void:
	if not ResourceLoader.exists(MAIN_SCENE_PATH):
		failures.append("Missing main scene at %s" % MAIN_SCENE_PATH)
		return

	var packed_scene := load(MAIN_SCENE_PATH) as PackedScene
	var scene := packed_scene.instantiate() as Node
	get_root().add_child(scene)
	scene.call("_ready")

	var board_view := scene.get_node_or_null("World/BoardView")
	if board_view == null:
		failures.append("Main scene must include World/BoardView")
	else:
		var road_count := 0
		for child in board_view.get_children():
			if str(child.name).begins_with("RoadSurface_"):
				road_count += 1
		if road_count < 1:
			failures.append("BoardView must spawn road surface model instances for path tiles")

	scene.free()

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
