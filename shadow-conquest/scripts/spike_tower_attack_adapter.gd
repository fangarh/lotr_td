extends Node3D
class_name SpikeTowerAttackAdapter

signal tower_registered(tower: Node3D)
signal tower_fired(tower: Node3D, enemy: Node, damage: float)

@export var auto_advance := true
@export_range(0.05, 3.0, 0.05) var projectile_visual_lifetime := 0.5
@export_range(0.05, 1.0, 0.05) var fire_cue_lifetime := 0.2

const PROJECTILE_START_OFFSET := Vector3(0.0, 0.78, 0.0)
const PROJECTILE_END_OFFSET := Vector3(0.0, 0.55, 0.0)
const FIRE_CUE_OFFSET := Vector3(0.0, 0.62, 0.0)
const PROJECTILE_READABILITY_COLOR := Color(1.0, 0.16, 0.04, 0.78)

var _combat_adapter: Node = null
var _registered_towers: Dictionary = {}
var _projectile_visual_ages: Dictionary = {}
var _fire_cue_ages: Dictionary = {}

func _process(delta: float) -> void:
	if auto_advance:
		advance(delta)

func set_combat_adapter(adapter: Node) -> void:
	_combat_adapter = adapter

func register_tower(tower: Node3D, data: Dictionary = {}) -> void:
	if tower == null:
		return

	var tower_id := tower.get_instance_id()
	_registered_towers[tower_id] = {
		"node": tower,
		"range": maxf(_dict_float(data, "range", 0.0), 0.0),
		"damage": maxf(_dict_float(data, "damage", 0.0), 0.0),
		"fireRate": maxf(_dict_float(data, "fireRate", 1.0), 0.01),
		"projectileModelPath": _dict_string(data, "projectileModelPath", ""),
		"cooldown": 0.0,
	}
	tower_registered.emit(tower)

func reset_runtime_state() -> void:
	_registered_towers.clear()
	_projectile_visual_ages.clear()
	_fire_cue_ages.clear()
	for child in get_children():
		child.queue_free()

func get_registered_tower_count() -> int:
	return _registered_towers.size()

func advance(delta: float) -> void:
	_age_projectile_visuals(delta)
	_age_fire_cues(delta)

	if _combat_adapter == null or not is_instance_valid(_combat_adapter):
		return
	if not _combat_adapter.has_method("get_tracked_enemies") or not _combat_adapter.has_method("apply_damage"):
		return

	var enemies := _combat_adapter.call("get_tracked_enemies") as Array
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

		var cooldown := maxf(float(tower_state.get("cooldown", 0.0)) - maxf(delta, 0.0), 0.0)
		tower_state["cooldown"] = cooldown
		_registered_towers[tower_id] = tower_state
		if cooldown > 0.0:
			continue

		var target := _find_target(tower, enemies, float(tower_state.get("range", 0.0)))
		if target == null:
			continue

		var damage := float(tower_state.get("damage", 0.0))
		_combat_adapter.call("apply_damage", target, damage)
		_spawn_fire_cue(tower)
		_spawn_projectile_visual(tower, target, str(tower_state.get("projectileModelPath", "")))
		tower_state["cooldown"] = 1.0 / maxf(float(tower_state.get("fireRate", 1.0)), 0.01)
		_registered_towers[tower_id] = tower_state
		tower_fired.emit(tower, target, damage)

func _find_target(tower: Node3D, enemies: Array, tower_range: float) -> Node:
	var best_enemy: Node = null
	var best_distance := INF
	for enemy_variant: Variant in enemies:
		var enemy := enemy_variant as Node
		if enemy == null or not is_instance_valid(enemy):
			continue
		if enemy.has_method("is_alive") and not bool(enemy.call("is_alive")):
			continue
		if not enemy is Node3D:
			continue

		var enemy_node := enemy as Node3D
		var distance := _node_position(tower).distance_to(_node_position(enemy_node))
		if distance > tower_range or distance >= best_distance:
			continue

		best_enemy = enemy
		best_distance = distance

	return best_enemy

func _spawn_fire_cue(tower: Node3D) -> void:
	var cue := Node3D.new()
	cue.name = "TowerFireCue"
	cue.position = _node_position(tower) + FIRE_CUE_OFFSET
	add_child(cue)

	var glow := MeshInstance3D.new()
	glow.name = "FireCueGlow"
	var glow_mesh := SphereMesh.new()
	glow_mesh.radius = 0.16
	glow_mesh.height = 0.18
	glow_mesh.radial_segments = 12
	glow_mesh.rings = 6
	glow.mesh = glow_mesh
	glow.material_override = _make_fire_cue_material()
	cue.add_child(glow)

	_fire_cue_ages[cue.get_instance_id()] = {
		"node": cue,
		"age": 0.0,
		"lifetime": maxf(fire_cue_lifetime, 0.01),
	}

func _spawn_projectile_visual(tower: Node3D, target: Node, projectile_model_path: String) -> void:
	if projectile_model_path == "" or not ResourceLoader.exists(projectile_model_path):
		return

	var packed_scene := load(projectile_model_path) as PackedScene
	if packed_scene == null:
		return

	var target_node := target as Node3D
	if target_node == null:
		return

	var start_position := _node_position(tower) + PROJECTILE_START_OFFSET
	var end_position := _node_position(target_node) + PROJECTILE_END_OFFSET
	var visual := Node3D.new()
	visual.name = "ProjectileVisual"
	visual.position = start_position
	add_child(visual)

	var model := packed_scene.instantiate() as Node3D
	if model == null:
		visual.queue_free()
		return

	model.name = "ProjectileModel"
	model.scale = Vector3.ONE * 0.3
	visual.add_child(model)
	_add_projectile_readability_helpers(visual, start_position, end_position)
	_projectile_visual_ages[visual.get_instance_id()] = {
		"node": visual,
		"age": 0.0,
		"start": start_position,
		"end": end_position,
		"lifetime": maxf(projectile_visual_lifetime, 0.01),
	}

func _add_projectile_readability_helpers(visual: Node3D, start_position: Vector3, end_position: Vector3) -> void:
	var glow := MeshInstance3D.new()
	glow.name = "ProjectileReadabilityGlow"
	var glow_mesh := SphereMesh.new()
	glow_mesh.radius = 0.16
	glow_mesh.height = 0.24
	glow_mesh.radial_segments = 12
	glow_mesh.rings = 6
	glow.mesh = glow_mesh
	glow.material_override = _make_projectile_readability_material(1.5)
	visual.add_child(glow)

	var trail := MeshInstance3D.new()
	trail.name = "ProjectileReadabilityTrail"
	var trail_mesh := CylinderMesh.new()
	trail_mesh.top_radius = 0.045
	trail_mesh.bottom_radius = 0.075
	trail_mesh.height = clampf(start_position.distance_to(end_position) * 0.45, 0.24, 0.9)
	trail_mesh.radial_segments = 8
	trail.mesh = trail_mesh
	trail.material_override = _make_projectile_readability_material(0.9)
	trail.position = Vector3(0.0, 0.0, -0.18)
	trail.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	visual.add_child(trail)

func _age_projectile_visuals(delta: float) -> void:
	var visual_ids := _projectile_visual_ages.keys()
	for visual_id_variant: Variant in visual_ids:
		var visual_id := int(visual_id_variant)
		var state := _projectile_visual_ages[visual_id] as Dictionary
		var visual := state.get("node") as Node
		if visual == null or not is_instance_valid(visual):
			_projectile_visual_ages.erase(visual_id)
			continue
		var visual_node := visual as Node3D
		if visual_node == null:
			_projectile_visual_ages.erase(visual_id)
			visual.queue_free()
			continue

		var age := float(state.get("age", 0.0)) + maxf(delta, 0.0)
		var lifetime := maxf(float(state.get("lifetime", projectile_visual_lifetime)), 0.01)
		if age >= lifetime:
			_projectile_visual_ages.erase(visual_id)
			visual.queue_free()
			continue

		var start_position: Vector3 = state.get("start", Vector3.ZERO)
		var end_position: Vector3 = state.get("end", start_position)
		visual_node.position = start_position.lerp(end_position, clampf(age / lifetime, 0.0, 1.0))
		state["age"] = age
		_projectile_visual_ages[visual_id] = state

func _age_fire_cues(delta: float) -> void:
	var cue_ids := _fire_cue_ages.keys()
	for cue_id_variant: Variant in cue_ids:
		var cue_id := int(cue_id_variant)
		var state := _fire_cue_ages[cue_id] as Dictionary
		var cue := state.get("node") as Node
		if cue == null or not is_instance_valid(cue):
			_fire_cue_ages.erase(cue_id)
			continue
		var cue_node := cue as Node3D
		if cue_node == null:
			_fire_cue_ages.erase(cue_id)
			cue.queue_free()
			continue

		var age := float(state.get("age", 0.0)) + maxf(delta, 0.0)
		var lifetime := maxf(float(state.get("lifetime", fire_cue_lifetime)), 0.01)
		if age >= lifetime:
			_fire_cue_ages.erase(cue_id)
			cue.queue_free()
			continue

		var progress := clampf(age / lifetime, 0.0, 1.0)
		cue_node.scale = Vector3.ONE * lerpf(1.0, 0.25, progress)
		state["age"] = age
		_fire_cue_ages[cue_id] = state

func _node_position(node: Node3D) -> Vector3:
	if node.is_inside_tree():
		return node.global_position
	return node.position

func _make_fire_cue_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.95, 0.12, 0.04, 0.72)
	material.emission_enabled = true
	material.emission = Color(0.9, 0.08, 0.02)
	material.emission_energy_multiplier = 1.8
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material

func _make_projectile_readability_material(emission_multiplier: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = PROJECTILE_READABILITY_COLOR
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = Color(1.0, 0.08, 0.02)
	material.emission_energy_multiplier = emission_multiplier
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material

func _dict_float(data: Dictionary, key: String, fallback: float) -> float:
	var value: Variant = data.get(key, fallback)
	return float(value)

func _dict_string(data: Dictionary, key: String, fallback: String) -> String:
	var value: Variant = data.get(key, fallback)
	return str(value)
