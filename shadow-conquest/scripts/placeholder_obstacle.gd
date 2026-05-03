extends Node3D
class_name PlaceholderObstacle

@export_range(0.35, 1.2, 0.01) var footprint: float = 0.82
@export_range(0.01, 0.25, 0.01) var ground_lift: float = 0.035
@export var show_morgul_glow: bool = true

func setup(world_position: Vector3) -> void:
	position = world_position + Vector3(0.0, ground_lift, 0.0)

func _ready() -> void:
	if get_child_count() > 0:
		return

	_add_shadow_patch()
	_add_roots()
	_add_webbing()
	if show_morgul_glow:
		_add_morgul_glow()

func _add_shadow_patch() -> void:
	var patch := MeshInstance3D.new()
	patch.name = "ShadowPatch"
	var mesh := CylinderMesh.new()
	mesh.top_radius = footprint * 0.45
	mesh.bottom_radius = footprint * 0.5
	mesh.height = 0.035
	mesh.radial_segments = 10
	patch.mesh = mesh
	patch.material_override = _make_material(Color(0.035, 0.025, 0.03), 0.98)
	add_child(patch)

func _add_roots() -> void:
	var root_specs := [
		{"name": "RootA", "offset": Vector3(-0.08, 0.055, 0.0), "length": 0.82, "width": 0.09, "yaw": 18.0},
		{"name": "RootB", "offset": Vector3(0.08, 0.07, 0.04), "length": 0.7, "width": 0.075, "yaw": -36.0},
		{"name": "RootC", "offset": Vector3(0.02, 0.085, -0.1), "length": 0.58, "width": 0.07, "yaw": 78.0},
		{"name": "RootD", "offset": Vector3(-0.18, 0.08, 0.12), "length": 0.42, "width": 0.065, "yaw": -82.0},
	]

	for spec in root_specs:
		var root := MeshInstance3D.new()
		root.name = str(spec["name"])
		var mesh := BoxMesh.new()
		var length := float(spec["length"]) * footprint
		var width := float(spec["width"]) * footprint
		mesh.size = Vector3(length, width, width)
		root.mesh = mesh
		root.position = spec["offset"] as Vector3
		root.rotation_degrees.y = float(spec["yaw"])
		root.material_override = _make_material(Color(0.07, 0.045, 0.035), 0.9)
		add_child(root)

func _add_webbing() -> void:
	var web_specs := [
		{"name": "WebStrandA", "offset": Vector3(0.0, 0.115, 0.0), "length": 0.62, "yaw": 45.0},
		{"name": "WebStrandB", "offset": Vector3(0.02, 0.12, -0.02), "length": 0.55, "yaw": -48.0},
		{"name": "WebStrandC", "offset": Vector3(-0.02, 0.125, 0.02), "length": 0.5, "yaw": 0.0},
	]

	for spec in web_specs:
		var strand := MeshInstance3D.new()
		strand.name = str(spec["name"])
		var mesh := BoxMesh.new()
		mesh.size = Vector3(float(spec["length"]) * footprint, 0.018, 0.024)
		strand.mesh = mesh
		strand.position = spec["offset"] as Vector3
		strand.rotation_degrees.y = float(spec["yaw"])
		strand.material_override = _make_emissive_material(Color(0.34, 0.75, 0.48), 0.55)
		add_child(strand)

func _add_morgul_glow() -> void:
	var glow := OmniLight3D.new()
	glow.name = "MorgulGlow"
	glow.light_color = Color(0.22, 0.75, 0.38)
	glow.light_energy = 0.35
	glow.omni_range = 1.25
	glow.position = Vector3(0.0, 0.28, 0.0)
	add_child(glow)

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
