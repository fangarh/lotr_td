extends SceneTree

const WAVE_RUNNER_PATH := "res://scripts/wave_runner.gd"

func _init() -> void:
	var failures: Array[String] = []

	if not ResourceLoader.exists(WAVE_RUNNER_PATH):
		failures.append("Missing wave runner script at %s" % WAVE_RUNNER_PATH)
	else:
		var runner_script := load(WAVE_RUNNER_PATH)
		var runner = runner_script.new()
		var waves: Array = [
			{
				"id": "wave-1",
				"spawns": [
					{
						"enemyId": "gondor-soldier",
						"count": 3,
						"delay": 0.0,
						"interval": 0.5
					}
				]
			}
		]

		runner.call("configure", waves)
		if not runner.call("start_next_wave"):
			failures.append("Wave runner must start the first configured wave")

		_expect_spawn_count(runner.call("advance", 0.0), 1, "first spawn should happen at zero delay", failures)
		_expect_spawn_count(runner.call("advance", 0.49), 0, "runner must wait until interval elapses", failures)
		_expect_spawn_count(runner.call("advance", 0.01), 1, "second spawn should happen after interval", failures)
		_expect_spawn_count(runner.call("advance", 0.5), 1, "third spawn should happen after the next interval", failures)
		_expect_spawn_count(runner.call("advance", 1.0), 0, "runner must stop after count is exhausted", failures)

		if not runner.call("is_spawning_complete"):
			failures.append("Wave runner must report spawning complete after all scheduled enemies are emitted")

	if failures.is_empty():
		print("smoke_wave_runner: ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect_spawn_count(spawns: Variant, expected_count: int, label: String, failures: Array[String]) -> void:
	if typeof(spawns) != TYPE_ARRAY:
		failures.append("%s: expected spawn array" % label)
		return

	var spawn_array := spawns as Array
	if spawn_array.size() != expected_count:
		failures.append("%s: expected %d spawn(s), got %d" % [label, expected_count, spawn_array.size()])
		return

	for spawn_variant: Variant in spawn_array:
		if typeof(spawn_variant) != TYPE_DICTIONARY:
			failures.append("%s: spawn request must be a dictionary" % label)
			continue

		var spawn := spawn_variant as Dictionary
		if str(spawn.get("enemyId", "")) == "":
			failures.append("%s: spawn request must include enemyId" % label)
