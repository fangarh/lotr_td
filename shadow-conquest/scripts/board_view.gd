extends Node3D
class_name BoardView

const TILE_SIZE := 1.0
const TILE_HEIGHT := 0.08

var _path_surface_model_path := ""
var _path_surface_target_footprint := 0.92
var _path_surface_target_height := 0.12
var _path_surface_yaw_degrees := 0.0
var _path_surface_lift := 0.015

func build(board: Dictionary, path_lookup: Dictionary, path_data: Dictionary = {}) -> void:
	_clear_children()
	_configure_path_surface(path_data)

	var width := _dict_int(board, "width", 8)
	var height := _dict_int(board, "height", 6)

	for z in range(height):
		for x in range(width):
			var cell := Vector2i(x, z)
			var is_path := path_lookup.has(cell_key(cell.x, cell.y))
			add_child(_create_tile(cell, is_path))
			if is_path:
				_add_path_surface(cell)

func tile_to_world(cell: Vector2i) -> Vector3:
	return Vector3(float(cell.x) * TILE_SIZE, 0.0, float(cell.y) * TILE_SIZE)

static func cell_key(x: int, z: int) -> String:
	return "%d:%d" % [x, z]

func _clear_children() -> void:
	for child in get_children():
		child.queue_free()

func _create_tile(cell: Vector2i, is_path: bool) -> MeshInstance3D:
	var tile := MeshInstance3D.new()
	tile.name = "PathTile_%d_%d" % [cell.x, cell.y] if is_path else "GroundTile_%d_%d" % [cell.x, cell.y]
	tile.position = tile_to_world(cell) + Vector3(0.0, -TILE_HEIGHT * 0.5, 0.0)

	var mesh := BoxMesh.new()
	mesh.size = Vector3(TILE_SIZE * 0.96, TILE_HEIGHT, TILE_SIZE * 0.96)
	tile.mesh = mesh

	if is_path:
		tile.material_override = _make_material(Color(0.25, 0.21, 0.17), 0.95)
	else:
		var variation := float((cell.x * 17 + cell.y * 31) % 7) * 0.012
		tile.material_override = _make_material(Color(0.16 + variation, 0.22 + variation, 0.14 + variation), 0.95)

	return tile

func _configure_path_surface(path_data: Dictionary) -> void:
	_path_surface_model_path = _dict_string(path_data, "surfaceModelPath", "")
	_path_surface_target_footprint = _dict_float(path_data, "surfaceTargetFootprint", _path_surface_target_footprint)
	_path_surface_target_height = _dict_float(path_data, "surfaceTargetHeight", _path_surface_target_height)
	_path_surface_yaw_degrees = _dict_float(path_data, "surfaceYawDegrees", _path_surface_yaw_degrees)
	_path_surface_lift = _dict_float(path_data, "surfaceLift", _path_surface_lift)

func _add_path_surface(cell: Vector2i) -> void:
	if _path_surface_model_path == "" or not ResourceLoader.exists(_path_surface_model_path):
		return

	var packed_scene := load(_path_surface_model_path) as PackedScene
	if packed_scene == null:
		push_warning("Path surface model did not load as PackedScene: %s" % _path_surface_model_path)
		return

	var surface := packed_scene.instantiate() as Node3D
	if surface == null:
		push_warning("Path surface model root is not Node3D: %s" % _path_surface_model_path)
		return

	surface.name = "RoadSurface_%d_%d" % [cell.x, cell.y]
	surface.position = tile_to_world(cell) + Vector3(0.0, TILE_HEIGHT * 0.5 + _path_surface_lift, 0.0)
	surface.rotation_degrees.y = _path_surface_yaw_degrees
	add_child(surface)
	_fit_path_surface(surface)

func _fit_path_surface(surface: Node3D) -> void:
	var bounds := _combined_local_mesh_bounds(surface)
	if bounds.size == Vector3.ZERO:
		return

	var horizontal_size := maxf(bounds.size.x, bounds.size.z)
	var vertical_size := bounds.size.y
	if horizontal_size <= 0.0 or vertical_size <= 0.0:
		return

	var uniform_scale := minf(_path_surface_target_footprint / horizontal_size, _path_surface_target_height / vertical_size)
	surface.scale = Vector3.ONE * uniform_scale

	var center := bounds.position + bounds.size * 0.5
	surface.position += Vector3(
		-center.x * uniform_scale,
		-bounds.position.y * uniform_scale,
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

func _dict_int(data: Dictionary, key: String, fallback: int) -> int:
	var value: Variant = data.get(key, fallback)
	return int(value)

func _dict_float(data: Dictionary, key: String, fallback: float) -> float:
	var value: Variant = data.get(key, fallback)
	return float(value)

func _dict_string(data: Dictionary, key: String, fallback: String) -> String:
	var value: Variant = data.get(key, fallback)
	return str(value)

func _make_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
