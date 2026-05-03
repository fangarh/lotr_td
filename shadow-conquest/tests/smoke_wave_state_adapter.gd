extends SceneTree

const WAVE_STATE_ADAPTER_PATH := "res://scripts/spike_wave_state_adapter.gd"
const COMBAT_ADAPTER_PATH := "res://scripts/spike_combat_adapter.gd"
const ENEMY_SCENE_PATH := "res://scenes/entities/placeholder_enemy.tscn"
const MAIN_SCENE_PATH := "res://scenes/main.tscn"

func _init() -> void:
	var failures: Array[String] = []

	if not ResourceLoader.exists(WAVE_STATE_ADAPTER_PATH):
		failures.append("Missing wave state adapter script at %s" % WAVE_STATE_ADAPTER_PATH)
	if not ResourceLoader.exists(COMBAT_ADAPTER_PATH):
		failures.append("Missing combat adapter script at %s" % COMBAT_ADAPTER_PATH)
	if not ResourceLoader.exists(ENEMY_SCENE_PATH):
		failures.append("Missing enemy scene at %s" % ENEMY_SCENE_PATH)

	if failures.is_empty():
		_validate_wave_state_adapter(failures)
	_validate_main_scene_boundary(failures)

	if failures.is_empty():
		print("smoke_wave_state_adapter: ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _validate_wave_state_adapter(failures: Array[String]) -> void:
	var wave_state_script := load(WAVE_STATE_ADAPTER_PATH)
	var combat_script := load(COMBAT_ADAPTER_PATH)
	var packed_enemy := load(ENEMY_SCENE_PATH) as PackedScene

	var wave_state := wave_state_script.new() as Node
	var combat_adapter := combat_script.new() as Node
	var enemy_a := packed_enemy.instantiate() as Node3D
	var enemy_b := packed_enemy.instantiate() as Node3D

	get_root().add_child(wave_state)
	get_root().add_child(combat_adapter)
	get_root().add_child(enemy_a)
	get_root().add_child(enemy_b)

	_configure_enemy(enemy_a)
	_configure_enemy(enemy_b)

	if not wave_state.has_method("set_combat_adapter"):
		failures.append("Wave state adapter must expose set_combat_adapter(adapter)")
	if not wave_state.has_method("start_wave"):
		failures.append("Wave state adapter must expose start_wave(wave_id, expected_spawn_count)")
	if not wave_state.has_method("register_spawn"):
		failures.append("Wave state adapter must expose register_spawn(enemy)")
	if not wave_state.has_method("mark_spawning_complete"):
		failures.append("Wave state adapter must expose mark_spawning_complete()")
	if not wave_state.has_method("is_wave_clear"):
		failures.append("Wave state adapter must expose is_wave_clear()")
	if not wave_state.has_method("get_active_enemy_count"):
		failures.append("Wave state adapter must expose get_active_enemy_count()")
	if not wave_state.has_method("get_spawned_count"):
		failures.append("Wave state adapter must expose get_spawned_count()")
	if not wave_state.has_method("get_removed_count"):
		failures.append("Wave state adapter must expose get_removed_count()")

	if failures.is_empty():
		wave_state.call("set_combat_adapter", combat_adapter)
		wave_state.call("start_wave", "wave-smoke", 2)

		if bool(wave_state.call("is_wave_clear")):
			failures.append("Started wave must not be clear before spawning is complete")

		combat_adapter.call("register_enemy", enemy_a, {"reward": 1})
		wave_state.call("register_spawn", enemy_a)
		if int(wave_state.call("get_spawned_count")) != 1:
			failures.append("Wave state adapter must count spawned enemies")
		if int(wave_state.call("get_active_enemy_count")) != 1:
			failures.append("Wave state adapter must count active spawned enemies")

		wave_state.call("mark_spawning_complete")
		if bool(wave_state.call("is_wave_clear")):
			failures.append("Wave must not clear while a spawned enemy is still active")

		combat_adapter.call("apply_damage", enemy_a, 99.0)
		if int(wave_state.call("get_removed_count")) != 1:
			failures.append("Wave state adapter must observe combat enemy_removed")
		if bool(wave_state.call("is_wave_clear")):
			failures.append("Wave must not clear until expected spawns have occurred")

		combat_adapter.call("register_enemy", enemy_b, {"reward": 1})
		wave_state.call("register_spawn", enemy_b)
		combat_adapter.call("apply_damage", enemy_b, 99.0)

		if int(wave_state.call("get_spawned_count")) != 2:
			failures.append("Wave state adapter must keep total spawned count")
		if int(wave_state.call("get_active_enemy_count")) != 0:
			failures.append("Wave state adapter must remove dead enemies from active count")
		if int(wave_state.call("get_removed_count")) != 2:
			failures.append("Wave state adapter must keep total removed count")
		if not bool(wave_state.call("is_wave_clear")):
			failures.append("Wave must clear when spawning is complete and active enemies are gone")

	wave_state.free()
	combat_adapter.free()
	if is_instance_valid(enemy_a) and not enemy_a.is_queued_for_deletion():
		enemy_a.free()
	if is_instance_valid(enemy_b) and not enemy_b.is_queued_for_deletion():
		enemy_b.free()

func _validate_main_scene_boundary(failures: Array[String]) -> void:
	if not ResourceLoader.exists(MAIN_SCENE_PATH):
		failures.append("Missing main scene at %s" % MAIN_SCENE_PATH)
		return

	var packed_main := load(MAIN_SCENE_PATH) as PackedScene
	var main := packed_main.instantiate() as Node
	var wave_state := main.get_node_or_null("WaveStateAdapter")
	if wave_state == null:
		failures.append("Main scene must include a scene-level WaveStateAdapter")
	elif wave_state.get_script() == null:
		failures.append("WaveStateAdapter node must have a valid script")
	main.free()

func _configure_enemy(enemy: Node3D) -> void:
	enemy.call("configure_visual", {"health": 12})
	var path_points: Array[Vector3] = [
		Vector3(0.0, 0.18, 0.0),
		Vector3(1.0, 0.18, 0.0),
	]
	enemy.call("setup", path_points, 0.0)
