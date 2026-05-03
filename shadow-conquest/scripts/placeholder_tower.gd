extends Node3D
class_name PlaceholderTower

@export_range(0.4, 1.4, 0.01) var target_footprint: float = 0.9
@export_range(0.6, 2.0, 0.01) var target_height: float = 1.35
@export_range(-180.0, 180.0, 1.0) var model_yaw_degrees: float = -45.0
@export_range(-0.2, 0.4, 0.01) var model_lift: float = 0.02
@export var show_readability_accents: bool = true

var _model_path := "res://assets/models/towers/base.glb"
var _mesh_path := ""
var _texture_diffuse_path := ""
var _texture_normal_path := ""
var _texture_metallic_path := ""
var _texture_roughness_path := ""
var _projectile_model_path := ""
var _show_projectile_preview := false
var _projectile_preview_offset := Vector3(0.42, 0.82, -0.42)
var _projectile_preview_size := 0.22

func configure_visual(data: Dictionary) -> void:
	_model_path = _dict_string(data, "modelPath", _model_path)
	_mesh_path = _dict_string(data, "meshPath", _mesh_path)
	_texture_diffuse_path = _dict_string(data, "textureDiffusePath", _texture_diffuse_path)
	_texture_normal_path = _dict_string(data, "textureNormalPath", _texture_normal_path)
	_texture_metallic_path = _dict_string(data, "textureMetallicPath", _texture_metallic_path)
	_texture_roughness_path = _dict_string(data, "textureRoughnessPath", _texture_roughness_path)
	_projectile_model_path = _dict_string(data, "projectileModelPath", _projectile_model_path)
	_show_projectile_preview = _dict_bool(data, "showProjectilePreview", _show_projectile_preview)
	_projectile_preview_offset = _dict_vector3(data, "projectilePreviewOffset", _projectile_preview_offset)
	_projectile_preview_size = _dict_float(data, "projectilePreviewScale", _projectile_preview_size)
	model_yaw_degrees = _dict_float(data, "modelYawDegrees", model_yaw_degrees)
	model_lift = _dict_float(data, "modelLift", model_lift)
	target_height = _dict_float(data, "targetHeight", target_height)
	target_footprint = _dict_float(data, "targetFootprint", target_footprint)
	show_readability_accents = _dict_bool(data, "showReadabilityAccents", show_readability_accents)

func setup(world_position: Vector3) -> void:
	position = world_position + Vector3(0.0, 0.06, 0.0)

func _ready() -> void:
	if get_child_count() > 0:
		return

	if _mesh_path != "" and _try_add_textured_mesh():
		return

	if _try_add_model():
		return

	_add_primitive_fallback()

func _try_add_textured_mesh() -> bool:
	if not ResourceLoader.exists(_mesh_path):
		push_warning("Tower mesh is missing, using model or primitive fallback: %s" % _mesh_path)
		return false

	var mesh := load(_mesh_path) as Mesh
	if mesh == null:
		push_warning("Tower mesh did not load as Mesh, using model or primitive fallback: %s" % _mesh_path)
		return false

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "TowerModel"
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _make_textured_material()
	add_child(mesh_instance)
	_fit_model_to_tile(mesh_instance)
	mesh_instance.rotation_degrees.y = model_yaw_degrees
	if show_readability_accents:
		_add_readability_accents()
	_add_projectile_preview()
	return true

func _try_add_model() -> bool:
	if not ResourceLoader.exists(_model_path):
		push_warning("Tower model is missing, using primitive fallback: %s" % _model_path)
		return false

	var packed_scene := load(_model_path) as PackedScene
	if packed_scene == null:
		push_warning("Tower model did not load as a PackedScene, using primitive fallback: %s" % _model_path)
		return false

	var model := packed_scene.instantiate() as Node3D
	if model == null:
		push_warning("Tower model root is not Node3D, using primitive fallback: %s" % _model_path)
		return false

	model.name = "TowerModel"
	add_child(model)
	_fit_model_to_tile(model)
	model.rotation_degrees.y = model_yaw_degrees
	if show_readability_accents:
		_add_readability_accents()
	_add_projectile_preview()
	return true

func _add_projectile_preview() -> void:
	if not _show_projectile_preview or _projectile_model_path == "":
		return
	if not ResourceLoader.exists(_projectile_model_path):
		push_warning("Tower projectile model is missing, skipping projectile preview: %s" % _projectile_model_path)
		return

	var packed_scene := load(_projectile_model_path) as PackedScene
	if packed_scene == null:
		push_warning("Tower projectile model did not load as PackedScene, skipping projectile preview: %s" % _projectile_model_path)
		return

	var preview := Node3D.new()
	preview.name = "ProjectilePreview"
	preview.position = _projectile_preview_offset
	add_child(preview)

	var model := packed_scene.instantiate() as Node3D
	if model == null:
		push_warning("Tower projectile model root is not Node3D, skipping projectile preview: %s" % _projectile_model_path)
		preview.queue_free()
		return

	model.name = "ProjectileModel"
	preview.add_child(model)
	_fit_projectile_model(model)
	model.rotation_degrees.y = model_yaw_degrees

func _fit_projectile_model(model: Node3D) -> void:
	var bounds := _combined_local_mesh_bounds(model)
	if bounds.size == Vector3.ZERO:
		return

	var largest_size := maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	if largest_size <= 0.0:
		return

	var uniform_scale := _projectile_preview_size / largest_size
	model.scale = Vector3.ONE * uniform_scale

	var center := bounds.position + bounds.size * 0.5
	model.position = Vector3(
		-center.x * uniform_scale,
		-center.y * uniform_scale,
		-center.z * uniform_scale
	)

func _fit_model_to_tile(model: Node3D) -> void:
	var bounds := _combined_local_mesh_bounds(model)
	if bounds.size == Vector3.ZERO:
		return

	var horizontal_size := maxf(bounds.size.x, bounds.size.z)
	var vertical_size := bounds.size.y
	if horizontal_size <= 0.0 or vertical_size <= 0.0:
		return

	var uniform_scale := minf(target_footprint / horizontal_size, target_height / vertical_size)
	model.scale = Vector3.ONE * uniform_scale

	var center := bounds.position + bounds.size * 0.5
	model.position = Vector3(
		-center.x * uniform_scale,
		-bounds.position.y * uniform_scale + model_lift,
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

func _add_readability_accents() -> void:
	var base_marker := MeshInstance3D.new()
	base_marker.name = "TowerBaseMarker"
	var marker_mesh := CylinderMesh.new()
	marker_mesh.top_radius = 0.47
	marker_mesh.bottom_radius = 0.52
	marker_mesh.height = 0.055
	marker_mesh.radial_segments = 8
	base_marker.mesh = marker_mesh
	base_marker.material_override = _make_material(Color(0.035, 0.032, 0.03), 0.96)
	base_marker.position.y = 0.025
	add_child(base_marker)
	move_child(base_marker, 0)

	var ember := MeshInstance3D.new()
	ember.name = "TowerEmberBeacon"
	var ember_mesh := SphereMesh.new()
	ember_mesh.radius = 0.075
	ember_mesh.height = 0.15
	ember_mesh.radial_segments = 12
	ember_mesh.rings = 6
	ember.mesh = ember_mesh
	ember.material_override = _make_emissive_material(Color(1.0, 0.08, 0.015), 1.7)
	ember.position = Vector3(0.0, target_height + 0.16, 0.0)
	add_child(ember)

	var light := OmniLight3D.new()
	light.name = "TowerEmberLight"
	light.light_color = Color(1.0, 0.18, 0.05)
	light.light_energy = 0.75
	light.omni_range = 1.65
	light.position = Vector3(0.0, target_height + 0.08, 0.0)
	add_child(light)

func _add_primitive_fallback() -> void:
	var base := MeshInstance3D.new()
	base.name = "BasaltBase"
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(0.62, 0.55, 0.62)
	base.mesh = base_mesh
	base.material_override = _make_material(Color(0.06, 0.055, 0.05), 0.9)
	base.position.y = 0.28
	add_child(base)

	var ember := MeshInstance3D.new()
	ember.name = "EmberCrown"
	var ember_mesh := BoxMesh.new()
	ember_mesh.size = Vector3(0.34, 0.22, 0.34)
	ember.mesh = ember_mesh
	ember.material_override = _make_material(Color(0.85, 0.08, 0.02), 0.35)
	ember.position.y = 0.7
	add_child(ember)

func _make_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _make_textured_material() -> StandardMaterial3D:
	var material := _make_material(Color.WHITE, 0.82)
	var diffuse := _load_texture(_texture_diffuse_path)
	if diffuse != null:
		material.albedo_texture = diffuse
	var normal := _load_texture(_texture_normal_path)
	if normal != null:
		material.normal_enabled = true
		material.normal_texture = normal
	var metallic := _load_texture(_texture_metallic_path)
	if metallic != null:
		material.metallic_texture = metallic
	var roughness := _load_texture(_texture_roughness_path)
	if roughness != null:
		material.roughness_texture = roughness
	return material

func _make_emissive_material(color: Color, intensity: float) -> StandardMaterial3D:
	var material := _make_material(color, 0.45)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = intensity
	return material

func _load_texture(texture_path: String) -> Texture2D:
	if texture_path == "" or not ResourceLoader.exists(texture_path):
		return null
	return load(texture_path) as Texture2D

func _dict_float(data: Dictionary, key: String, fallback: float) -> float:
	var value: Variant = data.get(key, fallback)
	return float(value)

func _dict_string(data: Dictionary, key: String, fallback: String) -> String:
	var value: Variant = data.get(key, fallback)
	return str(value)

func _dict_bool(data: Dictionary, key: String, fallback: bool) -> bool:
	var value: Variant = data.get(key, fallback)
	return bool(value)

func _dict_vector3(data: Dictionary, key: String, fallback: Vector3) -> Vector3:
	var value: Variant = data.get(key, fallback)
	if typeof(value) != TYPE_DICTIONARY:
		return fallback

	var dict := value as Dictionary
	return Vector3(
		float(dict.get("x", fallback.x)),
		float(dict.get("y", fallback.y)),
		float(dict.get("z", fallback.z))
	)
