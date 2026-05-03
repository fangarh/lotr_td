extends Node
class_name SpikeObstacleTowerAdapter

signal obstacle_registered(obstacle: Node3D)

var _registered_obstacles: Dictionary = {}
var _registered_towers: Dictionary = {}
var _slow_zones: Array[Dictionary] = []
var _spawned_slow_zones: Array[Dictionary] = []
var _blockers: Array[Dictionary] = []
var _path_points: Array[Vector3] = []
var _next_blocker_id := 1

func reset_runtime_state() -> void:
	_registered_obstacles.clear()
	_registered_towers.clear()
	_slow_zones.clear()
	_spawned_slow_zones.clear()
	_blockers.clear()
	_next_blocker_id = 1

func set_path_points(path_points: Array) -> void:
	_path_points.clear()
	for point_variant: Variant in path_points:
		if point_variant is Vector3:
			_path_points.append(point_variant as Vector3)

func register_obstacle(obstacle: Node3D, data: Dictionary = {}, world_position: Vector3 = Vector3.ZERO) -> void:
	if obstacle == null:
		return

	var obstacle_id := obstacle.get_instance_id()
	_registered_obstacles[obstacle_id] = {
		"node": obstacle,
		"effect": _dict_string(data, "effect", ""),
	}

	if _dict_string(data, "effect", "") == "slow-zone":
		_slow_zones.append({
			"position": world_position,
			"radius": maxf(_dict_float(data, "radius", 0.75), 0.0),
			"slowMultiplier": clampf(_dict_float(data, "slowMultiplier", 1.0), 0.0, 1.0),
		})

	obstacle_registered.emit(obstacle)

func get_registered_obstacle_count() -> int:
	return _registered_obstacles.size()

func register_tower(tower: Node3D, data: Dictionary = {}, obstacle_catalog: Dictionary = {}) -> void:
	if tower == null:
		return

	var effect_id := _dict_string(data, "obstacleEffectId", "")
	if effect_id == "" or not obstacle_catalog.has(effect_id):
		return

	var effect_variant: Variant = obstacle_catalog.get(effect_id, {})
	if typeof(effect_variant) != TYPE_DICTIONARY:
		return

	var effect_data := effect_variant as Dictionary
	var effect_type := _dict_string(effect_data, "effect", "")
	if effect_type != "slow-zone" and effect_type != "temporary-blocker":
		return

	_registered_towers[tower.get_instance_id()] = {
		"node": tower,
		"sourceTowerId": _dict_string(data, "id", str(tower.get_instance_id())),
		"effect": effect_data,
		"effectType": effect_type,
		"interval": maxf(_dict_float(data, "obstacleSpawnInterval", 1.0), 0.01),
		"hasLifetime": data.has("obstacleSpawnLifetime") or effect_data.has("lifetime"),
		"lifetime": maxf(float(data.get("obstacleSpawnLifetime", effect_data.get("lifetime", 1.0))), 0.01),
		"range": maxf(_dict_float(data, "obstacleSpawnRange", 1.0), 0.0),
		"cooldown": maxf(_dict_float(data, "obstacleSpawnInterval", 1.0), 0.01),
	}

func get_registered_tower_count() -> int:
	return _registered_towers.size()

func get_slow_zone_count() -> int:
	return _slow_zones.size()

func get_slow_zones() -> Array[Dictionary]:
	return _slow_zones.duplicate(true)

func get_blocker_count() -> int:
	return _blockers.size()

func get_blockers() -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	for blocker in _blockers:
		output.append(_blocker_output(blocker))
	return output

func apply_blocker_damage(blocker_id: String, amount: float) -> bool:
	var safe_amount := maxf(amount, 0.0)
	if safe_amount <= 0.0:
		return false

	for index in range(_blockers.size() - 1, -1, -1):
		var blocker := _blockers[index] as Dictionary
		if str(blocker.get("id", "")) != blocker_id:
			continue

		var current_health := maxf(float(blocker.get("currentHealth", 0.0)) - safe_amount, 0.0)
		if current_health <= 0.0:
			_blockers.remove_at(index)
			return true

		blocker["currentHealth"] = current_health
		_blockers[index] = blocker
		return false

	return false

func advance(delta: float) -> void:
	var safe_delta := maxf(delta, 0.0)
	_age_spawned_slow_zones(safe_delta)
	_age_blockers(safe_delta)
	_advance_registered_towers(safe_delta)

func _advance_registered_towers(delta: float) -> void:
	var tower_ids := _registered_towers.keys()
	for tower_id_variant: Variant in tower_ids:
		var tower_id := int(tower_id_variant)
		if not _registered_towers.has(tower_id):
			continue

		var tower_state := _registered_towers[tower_id] as Dictionary
		var tower := tower_state.get("node") as Node3D
		if tower == null or not is_instance_valid(tower):
			_registered_towers.erase(tower_id)
			continue

		var cooldown := maxf(float(tower_state.get("cooldown", 0.0)) - delta, 0.0)
		if cooldown > 0.0:
			tower_state["cooldown"] = cooldown
			_registered_towers[tower_id] = tower_state
			continue

		var effect_type := str(tower_state.get("effectType", ""))
		if effect_type == "slow-zone":
			_spawn_tower_slow_zone(tower, tower_state)
		elif effect_type == "temporary-blocker":
			_spawn_tower_blocker(tower, tower_state)
		tower_state["cooldown"] = maxf(float(tower_state.get("interval", 1.0)), 0.01)
		_registered_towers[tower_id] = tower_state

func _spawn_tower_slow_zone(tower: Node3D, tower_state: Dictionary) -> void:
	var spawn_position_variant: Variant = _nearest_path_point_in_range(tower, float(tower_state.get("range", 0.0)))
	if spawn_position_variant == null:
		return
	var spawn_position := spawn_position_variant as Vector3

	var effect_data := tower_state.get("effect", {}) as Dictionary
	var zone := {
		"position": spawn_position,
		"radius": maxf(_dict_float(effect_data, "radius", 0.75), 0.0),
		"slowMultiplier": clampf(_dict_float(effect_data, "slowMultiplier", 1.0), 0.0, 1.0),
	}
	_slow_zones.append(zone)
	_spawned_slow_zones.append({
		"zone": zone,
		"remaining": maxf(float(tower_state.get("lifetime", 1.0)), 0.01),
	})

func _spawn_tower_blocker(tower: Node3D, tower_state: Dictionary) -> void:
	var spawn_position_variant: Variant = _nearest_path_point_in_range(tower, float(tower_state.get("range", 0.0)))
	if spawn_position_variant == null:
		return
	var spawn_position := spawn_position_variant as Vector3

	var effect_data := tower_state.get("effect", {}) as Dictionary
	var blocker := {
		"id": "blocker-%d" % _next_blocker_id,
		"position": spawn_position,
		"radius": maxf(_dict_float(effect_data, "radius", 0.75), 0.0),
		"maxHealth": maxf(_dict_float(effect_data, "maxHealth", 1.0), 0.01),
		"currentHealth": maxf(_dict_float(effect_data, "maxHealth", 1.0), 0.01),
		"sourceTowerId": str(tower_state.get("sourceTowerId", "")),
		"hasLifetime": bool(tower_state.get("hasLifetime", false)),
	}
	if bool(blocker.get("hasLifetime", false)):
		blocker["remainingLifetime"] = maxf(float(tower_state.get("lifetime", 1.0)), 0.01)

	_next_blocker_id += 1
	_blockers.append(blocker)

func _age_spawned_slow_zones(delta: float) -> void:
	for index in range(_spawned_slow_zones.size() - 1, -1, -1):
		var state := _spawned_slow_zones[index] as Dictionary
		var remaining := float(state.get("remaining", 0.0)) - delta
		if remaining > 0.0:
			state["remaining"] = remaining
			_spawned_slow_zones[index] = state
			continue

		var zone := state.get("zone", {}) as Dictionary
		_slow_zones.erase(zone)
		_spawned_slow_zones.remove_at(index)

func _age_blockers(delta: float) -> void:
	for index in range(_blockers.size() - 1, -1, -1):
		var blocker := _blockers[index] as Dictionary
		if not bool(blocker.get("hasLifetime", false)):
			continue

		var remaining := float(blocker.get("remainingLifetime", 0.0)) - delta
		if remaining > 0.0:
			blocker["remainingLifetime"] = remaining
			_blockers[index] = blocker
			continue

		_blockers.remove_at(index)

func _blocker_output(blocker: Dictionary) -> Dictionary:
	var output := {
		"id": str(blocker.get("id", "")),
		"position": blocker.get("position", Vector3.ZERO),
		"radius": float(blocker.get("radius", 0.0)),
		"maxHealth": float(blocker.get("maxHealth", 0.0)),
		"currentHealth": float(blocker.get("currentHealth", 0.0)),
		"sourceTowerId": str(blocker.get("sourceTowerId", "")),
	}
	if bool(blocker.get("hasLifetime", false)):
		output["remainingLifetime"] = float(blocker.get("remainingLifetime", 0.0))
	return output

func _nearest_path_point_in_range(tower: Node3D, spawn_range: float) -> Variant:
	var best_point: Variant = null
	var best_distance := INF
	var tower_position := _node_position(tower)
	for point in _path_points:
		var flat_distance := Vector2(tower_position.x, tower_position.z).distance_to(Vector2(point.x, point.z))
		if flat_distance > spawn_range or flat_distance >= best_distance:
			continue
		best_point = point
		best_distance = flat_distance
	return best_point

func _node_position(node: Node3D) -> Vector3:
	if node.is_inside_tree():
		return node.global_position
	return node.position

func _dict_float(data: Dictionary, key: String, fallback: float) -> float:
	var value: Variant = data.get(key, fallback)
	return float(value)

func _dict_string(data: Dictionary, key: String, fallback: String) -> String:
	var value: Variant = data.get(key, fallback)
	return str(value)
