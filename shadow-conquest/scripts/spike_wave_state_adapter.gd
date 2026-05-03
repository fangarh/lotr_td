extends Node
class_name SpikeWaveStateAdapter

signal wave_started(wave_id: String, expected_spawn_count: int)
signal enemy_spawned(enemy: Node)
signal enemy_removed(enemy: Node)
signal wave_cleared(wave_id: String)

var _combat_adapter: Node = null
var _active_wave_id := ""
var _expected_spawn_count := 0
var _spawned_count := 0
var _removed_count := 0
var _spawning_complete := false
var _clear_emitted := false
var _active_enemies: Dictionary = {}

func set_combat_adapter(adapter: Node) -> void:
	if _combat_adapter != null and is_instance_valid(_combat_adapter) and _combat_adapter.has_signal("enemy_removed"):
		var old_callback := Callable(self, "_on_enemy_removed")
		if _combat_adapter.is_connected("enemy_removed", old_callback):
			_combat_adapter.disconnect("enemy_removed", old_callback)

	_combat_adapter = adapter
	if _combat_adapter == null or not is_instance_valid(_combat_adapter):
		return
	if not _combat_adapter.has_signal("enemy_removed"):
		return

	var callback := Callable(self, "_on_enemy_removed")
	if not _combat_adapter.is_connected("enemy_removed", callback):
		_combat_adapter.connect("enemy_removed", callback)

func start_wave(wave_id: String, expected_spawn_count: int = 0) -> void:
	_active_wave_id = wave_id
	_expected_spawn_count = maxi(expected_spawn_count, 0)
	_spawned_count = 0
	_removed_count = 0
	_spawning_complete = false
	_clear_emitted = false
	_active_enemies.clear()
	wave_started.emit(_active_wave_id, _expected_spawn_count)

func register_spawn(enemy: Node) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return

	var enemy_id := enemy.get_instance_id()
	if _active_enemies.has(enemy_id):
		return

	_active_enemies[enemy_id] = enemy
	_spawned_count += 1
	enemy_spawned.emit(enemy)
	_check_wave_clear()

func mark_spawning_complete() -> void:
	_spawning_complete = true
	_check_wave_clear()

func is_wave_clear() -> bool:
	return _spawning_complete and _active_enemies.is_empty() and _spawned_count >= _expected_spawn_count

func active_wave_id() -> String:
	return _active_wave_id

func get_expected_spawn_count() -> int:
	return _expected_spawn_count

func get_spawned_count() -> int:
	return _spawned_count

func get_removed_count() -> int:
	return _removed_count

func get_active_enemy_count() -> int:
	return _active_enemies.size()

func _on_enemy_removed(enemy: Node) -> void:
	if enemy == null:
		return

	var enemy_id := enemy.get_instance_id()
	if not _active_enemies.has(enemy_id):
		return

	_active_enemies.erase(enemy_id)
	_removed_count += 1
	enemy_removed.emit(enemy)
	_check_wave_clear()

func _check_wave_clear() -> void:
	if _clear_emitted:
		return
	if not is_wave_clear():
		return

	_clear_emitted = true
	wave_cleared.emit(_active_wave_id)
