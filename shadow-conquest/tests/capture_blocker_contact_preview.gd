extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const OUTPUT_PATH := "res://builds/previews/blocker_contact_preview.png"

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed_scene := load(MAIN_SCENE_PATH) as PackedScene
	if packed_scene == null:
		push_error("Missing main scene: %s" % MAIN_SCENE_PATH)
		quit(1)
		return

	DisplayServer.window_set_size(Vector2i(1280, 720))
	await process_frame

	var scene := packed_scene.instantiate() as Node3D
	if scene == null:
		push_error("Main scene must instantiate as Node3D")
		quit(1)
		return

	root.add_child(scene)
	await process_frame

	var tower_attack_adapter := scene.get_node_or_null("TowerAttackAdapter")
	if tower_attack_adapter != null:
		tower_attack_adapter.set("auto_advance", false)

	var obstacle_tower_adapter := scene.get_node_or_null("ObstacleTowerAdapter")
	if obstacle_tower_adapter == null or not obstacle_tower_adapter.has_method("get_blockers"):
		push_error("Blocker-contact capture requires ObstacleTowerAdapter with get_blockers().")
		quit(1)
		return

	var enemy := await _wait_for_first_spawned_enemy(scene)
	if enemy == null:
		scene.call("_ready")
		await _disable_tower_attack_auto_advance(scene)
		enemy = await _wait_for_first_spawned_enemy(scene)
	if enemy == null:
		push_error("Blocker-contact capture requires an already-spawned enemy.")
		quit(1)
		return

	var blocker := await _wait_for_runtime_blocker(scene, obstacle_tower_adapter)
	if blocker.is_empty():
		push_error("Blocker-contact capture could not observe a temporary blocker spawn.")
		quit(1)
		return

	var blocker_id := str(blocker.get("id", ""))
	var blocker_position: Vector3 = blocker.get("position", Vector3.ZERO)
	var initial_health := float(blocker.get("currentHealth", 0.0))
	enemy.position = blocker_position
	enemy.call("set_blockers", obstacle_tower_adapter.call("get_blockers"))

	if str(enemy.call("current_blocker_id")) != blocker_id:
		push_error("Blocker-contact capture requires enemy current_blocker_id() to match %s." % blocker_id)
		quit(1)
		return

	enemy.call("_process", 0.6)
	var bridge_result := _blocker_bridge_result(obstacle_tower_adapter, blocker_id, initial_health)
	if bridge_result == "unchanged":
		push_error("Blocker-contact capture requires existing enemy damage bridge to affect blocker HP.")
		quit(1)
		return

	_add_review_marker(scene, blocker_position, bridge_result)
	for frame in 8:
		await process_frame

	var output_dir := ProjectSettings.globalize_path("res://builds/previews")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		push_error("Viewport texture is unavailable; run this capture without --headless.")
		quit(1)
		return

	var image := viewport_texture.get_image()
	if image == null:
		push_error("Viewport image is unavailable; run this capture without --headless.")
		quit(1)
		return

	var error := image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	scene.queue_free()

	if error != OK:
		push_error("Failed to save blocker-contact preview PNG: %s" % error_string(error))
		quit(1)
		return

	print("capture_blocker_contact_preview: saved %s" % OUTPUT_PATH)
	quit(0)

func _wait_for_runtime_blocker(scene: Node, obstacle_tower_adapter: Node) -> Dictionary:
	for step in 24:
		scene.call("_process", 0.1)
		await process_frame
		var blockers := obstacle_tower_adapter.call("get_blockers") as Array
		if blockers.is_empty():
			continue

		var blocker_variant: Variant = blockers[0]
		if typeof(blocker_variant) == TYPE_DICTIONARY:
			return blocker_variant as Dictionary

	return {}

func _blocker_bridge_result(obstacle_tower_adapter: Node, blocker_id: String, initial_health: float) -> String:
	var blockers := obstacle_tower_adapter.call("get_blockers") as Array
	for blocker_variant: Variant in blockers:
		if typeof(blocker_variant) != TYPE_DICTIONARY:
			continue

		var blocker := blocker_variant as Dictionary
		if str(blocker.get("id", "")) != blocker_id:
			continue

		var current_health := float(blocker.get("currentHealth", initial_health))
		if current_health < initial_health:
			return "HP %.0f" % current_health
		return "unchanged"

	return "removed after hit"

func _first_spawned_enemy(scene: Node) -> Node3D:
	var enemy_root := scene.get_node_or_null("World/Enemies")
	if enemy_root == null or enemy_root.get_child_count() < 1:
		return null
	return enemy_root.get_child(0) as Node3D

func _wait_for_first_spawned_enemy(scene: Node) -> Node3D:
	for frame in 16:
		var enemy := _first_spawned_enemy(scene)
		if enemy != null:
			return enemy
		await process_frame
	return null

func _disable_tower_attack_auto_advance(scene: Node) -> void:
	var tower_attack_adapter := scene.get_node_or_null("TowerAttackAdapter")
	if tower_attack_adapter != null:
		tower_attack_adapter.set("auto_advance", false)
	await process_frame

func _add_review_marker(scene: Node, blocker_position: Vector3, bridge_result: String) -> void:
	var world := scene.get_node_or_null("World") as Node3D
	if world == null:
		return

	var marker := Node3D.new()
	marker.name = "BlockerContactReviewMarker"
	marker.position = blocker_position + Vector3(0.0, 0.075, 0.0)
	world.add_child(marker)

	var ring := MeshInstance3D.new()
	ring.name = "BlockerContactReviewRing"
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = 0.82
	ring_mesh.bottom_radius = 0.88
	ring_mesh.height = 0.035
	ring_mesh.radial_segments = 32
	ring.mesh = ring_mesh
	ring.material_override = _make_review_material()
	marker.add_child(ring)

	var label := Label3D.new()
	label.name = "BlockerContactReviewLabel"
	label.text = "Blocker contact\n%s" % bridge_result
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 38
	label.modulate = Color(1.0, 0.48, 0.32)
	label.position = Vector3(0.0, 0.92, -0.12)
	marker.add_child(label)

func _make_review_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.22, 0.12, 0.28)
	material.emission_enabled = true
	material.emission = Color(0.95, 0.16, 0.08)
	material.emission_energy_multiplier = 0.75
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material
