# Godot Timed Slow-Zone Spawning Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let one Godot spike tower periodically create temporary slow-zone effects through `SpikeObstacleTowerAdapter`.

**Architecture:** `Main` remains the composition root and registers towers with both tower attack and obstacle tower adapters. `SpikeObstacleTowerAdapter` owns obstacle cadence and runtime slow-zone lifetime. `PlaceholderEnemy` continues to apply slow multipliers from read-only slow-zone dictionaries.

**Tech Stack:** Godot 4.6.2, GDScript, JSON-backed scenario data, headless Godot smoke scripts, Node `npm.cmd test`.

---

### Task 1: Red Smoke For Timed Spawning

**Files:**
- Modify: `shadow-conquest/tests/smoke_obstacle_proxy.gd`

- [x] **Step 1: Write the failing smoke assertions**

Extend `_validate_obstacle_tower_adapter()` to require:
- `set_path_points(path_points)`;
- `register_tower(tower, tower_data, obstacle_catalog)`;
- `advance(delta)`;
- no spawned slow zone before interval;
- one spawned slow zone after interval;
- spawned slow zone expiry after lifetime;
- missing effect ids do not spawn zones.

- [x] **Step 2: Run focused smoke and verify RED**

Run from `shadow-conquest/`:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_obstacle_proxy.gd
```

Expected: FAIL because `SpikeObstacleTowerAdapter` does not expose timed tower spawn methods yet.

### Task 2: Adapter Timed Runtime

**Files:**
- Modify: `shadow-conquest/scripts/spike_obstacle_tower_adapter.gd`

- [x] **Step 1: Implement minimal timed spawning**

Add:
- `_path_points`;
- `_registered_towers`;
- `_spawned_slow_zones`;
- `set_path_points(path_points)`;
- `register_tower(tower, data, obstacle_catalog)`;
- `advance(delta)`.

The first implementation should choose the nearest path point within `obstacleSpawnRange`, spawn a slow-zone dictionary after `obstacleSpawnInterval`, and remove spawned zones after `obstacleSpawnLifetime`.

- [x] **Step 2: Run focused smoke and verify GREEN for adapter**

Run:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_obstacle_proxy.gd
```

Expected: adapter timed spawning checks pass; main-scene wiring may still need Task 3.

### Task 3: Main And Scenario Wiring

**Files:**
- Modify: `shadow-conquest/scripts/main.gd`
- Modify: `shadow-conquest/data/spike_scenario.json`
- Modify: `shadow-conquest/tests/smoke_obstacle_proxy.gd`

- [x] **Step 1: Add data to one tower candidate**

Add to one existing tower catalog entry:
- `obstacleEffectId: "corrupted-roots"`;
- `obstacleSpawnInterval`;
- `obstacleSpawnLifetime`;
- `obstacleSpawnRange`.

- [x] **Step 2: Wire `Main`**

Call `obstacle_tower_adapter.set_path_points(_path_points)` after path cache/runtime reset is ready, call `obstacle_tower_adapter.register_tower(tower, tower_config, _obstacle_catalog)` during `_spawn_towers()`, and call `obstacle_tower_adapter.advance(delta)` from `_process(delta)`.

- [x] **Step 3: Extend main-scene smoke**

Assert that `Main` registers at least one timed obstacle tower and that advancing the main scene creates more slow zones than the static obstacle placements alone.

- [x] **Step 4: Run focused smoke**

Run:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_obstacle_proxy.gd
```

Expected: PASS.

### Task 4: Docs And Verification

**Files:**
- Modify: `docs/decisions.md`
- Modify: `docs/roadmap.md`
- Modify: `docs/mechanics.md`
- Modify: `docs/android-porting.md`
- Modify: `docs/changelog.md`

- [x] **Step 1: Update Obsidian notes**

Record that timed slow-zone spawning is implemented through `SpikeObstacleTowerAdapter`, with no blocker HP, path blocking/rerouting, stacking rules, enemy blocker attacks, production UI, rewards, damage, visual spawned props, or balance changes.

- [x] **Step 2: Run full Godot smoke**

Run all `smoke_*.gd` scripts under `shadow-conquest/tests` sequentially with Godot.

Expected: all smoke scripts pass. The known root certificate warning is environmental if exit code is `0`.

- [x] **Step 3: Run npm tests**

Run from repo root:

```powershell
npm.cmd test
```

Expected: all tests pass.
