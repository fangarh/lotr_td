extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const TWO_WAVE_SCENARIO_PATH := "res://tests/fixtures/two_wave_scenario.json"
const OUTPUT_DIR := "res://builds/previews"

const DESKTOP_SIZE := Vector2i(1280, 720)
const MOBILE_LANDSCAPE_SIZE := Vector2i(844, 390)

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed_scene := load(MAIN_SCENE_PATH) as PackedScene
	if packed_scene == null:
		push_error("Missing main scene: %s" % MAIN_SCENE_PATH)
		quit(1)
		return
	if not FileAccess.file_exists(TWO_WAVE_SCENARIO_PATH):
		push_error("Missing two-wave scenario fixture: %s" % TWO_WAVE_SCENARIO_PATH)
		quit(1)
		return

	var output_dir := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(output_dir)

	var capture_targets: Array[Dictionary] = [
		{
			"state": "wave_clear",
			"desktop": "res://builds/previews/spike_hud_wave_clear_preview.png",
			"mobile": "res://builds/previews/spike_hud_wave_clear_mobile_landscape_preview.png",
		},
		{
			"state": "basic_win",
			"desktop": "res://builds/previews/spike_hud_basic_win_preview.png",
			"mobile": "res://builds/previews/spike_hud_basic_win_mobile_landscape_preview.png",
		},
		{
			"state": "basic_loss",
			"desktop": "res://builds/previews/spike_hud_basic_loss_preview.png",
			"mobile": "res://builds/previews/spike_hud_basic_loss_mobile_landscape_preview.png",
		},
	]

	for target: Dictionary in capture_targets:
		var state_name := str(target["state"])
		if not await _capture_state(packed_scene, state_name, DESKTOP_SIZE, str(target["desktop"])):
			quit(1)
			return
		if not await _capture_state(packed_scene, state_name, MOBILE_LANDSCAPE_SIZE, str(target["mobile"])):
			quit(1)
			return

	quit(0)

func _capture_state(packed_scene: PackedScene, state_name: String, viewport_size: Vector2i, output_path: String) -> bool:
	DisplayServer.window_set_size(viewport_size)
	await process_frame

	var scene := packed_scene.instantiate() as Node3D
	if scene == null:
		push_error("Main scene must instantiate as Node3D")
		return false

	scene.set("scenario_path", TWO_WAVE_SCENARIO_PATH)
	root.add_child(scene)
	await process_frame

	if not _prepare_state(scene, state_name):
		scene.queue_free()
		await process_frame
		return false

	var hud := scene.get_node_or_null("HUD")
	if hud == null:
		push_error("Missing HUD in main scene.")
		scene.queue_free()
		await process_frame
		return false

	hud.call("refresh")
	if not _validate_action_button(hud, state_name):
		scene.queue_free()
		await process_frame
		return false

	for frame in 8:
		await process_frame

	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		push_error("Viewport texture is unavailable; run this capture without --headless.")
		scene.queue_free()
		await process_frame
		return false

	var image := viewport_texture.get_image()
	if image == null:
		push_error("Viewport image is unavailable; run this capture without --headless.")
		scene.queue_free()
		await process_frame
		return false

	var error := image.save_png(ProjectSettings.globalize_path(output_path))
	scene.queue_free()
	await process_frame

	if error != OK:
		push_error("Failed to save terminal HUD action PNG %s: %s" % [output_path, error_string(error)])
		return false

	print("capture_spike_hud_action_states: saved %s" % output_path)
	return true

func _prepare_state(scene: Node, state_name: String) -> bool:
	var game_state := scene.get_node_or_null("GameStateAdapter")
	var combat_adapter := scene.get_node_or_null("CombatAdapter")
	if game_state == null or combat_adapter == null:
		push_error("Terminal HUD action capture requires game and combat adapters.")
		return false

	if state_name == "wave_clear":
		_force_first_tracked_enemy_endpoint_breach(combat_adapter)
	elif state_name == "basic_win":
		_kill_first_tracked_enemy(combat_adapter)
		if not bool(scene.call("start_next_wave_manually")):
			push_error("Unable to start second wave for basic_win capture.")
			return false
		_kill_first_tracked_enemy(combat_adapter)
	elif state_name == "basic_loss":
		_force_first_tracked_enemy_endpoint_breach(combat_adapter)
		if not bool(scene.call("start_next_wave_manually")):
			push_error("Unable to start second wave for basic_loss capture.")
			return false
		_force_first_tracked_enemy_endpoint_breach(combat_adapter)
	else:
		push_error("Unsupported terminal HUD action capture state: %s" % state_name)
		return false

	var actual_state := str(game_state.call("get_state"))
	if actual_state != state_name:
		push_error("Expected HUD capture state %s, got %s" % [state_name, actual_state])
		return false

	return true

func _validate_action_button(hud: Node, state_name: String) -> bool:
	var action_button := hud.get_node_or_null("HudBar/ActionButton") as Button
	if action_button == null:
		push_error("Terminal HUD action capture requires ActionButton.")
		return false
	if not action_button.visible:
		push_error("Terminal HUD action button must be visible in %s." % state_name)
		return false

	var expected_text := "Restart"
	if state_name == "wave_clear":
		expected_text = "Next wave"
	if action_button.text != expected_text:
		push_error("Expected %s button text '%s', got '%s'" % [state_name, expected_text, action_button.text])
		return false

	return true

func _force_first_tracked_enemy_endpoint_breach(combat_adapter: Node) -> void:
	var tracked_enemies := combat_adapter.call("get_tracked_enemies") as Array
	if tracked_enemies.is_empty():
		return

	var enemy := tracked_enemies[0] as Node
	var short_path: Array[Vector3] = [
		Vector3(0.0, 0.18, 0.0),
		Vector3(0.1, 0.18, 0.0),
	]
	enemy.call("setup", short_path, 10.0)
	enemy.call("_process", 1.0)

func _kill_first_tracked_enemy(combat_adapter: Node) -> void:
	var tracked_enemies := combat_adapter.call("get_tracked_enemies") as Array
	if tracked_enemies.is_empty():
		return

	var enemy := tracked_enemies[0] as Node
	combat_adapter.call("apply_damage", enemy, 999.0)
