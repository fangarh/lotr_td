extends Node3D

@export_file("*.json") var scenario_path: String = "res://data/spike_scenario.json"
@export_file("*.json") var scenario_index_path: String = "res://data/scenario_index.json"

const PLACEHOLDER_TOWER_SCENE := preload("res://scenes/entities/placeholder_tower.tscn")
const PLACEHOLDER_OBSTACLE_SCENE := preload("res://scenes/entities/placeholder_obstacle.tscn")
const PLACEHOLDER_TERRAIN_PROP_SCENE := preload("res://scenes/entities/placeholder_terrain_prop.tscn")
const PLACEHOLDER_ENEMY_SCENE := preload("res://scenes/entities/placeholder_enemy.tscn")
const SCENARIO_CATALOG_SCRIPT := preload("res://scripts/spike_scenario_catalog.gd")
const WAVE_RUNNER_SCRIPT := preload("res://scripts/wave_runner.gd")
const DEBUG_NEXT_WAVE_KEY := KEY_N
const DEBUG_RESTART_KEY := KEY_R

@onready var world: Node3D = $World
@onready var board_view: Node3D = $World/BoardView
@onready var towers: Node3D = $World/Towers
@onready var build_spots: Node3D = $World/BuildSpots
@onready var obstacles: Node3D = $World/Obstacles
@onready var terrain_props: Node3D = $World/TerrainProps
@onready var enemies: Node3D = $World/Enemies
@onready var combat_adapter: Node = $CombatAdapter
@onready var tower_attack_adapter: Node = $TowerAttackAdapter
@onready var obstacle_tower_adapter: Node = $ObstacleTowerAdapter
@onready var wave_state_adapter: Node = $WaveStateAdapter
@onready var game_state_adapter: Node = $GameStateAdapter
@onready var build_state_adapter: Node = $BuildStateAdapter
@onready var hud: Control = $HUD

var _scenario: Dictionary = {}
var _scenario_catalog: RefCounted = SCENARIO_CATALOG_SCRIPT.new()
var _active_scenario_id := ""
var _active_scenario_name := ""
var _tower_catalog: Dictionary = {}
var _obstacle_catalog: Dictionary = {}
var _terrain_prop_catalog: Dictionary = {}
var _enemy_catalog: Dictionary = {}
var _path_lookup: Dictionary = {}
var _path_points: Array[Vector3] = []
var _wave_runner: RefCounted = WAVE_RUNNER_SCRIPT.new()

func available_scenarios() -> Array:
	if _scenario_catalog.has_method("entries"):
		return _scenario_catalog.call("entries") as Array
	return []

func active_scenario_id() -> String:
	return _active_scenario_id

func active_scenario_name() -> String:
	return _active_scenario_name

func load_scenario_by_id(scenario_id: String) -> bool:
	if not _scenario_catalog.has_method("has_scenario") or not bool(_scenario_catalog.call("has_scenario", scenario_id)):
		return false
	var selected_path := str(_scenario_catalog.call("path_for_id", scenario_id))
	var loaded := _load_scenario_from_path(selected_path)
	if loaded.is_empty():
		return false
	_scenario = loaded
	_active_scenario_id = scenario_id
	_active_scenario_name = str(_scenario_catalog.call("name_for_id", scenario_id))
	_cache_catalogs()
	_cache_path()
	_start_runtime_from_scenario()
	hud.call("bind_adapters", game_state_adapter, wave_state_adapter, combat_adapter, _scenario_waves().size())
	hud.call("bind_scenarios", available_scenarios(), _active_scenario_id)
	hud.call("refresh")
	return true

func _ready() -> void:
	_configure_scenario_catalog()
	_load_initial_scenario_data()
	tower_attack_adapter.call("set_combat_adapter", combat_adapter)
	wave_state_adapter.call("set_combat_adapter", combat_adapter)
	var wave_clear_callback := Callable(self, "_on_wave_cleared")
	if wave_state_adapter.has_signal("wave_cleared") and not wave_state_adapter.is_connected("wave_cleared", wave_clear_callback):
		wave_state_adapter.connect("wave_cleared", wave_clear_callback)
	_start_runtime_from_scenario()
	hud.call("bind_adapters", game_state_adapter, wave_state_adapter, combat_adapter, _scenario_waves().size())
	hud.call("bind_scenarios", available_scenarios(), _active_scenario_id)
	_bind_hud_action_signals()

func _configure_scenario_catalog() -> void:
	if scenario_path != "res://data/spike_scenario.json":
		return
	if scenario_index_path != "" and FileAccess.file_exists(scenario_index_path):
		_scenario_catalog.call("load_from_path", scenario_index_path)

func _load_initial_scenario_data() -> void:
	var default_id := ""
	if _scenario_catalog.has_method("default_scenario_id"):
		default_id = str(_scenario_catalog.call("default_scenario_id"))
	if default_id != "" and _scenario_catalog.has_method("path_for_id"):
		var selected_path := str(_scenario_catalog.call("path_for_id", default_id))
		var loaded := _load_scenario_from_path(selected_path)
		if not loaded.is_empty():
			_scenario = loaded
			_active_scenario_id = default_id
			_active_scenario_name = str(_scenario_catalog.call("name_for_id", default_id))
			_cache_catalogs()
			_cache_path()
			return

	_scenario = _load_scenario_from_path(scenario_path)
	_active_scenario_id = str(_scenario.get("id", ""))
	_active_scenario_name = str(_scenario.get("name", _active_scenario_id))
	_cache_catalogs()
	_cache_path()

func _start_runtime_from_scenario() -> void:
	_clear_runtime_node_children(towers)
	_clear_runtime_node_children(build_spots)
	_clear_runtime_node_children(obstacles)
	_clear_runtime_node_children(terrain_props)
	_clear_runtime_node_children(enemies)
	if combat_adapter.has_method("reset_runtime_state"):
		combat_adapter.call("reset_runtime_state")
	if tower_attack_adapter.has_method("reset_runtime_state"):
		tower_attack_adapter.call("reset_runtime_state")
	if obstacle_tower_adapter.has_method("reset_runtime_state"):
		obstacle_tower_adapter.call("reset_runtime_state")
	if obstacle_tower_adapter.has_method("set_path_points"):
		obstacle_tower_adapter.call("set_path_points", _path_points)
	if build_state_adapter.has_method("configure"):
		build_state_adapter.call("configure", _scenario_build_spots(), _tower_catalog, _scenario_starting_gold(), _occupied_cells_from_initial_towers())
	_build_world()
	_spawn_build_spot_markers()
	_spawn_towers()
	_spawn_obstacles()
	_spawn_terrain_props()
	_start_first_wave()

func build_tower_at_spot(spot_id: String, tower_type_id: String) -> bool:
	if not build_state_adapter.has_method("build_at"):
		return false

	var result_variant: Variant = build_state_adapter.call("build_at", spot_id, tower_type_id)
	if typeof(result_variant) != TYPE_DICTIONARY:
		return false

	var result := result_variant as Dictionary
	if not bool(result.get("ok", false)):
		return false

	var spot_variant: Variant = result.get("spot", {})
	if typeof(spot_variant) != TYPE_DICTIONARY:
		return false

	var spot := spot_variant as Dictionary
	var cell := Vector2i(_dict_int(spot, "x", 0), _dict_int(spot, "z", 0))
	var tower := _spawn_tower_at_cell(tower_type_id, cell)
	if tower == null:
		return false

	_spawn_build_spot_markers()
	return true

func get_build_gold() -> int:
	if build_state_adapter.has_method("get_gold"):
		return int(build_state_adapter.call("get_gold"))
	return 0

func get_available_build_spots() -> Array:
	if build_state_adapter.has_method("get_available_build_spots"):
		return build_state_adapter.call("get_available_build_spots") as Array
	return []

func get_tower_build_options() -> Array:
	if build_state_adapter.has_method("get_tower_options"):
		return build_state_adapter.call("get_tower_options") as Array
	return []

func _process(delta: float) -> void:
	if obstacle_tower_adapter.has_method("advance"):
		obstacle_tower_adapter.call("advance", delta)
	_sync_slow_zones_to_spawned_enemies()
	_sync_blockers_to_spawned_enemies()
	for spawn_request: Dictionary in _wave_runner.advance(delta):
		_spawn_enemy_from_request(spawn_request)
	if _wave_runner.is_spawning_complete():
		wave_state_adapter.call("mark_spawning_complete")
	hud.call("refresh")

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var handled := false
	if key_event.keycode == DEBUG_NEXT_WAVE_KEY:
		handled = start_next_wave_manually()
	elif key_event.keycode == DEBUG_RESTART_KEY:
		handled = restart_current_scenario_manually()

	if handled:
		var viewport := get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()

func _load_scenario_from_path(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing scenario data: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Scenario data must be a JSON object: %s" % path)
		return {}

	return parsed as Dictionary

func _cache_catalogs() -> void:
	_tower_catalog = _index_catalog(_catalog_array("towers"))
	_obstacle_catalog = _index_catalog(_catalog_array("obstacles"))
	_terrain_prop_catalog = _index_catalog(_catalog_array("terrainProps"))
	_enemy_catalog = _index_catalog(_catalog_array("enemies"))

func _cache_path() -> void:
	_path_lookup.clear()
	_path_points.clear()

	var path_variant: Variant = _scenario.get("path", {})
	if typeof(path_variant) != TYPE_DICTIONARY:
		return

	var path_data := path_variant as Dictionary
	var points_variant: Variant = path_data.get("points", [])
	if typeof(points_variant) != TYPE_ARRAY:
		return

	for path_item: Variant in points_variant:
		if typeof(path_item) != TYPE_DICTIONARY:
			continue

		var path_cell := path_item as Dictionary
		var cell := Vector2i(_dict_int(path_cell, "x", 0), _dict_int(path_cell, "z", 0))
		_path_lookup[_cell_key(cell.x, cell.y)] = true
		var world_position := board_view.call("tile_to_world", cell) as Vector3
		_path_points.append(world_position + Vector3(0.0, 0.18, 0.0))

func _build_world() -> void:
	var board_variant: Variant = _scenario.get("board", {})
	var board := board_variant as Dictionary
	var path_variant: Variant = _scenario.get("path", {})
	var path_data := path_variant as Dictionary
	board_view.build(board, _path_lookup, path_data)

func _spawn_towers() -> void:
	var towers_variant: Variant = _scenario.get("towers", {})
	if typeof(towers_variant) != TYPE_DICTIONARY:
		return

	var tower_data := towers_variant as Dictionary
	var placements_variant: Variant = tower_data.get("placements", [])
	if typeof(placements_variant) != TYPE_ARRAY:
		return

	for placement_variant: Variant in placements_variant:
		if typeof(placement_variant) != TYPE_DICTIONARY:
			continue

		var placement := placement_variant as Dictionary
		var type_id := _dict_string(placement, "typeId", "")
		var cell := Vector2i(_dict_int(placement, "x", 3), _dict_int(placement, "z", 1))
		_spawn_tower_at_cell(type_id, cell)

func _spawn_tower_at_cell(type_id: String, cell: Vector2i) -> Node3D:
	if type_id != "" and not _tower_catalog.has(type_id):
		push_warning("Skipping unknown tower type in spike scenario: %s" % type_id)
		return null

	var tower_config_variant: Variant = _tower_catalog.get(type_id, {})
	if typeof(tower_config_variant) != TYPE_DICTIONARY:
		push_warning("Skipping invalid tower type in spike scenario: %s" % type_id)
		return null

	var tower_config := tower_config_variant as Dictionary
	var tower := PLACEHOLDER_TOWER_SCENE.instantiate() as Node3D
	var world_position := board_view.call("tile_to_world", cell) as Vector3
	tower.call("configure_visual", tower_config)
	tower.call("setup", world_position)
	towers.add_child(tower)
	tower_attack_adapter.call("register_tower", tower, tower_config)
	if obstacle_tower_adapter.has_method("register_tower"):
		obstacle_tower_adapter.call("register_tower", tower, tower_config, _obstacle_catalog)
	return tower

func _spawn_build_spot_markers() -> void:
	_clear_build_spot_markers()
	for spot_variant: Variant in get_available_build_spots():
		if typeof(spot_variant) != TYPE_DICTIONARY:
			continue

		var spot := spot_variant as Dictionary
		var cell := Vector2i(_dict_int(spot, "x", 0), _dict_int(spot, "z", 0))
		var marker_root := Node3D.new()
		marker_root.name = "BuildSpot_%s" % str(spot.get("id", "spot"))
		marker_root.position = (board_view.call("tile_to_world", cell) as Vector3) + Vector3(0.0, 0.045, 0.0)

		var marker_mesh := MeshInstance3D.new()
		marker_mesh.name = "Marker"
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.26
		cylinder.bottom_radius = 0.26
		cylinder.height = 0.035
		cylinder.radial_segments = 24
		marker_mesh.mesh = cylinder

		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.55, 0.08, 0.04, 0.72)
		material.emission_enabled = true
		material.emission = Color(0.8, 0.08, 0.02)
		material.emission_energy_multiplier = 0.25
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		marker_mesh.material_override = material

		marker_root.add_child(marker_mesh)
		build_spots.add_child(marker_root)

func _clear_build_spot_markers() -> void:
	for child in build_spots.get_children():
		build_spots.remove_child(child)
		child.free()

func _spawn_obstacles() -> void:
	var obstacles_variant: Variant = _scenario.get("obstacles", {})
	if typeof(obstacles_variant) != TYPE_DICTIONARY:
		return

	var obstacle_data := obstacles_variant as Dictionary
	var placements_variant: Variant = obstacle_data.get("placements", [])
	if typeof(placements_variant) != TYPE_ARRAY:
		return

	for placement_variant: Variant in placements_variant:
		if typeof(placement_variant) != TYPE_DICTIONARY:
			continue

		var placement := placement_variant as Dictionary
		var type_id := _dict_string(placement, "typeId", "")
		if type_id != "" and not _obstacle_catalog.has(type_id):
			push_warning("Skipping unknown obstacle type in spike scenario: %s" % type_id)
			continue

		var cell := Vector2i(_dict_int(placement, "x", 4), _dict_int(placement, "z", 3))
		var obstacle := PLACEHOLDER_OBSTACLE_SCENE.instantiate()
		var world_position := board_view.call("tile_to_world", cell) as Vector3
		obstacle.call("setup", world_position)
		obstacles.add_child(obstacle)
		var obstacle_config_variant: Variant = _obstacle_catalog.get(type_id, {})
		if typeof(obstacle_config_variant) == TYPE_DICTIONARY:
			obstacle_tower_adapter.call("register_obstacle", obstacle, obstacle_config_variant as Dictionary, world_position)

func _spawn_terrain_props() -> void:
	var terrain_props_variant: Variant = _scenario.get("terrainProps", {})
	if typeof(terrain_props_variant) != TYPE_DICTIONARY:
		return

	var terrain_prop_data := terrain_props_variant as Dictionary
	var placements_variant: Variant = terrain_prop_data.get("placements", [])
	if typeof(placements_variant) != TYPE_ARRAY:
		return

	for placement_variant: Variant in placements_variant:
		if typeof(placement_variant) != TYPE_DICTIONARY:
			continue

		var placement := placement_variant as Dictionary
		var type_id := _dict_string(placement, "typeId", "")
		if type_id != "" and not _terrain_prop_catalog.has(type_id):
			push_warning("Skipping unknown terrain prop type in spike scenario: %s" % type_id)
			continue

		var cell := Vector2i(_dict_int(placement, "x", 2), _dict_int(placement, "z", 4))
		var prop_data_variant: Variant = _terrain_prop_catalog.get(type_id, {})
		var prop_data := prop_data_variant as Dictionary
		var terrain_prop := PLACEHOLDER_TERRAIN_PROP_SCENE.instantiate()
		var world_position := board_view.call("tile_to_world", cell) as Vector3
		terrain_prop.call("configure_visual", prop_data)
		terrain_prop.call("setup", world_position)
		terrain_props.add_child(terrain_prop)

func _start_first_wave() -> void:
	var waves := _scenario_waves()
	if waves.is_empty():
		return

	_wave_runner.configure(waves)
	game_state_adapter.call("configure_wave_ids", _wave_ids_for_waves(waves))
	game_state_adapter.call("configure_base_lives", _scenario_base_lives())
	if not _wave_runner.start_next_wave():
		return
	var active_wave_id := str(_wave_runner.call("active_wave_id"))
	if not bool(game_state_adapter.call("start_first_wave")):
		return
	_start_active_wave_state(active_wave_id, waves)

func start_next_wave_manually() -> bool:
	if str(game_state_adapter.call("get_state")) != "wave_clear":
		return false

	var waves := _scenario_waves()
	if waves.is_empty():
		return false
	if not _wave_runner.start_next_wave():
		return false

	var active_wave_id := str(_wave_runner.call("active_wave_id"))
	if active_wave_id == "":
		return false
	if not bool(game_state_adapter.call("start_next_wave")):
		return false

	_start_active_wave_state(active_wave_id, waves)
	return true

func restart_current_scenario_manually() -> bool:
	var state := str(game_state_adapter.call("get_state"))
	if state != "basic_win" and state != "basic_loss":
		return false

	_start_runtime_from_scenario()
	hud.call("bind_adapters", game_state_adapter, wave_state_adapter, combat_adapter, _scenario_waves().size())
	hud.call("bind_scenarios", available_scenarios(), _active_scenario_id)
	return true

func _bind_hud_action_signals() -> void:
	var next_wave_callback := Callable(self, "_on_hud_next_wave_requested")
	if hud.has_signal("next_wave_requested") and not hud.is_connected("next_wave_requested", next_wave_callback):
		hud.connect("next_wave_requested", next_wave_callback)

	var restart_callback := Callable(self, "_on_hud_restart_requested")
	if hud.has_signal("restart_requested") and not hud.is_connected("restart_requested", restart_callback):
		hud.connect("restart_requested", restart_callback)

	var scenario_callback := Callable(self, "_on_hud_scenario_selected")
	if hud.has_signal("scenario_selected") and not hud.is_connected("scenario_selected", scenario_callback):
		hud.connect("scenario_selected", scenario_callback)

func _on_hud_next_wave_requested() -> void:
	if start_next_wave_manually():
		hud.call("refresh")

func _on_hud_restart_requested() -> void:
	if restart_current_scenario_manually():
		hud.call("refresh")

func _on_hud_scenario_selected(scenario_id: String) -> void:
	if load_scenario_by_id(scenario_id):
		hud.call("bind_scenarios", available_scenarios(), _active_scenario_id)
		hud.call("refresh")

func _start_active_wave_state(active_wave_id: String, waves: Array) -> void:
	wave_state_adapter.call("start_wave", active_wave_id, _expected_spawn_count_for_wave(waves, active_wave_id))
	for spawn_request: Dictionary in _wave_runner.advance(0.0):
		_spawn_enemy_from_request(spawn_request)
	if _wave_runner.is_spawning_complete():
		wave_state_adapter.call("mark_spawning_complete")

func _on_wave_cleared(_wave_id: String) -> void:
	game_state_adapter.call("mark_wave_clear")

func _spawn_enemy_from_request(spawn_request: Dictionary) -> void:
	if _path_points.is_empty():
		return

	var enemy_id := _dict_string(spawn_request, "enemyId", "")
	var enemy_variant: Variant = _enemy_catalog.get(enemy_id, {})
	if typeof(enemy_variant) != TYPE_DICTIONARY:
		push_warning("Skipping unknown enemy type in spike scenario: %s" % enemy_id)
		return

	var enemy_data := enemy_variant as Dictionary
	var enemy_speed := _dict_float(enemy_data, "speed", 1.0)
	var enemy := PLACEHOLDER_ENEMY_SCENE.instantiate()
	enemy.call("configure_visual", enemy_data)
	_apply_current_slow_zones_to_enemy(enemy)
	_apply_current_blockers_to_enemy(enemy)
	enemy.call("setup", _path_points, enemy_speed)
	if enemy.has_signal("path_breached"):
		var breach_callback := Callable(self, "_on_enemy_path_breached")
		if not enemy.is_connected("path_breached", breach_callback):
			enemy.connect("path_breached", breach_callback)
	if enemy.has_signal("blocker_attack_requested"):
		var blocker_attack_callback := Callable(self, "_on_enemy_blocker_attack_requested")
		if not enemy.is_connected("blocker_attack_requested", blocker_attack_callback):
			enemy.connect("blocker_attack_requested", blocker_attack_callback)
	enemies.add_child(enemy)
	combat_adapter.register_enemy(enemy, enemy_data)
	wave_state_adapter.call("register_spawn", enemy)

func _sync_slow_zones_to_spawned_enemies() -> void:
	for enemy_variant: Variant in enemies.get_children():
		var enemy := enemy_variant as Node
		if enemy == null:
			continue
		_apply_current_slow_zones_to_enemy(enemy)

func _apply_current_slow_zones_to_enemy(enemy: Node) -> void:
	if enemy.has_method("set_slow_zones") and obstacle_tower_adapter.has_method("get_slow_zones"):
		enemy.call("set_slow_zones", obstacle_tower_adapter.call("get_slow_zones"))

func _sync_blockers_to_spawned_enemies() -> void:
	for enemy_variant: Variant in enemies.get_children():
		var enemy := enemy_variant as Node
		if enemy == null:
			continue
		_apply_current_blockers_to_enemy(enemy)

func _apply_current_blockers_to_enemy(enemy: Node) -> void:
	if enemy.has_method("set_blockers") and obstacle_tower_adapter.has_method("get_blockers"):
		enemy.call("set_blockers", obstacle_tower_adapter.call("get_blockers"))

func _on_enemy_path_breached(enemy: Node) -> void:
	game_state_adapter.call("mark_path_breach")
	combat_adapter.call("unregister_enemy", enemy)
	if enemy != null and is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
		enemy.queue_free()

func _on_enemy_blocker_attack_requested(blocker_id: String, amount: float) -> void:
	if obstacle_tower_adapter.has_method("apply_blocker_damage"):
		obstacle_tower_adapter.call("apply_blocker_damage", blocker_id, amount)

func _expected_spawn_count_for_wave(waves: Array, wave_id: String) -> int:
	for wave_variant: Variant in waves:
		if typeof(wave_variant) != TYPE_DICTIONARY:
			continue

		var wave := wave_variant as Dictionary
		if str(wave.get("id", "")) != wave_id:
			continue

		var total := 0
		var spawns_variant: Variant = wave.get("spawns", [])
		if typeof(spawns_variant) != TYPE_ARRAY:
			return 0

		for spawn_variant: Variant in spawns_variant:
			if typeof(spawn_variant) != TYPE_DICTIONARY:
				continue
			var spawn := spawn_variant as Dictionary
			if str(spawn.get("enemyId", "")) == "":
				continue
			total += maxi(int(spawn.get("count", 0)), 0)
		return total

	return 0

func _wave_ids_for_waves(waves: Array) -> Array[String]:
	var wave_ids: Array[String] = []
	for wave_variant: Variant in waves:
		if typeof(wave_variant) != TYPE_DICTIONARY:
			continue

		var wave := wave_variant as Dictionary
		var wave_id := str(wave.get("id", ""))
		if wave_id != "":
			wave_ids.append(wave_id)

	return wave_ids

func _scenario_waves() -> Array:
	var waves_variant: Variant = _scenario.get("waves", [])
	if typeof(waves_variant) != TYPE_ARRAY:
		return []
	return waves_variant as Array

func _scenario_base_lives() -> int:
	var game_state_variant: Variant = _scenario.get("gameState", {})
	if typeof(game_state_variant) != TYPE_DICTIONARY:
		return 1

	var game_state := game_state_variant as Dictionary
	return maxi(_dict_int(game_state, "baseLives", 1), 1)

func _scenario_starting_gold() -> int:
	var game_state_variant: Variant = _scenario.get("gameState", {})
	if typeof(game_state_variant) != TYPE_DICTIONARY:
		return 0

	var game_state := game_state_variant as Dictionary
	return maxi(_dict_int(game_state, "startingGold", 0), 0)

func _scenario_build_spots() -> Array:
	var towers_variant: Variant = _scenario.get("towers", {})
	if typeof(towers_variant) != TYPE_DICTIONARY:
		return []

	var tower_data := towers_variant as Dictionary
	var build_spots_variant: Variant = tower_data.get("buildSpots", [])
	if typeof(build_spots_variant) != TYPE_ARRAY:
		return []

	return build_spots_variant as Array

func _occupied_cells_from_initial_towers() -> Array:
	var occupied: Array = []
	var towers_variant: Variant = _scenario.get("towers", {})
	if typeof(towers_variant) != TYPE_DICTIONARY:
		return occupied

	var tower_data := towers_variant as Dictionary
	var placements_variant: Variant = tower_data.get("placements", [])
	if typeof(placements_variant) != TYPE_ARRAY:
		return occupied

	for placement_variant: Variant in placements_variant:
		if typeof(placement_variant) != TYPE_DICTIONARY:
			continue
		var placement := placement_variant as Dictionary
		occupied.append({
			"x": _dict_int(placement, "x", 0),
			"z": _dict_int(placement, "z", 0),
		})

	return occupied

func _catalog_array(key: String) -> Array:
	var section_variant: Variant = _scenario.get(key, {})
	if typeof(section_variant) != TYPE_DICTIONARY:
		return []

	var section := section_variant as Dictionary
	var catalog_variant: Variant = section.get("catalog", [])
	if typeof(catalog_variant) != TYPE_ARRAY:
		return []

	return catalog_variant as Array

func _index_catalog(catalog: Array) -> Dictionary:
	var indexed: Dictionary = {}
	for entry_variant: Variant in catalog:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue

		var entry := entry_variant as Dictionary
		var id := _dict_string(entry, "id", "")
		if id != "":
			indexed[id] = entry

	return indexed

func _clear_runtime_node_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

func _cell_key(x: int, z: int) -> String:
	return "%d:%d" % [x, z]

func _dict_int(data: Dictionary, key: String, fallback: int) -> int:
	var value: Variant = data.get(key, fallback)
	return int(value)

func _dict_float(data: Dictionary, key: String, fallback: float) -> float:
	var value: Variant = data.get(key, fallback)
	return float(value)

func _dict_string(data: Dictionary, key: String, fallback: String) -> String:
	var value: Variant = data.get(key, fallback)
	return str(value)
