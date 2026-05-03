extends SceneTree

const SCENE_PATH := "res://scenes/main.tscn"
const BOARD_SCRIPT_PATH := "res://scripts/board_view.gd"
const TOWER_SCENE_PATH := "res://scenes/entities/placeholder_tower.tscn"
const OBSTACLE_SCENE_PATH := "res://scenes/entities/placeholder_obstacle.tscn"
const ENEMY_SCENE_PATH := "res://scenes/entities/placeholder_enemy.tscn"

func _init() -> void:
	var failures: Array[String] = []

	_expect_resource(BOARD_SCRIPT_PATH, failures)
	_expect_resource(TOWER_SCENE_PATH, failures)
	_expect_resource(OBSTACLE_SCENE_PATH, failures)
	_expect_resource(ENEMY_SCENE_PATH, failures)

	var packed_scene := load(SCENE_PATH) as PackedScene
	var scene := packed_scene.instantiate()
	if scene.get_script() == null:
		failures.append("Main scene root must have a valid script")

	var world := scene.get_node_or_null("World")
	if world == null:
		failures.append("Main scene must include World")
	else:
		var board := _expect_child(world, "BoardView", failures)
		if board != null and board.get_script() == null:
			failures.append("BoardView must have a valid script")
		_expect_child(world, "Towers", failures)
		_expect_child(world, "Obstacles", failures)
		_expect_child(world, "Enemies", failures)

	scene.free()

	if failures.is_empty():
		print("smoke_spike_boundaries: ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect_resource(path: String, failures: Array[String]) -> void:
	if not ResourceLoader.exists(path):
		failures.append("Missing resource: %s" % path)

func _expect_child(parent: Node, child_name: String, failures: Array[String]) -> Node:
	var child := parent.get_node_or_null(child_name)
	if child == null:
		failures.append("Missing child node: %s/%s" % [parent.name, child_name])
	return child
