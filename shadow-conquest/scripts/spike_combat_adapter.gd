extends Node
class_name SpikeCombatAdapter

signal enemy_killed(enemy: Node, reward: int)
signal enemy_removed(enemy: Node)
signal enemy_registered(enemy: Node)

var _tracked_enemies: Dictionary = {}
var _enemy_rewards: Dictionary = {}
var _kill_count := 0
var _reward_total := 0

func register_enemy(enemy: Node, data: Dictionary = {}) -> void:
	if enemy == null:
		return

	var enemy_id := enemy.get_instance_id()
	if _tracked_enemies.has(enemy_id):
		_enemy_rewards[enemy_id] = _reward_from_data(data)
		return

	_tracked_enemies[enemy_id] = enemy
	_enemy_rewards[enemy_id] = _reward_from_data(data)

	if enemy.has_signal("died"):
		var death_callback := Callable(self, "_on_enemy_died")
		if not enemy.is_connected("died", death_callback):
			enemy.connect("died", death_callback)

	enemy_registered.emit(enemy)

func reset_runtime_state() -> void:
	_tracked_enemies.clear()
	_enemy_rewards.clear()
	_kill_count = 0
	_reward_total = 0

func apply_damage(enemy: Node, amount: float) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false
	if not enemy.has_method("apply_damage"):
		return false

	var lethal := bool(enemy.call("apply_damage", amount))
	if lethal and _is_tracked(enemy):
		_handle_enemy_death(enemy)
		return true

	if enemy.has_method("is_alive") and not bool(enemy.call("is_alive")):
		if _is_tracked(enemy):
			_handle_enemy_death(enemy)
		return true

	return lethal

func unregister_enemy(enemy: Node) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return

	var enemy_id := enemy.get_instance_id()
	if not _tracked_enemies.has(enemy_id):
		return

	_tracked_enemies.erase(enemy_id)
	_enemy_rewards.erase(enemy_id)
	enemy_removed.emit(enemy)

func get_tracked_enemy_count() -> int:
	return _tracked_enemies.size()

func get_tracked_enemies() -> Array:
	var enemies: Array = []
	for enemy_variant: Variant in _tracked_enemies.values():
		var enemy := enemy_variant as Node
		if enemy != null and is_instance_valid(enemy):
			enemies.append(enemy)
	return enemies

func get_kill_count() -> int:
	return _kill_count

func get_reward_total() -> int:
	return _reward_total

func get_reward_count() -> int:
	return _reward_total

func _on_enemy_died(enemy: Node) -> void:
	_handle_enemy_death(enemy)

func _handle_enemy_death(enemy: Node) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return

	var enemy_id := enemy.get_instance_id()
	if not _tracked_enemies.has(enemy_id):
		return

	var reward := int(_enemy_rewards.get(enemy_id, 0))
	_tracked_enemies.erase(enemy_id)
	_enemy_rewards.erase(enemy_id)
	_kill_count += 1
	_reward_total += reward
	enemy_killed.emit(enemy, reward)
	enemy_removed.emit(enemy)

	if not enemy.is_queued_for_deletion():
		enemy.queue_free()

func _is_tracked(enemy: Node) -> bool:
	return enemy != null and is_instance_valid(enemy) and _tracked_enemies.has(enemy.get_instance_id())

func _reward_from_data(data: Dictionary) -> int:
	return maxi(int(data.get("reward", 0)), 0)
