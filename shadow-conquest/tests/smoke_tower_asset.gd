extends SceneTree

const TOWER_SCENE_PATH := "res://scenes/entities/placeholder_tower.tscn"
const TOWER_MODEL_PATH := "res://assets/models/towers/base.glb"

func _init() -> void:
	var failures: Array[String] = []

	if not FileAccess.file_exists(TOWER_MODEL_PATH):
		failures.append("Missing tower GLB at %s" % TOWER_MODEL_PATH)
	if not ResourceLoader.exists(TOWER_MODEL_PATH):
		failures.append("Tower GLB is not imported as a Godot resource: %s" % TOWER_MODEL_PATH)

	var packed_model := load(TOWER_MODEL_PATH) as PackedScene
	if packed_model == null:
		failures.append("Tower GLB must load as PackedScene")
	else:
		var model := packed_model.instantiate() as Node3D
		if model == null:
			failures.append("Tower GLB root must instantiate as Node3D")
		elif _count_mesh_instances(model) < 1:
			failures.append("Tower GLB must contain at least one MeshInstance3D")
		model.free()

	var packed_tower := load(TOWER_SCENE_PATH) as PackedScene
	if packed_tower == null:
		failures.append("Tower scene must load as PackedScene")
	else:
		var tower := packed_tower.instantiate() as Node3D
		tower.call("setup", Vector3.ZERO)
		tower.call("_ready")
		var tower_model := tower.get_node_or_null("TowerModel")
		if tower_model == null:
			failures.append("PlaceholderTower must attach the imported TowerModel")
		elif tower_model.scale.x <= 0.0:
			failures.append("TowerModel must have a positive fitted scale")
		if tower.get_node_or_null("TowerBaseMarker") == null:
			failures.append("PlaceholderTower must add a base readability marker")
		if tower.get_node_or_null("TowerEmberBeacon") == null:
			failures.append("PlaceholderTower must add an ember readability beacon")
		if tower.get_node_or_null("TowerEmberLight") == null:
			failures.append("PlaceholderTower must add an ember readability light")
		tower.free()

	if failures.is_empty():
		print("smoke_tower_asset: ok")
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
