extends Node3D
class_name PlaceholderTerrainProp

var _model_path := ""
var _model_yaw_degrees := 0.0
var _model_lift := 0.0
var _target_height := 0.6
var _target_footprint := 0.85

func configure_visual(data: Dictionary) -> void:
	_model_path = _dict_string(data, "modelPath", "")
	_model_yaw_degrees = _dict_float(data, "modelYawDegrees", _model_yaw_degrees)
	_model_lift = _dict_float(data, "modelLift", _model_lift)
	_target_height = _dict_float(data, "targetHeight", _target_height)
	_target_footprint = _dict_float(data, "targetFootprint", _target_footprint)

func setup(world_position: Vector3) -> void:
	position = world_position

func _ready() -> void:
	if get_child_count() > 0:
		return

	if _try_add_configured_model():
		return

	_add_primitive_rock_visual()

func _try_add_configured_model() -> bool:
	if _model_path == "":
		return false
	if not ResourceLoader.exists(_model_path):
		push_warning("Terrain prop model is missing, using primitive fallback: %s" % _model_path)
		return false

	var packed_scene := load(_model_path) as PackedScene
	if packed_scene == null:
		push_warning("Terrain prop model did not load as a PackedScene, using primitive fallback: %s" % _model_path)
		return false

	var model := packed_scene.instantiate() as Node3D
	if model == null:
		push_warning("Terrain prop model root is not Node3D, using primitive fallback: %s" % _model_path)
		return false

	model.name = "TerrainPropModel"
	add_child(model)
	_fit_model_to_tile(model)
	model.rotation_degrees.y = _model_yaw_degrees
	return true

func _fit_model_to_tile(model: Node3D) -> void:
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

func _add_primitive_rock_visual() -> void:
	var rock := MeshInstance3D.new()
	rock.name = "PrimitiveRock"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.55, 0.32, 0.42)
	rock.mesh = mesh
	rock.position.y = 0.16
	rock.rotation_degrees.y = 22.0
	rock.material_override = _make_material(Color(0.06, 0.055, 0.05), 0.94)
	add_child(rock)

	var ember := MeshInstance3D.new()
	ember.name = "PrimitiveEmberCrack"
	var ember_mesh := BoxMesh.new()
	ember_mesh.size = Vector3(0.05, 0.035, 0.36)
	ember.mesh = ember_mesh
	ember.position = Vector3(0.02, 0.28, -0.22)
	ember.rotation_degrees.y = 22.0
	ember.material_override = _make_emissive_material(Color(0.9, 0.13, 0.04), 0.55)
	add_child(ember)

func _make_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _make_emissive_material(color: Color, intensity: float) -> StandardMaterial3D:
	var material := _make_material(color, 0.62)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = intensity
	return material

func _dict_float(data: Dictionary, key: String, fallback: float) -> float:
	var value: Variant = data.get(key, fallback)
	return float(value)

func _dict_string(data: Dictionary, key: String, fallback: String) -> String:
	var value: Variant = data.get(key, fallback)
	return str(value)
