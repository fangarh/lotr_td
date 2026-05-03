extends SceneTree

const TERRAIN_PROP_SCENE_PATH := "res://scenes/entities/placeholder_terrain_prop.tscn"
const ROCK_CLUSTER_MODEL_PATH := "res://assets/models/terrain/mordor_rock_cluster_proxy.glb"

func _init() -> void:
	var failures: Array[String] = []

	if not FileAccess.file_exists(ROCK_CLUSTER_MODEL_PATH):
		failures.append("Missing terrain prop GLB at %s" % ROCK_CLUSTER_MODEL_PATH)
	if not ResourceLoader.exists(ROCK_CLUSTER_MODEL_PATH):
		failures.append("Terrain prop GLB is not imported as a Godot resource: %s" % ROCK_CLUSTER_MODEL_PATH)

	if FileAccess.file_exists(ROCK_CLUSTER_MODEL_PATH) and ResourceLoader.exists(ROCK_CLUSTER_MODEL_PATH):
		var packed_model := load(ROCK_CLUSTER_MODEL_PATH) as PackedScene
		if packed_model == null:
			failures.append("Terrain prop GLB must load as PackedScene")
		else:
			var model := packed_model.instantiate() as Node3D
			if model == null:
				failures.append("Terrain prop GLB root must instantiate as Node3D")
			elif _count_mesh_instances(model) < 4:
				failures.append("Terrain prop GLB must contain several MeshInstance3D nodes for rocks, ash, and corruption accents")
			model.free()

	if not ResourceLoader.exists(TERRAIN_PROP_SCENE_PATH):
		failures.append("Missing terrain prop scene at %s" % TERRAIN_PROP_SCENE_PATH)
	else:
		var packed_scene := load(TERRAIN_PROP_SCENE_PATH) as PackedScene
		var terrain_prop := packed_scene.instantiate() as Node3D
		if terrain_prop == null:
			failures.append("Terrain prop scene root must instantiate as Node3D")
		else:
			if not terrain_prop.has_method("configure_visual"):
				failures.append("Terrain prop must expose configure_visual(data)")
			else:
				terrain_prop.call("configure_visual", {
					"modelPath": ROCK_CLUSTER_MODEL_PATH,
					"modelYawDegrees": 18.0,
					"modelLift": 0.0,
					"targetHeight": 0.62,
					"targetFootprint": 0.88,
				})
			terrain_prop.call("setup", Vector3(2.0, 0.0, 5.0))
			terrain_prop.call("_ready")

			var prop_model := terrain_prop.get_node_or_null("TerrainPropModel")
			if prop_model == null:
				failures.append("Configured terrain prop must attach TerrainPropModel")
			elif prop_model.scale.x <= 0.0:
				failures.append("TerrainPropModel must have a positive fitted scale")
			if terrain_prop.get_node_or_null("PrimitiveRock") != null:
				failures.append("Configured terrain prop must not also build the primitive fallback")
			if terrain_prop.position.x != 2.0 or terrain_prop.position.z != 5.0:
				failures.append("Terrain prop setup must preserve requested world XZ position")
			terrain_prop.free()

	if failures.is_empty():
		print("smoke_terrain_prop_asset: ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

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
