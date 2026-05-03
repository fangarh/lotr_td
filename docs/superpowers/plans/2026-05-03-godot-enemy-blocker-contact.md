# Godot Enemy Blocker Contact Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let Godot spike enemies stop at temporary blockers and request adapter-owned blocker damage.

**Architecture:** `PlaceholderEnemy` owns local movement pause/contact detection and emits a signal when it attacks a blocker. `Main` bridges that signal into `SpikeObstacleTowerAdapter.apply_blocker_damage()`, while blocker HP/removal stays fully owned by the obstacle adapter.

**Tech Stack:** Godot 4.6.2, GDScript, headless smoke scripts, JSON-backed spike scenario data, Obsidian project notes.

---

## File Structure

- Modify `shadow-conquest/tests/smoke_enemy_proxy.gd`: add RED coverage for enemy blocker snapshots, contact stop, current blocker id, attack signal, and resume after blocker removal.
- Modify `shadow-conquest/tests/smoke_obstacle_proxy.gd`: add RED main-scene coverage that an already-spawned enemy receives runtime blockers and damages/removes one through `Main`.
- Modify `shadow-conquest/scripts/placeholder_enemy.gd`: add blocker snapshot APIs, contact detection, movement pause, attack cadence, and `blocker_attack_requested` signal.
- Modify `shadow-conquest/scripts/main.gd`: sync adapter blocker output into spawned enemies and bridge enemy blocker attack signals to `SpikeObstacleTowerAdapter.apply_blocker_damage()`.
- Modify project docs: record the implemented boundary and its explicit exclusions.

---

### Task 1: Enemy RED Coverage

**Files:**
- Modify: `shadow-conquest/tests/smoke_enemy_proxy.gd`
- Test: `shadow-conquest/tests/smoke_enemy_proxy.gd`

- [ ] **Step 1: Write failing smoke coverage**

Add a local signal counter at file scope:

```gdscript
var _blocker_attack_events := 0
var _last_blocker_id := ""
var _last_blocker_damage := 0.0
```

Add this helper:

```gdscript
func _on_blocker_attack_requested(blocker_id: String, amount: float) -> void:
	_blocker_attack_events += 1
	_last_blocker_id = blocker_id
	_last_blocker_damage = amount
```

Add a new blocker section after the existing slow-zone section:

```gdscript
		var blocker_enemy := slow_test_scene.instantiate() as Node3D
		if blocker_enemy == null:
			failures.append("Enemy scene must instantiate for blocker contact coverage")
		else:
			if not blocker_enemy.has_signal("blocker_attack_requested"):
				failures.append("Enemy proxy must expose blocker_attack_requested(blocker_id, amount)")
			if not blocker_enemy.has_method("set_blockers"):
				failures.append("Enemy proxy must expose set_blockers(blockers)")
			if not blocker_enemy.has_method("get_blocker_count"):
				failures.append("Enemy proxy must expose get_blocker_count()")
			if not blocker_enemy.has_method("current_blocker_id"):
				failures.append("Enemy proxy must expose current_blocker_id()")

			var blocker_path_points: Array[Vector3] = [
				Vector3(0.0, 0.18, 0.0),
				Vector3(4.0, 0.18, 0.0),
			]
			blocker_enemy.call("setup", blocker_path_points, 1.0)
			if blocker_enemy.has_method("set_blockers"):
				blocker_enemy.call("set_blockers", [{
					"id": "blocker-test",
					"position": Vector3(0.0, 0.18, 0.0),
					"radius": 0.7,
					"currentHealth": 8.0,
				}])
			if blocker_enemy.has_method("get_blocker_count") and int(blocker_enemy.call("get_blocker_count")) != 1:
				failures.append("Enemy must store one valid blocker snapshot")
			_blocker_attack_events = 0
			_last_blocker_id = ""
			_last_blocker_damage = 0.0
			if blocker_enemy.has_signal("blocker_attack_requested"):
				blocker_enemy.connect("blocker_attack_requested", Callable(self, "_on_blocker_attack_requested"))
			blocker_enemy.call("_process", 0.5)
			if blocker_enemy.position.x > 0.01:
				failures.append("Enemy must stop movement while touching a blocker")
			if blocker_enemy.has_method("current_blocker_id") and str(blocker_enemy.call("current_blocker_id")) != "blocker-test":
				failures.append("Enemy must report the current blocker id while blocked")
			if _blocker_attack_events < 1:
				failures.append("Enemy must request blocker damage while blocked")
			if _last_blocker_id != "blocker-test":
				failures.append("Enemy blocker damage signal must include blocker id")
			if _last_blocker_damage <= 0.0:
				failures.append("Enemy blocker damage signal must include positive damage")
			if blocker_enemy.has_method("set_blockers"):
				blocker_enemy.call("set_blockers", [])
			blocker_enemy.call("_process", 0.5)
			if blocker_enemy.position.x <= 0.01:
				failures.append("Enemy must resume movement after blocker list no longer contains the blocker")
			blocker_enemy.free()
```

- [ ] **Step 2: Run RED**

Run from `D:\Projects\Games\td\shadow-conquest`:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_enemy_proxy.gd
```

Expected: FAIL because `PlaceholderEnemy` does not yet expose blocker contact APIs or signal.

---

### Task 2: Main RED Coverage

**Files:**
- Modify: `shadow-conquest/tests/smoke_obstacle_proxy.gd`
- Test: `shadow-conquest/tests/smoke_obstacle_proxy.gd`

- [ ] **Step 1: Write failing main-scene coverage**

In the main-scene blocker check, after verifying `sourceTowerId`, capture current HP, run `main._process()`, and verify HP drops or the blocker is removed:

```gdscript
							var blocker_id := str(blocker.get("id", ""))
							var blocker_hp := float(blocker.get("currentHealth", 0.0))
							enemy.position = blocker.get("position", enemy.position)
							main.call("_process", 0.6)
							var blockers_after_attack := obstacle_tower_adapter.call("get_blockers") as Array
							var found_blocker_after_attack := false
							for blocker_after_variant: Variant in blockers_after_attack:
								var blocker_after := blocker_after_variant as Dictionary
								if str(blocker_after.get("id", "")) != blocker_id:
									continue
								found_blocker_after_attack = true
								if float(blocker_after.get("currentHealth", blocker_hp)) >= blocker_hp:
									failures.append("Main must bridge enemy blocker attacks into ObstacleTowerAdapter damage")
							if not found_blocker_after_attack and blocker_hp <= 0.0:
								failures.append("Main-scene blocker fixture must start with positive HP before attack coverage")
```

- [ ] **Step 2: Run RED**

Run:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_obstacle_proxy.gd
```

Expected: FAIL because `Main` does not yet sync blockers into enemies or bridge blocker attack signals.

---

### Task 3: Minimal Implementation

**Files:**
- Modify: `shadow-conquest/scripts/placeholder_enemy.gd`
- Modify: `shadow-conquest/scripts/main.gd`
- Tests: `shadow-conquest/tests/smoke_enemy_proxy.gd`, `shadow-conquest/tests/smoke_obstacle_proxy.gd`

- [ ] **Step 1: Implement `PlaceholderEnemy` blocker contact**

Add:
- `signal blocker_attack_requested(blocker_id: String, amount: float)`;
- `_blockers: Array[Dictionary]`;
- `_blocker_attack_cooldown`;
- constants for attack interval and damage;
- `set_blockers()`, `get_blocker_count()`, `current_blocker_id()`;
- movement pause and attack request inside `_process(delta)`.

- [ ] **Step 2: Implement `Main` sync/bridge**

Add:
- `_sync_blockers_to_spawned_enemies()` after obstacle adapter advancement;
- `_apply_current_blockers_to_enemy(enemy)`;
- connection to `blocker_attack_requested` during enemy spawn;
- `_on_enemy_blocker_attack_requested(blocker_id, amount)` calling `obstacle_tower_adapter.apply_blocker_damage(...)`.

- [ ] **Step 3: Run focused GREEN**

Run:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_enemy_proxy.gd
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_obstacle_proxy.gd
```

Expected: both PASS.

---

### Task 4: Documentation Update

**Files:**
- Modify: `docs/decisions.md`
- Modify: `docs/roadmap.md`
- Modify: `docs/changelog.md`
- Modify: `docs/mechanics.md`
- Modify: `docs/android-porting.md`
- Modify: `docs/lore-and-factions.md`
- Modify: `docs/visual-style.md`

- [ ] **Step 1: Record the boundary**

Document that the first enemy/blocker interaction is implemented as contact stop plus signal-bridged damage.

Explicitly preserve out-of-scope:
- path rerouting;
- stacking policy;
- attack animation/final VFX;
- production spawned blocker visuals;
- rewards, score, gold, wave/game-state ownership;
- tower retargeting;
- balance, upgrades, costs, production placement UI.

---

### Task 5: Final Verification

**Files:**
- Test: all `shadow-conquest/tests/smoke_*.gd`
- Test: root Node test suite

- [ ] **Step 1: Run all Godot smoke tests**

Run from `shadow-conquest`:

```powershell
$godot = 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe'
$failures = @()
foreach ($test in Get-ChildItem tests -Filter 'smoke_*.gd') {
  & $godot --headless --path . --script "res://tests/$($test.Name)"
  if ($LASTEXITCODE -ne 0) { $failures += $test.Name }
}
if ($failures.Count -gt 0) {
  Write-Error "Godot smoke failures: $($failures -join ', ')"
  exit 1
}
Write-Output 'all godot smoke tests passed'
```

Expected: PASS.

- [ ] **Step 2: Run root JavaScript tests**

Run from repo root:

```powershell
npm.cmd test
```

Expected: PASS.
