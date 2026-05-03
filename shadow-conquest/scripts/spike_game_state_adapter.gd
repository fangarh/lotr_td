extends Node
class_name SpikeGameStateAdapter

signal state_changed(state: String)
signal wave_started(wave_id: String, wave_index: int)
signal wave_cleared(wave_id: String, wave_index: int)
signal path_breached(remaining_lives: int, breach_count: int)
signal base_lives_changed(remaining_lives: int)

const STATE_IDLE := "idle"
const STATE_RUNNING := "running"
const STATE_WAVE_CLEAR := "wave_clear"
const STATE_BASIC_WIN := "basic_win"
const STATE_BASIC_LOSS := "basic_loss"

var _wave_ids: Array[String] = []
var _state := STATE_IDLE
var _current_wave_index := -1
var _active_wave_id := ""
var _base_lives := 1
var _path_breach_count := 0

func configure_wave_ids(wave_ids: Array) -> void:
	_wave_ids.clear()
	for wave_id_variant: Variant in wave_ids:
		var wave_id := str(wave_id_variant)
		if wave_id != "":
			_wave_ids.append(wave_id)

	_current_wave_index = -1
	_active_wave_id = ""
	_set_state(STATE_IDLE)

func configure_base_lives(lives: int) -> void:
	_base_lives = maxi(lives, 1)
	_path_breach_count = 0
	base_lives_changed.emit(_base_lives)

func start_first_wave() -> bool:
	return _start_wave_at(0)

func start_next_wave() -> bool:
	if _state == STATE_BASIC_WIN or _state == STATE_BASIC_LOSS:
		return false

	var next_index := _current_wave_index + 1
	if next_index < 0:
		next_index = 0
	return _start_wave_at(next_index)

func mark_wave_clear() -> void:
	if _state != STATE_RUNNING:
		return

	wave_cleared.emit(_active_wave_id, _current_wave_index)
	if _current_wave_index >= _wave_ids.size() - 1:
		_set_state(STATE_BASIC_WIN)
	else:
		_set_state(STATE_WAVE_CLEAR)

func mark_path_breach() -> bool:
	if _state != STATE_RUNNING:
		return false

	_path_breach_count += 1
	_base_lives = maxi(_base_lives - 1, 0)
	base_lives_changed.emit(_base_lives)
	path_breached.emit(_base_lives, _path_breach_count)
	if _base_lives <= 0:
		_set_state(STATE_BASIC_LOSS)
	return true

func get_state() -> String:
	return _state

func get_current_wave_index() -> int:
	return _current_wave_index

func active_wave_id() -> String:
	return _active_wave_id

func get_base_lives() -> int:
	return _base_lives

func get_path_breach_count() -> int:
	return _path_breach_count

func is_complete() -> bool:
	return _state == STATE_BASIC_WIN or _state == STATE_BASIC_LOSS

func is_loss() -> bool:
	return _state == STATE_BASIC_LOSS

func _start_wave_at(wave_index: int) -> bool:
	if _state == STATE_BASIC_LOSS:
		return false
	if wave_index < 0 or wave_index >= _wave_ids.size():
		return false

	_current_wave_index = wave_index
	_active_wave_id = _wave_ids[_current_wave_index]
	_set_state(STATE_RUNNING)
	wave_started.emit(_active_wave_id, _current_wave_index)
	return true

func _set_state(state: String) -> void:
	if _state == state:
		return

	_state = state
	state_changed.emit(_state)
