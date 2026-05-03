extends SceneTree

const ENEMY_SCENE_PATH := "res://scenes/entities/placeholder_enemy.tscn"

var _breach_events := 0
var _last_breached_enemy: Node = null
var _blocker_attack_events := 0
var _last_blocker_id := ""
var _last_blocker_damage := 0.0

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
			if not enemy.has_signal("path_breached"):
				failures.append("Enemy proxy must expose path_breached(enemy) signal")
			if not enemy.has_method("has_breached"):
				failures.append("Enemy proxy must expose has_breached()")

			var path_points: Array[Vector3] = [
				Vector3(0.0, 0.18, 0.0),
				Vector3(1.0, 0.18, 0.0),
				Vector3(1.0, 0.18, 1.0),
			]
			enemy.call("setup", path_points, 1.25)
			enemy.call("_ready")

			if not is_equal_approx(float(enemy.get("speed")), 1.25):
				failures.append("Enemy setup must preserve requested speed")
			if enemy.position != path_points[0]:
				failures.append("Enemy setup must place the proxy at the first path point")

			_expect_child(enemy, "GondorBody", failures)
			_expect_child(enemy, "GondorHead", failures)
			_expect_child(enemy, "GondorHelmet", failures)
			_expect_child(enemy, "GondorShield", failures)
			_expect_child(enemy, "GondorSpearShaft", failures)
			_expect_child(enemy, "GondorBanner", failures)

			enemy.call("_process", 0.4)
			if enemy.position.x <= path_points[0].x:
				failures.append("Enemy movement must advance along the configured path")
			if not is_equal_approx(enemy.position.y, path_points[0].y):
				failures.append("Enemy movement must preserve path height")

			if failures.is_empty():
				_breach_events = 0
				_last_breached_enemy = null
				enemy.connect("path_breached", Callable(self, "_on_enemy_path_breached"))
				enemy.call("setup", path_points, 3.0)
				enemy.call("_process", 2.0)
				if _breach_events != 1:
					failures.append("Enemy must emit one path_breached signal at the endpoint")
				if _last_breached_enemy != enemy:
					failures.append("Enemy path_breached signal must include the breached enemy")
				if not bool(enemy.call("has_breached")):
					failures.append("Enemy must report has_breached() after reaching the endpoint")
				if bool(enemy.call("is_alive")):
					failures.append("Breached enemy must leave the live targeting pool")
				if enemy.visible:
					failures.append("Breached enemy must hide itself until lifecycle removal")
				enemy.call("_process", 2.0)
				if _breach_events != 1:
					failures.append("Enemy must not emit repeated path_breached signals after endpoint")

			enemy.free()

		var slow_test_scene := load(ENEMY_SCENE_PATH) as PackedScene
		var slowed_enemy := slow_test_scene.instantiate() as Node3D
		var normal_enemy := slow_test_scene.instantiate() as Node3D
		if slowed_enemy == null or normal_enemy == null:
			failures.append("Enemy scene must instantiate for slow-zone movement coverage")
		else:
			if not slowed_enemy.has_method("set_slow_zones"):
				failures.append("Enemy proxy must expose set_slow_zones(zones)")
			if not slowed_enemy.has_method("current_slow_multiplier"):
				failures.append("Enemy proxy must expose current_slow_multiplier()")

			var slow_path_points: Array[Vector3] = [
				Vector3(0.0, 0.18, 0.0),
				Vector3(4.0, 0.18, 0.0),
			]
			slowed_enemy.call("setup", slow_path_points, 2.0)
			normal_enemy.call("setup", slow_path_points, 2.0)
			if slowed_enemy.has_method("set_slow_zones") and slowed_enemy.has_method("current_slow_multiplier"):
				slowed_enemy.call("set_slow_zones", [{
					"position": Vector3(0.0, 0.18, 0.0),
					"radius": 3.0,
					"slowMultiplier": 0.25,
				}])
				var active_multiplier := float(slowed_enemy.call("current_slow_multiplier"))
				if not is_equal_approx(active_multiplier, 0.25):
					failures.append("Enemy must report the strongest active slow-zone multiplier")

				slowed_enemy.call("_process", 0.5)
				normal_enemy.call("_process", 0.5)
				if slowed_enemy.position.x >= normal_enemy.position.x:
					failures.append("Enemy movement inside a slow zone must advance less than normal movement")

				slowed_enemy.position = Vector3(4.0, 0.18, 0.0)
				var clear_multiplier := float(slowed_enemy.call("current_slow_multiplier"))
				if not is_equal_approx(clear_multiplier, 1.0):
					failures.append("Enemy slow multiplier must return to 1.0 outside slow zones")
			slowed_enemy.free()
			normal_enemy.free()

		var blocker_enemy := slow_test_scene.instantiate() as Node3D
		if blocker_enemy == null:
			failures.append("Enemy scene must instantiate for blocker contact coverage")
		else:
			if not blocker_enemy.has_signal("blocker_attack_requested"):
				failures.append("Enemy proxy must expose blocker_attack_requested(blocker_id, amount)")
			if not blocker_enemy.has_method("set_blockers"):
				failures.append("Enemy proxy must expose set_blockers(blockers)")
			if not blocker_enemy.has_method("get_blocker_count"):
				failures.append("Enemy proxy must expose get_blocker_count()")
			if not blocker_enemy.has_method("current_blocker_id"):
				failures.append("Enemy proxy must expose current_blocker_id()")

			var blocker_path_points: Array[Vector3] = [
				Vector3(0.0, 0.18, 0.0),
				Vector3(4.0, 0.18, 0.0),
			]
			blocker_enemy.call("setup", blocker_path_points, 1.0)
			if blocker_enemy.has_method("set_blockers"):
				blocker_enemy.call("set_blockers", [{
					"id": "blocker-test",
					"position": Vector3(0.0, 0.18, 0.0),
					"radius": 0.7,
					"currentHealth": 8.0,
				}])
			if blocker_enemy.has_method("get_blocker_count") and int(blocker_enemy.call("get_blocker_count")) != 1:
				failures.append("Enemy must store one valid blocker snapshot")
			_blocker_attack_events = 0
			_last_blocker_id = ""
			_last_blocker_damage = 0.0
			if blocker_enemy.has_signal("blocker_attack_requested"):
				blocker_enemy.connect("blocker_attack_requested", Callable(self, "_on_blocker_attack_requested"))
			blocker_enemy.call("_process", 0.5)
			if blocker_enemy.position.x > 0.01:
				failures.append("Enemy must stop movement while touching a blocker")
			if blocker_enemy.has_method("current_blocker_id") and str(blocker_enemy.call("current_blocker_id")) != "blocker-test":
				failures.append("Enemy must report the current blocker id while blocked")
			if _blocker_attack_events < 1:
				failures.append("Enemy must request blocker damage while blocked")
			if _last_blocker_id != "blocker-test":
				failures.append("Enemy blocker damage signal must include blocker id")
			if _last_blocker_damage <= 0.0:
				failures.append("Enemy blocker damage signal must include positive damage")
			if blocker_enemy.has_method("set_blockers"):
				blocker_enemy.call("set_blockers", [])
			blocker_enemy.call("_process", 0.5)
			if blocker_enemy.position.x <= 0.01:
				failures.append("Enemy must resume movement after blocker list no longer contains the blocker")
			blocker_enemy.free()

	if failures.is_empty():
		print("smoke_enemy_proxy: ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect_child(parent: Node, child_name: String, failures: Array[String]) -> void:
	if parent.get_node_or_null(child_name) == null:
		failures.append("Missing enemy child node: %s" % child_name)

func _on_enemy_path_breached(enemy: Node) -> void:
	_breach_events += 1
	_last_breached_enemy = enemy

func _on_blocker_attack_requested(blocker_id: String, amount: float) -> void:
	_blocker_attack_events += 1
	_last_blocker_id = blocker_id
	_last_blocker_damage = amount
