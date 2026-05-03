# Godot Scenario Selection Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a data-driven two-scenario selection/loading foundation for the desktop Godot MVP.

**Architecture:** Add a small `SpikeScenarioCatalog` loader for scenario index data, keep scenario files JSON-backed, and let `Main` remain the composition root that switches scenarios by id. Add only a compact HUD selector as the first player-facing scenario choice; do not add economy, build spots, tower purchasing, campaign progression, or free placement in this plan.

**Tech Stack:** Godot 4.6.2, GDScript, JSON scenario data, existing `SceneTree` smoke tests.

---

## Scope

This plan implements only the first MVP block: scenario selection/loading for two maps.

In scope:
- `res://data/scenario_index.json`;
- two scenario files under `res://data/scenarios/`;
- a reusable `SpikeScenarioCatalog` loader;
- `Main.load_scenario_by_id(id)` runtime switching;
- a compact desktop HUD `OptionButton` for selecting maps;
- smoke coverage for catalog loading, main-scene switching, and HUD signal wiring;
- Obsidian updates.

Out of scope:
- build spots;
- tower buying;
- economy;
- upgrades;
- new enemy abilities;
- Android/touch-first UX;
- path rerouting;
- campaign persistence.

## Files

- Create: `shadow-conquest/scripts/spike_scenario_catalog.gd`
- Create: `shadow-conquest/data/scenario_index.json`
- Create: `shadow-conquest/data/scenarios/mvp_map_1.json`
- Create: `shadow-conquest/data/scenarios/mvp_map_2.json`
- Create: `shadow-conquest/tests/fixtures/scenario_index_fixture.json`
- Create: `shadow-conquest/tests/fixtures/alternate_scenario.json`
- Create: `shadow-conquest/tests/smoke_scenario_catalog.gd`
- Create: `shadow-conquest/tests/smoke_scenario_selection.gd`
- Modify: `shadow-conquest/scripts/main.gd`
- Modify: `shadow-conquest/scripts/spike_hud.gd`
- Modify: `shadow-conquest/tests/smoke_main_scene.gd`
- Modify: `shadow-conquest/tests/smoke_spike_hud.gd`
- Modify: `docs/roadmap.md`
- Modify: `docs/changelog.md`

Do not edit `shadow-conquest/scenes/main.tscn` unless the implementation discovers a hard blocker. Existing `Main` exports can supply defaults from script.

## Verification Commands

Run from `D:\Projects\Games\td\shadow-conquest`.

Primary focused commands:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_scenario_catalog.gd
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_scenario_selection.gd
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_main_scene.gd
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_spike_hud.gd
```

Expected focused output after implementation:

```text
smoke_scenario_catalog: ok
smoke_scenario_selection: ok
smoke_main_scene: ok
smoke_spike_hud: ok
```

Final required command from project root `D:\Projects\Games\td`:

```powershell
npm.cmd test
```

Expected final result: `npm.cmd test` exits `0`.

Git commit steps are intentionally omitted because `D:\Projects\Games\td` and `shadow-conquest` are not currently git repositories. If a repository is restored later, commit after each completed task.

---

### Task 1: Add Scenario Catalog Loader

**Files:**
- Create: `shadow-conquest/scripts/spike_scenario_catalog.gd`
- Create: `shadow-conquest/tests/fixtures/scenario_index_fixture.json`
- Create: `shadow-conquest/tests/smoke_scenario_catalog.gd`

- [ ] **Step 1: Write the failing catalog smoke test**

Create `shadow-conquest/tests/smoke_scenario_catalog.gd`:

```gdscript
extends SceneTree

const CATALOG_SCRIPT_PATH := "res://scripts/spike_scenario_catalog.gd"
const FIXTURE_INDEX_PATH := "res://tests/fixtures/scenario_index_fixture.json"

func _init() -> void:
	var failures: Array[String] = []

	if not ResourceLoader.exists(CATALOG_SCRIPT_PATH):
		failures.append("Missing scenario catalog script at %s" % CATALOG_SCRIPT_PATH)
	elif not FileAccess.file_exists(FIXTURE_INDEX_PATH):
		failures.append("Missing scenario index fixture at %s" % FIXTURE_INDEX_PATH)
	else:
		var catalog_script := load(CATALOG_SCRIPT_PATH) as Script
		var catalog = catalog_script.new()
		if not bool(catalog.call("load_from_path", FIXTURE_INDEX_PATH)):
			failures.append("Scenario catalog should load the fixture index")
		if str(catalog.call("default_scenario_id")) != "fixture-map-1":
			failures.append("Scenario catalog must expose fixture default scenario id")
		if not bool(catalog.call("has_scenario", "fixture-map-2")):
			failures.append("Scenario catalog must find fixture-map-2 by id")
		if str(catalog.call("path_for_id", "fixture-map-1")) != "res://tests/fixtures/two_wave_scenario.json":
			failures.append("Scenario catalog must return the configured map path")
		var entries := catalog.call("entries") as Array
		if entries.size() != 2:
			failures.append("Scenario catalog must expose two entries, got %d" % entries.size())
		else:
			var first := entries[0] as Dictionary
			if str(first.get("name", "")) != "Fixture Map One":
				failures.append("Scenario catalog entries must keep display names")
			first["name"] = "Mutated"
			var fresh_entries := catalog.call("entries") as Array
			var fresh_first := fresh_entries[0] as Dictionary
			if str(fresh_first.get("name", "")) != "Fixture Map One":
				failures.append("Scenario catalog entries() must return defensive copies")
		if str(catalog.call("path_for_id", "missing-map")) != "":
			failures.append("Scenario catalog must return an empty path for unknown ids")

	if failures.is_empty():
		print("smoke_scenario_catalog: ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
```

- [ ] **Step 2: Write the fixture index**

Create `shadow-conquest/tests/fixtures/scenario_index_fixture.json`:

```json
{
  "defaultScenarioId": "fixture-map-1",
  "scenarios": [
    {
      "id": "fixture-map-1",
      "name": "Fixture Map One",
      "path": "res://tests/fixtures/two_wave_scenario.json",
      "summary": "Baseline fixture map."
    },
    {
      "id": "fixture-map-2",
      "name": "Fixture Map Two",
      "path": "res://tests/fixtures/alternate_scenario.json",
      "summary": "Alternate fixture map."
    }
  ]
}
```

- [ ] **Step 3: Run test to verify it fails**

Run:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_scenario_catalog.gd
```

Expected: FAIL with `Missing scenario catalog script at res://scripts/spike_scenario_catalog.gd`.

- [ ] **Step 4: Add the catalog loader**

Create `shadow-conquest/scripts/spike_scenario_catalog.gd`:

```gdscript
extends RefCounted
class_name SpikeScenarioCatalog

var _default_scenario_id := ""
var _entries: Array[Dictionary] = []
var _entries_by_id: Dictionary = {}

func load_from_path(index_path: String) -> bool:
	_default_scenario_id = ""
	_entries.clear()
	_entries_by_id.clear()

	if not FileAccess.file_exists(index_path):
		push_error("Missing scenario index data: %s" % index_path)
		return false

	var file := FileAccess.open(index_path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Scenario index data must be a JSON object.")
		return false

	var data := parsed as Dictionary
	_default_scenario_id = str(data.get("defaultScenarioId", ""))
	var scenarios_variant: Variant = data.get("scenarios", [])
	if typeof(scenarios_variant) != TYPE_ARRAY:
		push_error("Scenario index scenarios must be an array.")
		return false

	for scenario_variant: Variant in scenarios_variant:
		if typeof(scenario_variant) != TYPE_DICTIONARY:
			continue
		var scenario := scenario_variant as Dictionary
		var id := str(scenario.get("id", ""))
		var path := str(scenario.get("path", ""))
		if id == "" or path == "":
			continue
		if _entries_by_id.has(id):
			push_warning("Skipping duplicate scenario id in index: %s" % id)
			continue
		var entry := {
			"id": id,
			"name": str(scenario.get("name", id)),
			"path": path,
			"summary": str(scenario.get("summary", ""))
		}
		_entries.append(entry)
		_entries_by_id[id] = entry

	if _entries.is_empty():
		push_error("Scenario index must include at least one valid scenario.")
		return false
	if _default_scenario_id == "" or not _entries_by_id.has(_default_scenario_id):
		var first_entry := _entries[0]
		_default_scenario_id = str(first_entry.get("id", ""))

	return true

func entries() -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	for entry: Dictionary in _entries:
		output.append(entry.duplicate(true))
	return output

func default_scenario_id() -> String:
	return _default_scenario_id

func has_scenario(scenario_id: String) -> bool:
	return _entries_by_id.has(scenario_id)

func entry_for_id(scenario_id: String) -> Dictionary:
	if not _entries_by_id.has(scenario_id):
		return {}
	var entry := _entries_by_id[scenario_id] as Dictionary
	return entry.duplicate(true)

func path_for_id(scenario_id: String) -> String:
	if not _entries_by_id.has(scenario_id):
		return ""
	var entry := _entries_by_id[scenario_id] as Dictionary
	return str(entry.get("path", ""))

func name_for_id(scenario_id: String) -> String:
	if not _entries_by_id.has(scenario_id):
		return ""
	var entry := _entries_by_id[scenario_id] as Dictionary
	return str(entry.get("name", ""))
```

- [ ] **Step 5: Run test to verify it passes**

Run:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_scenario_catalog.gd
```

Expected: PASS with `smoke_scenario_catalog: ok`.

---

### Task 2: Add Two MVP Scenario Data Files

**Files:**
- Create: `shadow-conquest/data/scenario_index.json`
- Create: `shadow-conquest/data/scenarios/mvp_map_1.json`
- Create: `shadow-conquest/data/scenarios/mvp_map_2.json`
- Create: `shadow-conquest/tests/fixtures/alternate_scenario.json`
- Modify: `shadow-conquest/tests/smoke_main_scene.gd`

- [ ] **Step 1: Extend main-scene smoke coverage for scenario index data**

In `shadow-conquest/tests/smoke_main_scene.gd`, add constants near the existing constants:

```gdscript
const SCENARIO_INDEX_PATH := "res://data/scenario_index.json"
const MVP_MAP_1_PATH := "res://data/scenarios/mvp_map_1.json"
const MVP_MAP_2_PATH := "res://data/scenarios/mvp_map_2.json"
```

Add this check inside `_init()` after `_validate_catalog_shape(data, failures)`:

```gdscript
			if str(data.get("id", "")) == "":
				failures.append("Default spike scenario data must include a scenario id")
			if str(data.get("name", "")) == "":
				failures.append("Default spike scenario data must include a scenario name")
```

Add this call before loading the main scene:

```gdscript
	_validate_mvp_scenario_index(failures)
```

Add this helper at the end of the file:

```gdscript
func _validate_mvp_scenario_index(failures: Array[String]) -> void:
	if not FileAccess.file_exists(SCENARIO_INDEX_PATH):
		failures.append("Missing MVP scenario index at %s" % SCENARIO_INDEX_PATH)
		return

	var index_file := FileAccess.open(SCENARIO_INDEX_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(index_file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		failures.append("MVP scenario index must be a JSON object")
		return

	var index := parsed as Dictionary
	if str(index.get("defaultScenarioId", "")) != "mvp-map-1":
		failures.append("MVP scenario index must default to mvp-map-1")
	var scenarios_variant: Variant = index.get("scenarios", [])
	if typeof(scenarios_variant) != TYPE_ARRAY:
		failures.append("MVP scenario index scenarios must be an array")
		return

	var ids: Dictionary = {}
	for scenario_variant: Variant in scenarios_variant:
		if typeof(scenario_variant) != TYPE_DICTIONARY:
			failures.append("MVP scenario index entries must be objects")
			continue
		var scenario := scenario_variant as Dictionary
		var id := str(scenario.get("id", ""))
		var path := str(scenario.get("path", ""))
		ids[id] = true
		if id == "":
			failures.append("MVP scenario index entry must include id")
		if str(scenario.get("name", "")) == "":
			failures.append("MVP scenario index entry %s must include name" % id)
		if path == "" or not FileAccess.file_exists(path):
			failures.append("MVP scenario index entry %s must point to an existing file" % id)

	if not ids.has("mvp-map-1"):
		failures.append("MVP scenario index must include mvp-map-1")
	if not ids.has("mvp-map-2"):
		failures.append("MVP scenario index must include mvp-map-2")
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_main_scene.gd
```

Expected: FAIL with `Missing MVP scenario index at res://data/scenario_index.json`.

- [ ] **Step 3: Create the production scenario index**

Create `shadow-conquest/data/scenario_index.json`:

```json
{
  "defaultScenarioId": "mvp-map-1",
  "scenarios": [
    {
      "id": "mvp-map-1",
      "name": "Black Gate Muster",
      "path": "res://data/scenarios/mvp_map_1.json",
      "summary": "A short baseline Shadow foothold map."
    },
    {
      "id": "mvp-map-2",
      "name": "Ithilien Pressure",
      "path": "res://data/scenarios/mvp_map_2.json",
      "summary": "A second map with longer pressure and more varied resistance."
    }
  ]
}
```

- [ ] **Step 4: Create MVP map scenario files**

Create `shadow-conquest/data/scenarios/mvp_map_1.json` by copying the current `shadow-conquest/data/spike_scenario.json`, then add these top-level fields immediately after `{`:

```json
  "id": "mvp-map-1",
  "name": "Black Gate Muster",
```

Create `shadow-conquest/data/scenarios/mvp_map_2.json` by copying `mvp_map_1.json`, then change these fields:

```json
  "id": "mvp-map-2",
  "name": "Ithilien Pressure",
```

In `mvp_map_2.json`, change `gameState.baseLives` to `6`, change `board.width` to `10`, and replace `path.points` with:

```json
    "points": [
      { "x": 0, "z": 4 },
      { "x": 1, "z": 4 },
      { "x": 2, "z": 3 },
      { "x": 3, "z": 3 },
      { "x": 4, "z": 4 },
      { "x": 5, "z": 4 },
      { "x": 6, "z": 3 },
      { "x": 7, "z": 3 },
      { "x": 8, "z": 2 },
      { "x": 9, "z": 2 }
    ]
```

Leave tower placements and wave data as temporary spike content for this block. Build spots, economy, and balance arrive in later MVP plans.

- [ ] **Step 5: Create alternate fixture scenario**

Create `shadow-conquest/tests/fixtures/alternate_scenario.json`:

```json
{
  "id": "fixture-map-2",
  "name": "Fixture Map Two",
  "board": {
    "width": 5,
    "height": 4,
    "tileSize": 1.0
  },
  "gameState": {
    "baseLives": 3
  },
  "path": {
    "id": "fixture-road-two",
    "points": [
      { "x": 0, "z": 2 },
      { "x": 1, "z": 2 },
      { "x": 2, "z": 2 },
      { "x": 3, "z": 1 },
      { "x": 4, "z": 1 }
    ]
  },
  "towers": {
    "catalog": [],
    "placements": []
  },
  "obstacles": {
    "catalog": [],
    "placements": []
  },
  "terrainProps": {
    "catalog": [],
    "placements": []
  },
  "enemies": {
    "catalog": [
      {
        "id": "test-soldier",
        "name": "Test Soldier",
        "faction": "free-peoples",
        "health": 10,
        "speed": 0.0,
        "reward": 1,
        "damage": 1
      }
    ]
  },
  "waves": [
    {
      "id": "alternate-wave-1",
      "spawns": [
        {
          "enemyId": "test-soldier",
          "count": 1,
          "delay": 0.0,
          "interval": 1.0
        }
      ]
    }
  ]
}
```

- [ ] **Step 6: Run main-scene smoke test**

Run:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_main_scene.gd
```

Expected: PASS with `smoke_main_scene: ok`.

---

### Task 3: Add Main Scenario Switching API

**Files:**
- Modify: `shadow-conquest/scripts/main.gd`
- Create: `shadow-conquest/tests/smoke_scenario_selection.gd`

- [ ] **Step 1: Write failing scenario selection smoke test**

Create `shadow-conquest/tests/smoke_scenario_selection.gd`:

```gdscript
extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const FIXTURE_INDEX_PATH := "res://tests/fixtures/scenario_index_fixture.json"

func _init() -> void:
	var failures: Array[String] = []

	if not ResourceLoader.exists(MAIN_SCENE_PATH):
		failures.append("Missing main scene at %s" % MAIN_SCENE_PATH)
	elif not FileAccess.file_exists(FIXTURE_INDEX_PATH):
		failures.append("Missing scenario index fixture at %s" % FIXTURE_INDEX_PATH)
	else:
		var packed_main := load(MAIN_SCENE_PATH) as PackedScene
		var main := packed_main.instantiate() as Node
		main.set("scenario_index_path", FIXTURE_INDEX_PATH)
		get_root().add_child(main)
		main.call("_ready")

		if not main.has_method("available_scenarios"):
			failures.append("Main must expose available_scenarios()")
		if not main.has_method("load_scenario_by_id"):
			failures.append("Main must expose load_scenario_by_id()")
		if not main.has_method("active_scenario_id"):
			failures.append("Main must expose active_scenario_id()")
		if not main.has_method("active_scenario_name"):
			failures.append("Main must expose active_scenario_name()")

		if failures.is_empty():
			var entries := main.call("available_scenarios") as Array
			if entries.size() != 2:
				failures.append("Main must expose two fixture scenarios")
			if str(main.call("active_scenario_id")) != "fixture-map-1":
				failures.append("Main must load the catalog default scenario first")
			if str(main.call("active_scenario_name")) != "Fixture Map One":
				failures.append("Main must expose the active scenario display name")
			var game_state := main.get_node_or_null("GameStateAdapter")
			if game_state == null:
				failures.append("Scenario selection requires GameStateAdapter")
			elif int(game_state.call("get_base_lives")) != 2:
				failures.append("Default fixture map should start with two lives")

			if not bool(main.call("load_scenario_by_id", "fixture-map-2")):
				failures.append("Main must load fixture-map-2 by id")
			if str(main.call("active_scenario_id")) != "fixture-map-2":
				failures.append("Main active id must update after scenario switch")
			if str(main.call("active_scenario_name")) != "Fixture Map Two":
				failures.append("Main active name must update after scenario switch")
			if game_state != null and int(game_state.call("get_base_lives")) != 3:
				failures.append("Scenario switch must rebuild runtime with second map lives")
			if bool(main.call("load_scenario_by_id", "missing-map")):
				failures.append("Main must reject unknown scenario ids")

		main.free()

	if failures.is_empty():
		print("smoke_scenario_selection: ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_scenario_selection.gd
```

Expected: FAIL with `Main must expose available_scenarios()` or missing `scenario_index_path` behavior.

- [ ] **Step 3: Add catalog state and public methods to Main**

In `shadow-conquest/scripts/main.gd`, add near the existing exports/constants:

```gdscript
@export_file("*.json") var scenario_index_path: String = "res://data/scenario_index.json"

const SCENARIO_CATALOG_SCRIPT := preload("res://scripts/spike_scenario_catalog.gd")
```

Add near the other runtime variables:

```gdscript
var _scenario_catalog: RefCounted = SCENARIO_CATALOG_SCRIPT.new()
var _active_scenario_id := ""
var _active_scenario_name := ""
```

Replace the start of `_ready()` up to `_cache_path()` with:

```gdscript
func _ready() -> void:
	_configure_scenario_catalog()
	_load_initial_scenario()
	tower_attack_adapter.call("set_combat_adapter", combat_adapter)
	wave_state_adapter.call("set_combat_adapter", combat_adapter)
	var wave_clear_callback := Callable(self, "_on_wave_cleared")
	if wave_state_adapter.has_signal("wave_cleared") and not wave_state_adapter.is_connected("wave_cleared", wave_clear_callback):
		wave_state_adapter.connect("wave_cleared", wave_clear_callback)
	_start_runtime_from_scenario()
	hud.call("bind_adapters", game_state_adapter, wave_state_adapter, combat_adapter, _scenario_waves().size())
	_bind_hud_action_signals()
```

Add these methods before `_start_runtime_from_scenario()`:

```gdscript
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
	hud.call("refresh")
	return true

func _configure_scenario_catalog() -> void:
	if scenario_index_path != "" and FileAccess.file_exists(scenario_index_path):
		_scenario_catalog.call("load_from_path", scenario_index_path)

func _load_initial_scenario() -> void:
	var default_id := ""
	if _scenario_catalog.has_method("default_scenario_id"):
		default_id = str(_scenario_catalog.call("default_scenario_id"))
	if default_id != "" and load_scenario_by_id(default_id):
		return

	_scenario = _load_scenario_from_path(scenario_path)
	_active_scenario_id = str(_scenario.get("id", ""))
	_active_scenario_name = str(_scenario.get("name", _active_scenario_id))
	_cache_catalogs()
	_cache_path()
```

Rename the existing `_load_scenario()` to `_load_scenario_from_path(path: String)` and update its body:

```gdscript
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
```

Remove the old `_load_scenario()` method after this replacement.

- [ ] **Step 4: Run focused scenario selection test**

Run:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_scenario_selection.gd
```

Expected: PASS with `smoke_scenario_selection: ok`.

- [ ] **Step 5: Run regression smokes**

Run:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_scenario_progression.gd
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_main_scene.gd
```

Expected:

```text
smoke_scenario_progression: ok
smoke_main_scene: ok
```

---

### Task 4: Add Compact HUD Scenario Selector

**Files:**
- Modify: `shadow-conquest/scripts/spike_hud.gd`
- Modify: `shadow-conquest/scripts/main.gd`
- Modify: `shadow-conquest/tests/smoke_spike_hud.gd`

- [ ] **Step 1: Extend HUD smoke coverage**

In `shadow-conquest/tests/smoke_spike_hud.gd`, add `scenario_selected` to the signal check in `_validate_main_hud_boundary`:

```gdscript
		for signal_name in ["next_wave_requested", "restart_requested", "scenario_selected"]:
			if not hud.has_signal(signal_name):
				failures.append("Spike HUD must expose %s signal" % signal_name)
```

Add `bind_scenarios` and `active_scenario_id` to the method check:

```gdscript
		for method_name in ["bind_adapters", "bind_scenarios", "refresh", "debug_text", "active_scenario_id"]:
			if not hud.has_method(method_name):
				failures.append("Spike HUD must expose %s()" % method_name)
```

Add this helper near the other helper functions:

```gdscript
func _validate_hud_scenario_selector(failures: Array[String]) -> void:
	var hud_script := load(HUD_SCRIPT_PATH) as Script
	if hud_script == null:
		return

	var hud := Control.new()
	hud.set_script(hud_script)
	get_root().add_child(hud)
	hud.call("_ready")
	var entries: Array = [
		{
			"id": "fixture-map-1",
			"name": "Fixture Map One",
			"path": "res://tests/fixtures/two_wave_scenario.json",
			"summary": ""
		},
		{
			"id": "fixture-map-2",
			"name": "Fixture Map Two",
			"path": "res://tests/fixtures/alternate_scenario.json",
			"summary": ""
		}
	]
	hud.call("bind_scenarios", entries, "fixture-map-1")
	var selector := hud.get_node_or_null("HudBar/ScenarioSelect") as OptionButton
	if selector == null:
		failures.append("HUD must create ScenarioSelect OptionButton")
	else:
		if selector.item_count != 2:
			failures.append("HUD ScenarioSelect must show two scenario options")
		if selector.get_item_text(0) != "Fixture Map One":
			failures.append("HUD ScenarioSelect must use scenario display names")
		if str(hud.call("active_scenario_id")) != "fixture-map-1":
			failures.append("HUD must track active scenario id")
		var selected_ids: Array[String] = []
		hud.connect("scenario_selected", func(scenario_id: String) -> void:
			selected_ids.append(scenario_id)
		)
		selector.select(1)
		selector.emit_signal("item_selected", 1)
		if selected_ids.size() != 1 or selected_ids[0] != "fixture-map-2":
			failures.append("HUD ScenarioSelect must emit selected scenario id")

	hud.free()
```

Call it from `_init()` after `_validate_main_hud_action_wiring(failures)`:

```gdscript
	_validate_hud_scenario_selector(failures)
```

- [ ] **Step 2: Run HUD test to verify it fails**

Run:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_spike_hud.gd
```

Expected: FAIL with missing `scenario_selected` signal or `bind_scenarios()`.

- [ ] **Step 3: Add HUD selector API**

In `shadow-conquest/scripts/spike_hud.gd`, add signal near existing signals:

```gdscript
signal scenario_selected(scenario_id: String)
```

Add variables near existing HUD node variables:

```gdscript
var _scenario_entries: Array = []
var _active_scenario_id := ""
var _scenario_select: OptionButton = null
```

Add public methods after `bind_adapters()`:

```gdscript
func bind_scenarios(entries: Array, active_scenario_id: String) -> void:
	_scenario_entries = []
	for entry_variant: Variant in entries:
		if typeof(entry_variant) == TYPE_DICTIONARY:
			_scenario_entries.append((entry_variant as Dictionary).duplicate(true))
	_active_scenario_id = active_scenario_id
	_ensure_nodes()
	_rebuild_scenario_select()

func active_scenario_id() -> String:
	return _active_scenario_id
```

In `_ensure_nodes()`, call `_ensure_scenario_select()` before `_ensure_action_button()`:

```gdscript
	_ensure_scenario_select()
	_ensure_action_button()
```

Add these helper methods before `_ensure_action_button()`:

```gdscript
func _ensure_scenario_select() -> void:
	if _scenario_select == null:
		_scenario_select = _hud_bar.get_node_or_null("ScenarioSelect") as OptionButton
	if _scenario_select == null:
		_scenario_select = OptionButton.new()
		_scenario_select.name = "ScenarioSelect"
		_scenario_select.mouse_filter = Control.MOUSE_FILTER_STOP
		_scenario_select.focus_mode = Control.FOCUS_NONE
		_scenario_select.add_theme_font_size_override("font_size", 13)
		_hud_bar.add_child(_scenario_select)

	var callback := Callable(self, "_on_scenario_select_item_selected")
	if not _scenario_select.is_connected("item_selected", callback):
		_scenario_select.connect("item_selected", callback)
	_rebuild_scenario_select()

func _rebuild_scenario_select() -> void:
	if _scenario_select == null:
		return

	_scenario_select.clear()
	var selected_index := 0
	for index in range(_scenario_entries.size()):
		var entry := _scenario_entries[index] as Dictionary
		var scenario_id := str(entry.get("id", ""))
		var scenario_name := str(entry.get("name", scenario_id))
		_scenario_select.add_item(scenario_name, index)
		_scenario_select.set_item_metadata(index, scenario_id)
		if scenario_id == _active_scenario_id:
			selected_index = index
	if _scenario_entries.is_empty():
		_scenario_select.visible = false
	else:
		_scenario_select.visible = true
		_scenario_select.select(selected_index)
```

Add this callback near `_on_action_button_pressed()`:

```gdscript
func _on_scenario_select_item_selected(index: int) -> void:
	if _scenario_select == null or index < 0 or index >= _scenario_select.item_count:
		return
	var metadata: Variant = _scenario_select.get_item_metadata(index)
	var scenario_id := str(metadata)
	if scenario_id == "" or scenario_id == _active_scenario_id:
		return
	_active_scenario_id = scenario_id
	scenario_selected.emit(scenario_id)
```

Update layout widths in `_layout_hud_bar_for_width()` by replacing the desktop sizing block:

```gdscript
	var gap := 8.0
	var padding := 10.0
	var selector_width := 170.0
	var action_width := 120.0
	var cell_width := (bar_width - padding * 2.0 - gap * 6.0 - selector_width - action_width) / 5.0
	var x := padding
	if _scenario_select != null:
		_scenario_select.position = Vector2(x, 17.0)
		_scenario_select.size = Vector2(selector_width, 30.0)
	x += selector_width + gap
	for label_name in ["State", "Wave", "Lives", "Breaches", "Enemies"]:
		_layout_field(label_name, x, cell_width, 8.0, 25.0, 28.0)
		x += cell_width + gap
	_layout_action_button(bar_width - padding - action_width, 17.0, action_width, 30.0)
```

Update `_layout_mobile_hud_bar()` with a compact selector position:

```gdscript
	if _scenario_select != null:
		_scenario_select.position = Vector2(padding, 58.0)
		_scenario_select.size = Vector2(112.0, 26.0)
```

- [ ] **Step 4: Bind HUD selector in Main**

In `shadow-conquest/scripts/main.gd`, after each existing `hud.call("bind_adapters", ...)`, add:

```gdscript
	hud.call("bind_scenarios", available_scenarios(), _active_scenario_id)
```

In `_bind_hud_action_signals()`, add:

```gdscript
	var scenario_callback := Callable(self, "_on_hud_scenario_selected")
	if hud.has_signal("scenario_selected") and not hud.is_connected("scenario_selected", scenario_callback):
		hud.connect("scenario_selected", scenario_callback)
```

Add this callback near the other HUD callbacks:

```gdscript
func _on_hud_scenario_selected(scenario_id: String) -> void:
	if load_scenario_by_id(scenario_id):
		hud.call("bind_scenarios", available_scenarios(), _active_scenario_id)
		hud.call("refresh")
```

- [ ] **Step 5: Run HUD and scenario selection tests**

Run:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_spike_hud.gd
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_scenario_selection.gd
```

Expected:

```text
smoke_spike_hud: ok
smoke_scenario_selection: ok
```

---

### Task 5: Documentation And Final Verification

**Files:**
- Modify: `docs/roadmap.md`
- Modify: `docs/changelog.md`

- [ ] **Step 1: Update roadmap**

In `docs/roadmap.md`, under the accepted two-map desktop MVP direction, add:

```markdown
   - Scenario selection/loading foundation: done when `res://data/scenario_index.json` owns two MVP map entries, `SpikeScenarioCatalog` loads scenario index data, `Main.load_scenario_by_id(id)` rebuilds the current runtime by scenario id, and `SpikeHud` exposes a compact desktop scenario selector. This remains scenario loading only; build spots, tower purchasing, economy, upgrades, balance, and campaign persistence stay in later MVP blocks.
```

- [ ] **Step 2: Update changelog**

In `docs/changelog.md`, under `## 2026-05-03`, add:

```markdown
- Added the scenario selection/loading foundation plan for the two-map desktop MVP corridor at `docs/superpowers/plans/2026-05-03-godot-scenario-selection-foundation.md`.
```

After implementation, replace that line with:

```markdown
- Implemented the scenario selection/loading foundation for the two-map desktop MVP corridor: added `scenario_index.json`, two MVP scenario files, `SpikeScenarioCatalog`, runtime scenario switching in `Main`, a compact HUD scenario selector, and smoke coverage for catalog loading, scenario switching, main scene data shape, and HUD selection wiring. Build spots, tower purchasing, economy, upgrades, balance, and campaign persistence remain out of scope for this block.
```

- [ ] **Step 3: Run focused Godot smokes**

Run:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_scenario_catalog.gd
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_scenario_selection.gd
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_main_scene.gd
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_spike_hud.gd
```

Expected:

```text
smoke_scenario_catalog: ok
smoke_scenario_selection: ok
smoke_main_scene: ok
smoke_spike_hud: ok
```

- [ ] **Step 4: Run full project test command**

From `D:\Projects\Games\td`, run:

```powershell
npm.cmd test
```

Expected: command exits `0`.

- [ ] **Step 5: Record verification output in final response**

Final response must mention:
- plan path;
- implemented files if execution happened;
- focused Godot smoke result;
- `npm.cmd test` result;
- no git commit was made because the workspace is not a git repository.

## Self-Review

Spec coverage:
- Two map scenario foundation: covered by Tasks 1-3.
- Player-facing scenario choice: covered by Task 4.
- Data-driven scenario boundaries: covered by Tasks 1-2.
- No economy/build spot creep: stated in scope and Task 5 changelog language.
- Smoke coverage: covered by Tasks 1, 3, 4, and 5.

Placeholder scan:
- No placeholder markers or unnamed future implementation remains in required steps.

Type consistency:
- `SpikeScenarioCatalog.load_from_path`, `entries`, `default_scenario_id`, `has_scenario`, `path_for_id`, and `name_for_id` are used consistently across tests and `Main`.
- `Main.available_scenarios`, `load_scenario_by_id`, `active_scenario_id`, and `active_scenario_name` are used consistently in tests and HUD binding.
- `SpikeHud.bind_scenarios`, `active_scenario_id`, and `scenario_selected` are used consistently in tests and `Main`.
