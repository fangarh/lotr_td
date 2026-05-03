extends SceneTree

const HUD_SCRIPT_PATH := "res://scripts/spike_hud.gd"
const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const TWO_WAVE_SCENARIO_PATH := "res://tests/fixtures/two_wave_scenario.json"
const MOBILE_CAPTURE_SCRIPT_PATH := "res://tests/capture_spike_hud_mobile_preview.gd"
const ACTION_CAPTURE_SCRIPT_PATH := "res://tests/capture_spike_hud_action_states.gd"

func _init() -> void:
	var failures: Array[String] = []

	if not ResourceLoader.exists(HUD_SCRIPT_PATH):
		failures.append("Missing spike HUD script at %s" % HUD_SCRIPT_PATH)

	_validate_main_hud_boundary(failures)
	_validate_main_hud_state_readout(failures)
	_validate_main_hud_action_wiring(failures)
	_validate_mobile_hud_layout(failures)
	_validate_mobile_capture_orientation(failures)
	_validate_terminal_action_capture_contract(failures)

	if failures.is_empty():
		print("smoke_spike_hud: ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _validate_main_hud_boundary(failures: Array[String]) -> void:
	if not ResourceLoader.exists(MAIN_SCENE_PATH):
		failures.append("Missing main scene at %s" % MAIN_SCENE_PATH)
		return

	var packed_main := load(MAIN_SCENE_PATH) as PackedScene
	var main := packed_main.instantiate() as Node
	var hud := main.get_node_or_null("HUD")
	if hud == null:
		failures.append("Main scene must include a scene-level HUD")
	elif not hud is Control:
		failures.append("Main HUD must be a Control node")
	elif hud.get_script() == null:
		failures.append("Main HUD must have a valid script")
	else:
		for method_name in ["bind_adapters", "refresh", "debug_text"]:
			if not hud.has_method(method_name):
				failures.append("Spike HUD must expose %s()" % method_name)
		for signal_name in ["next_wave_requested", "restart_requested"]:
			if not hud.has_signal(signal_name):
				failures.append("Spike HUD must expose %s signal" % signal_name)
	main.free()

func _validate_main_hud_state_readout(failures: Array[String]) -> void:
	if not ResourceLoader.exists(MAIN_SCENE_PATH):
		return
	if not FileAccess.file_exists(TWO_WAVE_SCENARIO_PATH):
		failures.append("Missing two-wave scenario fixture at %s" % TWO_WAVE_SCENARIO_PATH)
		return

	var packed_main := load(MAIN_SCENE_PATH) as PackedScene
	var main := packed_main.instantiate() as Node
	main.set("scenario_path", TWO_WAVE_SCENARIO_PATH)
	get_root().add_child(main)
	main.call("_ready")

	var hud := main.get_node_or_null("HUD")
	var combat_adapter := main.get_node_or_null("CombatAdapter")
	if hud == null:
		failures.append("Main HUD state readout requires HUD")
	if combat_adapter == null:
		failures.append("Main HUD state readout requires CombatAdapter")

	if failures.is_empty():
		var hud_bar := hud.get_node_or_null("HudBar")
		if hud_bar == null:
			failures.append("HUD must create a mobile-safe HudBar")
		elif not hud_bar is ColorRect:
			failures.append("HUD HudBar must be a ColorRect")
		else:
			if float(hud_bar.get("anchor_right")) < 0.99:
				failures.append("HUD HudBar must anchor across the top of the viewport")
			if float(hud_bar.get("offset_bottom")) > 96.0:
				failures.append("HUD HudBar must stay compact enough for mobile review")

		for value_node_name in ["StateValue", "WaveValue", "LivesValue", "BreachesValue", "EnemiesValue"]:
			var value_node := hud.get_node_or_null("HudBar/%s" % value_node_name)
			if value_node == null:
				failures.append("HUD HudBar must create %s" % value_node_name)
			elif not value_node is Label:
				failures.append("HUD %s must be a Label" % value_node_name)

		var action_button := hud.get_node_or_null("HudBar/ActionButton") as Button
		if action_button == null:
			failures.append("HUD must create a compact terminal ActionButton")
		elif action_button.visible:
			failures.append("HUD ActionButton must stay hidden while a wave is running")

		hud.call("refresh")
		var initial_text := str(hud.call("debug_text"))
		_expect_text(initial_text, "State: running", "HUD must show running state after first wave start", failures)
		_expect_text(initial_text, "Wave: test-wave-1 (1/2)", "HUD must show active fixture wave id and index", failures)
		_expect_text(initial_text, "Lives: 2", "HUD must show scenario-configured lives", failures)
		_expect_text(initial_text, "Breaches: 0", "HUD must show initial breach count", failures)
		_expect_text(initial_text, "Active enemies: 1", "HUD must show active enemy count", failures)
		_expect_label_text(hud, "StateValue", "running", "HUD StateValue must mirror running state", failures)
		_expect_label_text(hud, "WaveValue", "test-wave-1 (1/2)", "HUD WaveValue must mirror active wave label", failures)
		_expect_label_text(hud, "LivesValue", "2", "HUD LivesValue must mirror configured lives", failures)
		_expect_label_text(hud, "BreachesValue", "0", "HUD BreachesValue must mirror breach count", failures)
		_expect_label_text(hud, "EnemiesValue", "1", "HUD EnemiesValue must mirror active enemy count", failures)

		var tracked_enemies := combat_adapter.call("get_tracked_enemies") as Array
		if tracked_enemies.is_empty():
			failures.append("HUD endpoint-breach fixture must start with a tracked enemy")
		else:
			_force_enemy_endpoint_breach(tracked_enemies[0] as Node)
			hud.call("refresh")
			var breach_text := str(hud.call("debug_text"))
			_expect_text(breach_text, "State: wave_clear", "HUD must refresh to wave_clear after non-lethal endpoint breach clears the wave", failures)
			_expect_text(breach_text, "Lives: 1", "HUD must refresh remaining lives after endpoint breach", failures)
			_expect_text(breach_text, "Breaches: 1", "HUD must refresh breach count after endpoint breach", failures)
			_expect_text(breach_text, "Active enemies: 0", "HUD must refresh active enemy count after endpoint breach", failures)
			_expect_label_text(hud, "StateValue", "wave_clear", "HUD StateValue must refresh after wave clear", failures)
			_expect_label_text(hud, "LivesValue", "1", "HUD LivesValue must refresh after endpoint breach", failures)
			_expect_label_text(hud, "BreachesValue", "1", "HUD BreachesValue must refresh after endpoint breach", failures)
			_expect_label_text(hud, "EnemiesValue", "0", "HUD EnemiesValue must refresh after endpoint breach", failures)
			action_button = hud.get_node_or_null("HudBar/ActionButton") as Button
			if action_button == null:
				failures.append("HUD wave-clear action requires ActionButton")
			else:
				if not action_button.visible:
					failures.append("HUD ActionButton must become visible at wave_clear")
				if action_button.text != "Next wave":
					failures.append("HUD ActionButton must show Next wave at wave_clear")

	main.free()

func _validate_main_hud_action_wiring(failures: Array[String]) -> void:
	if not ResourceLoader.exists(MAIN_SCENE_PATH):
		return
	if not FileAccess.file_exists(TWO_WAVE_SCENARIO_PATH):
		failures.append("Missing two-wave scenario fixture at %s" % TWO_WAVE_SCENARIO_PATH)
		return

	var packed_main := load(MAIN_SCENE_PATH) as PackedScene
	var main := packed_main.instantiate() as Node
	main.set("scenario_path", TWO_WAVE_SCENARIO_PATH)
	get_root().add_child(main)
	main.call("_ready")

	var hud := main.get_node_or_null("HUD")
	var game_state := main.get_node_or_null("GameStateAdapter")
	var combat_adapter := main.get_node_or_null("CombatAdapter")
	var wave_state := main.get_node_or_null("WaveStateAdapter")
	if hud == null or game_state == null or combat_adapter == null or wave_state == null:
		failures.append("HUD action wiring requires HUD, game, combat, and wave adapters")
		main.free()
		return

	_force_enemy_endpoint_breach((combat_adapter.call("get_tracked_enemies") as Array)[0] as Node)
	hud.call("refresh")
	var action_button := hud.get_node_or_null("HudBar/ActionButton") as Button
	if action_button == null:
		failures.append("HUD action wiring requires ActionButton")
		main.free()
		return

	action_button.emit_signal("pressed")
	if str(game_state.call("get_state")) != "running":
		failures.append("HUD Next wave action must return game state to running")
	if int(game_state.call("get_current_wave_index")) != 1:
		failures.append("HUD Next wave action must advance to the second wave")
	if str(wave_state.call("active_wave_id")) != "test-wave-2":
		failures.append("HUD Next wave action must start WaveStateAdapter for the second wave")

	_force_enemy_endpoint_breach((combat_adapter.call("get_tracked_enemies") as Array)[0] as Node)
	hud.call("refresh")
	if str(game_state.call("get_state")) != "basic_loss":
		failures.append("HUD restart fixture must reach basic_loss")
	if not action_button.visible:
		failures.append("HUD ActionButton must stay visible at basic_loss")
	if action_button.text != "Restart":
		failures.append("HUD ActionButton must show Restart at basic_loss")

	action_button.emit_signal("pressed")
	if str(game_state.call("get_state")) != "running":
		failures.append("HUD Restart action must restart game state to running")
	if int(game_state.call("get_current_wave_index")) != 0:
		failures.append("HUD Restart action must reset to first wave index")
	if int(combat_adapter.call("get_tracked_enemy_count")) != 1:
		failures.append("HUD Restart action must rebuild first-wave tracked enemy")

	main.free()

func _validate_mobile_hud_layout(failures: Array[String]) -> void:
	var hud_script := load(HUD_SCRIPT_PATH) as Script
	if hud_script == null:
		return

	DisplayServer.window_set_size(Vector2i(390, 844))
	var hud := Control.new()
	hud.set_script(hud_script)
	get_root().add_child(hud)
	hud.call("_ready")
	hud.call("refresh")
	hud.call("_layout_hud_bar_for_width", 390.0)

	var hud_bar := hud.get_node_or_null("HudBar") as ColorRect
	if hud_bar == null:
		failures.append("Mobile HUD layout requires HudBar")
		hud.free()
		return

	if float(hud_bar.get("offset_bottom")) > 96.0:
		failures.append("Mobile HUD bar must stay within the compact top safe area")

	var state_value := hud_bar.get_node_or_null("StateValue") as Label
	var wave_value := hud_bar.get_node_or_null("WaveValue") as Label
	var lives_value := hud_bar.get_node_or_null("LivesValue") as Label
	var enemies_value := hud_bar.get_node_or_null("EnemiesValue") as Label
	if state_value == null or wave_value == null or lives_value == null or enemies_value == null:
		failures.append("Mobile HUD layout requires state, wave, lives, and enemies labels")
		hud.free()
		return

	if wave_value.size.x < 128.0:
		failures.append("Mobile HUD wave value must keep enough width for wave id/index text")
	if lives_value.position.y <= state_value.position.y + 24.0:
		failures.append("Mobile HUD compact layout must wrap lives/breaches/enemies to a second row")
	if enemies_value.position.y != lives_value.position.y:
		failures.append("Mobile HUD second-row values must align vertically")

	hud.free()

func _validate_mobile_capture_orientation(failures: Array[String]) -> void:
	var absolute_path := ProjectSettings.globalize_path(MOBILE_CAPTURE_SCRIPT_PATH)
	if not FileAccess.file_exists(MOBILE_CAPTURE_SCRIPT_PATH):
		failures.append("Missing mobile HUD capture script at %s" % MOBILE_CAPTURE_SCRIPT_PATH)
		return

	var script_text := FileAccess.get_file_as_string(absolute_path)
	if not script_text.contains("Vector2i(844, 390)"):
		failures.append("Mobile HUD capture must use rotated phone landscape viewport 844x390")
	if not script_text.contains("spike_hud_mobile_landscape_preview.png"):
		failures.append("Mobile HUD capture output must name the landscape orientation explicitly")

func _validate_terminal_action_capture_contract(failures: Array[String]) -> void:
	var absolute_path := ProjectSettings.globalize_path(ACTION_CAPTURE_SCRIPT_PATH)
	if not FileAccess.file_exists(ACTION_CAPTURE_SCRIPT_PATH):
		failures.append("Missing terminal HUD action capture script at %s" % ACTION_CAPTURE_SCRIPT_PATH)
		return

	var script_text := FileAccess.get_file_as_string(absolute_path)
	for state_name in ["wave_clear", "basic_win", "basic_loss"]:
		if not script_text.contains(state_name):
			failures.append("Terminal HUD action capture must prepare %s state" % state_name)
		if not script_text.contains("spike_hud_%s_preview.png" % state_name):
			failures.append("Terminal HUD action capture must save desktop %s preview PNG" % state_name)
		if not script_text.contains("spike_hud_%s_mobile_landscape_preview.png" % state_name):
			failures.append("Terminal HUD action capture must save rotated-phone %s preview PNG" % state_name)

	if not script_text.contains("Vector2i(1280, 720)"):
		failures.append("Terminal HUD action capture must include desktop viewport 1280x720")
	if not script_text.contains("Vector2i(844, 390)"):
		failures.append("Terminal HUD action capture must include rotated-phone landscape viewport 844x390")

func _expect_text(text: String, expected: String, message: String, failures: Array[String]) -> void:
	if not text.contains(expected):
		failures.append("%s. Expected to find '%s' in '%s'" % [message, expected, text])

func _expect_label_text(hud: Node, label_name: String, expected: String, message: String, failures: Array[String]) -> void:
	var label := hud.get_node_or_null("HudBar/%s" % label_name) as Label
	if label == null:
		return
	if label.text != expected:
		failures.append("%s. Expected '%s', got '%s'" % [message, expected, label.text])

func _force_enemy_endpoint_breach(enemy: Node) -> void:
	var short_path: Array[Vector3] = [
		Vector3(0.0, 0.18, 0.0),
		Vector3(0.1, 0.18, 0.0),
	]
	enemy.call("setup", short_path, 10.0)
	enemy.call("_process", 1.0)
