extends SceneTree

const TOWER_ATTACK_ADAPTER_PATH := "res://scripts/spike_tower_attack_adapter.gd"
const COMBAT_ADAPTER_PATH := "res://scripts/spike_combat_adapter.gd"
const TOWER_SCENE_PATH := "res://scenes/entities/placeholder_tower.tscn"
const ENEMY_SCENE_PATH := "res://scenes/entities/placeholder_enemy.tscn"
const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const PROJECTILE_MODEL_PATH := "res://assets/models/projectiles/shadow_tower_b4_shot.glb"

class DeadTarget:
	extends Node3D

	func is_alive() -> bool:
		return false

	func apply_damage(_amount: float) -> bool:
		return false

func _init() -> void:
	var failures: Array[String] = []

	if not ResourceLoader.exists(TOWER_ATTACK_ADAPTER_PATH):
		failures.append("Missing tower attack adapter script at %s" % TOWER_ATTACK_ADAPTER_PATH)
	if not ResourceLoader.exists(COMBAT_ADAPTER_PATH):
		failures.append("Missing combat adapter script at %s" % COMBAT_ADAPTER_PATH)
	if not ResourceLoader.exists(TOWER_SCENE_PATH):
		failures.append("Missing tower scene at %s" % TOWER_SCENE_PATH)
	if not ResourceLoader.exists(ENEMY_SCENE_PATH):
		failures.append("Missing enemy scene at %s" % ENEMY_SCENE_PATH)

	if failures.is_empty():
		_validate_tower_attack_adapter(failures)
		_validate_target_filter_and_fire_cue(failures)
	_validate_main_scene_boundary(failures)

	if failures.is_empty():
		print("smoke_tower_attack_adapter: ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _validate_tower_attack_adapter(failures: Array[String]) -> void:
	var attack_script := load(TOWER_ATTACK_ADAPTER_PATH)
	var combat_script := load(COMBAT_ADAPTER_PATH)
	var packed_tower := load(TOWER_SCENE_PATH) as PackedScene
	var packed_enemy := load(ENEMY_SCENE_PATH) as PackedScene

	var attack_adapter := attack_script.new() as Node3D
	var combat_adapter := combat_script.new() as Node
	var tower := packed_tower.instantiate() as Node3D
	var enemy := packed_enemy.instantiate() as Node3D

	get_root().add_child(combat_adapter)
	get_root().add_child(attack_adapter)
	get_root().add_child(tower)
	get_root().add_child(enemy)

	tower.call("setup", Vector3.ZERO)
	enemy.call("configure_visual", {
		"health": 30,
	})
	var path_points: Array[Vector3] = [
		Vector3(1.0, 0.18, 0.0),
		Vector3(2.0, 0.18, 0.0),
	]
	enemy.call("setup", path_points, 0.0)

	if not attack_adapter.has_method("set_combat_adapter"):
		failures.append("Tower attack adapter must expose set_combat_adapter(adapter)")
	if not attack_adapter.has_method("register_tower"):
		failures.append("Tower attack adapter must expose register_tower(tower, data)")
	if not attack_adapter.has_method("advance"):
		failures.append("Tower attack adapter must expose advance(delta)")
	if not attack_adapter.has_method("get_registered_tower_count"):
		failures.append("Tower attack adapter must expose get_registered_tower_count()")

	if failures.is_empty():
		attack_adapter.call("set_combat_adapter", combat_adapter)
		attack_adapter.call("register_tower", tower, {
			"range": 2.0,
			"damage": 10,
			"fireRate": 1.0,
			"projectileModelPath": PROJECTILE_MODEL_PATH,
		})
		combat_adapter.call("register_enemy", enemy, {
			"reward": 4,
		})

		if int(attack_adapter.call("get_registered_tower_count")) != 1:
			failures.append("Tower attack adapter must track registered towers")

		attack_adapter.call("advance", 0.0)
		if int(enemy.get("current_health")) != 20:
			failures.append("Enemy in tower range must receive damage through the combat adapter")
		var first_fire_cue := attack_adapter.get_node_or_null("TowerFireCue") as Node3D
		if first_fire_cue == null:
			failures.append("Tower attack adapter must spawn a short visual fire cue when a tower fires")
		else:
			var expected_cue_position := tower.position + Vector3(0.0, 0.62, 0.0)
			if first_fire_cue.position.distance_to(expected_cue_position) > 0.01:
				failures.append("Tower fire cue must start near the firing tower")
		var first_projectile := attack_adapter.get_node_or_null("ProjectileVisual") as Node3D
		var expected_start := tower.position + Vector3(0.0, 0.78, 0.0)
		var expected_end := enemy.position + Vector3(0.0, 0.55, 0.0)
		if first_projectile == null:
			failures.append("Tower attack adapter must spawn a visual-only projectile node when projectileModelPath exists")
		else:
			if first_projectile.position.distance_to(expected_start) > 0.01:
				failures.append("Projectile visual must start at the firing tower position")
			if first_projectile.get_node_or_null("ProjectileReadabilityGlow") == null:
				failures.append("Projectile visual must include a temporary readability glow")
			if first_projectile.get_node_or_null("ProjectileReadabilityTrail") == null:
				failures.append("Projectile visual must include a temporary readability trail")

		attack_adapter.call("advance", 0.0)
		if int(enemy.get("current_health")) != 20:
			failures.append("Tower attack adapter must respect fireRate cooldown between attacks")
		if first_projectile != null and is_instance_valid(first_projectile):
			var projectile_before_advance := first_projectile.position
			attack_adapter.call("advance", 0.25)
			if first_projectile.position.distance_to(projectile_before_advance) <= 0.01:
				failures.append("Projectile visual must advance over time when the adapter processes delta")
			if first_projectile.position.distance_to(expected_end) >= expected_start.distance_to(expected_end):
				failures.append("Projectile visual must move toward the targeted enemy")
			if int(enemy.get("current_health")) != 20:
				failures.append("Projectile visual movement must not apply extra damage outside tower fire timing")
			attack_adapter.call("advance", 0.25)
			if is_instance_valid(first_projectile) and not first_projectile.is_queued_for_deletion():
				failures.append("Projectile visual must expire after its configured lifetime")
			if first_fire_cue != null and is_instance_valid(first_fire_cue) and not first_fire_cue.is_queued_for_deletion():
				failures.append("Tower fire cue must expire after its configured lifetime")

		attack_adapter.call("advance", 1.0)
		if int(enemy.get("current_health")) != 10:
			failures.append("Tower attack adapter must fire again after cooldown expires")

		attack_adapter.call("advance", 1.0)
		if int(combat_adapter.call("get_kill_count")) != 1:
			failures.append("Lethal tower attack must increment combat adapter kill count")
		if int(combat_adapter.call("get_reward_total")) != 4:
			failures.append("Lethal tower attack must increment combat adapter reward total")
		if attack_adapter.get_node_or_null("ProjectileVisual") == null:
			failures.append("Tower attack adapter must spawn a visual-only projectile node when projectileModelPath exists")

	attack_adapter.free()
	combat_adapter.free()
	if is_instance_valid(tower) and not tower.is_queued_for_deletion():
		tower.free()
	if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
		enemy.free()

func _validate_target_filter_and_fire_cue(failures: Array[String]) -> void:
	var attack_script := load(TOWER_ATTACK_ADAPTER_PATH)
	var combat_script := load(COMBAT_ADAPTER_PATH)
	var packed_tower := load(TOWER_SCENE_PATH) as PackedScene
	var packed_enemy := load(ENEMY_SCENE_PATH) as PackedScene

	var attack_adapter := attack_script.new() as Node3D
	var combat_adapter := combat_script.new() as Node
	var tower := packed_tower.instantiate() as Node3D
	var dead_near_target := DeadTarget.new()
	var live_far_target := packed_enemy.instantiate() as Node3D

	get_root().add_child(combat_adapter)
	get_root().add_child(attack_adapter)
	get_root().add_child(tower)
	get_root().add_child(dead_near_target)
	get_root().add_child(live_far_target)

	tower.call("setup", Vector3.ZERO)
	dead_near_target.position = Vector3(0.25, 0.18, 0.0)
	live_far_target.call("configure_visual", {
		"health": 24,
	})
	var live_path_points: Array[Vector3] = [
		Vector3(1.25, 0.18, 0.0),
		Vector3(2.25, 0.18, 0.0),
	]
	live_far_target.call("setup", live_path_points, 0.0)

	attack_adapter.call("set_combat_adapter", combat_adapter)
	attack_adapter.call("register_tower", tower, {
		"range": 2.0,
		"damage": 8,
		"fireRate": 1.0,
	})
	combat_adapter.call("register_enemy", dead_near_target)
	combat_adapter.call("register_enemy", live_far_target)

	attack_adapter.call("advance", 0.0)
	if int(live_far_target.get("current_health")) != 16:
		failures.append("Tower attack adapter must ignore dead tracked targets and fire at the nearest live target")
	var cue := attack_adapter.get_node_or_null("TowerFireCue") as Node3D
	if cue == null:
		failures.append("Tower attack adapter must spawn a readable fire cue even when no projectile model is configured")

	attack_adapter.free()
	combat_adapter.free()
	if is_instance_valid(tower) and not tower.is_queued_for_deletion():
		tower.free()
	if is_instance_valid(dead_near_target) and not dead_near_target.is_queued_for_deletion():
		dead_near_target.free()
	if is_instance_valid(live_far_target) and not live_far_target.is_queued_for_deletion():
		live_far_target.free()

func _validate_main_scene_boundary(failures: Array[String]) -> void:
	if not ResourceLoader.exists(MAIN_SCENE_PATH):
		failures.append("Missing main scene at %s" % MAIN_SCENE_PATH)
		return

	var packed_main := load(MAIN_SCENE_PATH) as PackedScene
	var main := packed_main.instantiate() as Node
	var attack_adapter := main.get_node_or_null("TowerAttackAdapter")
	if attack_adapter == null:
		failures.append("Main scene must include a scene-level TowerAttackAdapter")
	elif attack_adapter.get_script() == null:
		failures.append("TowerAttackAdapter node must have a valid script")
	main.free()
