extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const OUTPUT_PATH := "res://builds/previews/timed_slow_zone_preview.png"

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
	if obstacle_tower_adapter == null or not obstacle_tower_adapter.has_method("get_slow_zone_count"):
		push_error("Timed slow-zone capture requires ObstacleTowerAdapter with get_slow_zone_count().")
		quit(1)
		return

	var enemy := await _wait_for_first_spawned_enemy(scene)
	if enemy == null:
		scene.call("_ready")
		await _disable_tower_attack_auto_advance(scene)
		enemy = await _wait_for_first_spawned_enemy(scene)
	if enemy == null:
		push_error("Timed slow-zone capture requires an already-spawned enemy.")
		quit(1)
		return

	var static_slow_zone_count := int(obstacle_tower_adapter.call("get_slow_zone_count"))
	var timed_zone := await _wait_for_timed_slow_zone(scene, obstacle_tower_adapter, static_slow_zone_count)
	if timed_zone.is_empty():
		push_error("Timed slow-zone capture could not observe a tower-owned slow-zone spawn.")
		quit(1)
		return

	var timed_zone_position: Vector3 = timed_zone.get("position", Vector3.ZERO)
	enemy.position = timed_zone_position
	enemy.call("set_slow_zones", obstacle_tower_adapter.call("get_slow_zones"))

	var slow_multiplier := float(enemy.call("current_slow_multiplier"))
	if slow_multiplier >= 1.0:
		push_error("Timed slow-zone capture requires active slow multiplier below 1.0, got %.3f." % slow_multiplier)
		quit(1)
		return

	_add_review_marker(scene, timed_zone_position, slow_multiplier)
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
		push_error("Failed to save timed slow-zone preview PNG: %s" % error_string(error))
		quit(1)
		return

	print("capture_timed_slow_zone_preview: saved %s" % OUTPUT_PATH)
	quit(0)

func _wait_for_timed_slow_zone(scene: Node, obstacle_tower_adapter: Node, static_slow_zone_count: int) -> Dictionary:
	for step in 24:
		scene.call("_process", 0.1)
		await process_frame
		var slow_zone_count := int(obstacle_tower_adapter.call("get_slow_zone_count"))
		if slow_zone_count <= static_slow_zone_count:
			continue

		var slow_zones := obstacle_tower_adapter.call("get_slow_zones") as Array
		if slow_zones.size() <= static_slow_zone_count:
			continue

		var timed_zone_variant: Variant = slow_zones[slow_zones.size() - 1]
		if typeof(timed_zone_variant) == TYPE_DICTIONARY:
			return timed_zone_variant as Dictionary

	return {}

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

func _add_review_marker(scene: Node, zone_position: Vector3, slow_multiplier: float) -> void:
	var world := scene.get_node_or_null("World") as Node3D
	if world == null:
		return

	var marker := Node3D.new()
	marker.name = "TimedSlowZoneReviewMarker"
	marker.position = zone_position + Vector3(0.0, 0.065, 0.0)
	world.add_child(marker)

	var ring := MeshInstance3D.new()
	ring.name = "TimedSlowZoneReviewRing"
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = 0.86
	ring_mesh.bottom_radius = 0.92
	ring_mesh.height = 0.03
	ring_mesh.radial_segments = 32
	ring.mesh = ring_mesh
	ring.material_override = _make_review_material()
	marker.add_child(ring)

	var label := Label3D.new()
	label.name = "TimedSlowZoneReviewLabel"
	label.text = "Timed slow x%.2f" % slow_multiplier
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 42
	label.modulate = Color(0.64, 1.0, 0.72)
	label.position = Vector3(0.0, 0.62, 0.0)
	marker.add_child(label)

func _make_review_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.18, 0.86, 0.42, 0.28)
	material.emission_enabled = true
	material.emission = Color(0.1, 0.9, 0.32)
	material.emission_energy_multiplier = 0.75
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material
