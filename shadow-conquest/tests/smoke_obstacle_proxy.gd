extends SceneTree

const OBSTACLE_SCENE_PATH := "res://scenes/entities/placeholder_obstacle.tscn"
const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const SLOW_ZONE_CAPTURE_SCRIPT_PATH := "res://tests/capture_spike_slow_zone_preview.gd"
const TIMED_SLOW_ZONE_CAPTURE_SCRIPT_PATH := "res://tests/capture_timed_slow_zone_preview.gd"
const BLOCKER_CONTACT_CAPTURE_SCRIPT_PATH := "res://tests/capture_blocker_contact_preview.gd"
const OBSTACLE_TOWER_ADAPTER_PATH := "res://scripts/spike_obstacle_tower_adapter.gd"

func _init() -> void:
	var failures: Array[String] = []

	if not ResourceLoader.exists(OBSTACLE_SCENE_PATH):
		failures.append("Missing obstacle scene at %s" % OBSTACLE_SCENE_PATH)
	else:
		var packed_scene := load(OBSTACLE_SCENE_PATH) as PackedScene
		var obstacle := packed_scene.instantiate() as Node3D
		if obstacle == null:
			failures.append("Obstacle scene root must instantiate as Node3D")
		else:
			obstacle.call("setup", Vector3(4.0, 0.0, 3.0))
			obstacle.call("_ready")
			_expect_child(obstacle, "ShadowPatch", failures)
			_expect_child(obstacle, "RootA", failures)
			_expect_child(obstacle, "WebStrandA", failures)
			_expect_child(obstacle, "MorgulGlow", failures)
			if obstacle.position.x != 4.0 or obstacle.position.z != 3.0:
				failures.append("Obstacle setup must preserve requested world XZ position")
			obstacle.free()

	if not ResourceLoader.exists(MAIN_SCENE_PATH):
		failures.append("Missing main scene at %s" % MAIN_SCENE_PATH)
	else:
		var packed_main := load(MAIN_SCENE_PATH) as PackedScene
		var main := packed_main.instantiate() as Node
		var obstacle_tower_adapter := main.get_node_or_null("ObstacleTowerAdapter")
		if obstacle_tower_adapter == null:
			failures.append("Main scene must include a scene-level ObstacleTowerAdapter")
		elif obstacle_tower_adapter.get_script() == null:
			failures.append("ObstacleTowerAdapter node must have a valid script")
		get_root().add_child(main)
		main.call("_ready")

		var enemy_root := main.get_node_or_null("World/Enemies")
		if enemy_root == null or enemy_root.get_child_count() < 1:
			failures.append("Main scene must spawn an enemy for obstacle slow-zone wiring coverage")
		else:
			var enemy := enemy_root.get_child(0) as Node
			var enemy_initial_slow_zone_count := -1
			if not enemy.has_method("get_slow_zone_count"):
				failures.append("Enemy proxy must expose get_slow_zone_count() for scenario slow-zone wiring")
			else:
				enemy_initial_slow_zone_count = int(enemy.call("get_slow_zone_count"))
				if enemy_initial_slow_zone_count < 1:
					failures.append("Main scene must pass configured obstacle slow zones to spawned enemies")

			if obstacle_tower_adapter != null and obstacle_tower_adapter.has_method("get_slow_zone_count"):
				if int(obstacle_tower_adapter.call("get_slow_zone_count")) < 1:
					failures.append("Main scene ObstacleTowerAdapter must own slow zones from obstacle placements")
				var static_slow_zone_count := int(obstacle_tower_adapter.call("get_slow_zone_count"))
				main.call("_process", 1.2)
				if int(obstacle_tower_adapter.call("get_slow_zone_count")) <= static_slow_zone_count:
					failures.append("Main scene must spawn a timed tower-owned slow zone through ObstacleTowerAdapter")
				if enemy_initial_slow_zone_count >= 0 and int(enemy.call("get_slow_zone_count")) <= enemy_initial_slow_zone_count:
					failures.append("Already-spawned enemies must receive live slow-zone updates from timed tower zones")
				if obstacle_tower_adapter.has_method("get_blocker_count"):
					if int(obstacle_tower_adapter.call("get_blocker_count")) < 1:
						failures.append("Main scene must spawn a temporary blocker through ObstacleTowerAdapter")
					elif obstacle_tower_adapter.has_method("get_blockers"):
						var blockers := obstacle_tower_adapter.call("get_blockers") as Array
						if not blockers.is_empty():
							var blocker := blockers[0] as Dictionary
							if str(blocker.get("sourceTowerId", "")) == "":
								failures.append("Main-scene blocker output must include sourceTowerId")
							var blocker_id := str(blocker.get("id", ""))
							var blocker_hp := float(blocker.get("currentHealth", 0.0))
							enemy.position = blocker.get("position", enemy.position)
							main.call("_process", 0.1)
							enemy.call("_process", 0.6)
							var blockers_after_attack := obstacle_tower_adapter.call("get_blockers") as Array
							var found_blocker_after_attack := false
							for blocker_after_variant: Variant in blockers_after_attack:
								var blocker_after := blocker_after_variant as Dictionary
								if str(blocker_after.get("id", "")) != blocker_id:
									continue
								found_blocker_after_attack = true
								if float(blocker_after.get("currentHealth", blocker_hp)) >= blocker_hp:
									failures.append("Main must bridge enemy blocker attacks into ObstacleTowerAdapter damage")
							if not found_blocker_after_attack and blocker_hp <= 0.0:
								failures.append("Main-scene blocker fixture must start with positive HP before attack coverage")
				else:
					failures.append("Main scene ObstacleTowerAdapter must expose get_blocker_count()")

		main.free()

	_validate_obstacle_tower_adapter(failures)
	_validate_slow_zone_capture_contract(failures)
	_validate_timed_slow_zone_capture_contract(failures)
	_validate_blocker_contact_capture_contract(failures)

	if failures.is_empty():
		print("smoke_obstacle_proxy: ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect_child(parent: Node, child_name: String, failures: Array[String]) -> void:
	if parent.get_node_or_null(child_name) == null:
		failures.append("Missing obstacle child node: %s" % child_name)

func _validate_obstacle_tower_adapter(failures: Array[String]) -> void:
	if not ResourceLoader.exists(OBSTACLE_TOWER_ADAPTER_PATH):
		failures.append("Missing obstacle tower adapter script at %s" % OBSTACLE_TOWER_ADAPTER_PATH)
		return

	var adapter_script := load(OBSTACLE_TOWER_ADAPTER_PATH)
	var adapter := adapter_script.new() as Node
	if adapter == null:
		failures.append("Obstacle tower adapter script must instantiate as Node")
		return

	var obstacle := Node3D.new()
	adapter.call("register_obstacle", obstacle, {
		"effect": "slow-zone",
		"radius": 1.25,
		"slowMultiplier": 0.45,
	}, Vector3(2.0, 0.0, 3.0))

	if int(adapter.call("get_registered_obstacle_count")) != 1:
		failures.append("Obstacle tower adapter must track registered obstacles")
	if int(adapter.call("get_slow_zone_count")) != 1:
		failures.append("Obstacle tower adapter must expose one slow zone for a slow-zone obstacle")

	var slow_zones := adapter.call("get_slow_zones") as Array
	if slow_zones.size() != 1:
		failures.append("Obstacle tower adapter get_slow_zones() must return one zone")
	else:
		var zone := slow_zones[0] as Dictionary
		var zone_position: Vector3 = zone.get("position", Vector3.ZERO)
		if zone_position.distance_to(Vector3(2.0, 0.0, 3.0)) > 0.01:
			failures.append("Obstacle tower adapter slow zone must preserve world position")
		if not is_equal_approx(float(zone.get("radius", 0.0)), 1.25):
			failures.append("Obstacle tower adapter slow zone must preserve configured radius")
		if not is_equal_approx(float(zone.get("slowMultiplier", 1.0)), 0.45):
			failures.append("Obstacle tower adapter slow zone must preserve configured slow multiplier")

	var visual_only_obstacle := Node3D.new()
	adapter.call("register_obstacle", visual_only_obstacle, {
		"effect": "visual-only",
		"radius": 5.0,
		"slowMultiplier": 0.1,
	}, Vector3.ZERO)
	if int(adapter.call("get_registered_obstacle_count")) != 2:
		failures.append("Obstacle tower adapter must track visual-only obstacle registrations")
	if int(adapter.call("get_slow_zone_count")) != 1:
		failures.append("Visual-only obstacle data must not create slow zones")

	adapter.call("reset_runtime_state")
	if int(adapter.call("get_registered_obstacle_count")) != 0 or int(adapter.call("get_slow_zone_count")) != 0:
		failures.append("Obstacle tower adapter reset_runtime_state() must clear registered obstacles and slow zones")

	var tower := Node3D.new()
	tower.position = Vector3(0.0, 0.0, 0.0)
	adapter.call("set_path_points", [
		Vector3(0.75, 0.18, 0.0),
		Vector3(4.0, 0.18, 0.0),
	])
	adapter.call("register_tower", tower, {
		"obstacleEffectId": "corrupted-roots",
		"obstacleSpawnInterval": 1.0,
		"obstacleSpawnLifetime": 0.5,
		"obstacleSpawnRange": 2.0,
	}, {
		"corrupted-roots": {
			"effect": "slow-zone",
			"radius": 0.9,
			"slowMultiplier": 0.5,
		}
	})
	if not adapter.has_method("get_registered_tower_count"):
		failures.append("Obstacle tower adapter must expose get_registered_tower_count()")
	elif int(adapter.call("get_registered_tower_count")) != 1:
		failures.append("Obstacle tower adapter must track registered obstacle towers")

	adapter.call("advance", 0.5)
	if int(adapter.call("get_slow_zone_count")) != 0:
		failures.append("Obstacle tower adapter must not spawn a timed slow zone before interval")
	adapter.call("advance", 0.5)
	if int(adapter.call("get_slow_zone_count")) != 1:
		failures.append("Obstacle tower adapter must spawn one timed slow zone when interval elapses")
	else:
		var spawned_zone := (adapter.call("get_slow_zones") as Array)[0] as Dictionary
		var spawned_position: Vector3 = spawned_zone.get("position", Vector3.ZERO)
		if spawned_position.distance_to(Vector3(0.75, 0.18, 0.0)) > 0.01:
			failures.append("Timed slow zone must spawn at the nearest path point in range")
		if not is_equal_approx(float(spawned_zone.get("radius", 0.0)), 0.9):
			failures.append("Timed slow zone must use the referenced obstacle radius")
		if not is_equal_approx(float(spawned_zone.get("slowMultiplier", 1.0)), 0.5):
			failures.append("Timed slow zone must use the referenced obstacle slow multiplier")
	adapter.call("advance", 0.51)
	if int(adapter.call("get_slow_zone_count")) != 0:
		failures.append("Timed slow zone must expire after configured lifetime")

	adapter.call("reset_runtime_state")
	adapter.call("set_path_points", [Vector3(0.75, 0.18, 0.0)])
	adapter.call("register_tower", Node3D.new(), {
		"obstacleEffectId": "missing-roots",
		"obstacleSpawnInterval": 0.1,
		"obstacleSpawnLifetime": 1.0,
		"obstacleSpawnRange": 2.0,
	}, {
		"corrupted-roots": {
			"effect": "slow-zone",
			"radius": 0.9,
			"slowMultiplier": 0.5,
		}
	})
	adapter.call("advance", 0.2)
	if int(adapter.call("get_slow_zone_count")) != 0:
		failures.append("Missing obstacle effect ids must not spawn timed slow zones")

	adapter.call("reset_runtime_state")
	adapter.call("set_path_points", [
		Vector3(0.75, 0.18, 0.0),
		Vector3(4.0, 0.18, 0.0),
	])
	var blocker_tower := Node3D.new()
	blocker_tower.position = Vector3(0.0, 0.0, 0.0)
	adapter.call("register_tower", blocker_tower, {
		"id": "blocker-test-tower",
		"obstacleEffectId": "orc-blockade",
		"obstacleSpawnInterval": 1.2,
		"obstacleSpawnLifetime": 1.0,
		"obstacleSpawnRange": 2.0,
	}, {
		"orc-blockade": {
			"effect": "temporary-blocker",
			"radius": 0.7,
			"maxHealth": 30.0,
			"lifetime": 1.0,
		}
	})
	if not adapter.has_method("get_blocker_count"):
		failures.append("Obstacle tower adapter must expose get_blocker_count()")
	if not adapter.has_method("get_blockers"):
		failures.append("Obstacle tower adapter must expose get_blockers()")
	if not adapter.has_method("apply_blocker_damage"):
		failures.append("Obstacle tower adapter must expose apply_blocker_damage(blocker_id, amount)")
	adapter.call("advance", 1.2)
	if adapter.has_method("get_blocker_count") and int(adapter.call("get_blocker_count")) != 1:
		failures.append("Temporary blocker tower effect must spawn one runtime blocker when interval elapses")
	elif adapter.has_method("get_blockers") and adapter.has_method("apply_blocker_damage"):
		var blockers := adapter.call("get_blockers") as Array
		var blocker := blockers[0] as Dictionary
		var blocker_id := str(blocker.get("id", ""))
		var blocker_position: Vector3 = blocker.get("position", Vector3.ZERO)
		if blocker_id == "":
			failures.append("Runtime blocker output must include a stable id")
		if blocker_position.distance_to(Vector3(0.75, 0.18, 0.0)) > 0.01:
			failures.append("Runtime blocker must spawn at the nearest path point in range")
		if str(blocker.get("sourceTowerId", "")) != "blocker-test-tower":
			failures.append("Runtime blocker must expose sourceTowerId from tower data")
		if not is_equal_approx(float(blocker.get("radius", 0.0)), 0.7):
			failures.append("Runtime blocker must expose configured radius")
		if not is_equal_approx(float(blocker.get("maxHealth", 0.0)), 30.0):
			failures.append("Runtime blocker must expose configured maxHealth")
		if not is_equal_approx(float(blocker.get("currentHealth", 0.0)), 30.0):
			failures.append("Runtime blocker must start at max health")
		if not is_equal_approx(float(blocker.get("remainingLifetime", 0.0)), 1.0):
			failures.append("Runtime blocker must expose remaining lifetime")
		blocker["currentHealth"] = 1.0
		var blockers_after_mutation := adapter.call("get_blockers") as Array
		var blocker_after_mutation := blockers_after_mutation[0] as Dictionary
		if not is_equal_approx(float(blocker_after_mutation.get("currentHealth", 0.0)), 30.0):
			failures.append("get_blockers() must return read-only copies instead of live blocker state")
		if bool(adapter.call("apply_blocker_damage", blocker_id, -5.0)):
			failures.append("Negative blocker damage must not remove a blocker")
		var damaged := (adapter.call("get_blockers") as Array)[0] as Dictionary
		if not is_equal_approx(float(damaged.get("currentHealth", 0.0)), 30.0):
			failures.append("Negative blocker damage must not reduce HP")
		if bool(adapter.call("apply_blocker_damage", blocker_id, 12.5)):
			failures.append("Non-lethal blocker damage must return false")
		damaged = (adapter.call("get_blockers") as Array)[0] as Dictionary
		if not is_equal_approx(float(damaged.get("currentHealth", 0.0)), 17.5):
			failures.append("Non-lethal blocker damage must reduce currentHealth")
		if not bool(adapter.call("apply_blocker_damage", blocker_id, 18.0)):
			failures.append("Lethal blocker damage must return true")
		if int(adapter.call("get_blocker_count")) != 0:
			failures.append("Lethal blocker damage must remove blocker from output")

	adapter.call("advance", 1.2)
	if adapter.has_method("get_blocker_count") and int(adapter.call("get_blocker_count")) != 1:
		failures.append("Blocker tower must be able to spawn a second blocker after cooldown")
	elif adapter.has_method("get_blockers") and adapter.has_method("apply_blocker_damage"):
		var expiring_blocker := (adapter.call("get_blockers") as Array)[0] as Dictionary
		adapter.call("advance", 1.01)
		if int(adapter.call("get_blocker_count")) != 0:
			failures.append("Runtime blocker must expire after configured lifetime")
		if bool(adapter.call("apply_blocker_damage", str(expiring_blocker.get("id", "")), 1.0)):
			failures.append("Damage against an expired blocker id must return false")

	adapter.free()
	obstacle.free()
	visual_only_obstacle.free()
	tower.free()
	blocker_tower.free()

func _validate_slow_zone_capture_contract(failures: Array[String]) -> void:
	var absolute_path := ProjectSettings.globalize_path(SLOW_ZONE_CAPTURE_SCRIPT_PATH)
	if not FileAccess.file_exists(SLOW_ZONE_CAPTURE_SCRIPT_PATH):
		failures.append("Missing slow-zone capture script at %s" % SLOW_ZONE_CAPTURE_SCRIPT_PATH)
		return

	var script_text := FileAccess.get_file_as_string(absolute_path)
	if not script_text.contains("spike_slow_zone_preview.png"):
		failures.append("Slow-zone capture must save spike_slow_zone_preview.png")
	if not script_text.contains("Vector2i(1280, 720)"):
		failures.append("Slow-zone capture must use desktop viewport 1280x720")
	if not script_text.contains("current_slow_multiplier"):
		failures.append("Slow-zone capture must verify the active enemy slow multiplier before saving")
	if not script_text.contains("SlowZoneReviewMarker"):
		failures.append("Slow-zone capture must add a capture-only SlowZoneReviewMarker")

func _validate_timed_slow_zone_capture_contract(failures: Array[String]) -> void:
	var absolute_path := ProjectSettings.globalize_path(TIMED_SLOW_ZONE_CAPTURE_SCRIPT_PATH)
	if not FileAccess.file_exists(TIMED_SLOW_ZONE_CAPTURE_SCRIPT_PATH):
		failures.append("Missing timed slow-zone capture script at %s" % TIMED_SLOW_ZONE_CAPTURE_SCRIPT_PATH)
		return

	var script_text := FileAccess.get_file_as_string(absolute_path)
	if not script_text.contains("timed_slow_zone_preview.png"):
		failures.append("Timed slow-zone capture must save timed_slow_zone_preview.png")
	if not script_text.contains("Vector2i(1280, 720)"):
		failures.append("Timed slow-zone capture must use desktop viewport 1280x720")
	if not script_text.contains("get_slow_zone_count"):
		failures.append("Timed slow-zone capture must wait for a timed slow-zone count increase")
	if not script_text.contains("current_slow_multiplier"):
		failures.append("Timed slow-zone capture must verify the active enemy slow multiplier before saving")
	if not script_text.contains("TimedSlowZoneReviewMarker"):
		failures.append("Timed slow-zone capture must add a capture-only TimedSlowZoneReviewMarker")

func _validate_blocker_contact_capture_contract(failures: Array[String]) -> void:
	var absolute_path := ProjectSettings.globalize_path(BLOCKER_CONTACT_CAPTURE_SCRIPT_PATH)
	if not FileAccess.file_exists(BLOCKER_CONTACT_CAPTURE_SCRIPT_PATH):
		failures.append("Missing blocker-contact capture script at %s" % BLOCKER_CONTACT_CAPTURE_SCRIPT_PATH)
		return

	var script_text := FileAccess.get_file_as_string(absolute_path)
	if not script_text.contains("blocker_contact_preview.png"):
		failures.append("Blocker-contact capture must save blocker_contact_preview.png")
	if not script_text.contains("Vector2i(1280, 720)"):
		failures.append("Blocker-contact capture must use desktop viewport 1280x720")
	if not script_text.contains("get_blockers"):
		failures.append("Blocker-contact capture must read blocker snapshots from the obstacle adapter")
	if not script_text.contains("current_blocker_id"):
		failures.append("Blocker-contact capture must verify current_blocker_id() before saving")
	if not script_text.contains("BlockerContactReviewMarker"):
		failures.append("Blocker-contact capture must add a capture-only BlockerContactReviewMarker")
