extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const OUTPUT_PATH := "res://builds/previews/spike_hud_mobile_landscape_preview.png"

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed_scene := load(MAIN_SCENE_PATH) as PackedScene
	if packed_scene == null:
		push_error("Missing main scene: %s" % MAIN_SCENE_PATH)
		quit(1)
		return

	DisplayServer.window_set_size(Vector2i(844, 390))

	var scene := packed_scene.instantiate() as Node3D
	if scene == null:
		push_error("Main scene must instantiate as Node3D")
		quit(1)
		return

	root.add_child(scene)
	for frame in 96:
		await process_frame

	var hud := scene.get_node_or_null("HUD")
	if hud == null:
		push_error("Missing HUD in main scene.")
		quit(1)
		return
	hud.call("refresh")

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
		push_error("Failed to save mobile HUD preview PNG: %s" % error_string(error))
		quit(1)
		return

	print("capture_spike_hud_mobile_preview: saved %s" % OUTPUT_PATH)
	quit(0)
