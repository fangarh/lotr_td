extends Node3D
class_name PlaceholderEnemy

signal died(enemy: PlaceholderEnemy)
signal health_changed(current: float, maximum: float)
signal path_breached(enemy: PlaceholderEnemy)
signal blocker_attack_requested(blocker_id: String, amount: float)

const BLOCKER_ATTACK_INTERVAL := 0.5
const BLOCKER_ATTACK_DAMAGE := 8.0

var speed := 1.0
var max_health := 32.0
var current_health := 32.0
var _path_points: Array[Vector3] = []
var _segment := 0
var _segment_progress := 0.0
var _alive := true
var _breached := false
var _model_path := ""
var _model_yaw_degrees := 0.0
var _model_lift := 0.0
var _target_height := 0.9
var _target_footprint := 0.7
var _base_marker_name := "ElfEnemyBaseMarker"
var _base_marker_color := Color(0.18, 0.32, 0.24)
var _slow_zones: Array[Dictionary] = []
var _blockers: Array[Dictionary] = []
var _blocker_attack_cooldown := 0.0

func configure_visual(data: Dictionary) -> void:
	max_health = maxf(_dict_float(data, "health", max_health), 1.0)
	current_health = max_health
	_alive = true
	_breached = false
	visible = true
	set_process(true)
	_model_path = _dict_string(data, "modelPath", "")
	_model_yaw_degrees = _dict_float(data, "modelYawDegrees", _model_yaw_degrees)
	_model_lift = _dict_float(data, "modelLift", _model_lift)
	_target_height = _dict_float(data, "targetHeight", _target_height)
	_target_footprint = _dict_float(data, "targetFootprint", _target_footprint)
	_base_marker_name = _dict_string(data, "baseMarkerName", _base_marker_name)
	_base_marker_color = _dict_color(data, "baseMarkerColor", _base_marker_color)

func setup(path_points: Array[Vector3], next_speed: float) -> void:
	_path_points = path_points.duplicate()
	speed = next_speed
	_segment = 0
	_segment_progress = 0.0
	_breached = false
	_blocker_attack_cooldown = 0.0
	_alive = current_health > 0.0
	visible = _alive
	set_process(_alive)
	if not _path_points.is_empty():
		position = _path_points[0]

func apply_damage(amount: float) -> bool:
	if not _alive:
		return true

	current_health = clampf(current_health - maxf(amount, 0.0), 0.0, max_health)
	health_changed.emit(current_health, max_health)
	_update_health_bar()

	if current_health <= 0.0:
		_die()
		return true

	return false

func is_alive() -> bool:
	return _alive and not _breached

func has_breached() -> bool:
	return _breached

func set_slow_zones(zones: Array) -> void:
	_slow_zones.clear()
	for zone_variant: Variant in zones:
		if typeof(zone_variant) != TYPE_DICTIONARY:
			continue

		var zone := zone_variant as Dictionary
		var position_variant: Variant = zone.get("position", Vector3.ZERO)
		if not position_variant is Vector3:
			continue

		_slow_zones.append({
			"position": position_variant as Vector3,
			"radius": maxf(_dict_float(zone, "radius", 0.0), 0.0),
			"slowMultiplier": clampf(_dict_float(zone, "slowMultiplier", 1.0), 0.0, 1.0),
		})

func get_slow_zone_count() -> int:
	return _slow_zones.size()

func set_blockers(blockers: Array) -> void:
	_blockers.clear()
	for blocker_variant: Variant in blockers:
		if typeof(blocker_variant) != TYPE_DICTIONARY:
			continue

		var blocker := blocker_variant as Dictionary
		var blocker_id := _dict_string(blocker, "id", "")
		var position_variant: Variant = blocker.get("position", Vector3.ZERO)
		var radius := maxf(_dict_float(blocker, "radius", 0.0), 0.0)
		if blocker_id == "" or not position_variant is Vector3 or radius <= 0.0:
			continue

		_blockers.append({
			"id": blocker_id,
			"position": position_variant as Vector3,
			"radius": radius,
		})

func get_blocker_count() -> int:
	return _blockers.size()

func current_blocker_id() -> String:
	var blocker := _current_blocker()
	if blocker.is_empty():
		return ""
	return str(blocker.get("id", ""))

func current_slow_multiplier() -> float:
	var multiplier := 1.0
	for zone in _slow_zones:
		var zone_position: Vector3 = zone.get("position", Vector3.ZERO)
		var radius := maxf(float(zone.get("radius", 0.0)), 0.0)
		if radius <= 0.0:
			continue
		var flat_distance := Vector2(position.x, position.z).distance_to(Vector2(zone_position.x, zone_position.z))
		if flat_distance <= radius:
			multiplier = minf(multiplier, clampf(float(zone.get("slowMultiplier", 1.0)), 0.0, 1.0))
	return multiplier

func get_health_fraction() -> float:
	if max_health <= 0.0:
		return 0.0
	return clampf(current_health / max_health, 0.0, 1.0)

func _ready() -> void:
	if get_child_count() > 0:
		return

	if not _try_add_configured_model():
		_add_gondor_proxy_visual()

	_add_health_bar()
	_update_health_bar()

func _try_add_configured_model() -> bool:
	if _model_path == "":
		return false
	if not ResourceLoader.exists(_model_path):
		push_warning("Enemy model is missing, using primitive fallback: %s" % _model_path)
		return false

	var packed_scene := load(_model_path) as PackedScene
	if packed_scene == null:
		push_warning("Enemy model did not load as a PackedScene, using primitive fallback: %s" % _model_path)
		return false

	var model := packed_scene.instantiate() as Node3D
	if model == null:
		push_warning("Enemy model root is not Node3D, using primitive fallback: %s" % _model_path)
		return false

	model.name = "EnemyModel"
	add_child(model)
	_fit_model_to_path_proxy(model)
	model.rotation_degrees.y = _model_yaw_degrees
	_add_model_readability_marker()
	return true

func _fit_model_to_path_proxy(model: Node3D) -> void:
	var bounds := _combined_local_mesh_bounds(model)
	if bounds.size == Vector3.ZERO:
		return

	var horizontal_size := maxf(bounds.size.x, bounds.size.z)
	var vertical_size := bounds.size.y
	if horizontal_size <= 0.0 or vertical_size <= 0.0:
		return

	var uniform_scale := minf(_target_footprint / horizontal_size, _target_height / vertical_size)
	model.scale = Vector3.ONE * uniform_scale

	var center := bounds.position + bounds.size * 0.5
	model.position = Vector3(
		-center.x * uniform_scale,
		-bounds.position.y * uniform_scale + _model_lift,
		-center.z * uniform_scale
	)

func _combined_local_mesh_bounds(root: Node3D) -> AABB:
	var has_bounds := false
	var combined := AABB()
	var stack: Array[Dictionary] = [{
		"node": root,
		"transform": Transform3D.IDENTITY,
	}]

	while not stack.is_empty():
		var entry := stack.pop_back() as Dictionary
		var node := entry["node"] as Node
		var node_transform := entry["transform"] as Transform3D
		for child in node.get_children():
			var child_transform := node_transform
			if child is Node3D:
				child_transform = node_transform * (child as Node3D).transform
			stack.append({
				"node": child,
				"transform": child_transform,
			})

		if not node is MeshInstance3D:
			continue

		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null:
			continue

		var mesh_bounds := node_transform * mesh_instance.mesh.get_aabb()
		if has_bounds:
			combined = combined.merge(mesh_bounds)
		else:
			combined = mesh_bounds
			has_bounds = true

	return combined

func _add_model_readability_marker() -> void:
	var base_marker := MeshInstance3D.new()
	base_marker.name = _base_marker_name
	var marker_mesh := CylinderMesh.new()
	marker_mesh.top_radius = _target_footprint * 0.42
	marker_mesh.bottom_radius = _target_footprint * 0.46
	marker_mesh.height = 0.035
	marker_mesh.radial_segments = 16
	base_marker.mesh = marker_mesh
	base_marker.material_override = _make_material(_base_marker_color, 0.88)
	base_marker.position.y = 0.018
	add_child(base_marker)
	move_child(base_marker, 0)

func _add_health_bar() -> void:
	var health_bar := Node3D.new()
	health_bar.name = "HealthBar"
	health_bar.position = Vector3(0.0, _target_height + 0.16, -0.04)
	add_child(health_bar)

	var back := MeshInstance3D.new()
	back.name = "HealthBarBack"
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(0.48, 0.055, 0.024)
	back.mesh = back_mesh
	back.material_override = _make_material(Color(0.035, 0.025, 0.025), 0.86)
	health_bar.add_child(back)

	var fill := MeshInstance3D.new()
	fill.name = "HealthBarFill"
	var fill_mesh := BoxMesh.new()
	fill_mesh.size = Vector3(0.44, 0.04, 0.028)
	fill.mesh = fill_mesh
	fill.position = Vector3(0.0, 0.0, -0.018)
	fill.material_override = _make_material(Color(0.62, 0.08, 0.055), 0.7)
	health_bar.add_child(fill)

func _update_health_bar() -> void:
	var fill := get_node_or_null("HealthBar/HealthBarFill") as Node3D
	if fill == null:
		return
	fill.scale.x = get_health_fraction()

func _die() -> void:
	_alive = false
	visible = false
	set_process(false)
	died.emit(self)

func _add_gondor_proxy_visual() -> void:
	var body := MeshInstance3D.new()
	body.name = "GondorBody"
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.32, 0.46, 0.24)
	body.mesh = body_mesh
	body.material_override = _make_material(Color(0.22, 0.28, 0.34), 0.78)
	body.position.y = 0.28
	add_child(body)

	var chest := MeshInstance3D.new()
	chest.name = "GondorWhiteTreeMark"
	var chest_mesh := BoxMesh.new()
	chest_mesh.size = Vector3(0.18, 0.24, 0.018)
	chest.mesh = chest_mesh
	chest.material_override = _make_material(Color(0.92, 0.92, 0.84), 0.62)
	chest.position = Vector3(0.0, 0.32, -0.13)
	add_child(chest)

	var head := MeshInstance3D.new()
	head.name = "GondorHead"
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.14
	head_mesh.height = 0.2
	head_mesh.radial_segments = 12
	head_mesh.rings = 6
	head.mesh = head_mesh
	head.material_override = _make_material(Color(0.82, 0.68, 0.52), 0.72)
	head.position.y = 0.58
	add_child(head)

	var helmet := MeshInstance3D.new()
	helmet.name = "GondorHelmet"
	var helmet_mesh := SphereMesh.new()
	helmet_mesh.radius = 0.155
	helmet_mesh.height = 0.14
	helmet_mesh.radial_segments = 12
	helmet_mesh.rings = 4
	helmet.mesh = helmet_mesh
	helmet.material_override = _make_material(Color(0.72, 0.76, 0.78), 0.38, 0.55)
	helmet.position.y = 0.66
	add_child(helmet)

	var shield := MeshInstance3D.new()
	shield.name = "GondorShield"
	var shield_mesh := BoxMesh.new()
	shield_mesh.size = Vector3(0.08, 0.38, 0.3)
	shield.mesh = shield_mesh
	shield.material_override = _make_material(Color(0.84, 0.86, 0.82), 0.55, 0.2)
	shield.position = Vector3(-0.22, 0.32, -0.03)
	shield.rotation_degrees.z = -6.0
	add_child(shield)

	var shield_band := MeshInstance3D.new()
	shield_band.name = "GondorShieldBand"
	var shield_band_mesh := BoxMesh.new()
	shield_band_mesh.size = Vector3(0.086, 0.08, 0.32)
	shield_band.mesh = shield_band_mesh
	shield_band.material_override = _make_material(Color(0.18, 0.26, 0.42), 0.58)
	shield_band.position = Vector3(-0.226, 0.32, -0.03)
	shield_band.rotation_degrees.z = -6.0
	add_child(shield_band)

	var spear := MeshInstance3D.new()
	spear.name = "GondorSpearShaft"
	var spear_mesh := CylinderMesh.new()
	spear_mesh.top_radius = 0.018
	spear_mesh.bottom_radius = 0.018
	spear_mesh.height = 0.82
	spear_mesh.radial_segments = 8
	spear.mesh = spear_mesh
	spear.material_override = _make_material(Color(0.28, 0.19, 0.12), 0.82)
	spear.position = Vector3(0.24, 0.48, 0.02)
	spear.rotation_degrees.z = -7.0
	add_child(spear)

	var spear_tip := MeshInstance3D.new()
	spear_tip.name = "GondorSpearTip"
	var spear_tip_mesh := CylinderMesh.new()
	spear_tip_mesh.top_radius = 0.0
	spear_tip_mesh.bottom_radius = 0.055
	spear_tip_mesh.height = 0.14
	spear_tip_mesh.radial_segments = 8
	spear_tip.mesh = spear_tip_mesh
	spear_tip.material_override = _make_material(Color(0.82, 0.84, 0.82), 0.32, 0.65)
	spear_tip.position = Vector3(0.19, 0.9, 0.02)
	spear_tip.rotation_degrees.z = -7.0
	add_child(spear_tip)

	var banner := MeshInstance3D.new()
	banner.name = "GondorBanner"
	var banner_mesh := BoxMesh.new()
	banner_mesh.size = Vector3(0.24, 0.16, 0.018)
	banner.mesh = banner_mesh
	banner.material_override = _make_material(Color(0.88, 0.9, 0.86), 0.7)
	banner.position = Vector3(0.34, 0.78, -0.01)
	banner.rotation_degrees.z = -7.0
	add_child(banner)

	var banner_band := MeshInstance3D.new()
	banner_band.name = "GondorBannerBand"
	var banner_band_mesh := BoxMesh.new()
	banner_band_mesh.size = Vector3(0.24, 0.045, 0.022)
	banner_band.mesh = banner_band_mesh
	banner_band.material_override = _make_material(Color(0.18, 0.26, 0.42), 0.55)
	banner_band.position = Vector3(0.34, 0.78, -0.02)
	banner_band.rotation_degrees.z = -7.0
	add_child(banner_band)

func _process(delta: float) -> void:
	if not is_alive():
		return
	if _process_blocker_contact(delta):
		return
	_move(delta * current_slow_multiplier())

func _process_blocker_contact(delta: float) -> bool:
	var blocker := _current_blocker()
	if blocker.is_empty():
		_blocker_attack_cooldown = 0.0
		return false

	_blocker_attack_cooldown -= maxf(delta, 0.0)
	if _blocker_attack_cooldown <= 0.0:
		blocker_attack_requested.emit(str(blocker.get("id", "")), BLOCKER_ATTACK_DAMAGE)
		_blocker_attack_cooldown = BLOCKER_ATTACK_INTERVAL
	return true

func _current_blocker() -> Dictionary:
	for blocker in _blockers:
		var blocker_position: Vector3 = blocker.get("position", Vector3.ZERO)
		var radius := maxf(float(blocker.get("radius", 0.0)), 0.0)
		if radius <= 0.0:
			continue
		var flat_distance := Vector2(position.x, position.z).distance_to(Vector2(blocker_position.x, blocker_position.z))
		if flat_distance <= radius:
			return blocker
	return {}

func _move(delta: float) -> void:
	if _path_points.size() < 2:
		return

	var remaining := speed * delta
	while remaining > 0.0:
		var from_point := _path_points[_segment]
		var to_point := _path_points[_segment + 1]
		var segment := to_point - from_point
		var segment_length := segment.length()
		if segment_length <= 0.001:
			_advance_segment()
			continue

		var distance_left := segment_length - _segment_progress
		if remaining < distance_left:
			_segment_progress += remaining
			position = from_point + segment.normalized() * _segment_progress
			return

		remaining -= distance_left
		_advance_segment()
		if not is_alive():
			return

func _advance_segment() -> void:
	_segment += 1
	_segment_progress = 0.0
	if _segment >= _path_points.size() - 1:
		_segment = _path_points.size() - 1
		position = _path_points[_segment]
		_breach_path()
		return
	position = _path_points[_segment]

func _breach_path() -> void:
	if _breached:
		return

	_breached = true
	_alive = false
	visible = false
	set_process(false)
	path_breached.emit(self)

func _make_material(color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func _dict_float(data: Dictionary, key: String, fallback: float) -> float:
	var value: Variant = data.get(key, fallback)
	return float(value)

func _dict_string(data: Dictionary, key: String, fallback: String) -> String:
	var value: Variant = data.get(key, fallback)
	return str(value)

func _dict_color(data: Dictionary, key: String, fallback: Color) -> Color:
	var value: Variant = data.get(key, fallback)
	if value is Color:
		return value as Color
	if typeof(value) == TYPE_DICTIONARY:
		var color_data := value as Dictionary
		return Color(
			_dict_float(color_data, "r", fallback.r),
			_dict_float(color_data, "g", fallback.g),
			_dict_float(color_data, "b", fallback.b),
			_dict_float(color_data, "a", fallback.a)
		)
	return fallback
