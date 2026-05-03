extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const OUTPUT_PATH := "res://builds/previews/tower_attack_readability_preview.png"

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed_scene := load(MAIN_SCENE_PATH) as PackedScene
	if packed_scene == null:
		push_error("Missing main scene: %s" % MAIN_SCENE_PATH)
		quit(1)
		return

	DisplayServer.window_set_size(Vector2i(1280, 720))

	var scene := packed_scene.instantiate() as Node3D
	if scene == null:
		push_error("Main scene must instantiate as Node3D")
		quit(1)
		return

	root.add_child(scene)

	var attack_adapter := scene.get_node_or_null("TowerAttackAdapter")
	if attack_adapter == null:
		push_error("Missing TowerAttackAdapter in main scene.")
		quit(1)
		return

	attack_adapter.set("auto_advance", false)
	for frame in 4:
		await process_frame

	attack_adapter.call("advance", 0.0)
	attack_adapter.call("advance", 0.18)

	var fire_cue := attack_adapter.get_node_or_null("TowerFireCue")
	if fire_cue == null:
		push_error("Tower attack preview requires a TowerFireCue.")
		quit(1)
		return

	var projectile := attack_adapter.get_node_or_null("ProjectileVisual")
	if projectile == null:
		push_error("Tower attack preview requires a ProjectileVisual.")
		quit(1)
		return

	for frame in 4:
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
		push_error("Failed to save tower attack preview PNG: %s" % error_string(error))
		quit(1)
		return

	print("capture_tower_attack_readability_preview: saved %s" % OUTPUT_PATH)
	quit(0)
