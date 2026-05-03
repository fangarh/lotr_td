extends SceneTree

const COMBAT_ADAPTER_PATH := "res://scripts/spike_combat_adapter.gd"
const ENEMY_SCENE_PATH := "res://scenes/entities/placeholder_enemy.tscn"

func _init() -> void:
	var failures: Array[String] = []

	if not ResourceLoader.exists(COMBAT_ADAPTER_PATH):
		failures.append("Missing combat adapter script at %s" % COMBAT_ADAPTER_PATH)
	elif not ResourceLoader.exists(ENEMY_SCENE_PATH):
		failures.append("Missing enemy scene at %s" % ENEMY_SCENE_PATH)
	else:
		var adapter_script := load(COMBAT_ADAPTER_PATH)
		var adapter := adapter_script.new() as Node
		var packed_enemy := load(ENEMY_SCENE_PATH) as PackedScene
		var enemy := packed_enemy.instantiate() as Node3D

		get_root().add_child(adapter)
		get_root().add_child(enemy)

		enemy.call("configure_visual", {
			"health": 20,
		})
		var path_points: Array[Vector3] = [
			Vector3(0.0, 0.18, 0.0),
			Vector3(1.0, 0.18, 0.0),
		]
		enemy.call("setup", path_points, 1.0)

		if not adapter.has_method("register_enemy"):
			failures.append("Combat adapter must expose register_enemy(enemy, data)")
		if not adapter.has_method("apply_damage"):
			failures.append("Combat adapter must expose apply_damage(enemy, amount)")
		if not adapter.has_method("get_tracked_enemy_count"):
			failures.append("Combat adapter must expose get_tracked_enemy_count()")
		if not adapter.has_method("get_kill_count"):
			failures.append("Combat adapter must expose get_kill_count()")
		if not adapter.has_method("get_reward_total"):
			failures.append("Combat adapter must expose get_reward_total()")
		if not adapter.has_method("get_tracked_enemies"):
			failures.append("Combat adapter must expose get_tracked_enemies() for read-only targeting adapters")

		if failures.is_empty():
			adapter.call("register_enemy", enemy, {
				"reward": 5,
			})
			if int(adapter.call("get_tracked_enemy_count")) != 1:
				failures.append("Combat adapter must track a registered enemy")
			if (adapter.call("get_tracked_enemies") as Array).size() != 1:
				failures.append("Combat adapter must expose registered enemies without transferring ownership")

			var nonlethal_result := bool(adapter.call("apply_damage", enemy, 7.0))
			if nonlethal_result:
				failures.append("Non-lethal adapter damage must not report a kill")
			if int(adapter.call("get_tracked_enemy_count")) != 1:
				failures.append("Non-lethal damage must keep the enemy tracked")
			if not bool(enemy.call("is_alive")):
				failures.append("Non-lethal adapter damage must keep the enemy alive")
			if int(adapter.call("get_kill_count")) != 0:
				failures.append("Non-lethal adapter damage must not increment kill count")
			if int(adapter.call("get_reward_total")) != 0:
				failures.append("Non-lethal adapter damage must not increment reward total")

			var lethal_result := bool(adapter.call("apply_damage", enemy, 99.0))
			if not lethal_result:
				failures.append("Lethal adapter damage must report a kill")
			if int(adapter.call("get_tracked_enemy_count")) != 0:
				failures.append("Lethal damage must untrack the dead enemy")
			if not enemy.is_queued_for_deletion():
				failures.append("Lethal damage must queue the dead enemy for removal")
			if int(adapter.call("get_kill_count")) != 1:
				failures.append("Lethal damage must increment kill count")
			if int(adapter.call("get_reward_total")) != 5:
				failures.append("Lethal damage must add the registered enemy reward")

		adapter.free()
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			enemy.free()

	if failures.is_empty():
		print("smoke_combat_adapter: ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
