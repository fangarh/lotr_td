extends SceneTree

const GAME_STATE_ADAPTER_PATH := "res://scripts/spike_game_state_adapter.gd"
const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const TWO_WAVE_SCENARIO_PATH := "res://tests/fixtures/two_wave_scenario.json"

func _init() -> void:
	var failures: Array[String] = []

	if not ResourceLoader.exists(GAME_STATE_ADAPTER_PATH):
		failures.append("Missing game state adapter script at %s" % GAME_STATE_ADAPTER_PATH)

	if failures.is_empty():
		_validate_game_state_adapter(failures)
	_validate_main_manual_next_wave_flow(failures)
	_validate_main_debug_next_wave_input(failures)
	_validate_main_enemy_endpoint_breach_flow(failures)
	_validate_main_manual_restart_flow(failures)
	_validate_main_debug_restart_input(failures)
	_validate_main_scene_boundary(failures)

	if failures.is_empty():
		print("smoke_game_state_adapter: ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _validate_game_state_adapter(failures: Array[String]) -> void:
	var game_state_script := load(GAME_STATE_ADAPTER_PATH)
	var game_state := game_state_script.new() as Node
	get_root().add_child(game_state)

	for method_name in [
		"configure_wave_ids",
		"start_first_wave",
		"start_next_wave",
		"mark_wave_clear",
		"configure_base_lives",
		"mark_path_breach",
		"get_state",
		"get_current_wave_index",
		"active_wave_id",
		"get_base_lives",
		"get_path_breach_count",
		"is_complete",
		"is_loss",
	]:
		if not game_state.has_method(method_name):
			failures.append("Game state adapter must expose %s()" % method_name)

	for forbidden_method in [
		"apply_damage",
		"register_enemy",
		"register_tower",
		"advance",
	]:
		if game_state.has_method(forbidden_method):
			failures.append("Game state adapter must not own %s()" % forbidden_method)

	if failures.is_empty():
		if str(game_state.call("get_state")) != "idle":
			failures.append("Game state adapter must start idle")
		if int(game_state.call("get_current_wave_index")) != -1:
			failures.append("Idle game state must not have a current wave index")
		if str(game_state.call("active_wave_id")) != "":
			failures.append("Idle game state must not have an active wave id")

		game_state.call("configure_wave_ids", ["wave-a", "wave-b"])
		if not bool(game_state.call("start_first_wave")):
			failures.append("Game state adapter must start the first configured wave")
		if str(game_state.call("get_state")) != "running":
			failures.append("Starting the first wave must set running state")
		if int(game_state.call("get_current_wave_index")) != 0:
			failures.append("First wave must use index 0")
		if str(game_state.call("active_wave_id")) != "wave-a":
			failures.append("First wave must expose the active wave id")

		game_state.call("mark_wave_clear")
		if str(game_state.call("get_state")) != "wave_clear":
			failures.append("Clearing a non-final wave must set wave_clear state")
		if bool(game_state.call("is_complete")):
			failures.append("Clearing a non-final wave must not complete the scenario")

		if not bool(game_state.call("start_next_wave")):
			failures.append("Game state adapter must manually start the next configured wave")
		if str(game_state.call("get_state")) != "running":
			failures.append("Starting the next wave must return to running state")
		if int(game_state.call("get_current_wave_index")) != 1:
			failures.append("Second wave must use index 1")
		if str(game_state.call("active_wave_id")) != "wave-b":
			failures.append("Second wave must expose the active wave id")

		game_state.call("mark_wave_clear")
		if str(game_state.call("get_state")) != "basic_win":
			failures.append("Clearing the final wave must set basic_win state")
		if not bool(game_state.call("is_complete")):
			failures.append("Clearing the final wave must complete the scenario")
		if bool(game_state.call("start_next_wave")):
			failures.append("Game state adapter must not start a wave after basic_win")

		game_state.call("configure_wave_ids", ["breach-wave", "unused-wave"])
		game_state.call("configure_base_lives", 2)
		if int(game_state.call("get_base_lives")) != 2:
			failures.append("Game state adapter must expose configured base lives")
		if int(game_state.call("get_path_breach_count")) != 0:
			failures.append("Game state adapter must start with zero path breaches")
		if bool(game_state.call("mark_path_breach")):
			failures.append("Game state adapter must ignore path breaches while idle")

		if not bool(game_state.call("start_first_wave")):
			failures.append("Game state adapter must start a breach test wave")
		if not bool(game_state.call("mark_path_breach")):
			failures.append("Running game state must accept explicit path breach events")
		if str(game_state.call("get_state")) != "running":
			failures.append("Non-lethal path breach must keep the wave running")
		if int(game_state.call("get_base_lives")) != 1:
			failures.append("Path breach must decrement base lives")
		if int(game_state.call("get_path_breach_count")) != 1:
			failures.append("Path breach must increment breach count")
		if bool(game_state.call("is_loss")):
			failures.append("Non-lethal path breach must not set loss")

		if not bool(game_state.call("mark_path_breach")):
			failures.append("Running game state must accept a lethal path breach")
		if str(game_state.call("get_state")) != "basic_loss":
			failures.append("Lethal path breach must set basic_loss state")
		if not bool(game_state.call("is_loss")):
			failures.append("basic_loss must be reported by is_loss()")
		if not bool(game_state.call("is_complete")):
			failures.append("basic_loss must be a terminal complete state")
		if bool(game_state.call("start_next_wave")):
			failures.append("Game state adapter must not start another wave after basic_loss")
		game_state.call("mark_wave_clear")
		if str(game_state.call("get_state")) != "basic_loss":
			failures.append("Game state adapter must ignore wave clear after basic_loss")

	game_state.free()

func _validate_main_scene_boundary(failures: Array[String]) -> void:
	if not ResourceLoader.exists(MAIN_SCENE_PATH):
		failures.append("Missing main scene at %s" % MAIN_SCENE_PATH)
		return

	var packed_main := load(MAIN_SCENE_PATH) as PackedScene
	var main := packed_main.instantiate() as Node
	var game_state := main.get_node_or_null("GameStateAdapter")
	if game_state == null:
		failures.append("Main scene must include a scene-level GameStateAdapter")
	elif game_state.get_script() == null:
		failures.append("GameStateAdapter node must have a valid script")
	main.free()

func _validate_main_manual_next_wave_flow(failures: Array[String]) -> void:
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

	if not main.has_method("start_next_wave_manually"):
		failures.append("Main must expose start_next_wave_manually() for explicit next-wave flow")
		main.free()
		return

	var game_state := main.get_node_or_null("GameStateAdapter")
	var combat_adapter := main.get_node_or_null("CombatAdapter")
	var wave_state := main.get_node_or_null("WaveStateAdapter")
	if game_state == null:
		failures.append("Main manual next-wave flow requires GameStateAdapter")
	if combat_adapter == null:
		failures.append("Main manual next-wave flow requires CombatAdapter")
	if wave_state == null:
		failures.append("Main manual next-wave flow requires WaveStateAdapter")

	if failures.is_empty():
		if str(game_state.call("get_state")) != "running":
			failures.append("Main must start the first fixture wave in running state")
		if int(game_state.call("get_current_wave_index")) != 0:
			failures.append("Main must start at wave index 0")
		if str(game_state.call("active_wave_id")) != "test-wave-1":
			failures.append("Main must expose the first active fixture wave id")

		if bool(main.call("start_next_wave_manually")):
			failures.append("Main must not start the next wave while the current wave is still running")

		_kill_first_tracked_enemy(combat_adapter)
		if str(game_state.call("get_state")) != "wave_clear":
			failures.append("Main must stay in wave_clear after first wave clear until manual next-wave start")
		if str(wave_state.call("active_wave_id")) != "test-wave-1":
			failures.append("WaveStateAdapter must still report first wave before manual next-wave start")

		if not bool(main.call("start_next_wave_manually")):
			failures.append("Main must manually start the second fixture wave after wave_clear")
		if str(game_state.call("get_state")) != "running":
			failures.append("Manual next-wave start must return game state to running")
		if int(game_state.call("get_current_wave_index")) != 1:
			failures.append("Manual next-wave start must advance game state wave index")
		if str(game_state.call("active_wave_id")) != "test-wave-2":
			failures.append("Manual next-wave start must expose second active wave id")
		if str(wave_state.call("active_wave_id")) != "test-wave-2":
			failures.append("Manual next-wave start must start WaveStateAdapter for the second wave")

		_kill_first_tracked_enemy(combat_adapter)
		if str(game_state.call("get_state")) != "basic_win":
			failures.append("Clearing the final fixture wave must set basic_win")
		if bool(main.call("start_next_wave_manually")):
			failures.append("Main must not start a next wave after basic_win")

	main.free()

func _validate_main_debug_next_wave_input(failures: Array[String]) -> void:
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

	if not main.has_method("_unhandled_input"):
		failures.append("Main must expose a debug next-wave input hook")
		main.free()
		return

	var game_state := main.get_node_or_null("GameStateAdapter")
	var combat_adapter := main.get_node_or_null("CombatAdapter")
	var wave_state := main.get_node_or_null("WaveStateAdapter")
	if game_state == null:
		failures.append("Main debug next-wave input requires GameStateAdapter")
	if combat_adapter == null:
		failures.append("Main debug next-wave input requires CombatAdapter")
	if wave_state == null:
		failures.append("Main debug next-wave input requires WaveStateAdapter")

	if failures.is_empty():
		_press_debug_next_wave_key(main)
		if int(game_state.call("get_current_wave_index")) != 0:
			failures.append("Debug next-wave key must not advance while the current wave is running")

		_kill_first_tracked_enemy(combat_adapter)
		if str(game_state.call("get_state")) != "wave_clear":
			failures.append("Debug next-wave input fixture must reach wave_clear before key advance")

		_press_debug_next_wave_key(main)
		if str(game_state.call("get_state")) != "running":
			failures.append("Debug next-wave key must return game state to running after wave_clear")
		if int(game_state.call("get_current_wave_index")) != 1:
			failures.append("Debug next-wave key must advance to the next wave index")
		if str(game_state.call("active_wave_id")) != "test-wave-2":
			failures.append("Debug next-wave key must expose the second active wave id")
		if str(wave_state.call("active_wave_id")) != "test-wave-2":
			failures.append("Debug next-wave key must start WaveStateAdapter for the second wave")

	main.free()

func _validate_main_enemy_endpoint_breach_flow(failures: Array[String]) -> void:
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
	if game_state == null:
		failures.append("Main endpoint breach flow requires GameStateAdapter")
	if combat_adapter == null:
		failures.append("Main endpoint breach flow requires CombatAdapter")
	if wave_state == null:
		failures.append("Main endpoint breach flow requires WaveStateAdapter")

	if failures.is_empty():
		if int(game_state.call("get_base_lives")) != 2:
			failures.append("Main must configure base lives from the scenario fixture")

		var tracked_enemies := combat_adapter.call("get_tracked_enemies") as Array
		if tracked_enemies.size() != 1:
			failures.append("Endpoint breach fixture must start with one tracked enemy")
		else:
			var enemy := tracked_enemies[0] as Node
			if not enemy.has_signal("path_breached"):
				failures.append("Main endpoint breach flow requires enemy path_breached signal")
			else:
				_force_enemy_endpoint_breach(enemy)
				if int(game_state.call("get_path_breach_count")) != 1:
					failures.append("Enemy endpoint breach must increment game-state breach count")
				if int(game_state.call("get_base_lives")) != 1:
					failures.append("Enemy endpoint breach must decrement configured scenario base lives")
				if str(game_state.call("get_state")) != "wave_clear":
					failures.append("Endpoint breach with remaining configured lives must allow wave_clear when no active enemies remain")
				if bool(game_state.call("is_loss")):
					failures.append("Endpoint breach with remaining configured lives must not set basic_loss")
				if int(combat_adapter.call("get_tracked_enemy_count")) != 0:
					failures.append("Endpoint breach must untrack enemy from combat adapter")
				if int(combat_adapter.call("get_kill_count")) != 0:
					failures.append("Endpoint breach must not count as a kill")
				if int(combat_adapter.call("get_reward_total")) != 0:
					failures.append("Endpoint breach must not grant rewards")
				if int(wave_state.call("get_active_enemy_count")) != 0:
					failures.append("Endpoint breach must remove enemy from active wave state")
				if not enemy.is_queued_for_deletion():
					failures.append("Endpoint breach must queue the breached enemy for removal")

	main.free()

func _validate_main_manual_restart_flow(failures: Array[String]) -> void:
	if not ResourceLoader.exists(MAIN_SCENE_PATH):
		failures.append("Missing main scene at %s" % MAIN_SCENE_PATH)
		return
	if not FileAccess.file_exists(TWO_WAVE_SCENARIO_PATH):
		failures.append("Missing two-wave scenario fixture at %s" % TWO_WAVE_SCENARIO_PATH)
		return

	var packed_main := load(MAIN_SCENE_PATH) as PackedScene
	var win_main := packed_main.instantiate() as Node
	win_main.set("scenario_path", TWO_WAVE_SCENARIO_PATH)
	get_root().add_child(win_main)
	win_main.call("_ready")

	if not win_main.has_method("restart_current_scenario_manually"):
		failures.append("Main must expose restart_current_scenario_manually() for terminal-state local review")
		win_main.free()
		return

	var win_game_state := win_main.get_node_or_null("GameStateAdapter")
	var win_combat_adapter := win_main.get_node_or_null("CombatAdapter")
	var win_wave_state := win_main.get_node_or_null("WaveStateAdapter")
	var win_tower_attack := win_main.get_node_or_null("TowerAttackAdapter")
	if win_game_state == null:
		failures.append("Manual restart flow requires GameStateAdapter")
	if win_combat_adapter == null:
		failures.append("Manual restart flow requires CombatAdapter")
	if win_wave_state == null:
		failures.append("Manual restart flow requires WaveStateAdapter")
	if win_tower_attack == null:
		failures.append("Manual restart flow requires TowerAttackAdapter")

	if failures.is_empty():
		var initial_tower_count := int(win_tower_attack.call("get_registered_tower_count"))
		if bool(win_main.call("restart_current_scenario_manually")):
			failures.append("Manual restart must not run while a wave is running")

		_kill_first_tracked_enemy(win_combat_adapter)
		if str(win_game_state.call("get_state")) != "wave_clear":
			failures.append("Manual restart win fixture must reach wave_clear after first kill")
		if bool(win_main.call("restart_current_scenario_manually")):
			failures.append("Manual restart must not run from non-terminal wave_clear")

		if not bool(win_main.call("start_next_wave_manually")):
			failures.append("Manual restart win fixture must start second wave")
		_kill_first_tracked_enemy(win_combat_adapter)
		if str(win_game_state.call("get_state")) != "basic_win":
			failures.append("Manual restart win fixture must reach basic_win")
		if not bool(win_main.call("restart_current_scenario_manually")):
			failures.append("Manual restart must run after basic_win")
		_expect_restarted_fixture_state(win_game_state, win_combat_adapter, win_wave_state, win_tower_attack, initial_tower_count, "basic_win restart", failures)

	win_main.free()

	var loss_main := packed_main.instantiate() as Node
	loss_main.set("scenario_path", TWO_WAVE_SCENARIO_PATH)
	get_root().add_child(loss_main)
	loss_main.call("_ready")

	var loss_game_state := loss_main.get_node_or_null("GameStateAdapter")
	var loss_combat_adapter := loss_main.get_node_or_null("CombatAdapter")
	var loss_wave_state := loss_main.get_node_or_null("WaveStateAdapter")
	var loss_tower_attack := loss_main.get_node_or_null("TowerAttackAdapter")
	if loss_game_state == null or loss_combat_adapter == null or loss_wave_state == null or loss_tower_attack == null:
		failures.append("Manual restart loss flow requires game/combat/wave/tower adapters")
		loss_main.free()
		return

	var initial_loss_tower_count := int(loss_tower_attack.call("get_registered_tower_count"))
	_force_enemy_endpoint_breach((loss_combat_adapter.call("get_tracked_enemies") as Array)[0] as Node)
	if not bool(loss_main.call("start_next_wave_manually")):
		failures.append("Manual restart loss fixture must start second wave after first breach")
	_force_enemy_endpoint_breach((loss_combat_adapter.call("get_tracked_enemies") as Array)[0] as Node)
	if str(loss_game_state.call("get_state")) != "basic_loss":
		failures.append("Manual restart loss fixture must reach basic_loss")
	if not bool(loss_main.call("restart_current_scenario_manually")):
		failures.append("Manual restart must run after basic_loss")
	_expect_restarted_fixture_state(loss_game_state, loss_combat_adapter, loss_wave_state, loss_tower_attack, initial_loss_tower_count, "basic_loss restart", failures)

	loss_main.free()

func _validate_main_debug_restart_input(failures: Array[String]) -> void:
	if not ResourceLoader.exists(MAIN_SCENE_PATH):
		failures.append("Missing main scene at %s" % MAIN_SCENE_PATH)
		return
	if not FileAccess.file_exists(TWO_WAVE_SCENARIO_PATH):
		failures.append("Missing two-wave scenario fixture at %s" % TWO_WAVE_SCENARIO_PATH)
		return

	var packed_main := load(MAIN_SCENE_PATH) as PackedScene
	var win_main := packed_main.instantiate() as Node
	win_main.set("scenario_path", TWO_WAVE_SCENARIO_PATH)
	get_root().add_child(win_main)
	win_main.call("_ready")

	if not win_main.has_method("_unhandled_input"):
		failures.append("Main must expose a debug restart input hook")
		win_main.free()
		return

	var win_game_state := win_main.get_node_or_null("GameStateAdapter")
	var win_combat_adapter := win_main.get_node_or_null("CombatAdapter")
	var win_wave_state := win_main.get_node_or_null("WaveStateAdapter")
	var win_tower_attack := win_main.get_node_or_null("TowerAttackAdapter")
	if win_game_state == null or win_combat_adapter == null or win_wave_state == null or win_tower_attack == null:
		failures.append("Debug restart input requires game/combat/wave/tower adapters")
		win_main.free()
		return

	var initial_tower_count := int(win_tower_attack.call("get_registered_tower_count"))
	_kill_first_tracked_enemy(win_combat_adapter)
	if str(win_game_state.call("get_state")) != "wave_clear":
		failures.append("Debug restart input win fixture must reach wave_clear")
	_press_debug_restart_key(win_main)
	if str(win_game_state.call("get_state")) != "wave_clear":
		failures.append("Debug restart key must not restart from non-terminal wave_clear")
	if int(win_combat_adapter.call("get_tracked_enemy_count")) != 0:
		failures.append("Debug restart key must not respawn enemies from non-terminal wave_clear")

	if not bool(win_main.call("start_next_wave_manually")):
		failures.append("Debug restart input win fixture must start second wave")
	_kill_first_tracked_enemy(win_combat_adapter)
	if str(win_game_state.call("get_state")) != "basic_win":
		failures.append("Debug restart input win fixture must reach basic_win")
	_press_debug_restart_key(win_main)
	_expect_restarted_fixture_state(win_game_state, win_combat_adapter, win_wave_state, win_tower_attack, initial_tower_count, "debug key basic_win restart", failures)

	win_main.free()

	var loss_main := packed_main.instantiate() as Node
	loss_main.set("scenario_path", TWO_WAVE_SCENARIO_PATH)
	get_root().add_child(loss_main)
	loss_main.call("_ready")

	var loss_game_state := loss_main.get_node_or_null("GameStateAdapter")
	var loss_combat_adapter := loss_main.get_node_or_null("CombatAdapter")
	var loss_wave_state := loss_main.get_node_or_null("WaveStateAdapter")
	var loss_tower_attack := loss_main.get_node_or_null("TowerAttackAdapter")
	if loss_game_state == null or loss_combat_adapter == null or loss_wave_state == null or loss_tower_attack == null:
		failures.append("Debug restart input loss flow requires game/combat/wave/tower adapters")
		loss_main.free()
		return

	var initial_loss_tower_count := int(loss_tower_attack.call("get_registered_tower_count"))
	_force_enemy_endpoint_breach((loss_combat_adapter.call("get_tracked_enemies") as Array)[0] as Node)
	if not bool(loss_main.call("start_next_wave_manually")):
		failures.append("Debug restart input loss fixture must start second wave after first breach")
	_force_enemy_endpoint_breach((loss_combat_adapter.call("get_tracked_enemies") as Array)[0] as Node)
	if str(loss_game_state.call("get_state")) != "basic_loss":
		failures.append("Debug restart input loss fixture must reach basic_loss")
	_press_debug_restart_key(loss_main)
	_expect_restarted_fixture_state(loss_game_state, loss_combat_adapter, loss_wave_state, loss_tower_attack, initial_loss_tower_count, "debug key basic_loss restart", failures)

	loss_main.free()

func _expect_restarted_fixture_state(game_state: Node, combat_adapter: Node, wave_state: Node, tower_attack: Node, expected_tower_count: int, context: String, failures: Array[String]) -> void:
	if str(game_state.call("get_state")) != "running":
		failures.append("%s must restart into running state" % context)
	if int(game_state.call("get_current_wave_index")) != 0:
		failures.append("%s must restart at wave index 0" % context)
	if str(game_state.call("active_wave_id")) != "test-wave-1":
		failures.append("%s must restart test-wave-1" % context)
	if int(game_state.call("get_base_lives")) != 2:
		failures.append("%s must restore configured base lives" % context)
	if int(game_state.call("get_path_breach_count")) != 0:
		failures.append("%s must reset breach count" % context)
	if int(combat_adapter.call("get_tracked_enemy_count")) != 1:
		failures.append("%s must restart with one tracked first-wave enemy" % context)
	if int(combat_adapter.call("get_kill_count")) != 0:
		failures.append("%s must reset kill count" % context)
	if int(combat_adapter.call("get_reward_total")) != 0:
		failures.append("%s must reset reward total" % context)
	if str(wave_state.call("active_wave_id")) != "test-wave-1":
		failures.append("%s must reset WaveStateAdapter active wave" % context)
	if int(wave_state.call("get_active_enemy_count")) != 1:
		failures.append("%s must reset WaveStateAdapter active enemies" % context)
	if int(tower_attack.call("get_registered_tower_count")) != expected_tower_count:
		failures.append("%s must rebuild tower attack registrations without duplication" % context)

func _force_enemy_endpoint_breach(enemy: Node) -> void:
	var short_path: Array[Vector3] = [
		Vector3(0.0, 0.18, 0.0),
		Vector3(0.1, 0.18, 0.0),
	]
	enemy.call("setup", short_path, 10.0)
	enemy.call("_process", 1.0)

func _press_debug_next_wave_key(main: Node) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_N
	event.pressed = true
	main.call("_unhandled_input", event)

func _press_debug_restart_key(main: Node) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_R
	event.pressed = true
	main.call("_unhandled_input", event)

func _kill_first_tracked_enemy(combat_adapter: Node) -> void:
	var tracked_enemies := combat_adapter.call("get_tracked_enemies") as Array
	if tracked_enemies.is_empty():
		return
	var enemy := tracked_enemies[0] as Node
	combat_adapter.call("apply_damage", enemy, 999.0)
