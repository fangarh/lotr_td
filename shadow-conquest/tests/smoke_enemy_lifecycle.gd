extends SceneTree

const ENEMY_SCENE_PATH := "res://scenes/entities/placeholder_enemy.tscn"

func _init() -> void:
	var failures: Array[String] = []

	if not ResourceLoader.exists(ENEMY_SCENE_PATH):
		failures.append("Missing enemy scene at %s" % ENEMY_SCENE_PATH)
	else:
		var packed_scene := load(ENEMY_SCENE_PATH) as PackedScene
		var enemy := packed_scene.instantiate() as Node3D
		if enemy == null:
			failures.append("Enemy scene root must instantiate as Node3D")
		else:
			if not enemy.has_method("apply_damage"):
				failures.append("Enemy must expose apply_damage(amount)")
			if not enemy.has_method("is_alive"):
				failures.append("Enemy must expose is_alive()")
			if not enemy.has_method("get_health_fraction"):
				failures.append("Enemy must expose get_health_fraction()")

			enemy.call("configure_visual", {
				"health": 40,
			})
			var path_points: Array[Vector3] = [
				Vector3(0.0, 0.18, 0.0),
				Vector3(1.0, 0.18, 0.0),
			]
			enemy.call("setup", path_points, 1.0)
			enemy.call("_ready")

			_expect_child(enemy, "HealthBar", failures)
			_expect_child(enemy, "HealthBar/HealthBarBack", failures)
			_expect_child(enemy, "HealthBar/HealthBarFill", failures)

			if enemy.has_method("is_alive") and not bool(enemy.call("is_alive")):
				failures.append("Enemy must start alive after setup")
			if enemy.has_method("get_health_fraction") and not is_equal_approx(float(enemy.call("get_health_fraction")), 1.0):
				failures.append("Enemy health fraction must start full")

			if enemy.has_method("apply_damage"):
				var lethal_before_damage := bool(enemy.call("apply_damage", 10.0))
				if lethal_before_damage:
					failures.append("Enemy must not report death from non-lethal damage")

			if enemy.has_method("get_health_fraction") and not is_equal_approx(float(enemy.call("get_health_fraction")), 0.75):
				failures.append("Enemy health fraction must reflect non-lethal damage")

			var fill := enemy.get_node_or_null("HealthBar/HealthBarFill") as Node3D
			if fill == null:
				failures.append("Enemy health bar fill node must be Node3D")
			elif not is_equal_approx(fill.scale.x, 0.75):
				failures.append("Enemy health bar fill scale must track current health")

			if enemy.has_method("apply_damage"):
				var lethal_after_damage := bool(enemy.call("apply_damage", 100.0))
				if not lethal_after_damage:
					failures.append("Enemy must report death from lethal damage")
			if enemy.has_method("is_alive") and bool(enemy.call("is_alive")):
				failures.append("Enemy must not be alive after lethal damage")
			if enemy.visible:
				failures.append("Enemy must hide itself after lethal damage until lifecycle removal exists")

			enemy.free()

	if failures.is_empty():
		print("smoke_enemy_lifecycle: ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect_child(parent: Node, child_path: String, failures: Array[String]) -> void:
	if parent.get_node_or_null(child_path) == null:
		failures.append("Missing enemy lifecycle child node: %s" % child_path)
