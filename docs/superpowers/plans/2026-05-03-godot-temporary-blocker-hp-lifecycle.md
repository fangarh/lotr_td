# Godot Temporary Blocker HP Lifecycle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the first adapter-owned temporary blocker HP/lifetime lifecycle contract to the Godot spike.

**Architecture:** `SpikeObstacleTowerAdapter` remains the only runtime owner for obstacle lifecycle data. It will keep existing slow-zone behavior intact, add separate temporary blocker entries, and expose read-only blocker diagnostics plus explicit damage/removal APIs.

**Tech Stack:** Godot 4.6.2, GDScript, headless smoke scripts, JSON-backed spike scenario data, Obsidian project notes.

---

## File Structure

- Modify `shadow-conquest/tests/smoke_obstacle_proxy.gd`: add failing smoke coverage for blocker API, spawn, read-only output, damage, lethal removal, lifetime expiry, reset, and main-scene registration.
- Modify `shadow-conquest/scripts/spike_obstacle_tower_adapter.gd`: add blocker runtime dictionaries, tower registration for `effect: "temporary-blocker"`, output APIs, damage/removal, and lifetime aging.
- Modify `shadow-conquest/data/spike_scenario.json`: add a blocker-capable obstacle catalog entry and one tower reference for main-scene registration/spawn coverage.
- Modify `docs/decisions.md`, `docs/roadmap.md`, `docs/changelog.md`, `docs/mechanics.md`, `docs/visual-style.md`, `docs/android-porting.md`, and `docs/lore-and-factions.md`: record that the blocker HP lifecycle contract is implemented and still excludes movement blocking, enemy attacks, rerouting, stacking, rewards, production UI, balance, and final blocker visuals.

---

### Task 1: Failing Blocker Smoke Coverage

**Files:**
- Modify: `shadow-conquest/tests/smoke_obstacle_proxy.gd`
- Test: `shadow-conquest/tests/smoke_obstacle_proxy.gd`

- [ ] **Step 1: Write the failing test**

Add checks inside `_validate_obstacle_tower_adapter(failures)` after the existing timed slow-zone tests:

```gdscript
	adapter.call("reset_runtime_state")
	adapter.call("set_path_points", [
		Vector3(0.75, 0.18, 0.0),
		Vector3(4.0, 0.18, 0.0),
	])
	var blocker_tower := Node3D.new()
	blocker_tower.position = Vector3(0.0, 0.0, 0.0)
	adapter.call("register_tower", blocker_tower, {
		"id": "blocker-test-tower",
		"obstacleEffectId": "orc-blockade",
		"obstacleSpawnInterval": 0.4,
		"obstacleSpawnLifetime": 1.0,
		"obstacleSpawnRange": 2.0,
	}, {
		"orc-blockade": {
			"effect": "temporary-blocker",
			"radius": 0.7,
			"maxHealth": 30.0,
			"lifetime": 1.0,
		}
	})
	if not adapter.has_method("get_blocker_count"):
		failures.append("Obstacle tower adapter must expose get_blocker_count()")
	if not adapter.has_method("get_blockers"):
		failures.append("Obstacle tower adapter must expose get_blockers()")
	if not adapter.has_method("apply_blocker_damage"):
		failures.append("Obstacle tower adapter must expose apply_blocker_damage(blocker_id, amount)")
	adapter.call("advance", 0.4)
	if int(adapter.call("get_blocker_count")) != 1:
		failures.append("Temporary blocker tower effect must spawn one runtime blocker when interval elapses")
	else:
		var blockers := adapter.call("get_blockers") as Array
		var blocker := blockers[0] as Dictionary
		var blocker_id := str(blocker.get("id", ""))
		var blocker_position: Vector3 = blocker.get("position", Vector3.ZERO)
		if blocker_id == "":
			failures.append("Runtime blocker output must include a stable id")
		if blocker_position.distance_to(Vector3(0.75, 0.18, 0.0)) > 0.01:
			failures.append("Runtime blocker must spawn at the nearest path point in range")
		if str(blocker.get("sourceTowerId", "")) != "blocker-test-tower":
			failures.append("Runtime blocker must expose sourceTowerId from tower data")
		if not is_equal_approx(float(blocker.get("radius", 0.0)), 0.7):
			failures.append("Runtime blocker must expose configured radius")
		if not is_equal_approx(float(blocker.get("maxHealth", 0.0)), 30.0):
			failures.append("Runtime blocker must expose configured maxHealth")
		if not is_equal_approx(float(blocker.get("currentHealth", 0.0)), 30.0):
			failures.append("Runtime blocker must start at max health")
		if not is_equal_approx(float(blocker.get("remainingLifetime", 0.0)), 1.0):
			failures.append("Runtime blocker must expose remaining lifetime")
		blocker["currentHealth"] = 1.0
		var blockers_after_mutation := adapter.call("get_blockers") as Array
		var blocker_after_mutation := blockers_after_mutation[0] as Dictionary
		if not is_equal_approx(float(blocker_after_mutation.get("currentHealth", 0.0)), 30.0):
			failures.append("get_blockers() must return read-only copies instead of live blocker state")
		if bool(adapter.call("apply_blocker_damage", blocker_id, -5.0)):
			failures.append("Negative blocker damage must not remove a blocker")
		var damaged := (adapter.call("get_blockers") as Array)[0] as Dictionary
		if not is_equal_approx(float(damaged.get("currentHealth", 0.0)), 30.0):
			failures.append("Negative blocker damage must not reduce HP")
		if bool(adapter.call("apply_blocker_damage", blocker_id, 12.5)):
			failures.append("Non-lethal blocker damage must return false")
		damaged = (adapter.call("get_blockers") as Array)[0] as Dictionary
		if not is_equal_approx(float(damaged.get("currentHealth", 0.0)), 17.5):
			failures.append("Non-lethal blocker damage must reduce currentHealth")
		if not bool(adapter.call("apply_blocker_damage", blocker_id, 18.0)):
			failures.append("Lethal blocker damage must return true")
		if int(adapter.call("get_blocker_count")) != 0:
			failures.append("Lethal blocker damage must remove blocker from output")

	adapter.call("advance", 0.4)
	if int(adapter.call("get_blocker_count")) != 1:
		failures.append("Blocker tower must be able to spawn a second blocker after cooldown")
	else:
		var expiring_blocker := (adapter.call("get_blockers") as Array)[0] as Dictionary
		adapter.call("advance", 1.01)
		if int(adapter.call("get_blocker_count")) != 0:
			failures.append("Runtime blocker must expire after configured lifetime")
		if bool(adapter.call("apply_blocker_damage", str(expiring_blocker.get("id", "")), 1.0)):
			failures.append("Damage against an expired blocker id must return false")

	blocker_tower.free()
```

Add main-scene coverage inside the existing main scene block after timed slow-zone assertions:

```gdscript
			if obstacle_tower_adapter.has_method("get_blocker_count"):
				main.call("_process", 1.2)
				if int(obstacle_tower_adapter.call("get_blocker_count")) < 1:
					failures.append("Main scene must spawn a temporary blocker through ObstacleTowerAdapter")
				var blockers := obstacle_tower_adapter.call("get_blockers") as Array
				if not blockers.is_empty():
					var blocker := blockers[0] as Dictionary
					if str(blocker.get("sourceTowerId", "")) == "":
						failures.append("Main-scene blocker output must include sourceTowerId")
```

- [ ] **Step 2: Run test to verify it fails**

Run from `D:\Projects\Games\td\shadow-conquest`:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_obstacle_proxy.gd
```

Expected: FAIL because `SpikeObstacleTowerAdapter` does not yet expose blocker APIs or spawn temporary blockers.

---

### Task 2: Minimal Adapter Blocker Lifecycle

**Files:**
- Modify: `shadow-conquest/scripts/spike_obstacle_tower_adapter.gd`
- Test: `shadow-conquest/tests/smoke_obstacle_proxy.gd`

- [ ] **Step 1: Implement the minimal code**

Add a separate `_blockers` array, `_next_blocker_id`, read-only output methods, `apply_blocker_damage()`, tower registration for `temporary-blocker`, spawn logic, and lifetime aging. Keep slow zones separate and unchanged.

Implementation requirements:
- `reset_runtime_state()` clears blockers and resets id counter.
- `register_tower()` accepts both `slow-zone` and `temporary-blocker` effects.
- `_advance_registered_towers()` dispatches by effect type.
- Blocker output dictionaries include `id`, `position`, `radius`, `maxHealth`, `currentHealth`, optional `remainingLifetime`, and `sourceTowerId`.
- Damage is clamped to non-negative values.
- Lethal damage removes the blocker and returns `true`.
- Missing ids, expired ids, and non-lethal damage return `false`.

- [ ] **Step 2: Run test to verify it passes**

Run:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_obstacle_proxy.gd
```

Expected: PASS with `smoke_obstacle_proxy: ok`.

---

### Task 3: Scenario Main-Scene Blocker Fixture

**Files:**
- Modify: `shadow-conquest/data/spike_scenario.json`
- Test: `shadow-conquest/tests/smoke_obstacle_proxy.gd`

- [ ] **Step 1: Add blocker fixture data**

Add a new obstacle catalog entry:

```json
{
  "id": "orc-blockade",
  "name": "Orc Blockade",
  "role": "temporary-blocker-contract",
  "effect": "temporary-blocker",
  "maxHealth": 30,
  "radius": 0.72,
  "lifetime": 1.2
}
```

Add `obstacleEffectId`, `obstacleSpawnInterval`, `obstacleSpawnLifetime`, and `obstacleSpawnRange` to one non-slow-zone tower candidate, preferably `shadow-tower-b3`, so the existing B2 slow-zone contract remains untouched:

```json
"obstacleEffectId": "orc-blockade",
"obstacleSpawnInterval": 1.0,
"obstacleSpawnLifetime": 1.2,
"obstacleSpawnRange": 2.2,
```

- [ ] **Step 2: Run test to verify it passes**

Run:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_obstacle_proxy.gd
```

Expected: PASS with `smoke_obstacle_proxy: ok`.

---

### Task 4: Obsidian Documentation Update

**Files:**
- Modify: `docs/decisions.md`
- Modify: `docs/roadmap.md`
- Modify: `docs/changelog.md`
- Modify: `docs/mechanics.md`
- Modify: `docs/visual-style.md`
- Modify: `docs/android-porting.md`
- Modify: `docs/lore-and-factions.md`

- [ ] **Step 1: Record implementation boundary**

Update notes to state that the first temporary blocker HP/lifetime lifecycle contract is implemented in `SpikeObstacleTowerAdapter`, using read-only blocker output and explicit damage/removal APIs.

The docs must explicitly preserve the out-of-scope list:
- no enemy movement blocking;
- no enemy blocker attacks;
- no path rerouting;
- no stacking policy;
- no tower retargeting;
- no rewards, score, wave/game-state ownership, or balance changes;
- no production placement UI;
- no final spawned blocker visuals.

- [ ] **Step 2: Run documentation sanity search**

Run:

```powershell
rg "Temporary blocker|blocker HP|temporary blocker|orc-blockade|Orc Blockade" docs shadow-conquest\data\spike_scenario.json shadow-conquest\scripts\spike_obstacle_tower_adapter.gd shadow-conquest\tests\smoke_obstacle_proxy.gd
```

Expected: updated docs and code references appear; no stale note says blocker HP is only the next implementation step.

---

### Task 5: Final Verification

**Files:**
- Test: `shadow-conquest/tests/smoke_obstacle_proxy.gd`
- Test: root Node test suite

- [ ] **Step 1: Run focused Godot smoke**

Run:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path shadow-conquest --script res://tests/smoke_obstacle_proxy.gd
```

Expected: PASS with `smoke_obstacle_proxy: ok`.

- [ ] **Step 2: Run JavaScript regression tests**

Run from repo root:

```powershell
npm.cmd test
```

Expected: PASS.

- [ ] **Step 3: Check no unintended generated outputs are required**

Run:

```powershell
Get-ChildItem shadow-conquest\builds -Recurse -Force | Select-Object -First 5
```

Expected: no blocker implementation depends on regenerated preview/build outputs.
