extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const TWO_WAVE_SCENARIO_PATH := "res://tests/fixtures/two_wave_scenario.json"

func _init() -> void:
	var failures: Array[String] = []

	_validate_two_breach_loss_progression(failures)

	if failures.is_empty():
		print("smoke_scenario_progression: ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _validate_two_breach_loss_progression(failures: Array[String]) -> void:
	if not ResourceLoader.exists(MAIN_SCENE_PATH):
		failures.append("Missing main scene at %s" % MAIN_SCENE_PATH)
		return
	if not FileAccess.file_exists(TWO_WAVE_SCENARIO_PATH):
		failures.append("Missing two-wave scenario fixture at %s" % TWO_WAVE_SCENARIO_PATH)
		return

	var packed_main := load(MAIN_SCENE_PATH) as PackedScene
	var main := packed_main.instantiate() as Node
	main.set("scenario_path", TWO_WAVE_SCENARIO_PATH)
	get_root().add_child(main)
	main.call("_ready")

	var game_state := main.get_node_or_null("GameStateAdapter")
	var combat_adapter := main.get_node_or_null("CombatAdapter")
	var wave_state := main.get_node_or_null("WaveStateAdapter")
	var hud := main.get_node_or_null("HUD")
	if game_state == null:
		failures.append("Scenario progression requires GameStateAdapter")
	if combat_adapter == null:
		failures.append("Scenario progression requires CombatAdapter")
	if wave_state == null:
		failures.append("Scenario progression requires WaveStateAdapter")
	if hud == null:
		failures.append("Scenario progression requires HUD readout")

	if failures.is_empty():
		if int(game_state.call("get_base_lives")) != 2:
			failures.append("Two-breach progression fixture must start with two base lives")
		if str(game_state.call("get_state")) != "running":
			failures.append("Two-breach progression must start running the first wave")
		if str(game_state.call("active_wave_id")) != "test-wave-1":
			failures.append("Two-breach progression must start on test-wave-1")

		_force_first_tracked_enemy_endpoint_breach(combat_adapter, failures)
		hud.call("refresh")
		if str(game_state.call("get_state")) != "wave_clear":
			failures.append("First endpoint breach should clear wave 1 without losing while lives remain")
		if int(game_state.call("get_base_lives")) != 1:
			failures.append("First endpoint breach should leave one base life")
		if int(game_state.call("get_path_breach_count")) != 1:
			failures.append("First endpoint breach should set breach count to one")
		if bool(game_state.call("is_loss")):
			failures.append("First endpoint breach should not set loss")
		if int(combat_adapter.call("get_kill_count")) != 0:
			failures.append("First endpoint breach should not count as a kill")
		if int(combat_adapter.call("get_reward_total")) != 0:
			failures.append("First endpoint breach should not grant rewards")
		if not str(hud.call("debug_text")).contains("Lives: 1"):
			failures.append("HUD should refresh after first endpoint breach")

		if not bool(main.call("start_next_wave_manually")):
			failures.append("Manual next-wave start should run after non-lethal breach wave_clear")
		if str(game_state.call("get_state")) != "running":
			failures.append("Manual next-wave start after breach should return game state to running")
		if str(game_state.call("active_wave_id")) != "test-wave-2":
			failures.append("Manual next-wave start after breach should activate test-wave-2")
		if int(wave_state.call("get_active_enemy_count")) != 1:
			failures.append("Second wave should spawn one active enemy after manual start")

		_force_first_tracked_enemy_endpoint_breach(combat_adapter, failures)
		hud.call("refresh")
		if str(game_state.call("get_state")) != "basic_loss":
			failures.append("Second endpoint breach should set basic_loss when configured lives reach zero")
		if int(game_state.call("get_base_lives")) != 0:
			failures.append("Second endpoint breach should leave zero base lives")
		if int(game_state.call("get_path_breach_count")) != 2:
			failures.append("Second endpoint breach should set breach count to two")
		if not bool(game_state.call("is_loss")):
			failures.append("Second endpoint breach should report loss")
		if not bool(game_state.call("is_complete")):
			failures.append("basic_loss should complete the scenario")
		if bool(main.call("start_next_wave_manually")):
			failures.append("Main should not start another wave after basic_loss")
		if int(combat_adapter.call("get_kill_count")) != 0:
			failures.append("Endpoint-breach loss should still not count kills")
		if int(combat_adapter.call("get_reward_total")) != 0:
			failures.append("Endpoint-breach loss should still not grant rewards")
		if int(wave_state.call("get_active_enemy_count")) != 0:
			failures.append("Endpoint-breach loss should remove the active wave enemy")
		var hud_text := str(hud.call("debug_text"))
		if not hud_text.contains("State: basic_loss") or not hud_text.contains("Lives: 0") or not hud_text.contains("Breaches: 2"):
			failures.append("HUD should refresh terminal loss state after second endpoint breach")

	main.free()

func _force_first_tracked_enemy_endpoint_breach(combat_adapter: Node, failures: Array[String]) -> void:
	var tracked_enemies := combat_adapter.call("get_tracked_enemies") as Array
	if tracked_enemies.size() != 1:
		failures.append("Endpoint breach progression expects exactly one tracked enemy, got %d" % tracked_enemies.size())
		return

	var enemy := tracked_enemies[0] as Node
	var short_path: Array[Vector3] = [
		Vector3(0.0, 0.18, 0.0),
		Vector3(0.1, 0.18, 0.0),
	]
	enemy.call("setup", short_path, 10.0)
	enemy.call("_process", 1.0)
