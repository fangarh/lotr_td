extends RefCounted
class_name WaveRunner

const EPSILON := 0.0001

var _waves: Array = []
var _wave_index := -1
var _active_wave: Dictionary = {}
var _spawn_plans: Array[Dictionary] = []
var _elapsed := 0.0
var _running := false

func configure(waves: Array) -> void:
	_waves = waves.duplicate(true)
	_wave_index = -1
	_active_wave.clear()
	_spawn_plans.clear()
	_elapsed = 0.0
	_running = false

func start_next_wave() -> bool:
	if _wave_index + 1 >= _waves.size():
		return false

	_wave_index += 1
	var wave_variant: Variant = _waves[_wave_index]
	if typeof(wave_variant) != TYPE_DICTIONARY:
		_active_wave = {}
		_spawn_plans.clear()
		_running = false
		return false

	_active_wave = wave_variant as Dictionary
	_spawn_plans = _build_spawn_plans(_active_wave)
	_elapsed = 0.0
	_running = not _spawn_plans.is_empty()
	return _running

func advance(delta: float) -> Array:
	if not _running:
		return []

	_elapsed += maxf(delta, 0.0)
	var requests: Array[Dictionary] = []

	for plan in _spawn_plans:
		while plan.emitted < plan.count and _elapsed + EPSILON >= plan.next_time:
			requests.append({
				"waveId": str(_active_wave.get("id", "")),
				"enemyId": plan.enemy_id
			})
			plan.emitted += 1
			plan.next_time += plan.interval

	if is_spawning_complete():
		_running = false

	return requests

func is_spawning_complete() -> bool:
	for plan in _spawn_plans:
		if plan.emitted < plan.count:
			return false
	return true

func active_wave_id() -> String:
	return str(_active_wave.get("id", ""))

func _build_spawn_plans(wave: Dictionary) -> Array[Dictionary]:
	var plans: Array[Dictionary] = []
	var spawns_variant: Variant = wave.get("spawns", [])
	if typeof(spawns_variant) != TYPE_ARRAY:
		return plans

	for spawn_variant: Variant in spawns_variant:
		if typeof(spawn_variant) != TYPE_DICTIONARY:
			continue

		var spawn := spawn_variant as Dictionary
		var enemy_id := str(spawn.get("enemyId", ""))
		var count := maxi(int(spawn.get("count", 0)), 0)
		if enemy_id == "" or count <= 0:
			continue

		plans.append({
			"enemy_id": enemy_id,
			"count": count,
			"emitted": 0,
			"next_time": maxf(float(spawn.get("delay", 0.0)), 0.0),
			"interval": maxf(float(spawn.get("interval", 0.0)), EPSILON)
		})

	return plans
