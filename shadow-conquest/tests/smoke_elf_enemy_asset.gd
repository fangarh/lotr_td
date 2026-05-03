extends SceneTree

const ENEMY_SCENE_PATH := "res://scenes/entities/placeholder_enemy.tscn"
const ELF_MODEL_PATH := "res://assets/models/enemies/elf_archer_proxy.glb"

func _init() -> void:
	var failures: Array[String] = []

	if not FileAccess.file_exists(ELF_MODEL_PATH):
		failures.append("Missing elf enemy GLB at %s" % ELF_MODEL_PATH)
	if not ResourceLoader.exists(ELF_MODEL_PATH):
		failures.append("Elf enemy GLB is not imported as a Godot resource: %s" % ELF_MODEL_PATH)
	if FileAccess.file_exists(ELF_MODEL_PATH):
		var file_size := FileAccess.get_file_as_bytes(ELF_MODEL_PATH).size()
		if file_size < 1_000_000:
			failures.append("Elf enemy GLB must be refreshed from the user-provided ZIP export, got only %d bytes" % file_size)

	if FileAccess.file_exists(ELF_MODEL_PATH) and ResourceLoader.exists(ELF_MODEL_PATH):
		var packed_model := load(ELF_MODEL_PATH) as PackedScene
		if packed_model == null:
			failures.append("Elf enemy GLB must load as PackedScene")
		else:
			var model := packed_model.instantiate() as Node3D
			if model == null:
				failures.append("Elf enemy GLB root must instantiate as Node3D")
			elif _count_mesh_instances(model) < 1:
				failures.append("Elf enemy GLB must contain MeshInstance3D content")
			model.free()

	var packed_enemy := load(ENEMY_SCENE_PATH) as PackedScene
	if packed_enemy == null:
		failures.append("Enemy scene must load as PackedScene")
	else:
		var enemy := packed_enemy.instantiate() as Node3D
		if not enemy.has_method("configure_visual"):
			failures.append("PlaceholderEnemy must expose configure_visual(data) for catalog-driven model assets")
		else:
			enemy.call("configure_visual", {
				"modelPath": ELF_MODEL_PATH,
				"modelYawDegrees": -35.0,
				"modelLift": 0.0,
				"targetHeight": 0.92,
				"targetFootprint": 0.72,
			})

		var path_points: Array[Vector3] = [
			Vector3(0.0, 0.18, 0.0),
			Vector3(1.0, 0.18, 0.0),
		]
		enemy.call("setup", path_points, 1.1)
		enemy.call("_ready")

		var enemy_model := enemy.get_node_or_null("EnemyModel")
		if enemy_model == null:
			failures.append("PlaceholderEnemy must attach configured EnemyModel")
		elif enemy_model.scale.x <= 0.0:
			failures.append("EnemyModel must have a positive fitted scale")
		if enemy.get_node_or_null("ElfEnemyBaseMarker") == null:
			failures.append("PlaceholderEnemy must add an elf base readability marker")
		if enemy.get_node_or_null("GondorBody") != null:
			failures.append("Configured model enemies must not also build the Gondor primitive fallback")
		enemy.free()

	if failures.is_empty():
		print("smoke_elf_enemy_asset: ok")
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
