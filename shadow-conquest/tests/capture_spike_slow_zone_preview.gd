extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const ENEMY_SCENE_PATH := "res://scenes/entities/placeholder_enemy.tscn"
const OUTPUT_PATH := "res://builds/previews/spike_slow_zone_preview.png"

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
	for frame in 8:
		await process_frame

	if _first_spawned_enemy(scene) == null or _first_spawned_obstacle(scene) == null:
		scene.call("_ready")
		for frame in 8:
			await process_frame

	var enemy := _first_spawned_enemy(scene)
	var obstacle := _first_spawned_obstacle(scene)
	if obstacle == null:
		push_error("Slow-zone capture requires one spawned obstacle. Found obstacles=%d." % _child_count(scene, "World/Obstacles"))
		quit(1)
		return
	if enemy == null:
		enemy = _create_review_enemy(scene, obstacle.position)
		if enemy == null:
			push_error("Slow-zone capture could not create a review enemy.")
			quit(1)
			return

	enemy.position = obstacle.position + Vector3(0.0, 0.18, 0.0)
	var slow_multiplier := float(enemy.call("current_slow_multiplier"))
	if slow_multiplier >= 1.0:
		push_error("Slow-zone capture requires active slow multiplier below 1.0, got %.3f." % slow_multiplier)
		quit(1)
		return

	_add_review_marker(scene, obstacle.position, slow_multiplier)
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
		push_error("Failed to save slow-zone preview PNG: %s" % error_string(error))
		quit(1)
		return

	print("capture_spike_slow_zone_preview: saved %s" % OUTPUT_PATH)
	quit(0)

func _first_spawned_enemy(scene: Node) -> Node3D:
	var enemy_root := scene.get_node_or_null("World/Enemies")
	if enemy_root == null or enemy_root.get_child_count() < 1:
		return null
	return enemy_root.get_child(0) as Node3D

func _first_spawned_obstacle(scene: Node) -> Node3D:
	var obstacle_root := scene.get_node_or_null("World/Obstacles")
	if obstacle_root == null or obstacle_root.get_child_count() < 1:
		return null
	return obstacle_root.get_child(0) as Node3D

func _create_review_enemy(scene: Node, zone_position: Vector3) -> Node3D:
	var enemy_root := scene.get_node_or_null("World/Enemies")
	var packed_enemy := load(ENEMY_SCENE_PATH) as PackedScene
	if enemy_root == null or packed_enemy == null:
		return null

	var enemy := packed_enemy.instantiate() as Node3D
	if enemy == null:
		return null

	var review_path: Array[Vector3] = [
		zone_position + Vector3(-0.2, 0.18, 0.0),
		zone_position + Vector3(0.2, 0.18, 0.0),
	]
	enemy.call("setup", review_path, 0.0)
	enemy.call("set_slow_zones", [{
		"position": zone_position,
		"radius": 0.85,
		"slowMultiplier": 0.55,
	}])
	enemy_root.add_child(enemy)
	return enemy

func _child_count(scene: Node, node_path: String) -> int:
	var node := scene.get_node_or_null(node_path)
	if node == null:
		return -1
	return node.get_child_count()

func _add_review_marker(scene: Node, zone_position: Vector3, slow_multiplier: float) -> void:
	var world := scene.get_node_or_null("World") as Node3D
	if world == null:
		return

	var marker := Node3D.new()
	marker.name = "SlowZoneReviewMarker"
	marker.position = zone_position + Vector3(0.0, 0.055, 0.0)
	world.add_child(marker)

	var ring := MeshInstance3D.new()
	ring.name = "SlowZoneReviewRing"
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = 0.86
	ring_mesh.bottom_radius = 0.9
	ring_mesh.height = 0.025
	ring_mesh.radial_segments = 32
	ring.mesh = ring_mesh
	ring.material_override = _make_review_material()
	marker.add_child(ring)

	var label := Label3D.new()
	label.name = "SlowZoneReviewLabel"
	label.text = "Slow x%.2f" % slow_multiplier
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 42
	label.modulate = Color(0.62, 1.0, 0.68)
	label.position = Vector3(0.0, 0.55, 0.0)
	marker.add_child(label)

func _make_review_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.22, 0.78, 0.36, 0.24)
	material.emission_enabled = true
	material.emission = Color(0.12, 0.8, 0.28)
	material.emission_energy_multiplier = 0.6
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material
