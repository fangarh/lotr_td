# Godot Obstacle Tower Ownership Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a narrow `SpikeObstacleTowerAdapter` boundary that owns runtime obstacle effect registration while preserving the current slow-zone gameplay behavior.

**Architecture:** `Main` stays the composition root and still spawns visual obstacle proxies. A new scene-level `SpikeObstacleTowerAdapter` owns obstacle effect registration and exposes read-only slow-zone dictionaries to enemy spawns. `PlaceholderEnemy` continues to apply slow multipliers locally, while `SpikeTowerAttackAdapter` remains the enemy damage/cooldown owner.

**Tech Stack:** Godot 4.6.2, GDScript, `.tscn` scene serialization, JSON scenario data, existing headless Godot smoke scripts, npm test suite for browser reference code.

---

### Task 1: Red Test For Adapter Boundary

**Files:**
- Modify: `shadow-conquest/tests/smoke_obstacle_proxy.gd`
- Test: `shadow-conquest/tests/smoke_obstacle_proxy.gd`

- [x] **Step 1: Write the failing test**

Add expectations that:
- `res://scripts/spike_obstacle_tower_adapter.gd` exists;
- a new adapter can register a `slow-zone` obstacle and expose one slow zone;
- visual-only data does not create slow zones;
- `scenes/main.tscn` contains `ObstacleTowerAdapter`;
- spawned enemies still receive at least one slow zone.

- [x] **Step 2: Run test to verify it fails**

Run from `shadow-conquest/`:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_obstacle_proxy.gd
```

Expected: FAIL because `spike_obstacle_tower_adapter.gd` and `ObstacleTowerAdapter` do not exist yet.

### Task 2: Minimal Adapter Implementation

**Files:**
- Create: `shadow-conquest/scripts/spike_obstacle_tower_adapter.gd`
- Modify: `shadow-conquest/scenes/main.tscn`
- Test: `shadow-conquest/tests/smoke_obstacle_proxy.gd`

- [x] **Step 1: Create adapter script**

Implement:
- `reset_runtime_state()`;
- `register_obstacle(obstacle: Node3D, data: Dictionary, world_position: Vector3)`;
- `get_registered_obstacle_count() -> int`;
- `get_slow_zone_count() -> int`;
- `get_slow_zones() -> Array[Dictionary]`.

Clamp `radius` to `>= 0.0` and `slowMultiplier` to `0.0..1.0`. Only `effect: "slow-zone"` creates slow-zone data.

- [x] **Step 2: Add scene node**

Add an `ext_resource` for `res://scripts/spike_obstacle_tower_adapter.gd` and a root child node:

```gdscene
[node name="ObstacleTowerAdapter" type="Node" parent="."]
script = ExtResource("...")
```

- [x] **Step 3: Run focused test**

Run:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_obstacle_proxy.gd
```

Expected: adapter unit checks pass, but main-scene wiring may still fail until Task 3.

### Task 3: Move Slow-Zone Ownership Out Of Main

**Files:**
- Modify: `shadow-conquest/scripts/main.gd`
- Test: `shadow-conquest/tests/smoke_obstacle_proxy.gd`

- [x] **Step 1: Wire adapter in `Main`**

Add `@onready var obstacle_tower_adapter: Node = $ObstacleTowerAdapter`.

Remove `_slow_zones` storage and `_collect_slow_zone_from_obstacle()`.

During runtime reset, call `obstacle_tower_adapter.reset_runtime_state()`.

During `_spawn_obstacles()`, after spawning a visual obstacle, call:

```gdscript
obstacle_tower_adapter.call("register_obstacle", obstacle, obstacle_config, world_position)
```

During enemy spawn, call:

```gdscript
enemy.call("set_slow_zones", obstacle_tower_adapter.call("get_slow_zones"))
```

- [x] **Step 2: Run focused test**

Run:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_obstacle_proxy.gd
```

Expected: PASS.

### Task 4: Documentation And Full Verification

**Files:**
- Modify: `docs/decisions.md`
- Modify: `docs/roadmap.md`
- Modify: `docs/mechanics.md`
- Modify: `docs/android-porting.md`
- Modify: `docs/changelog.md`

- [x] **Step 1: Update Obsidian notes**

Record that `SpikeObstacleTowerAdapter` now owns runtime obstacle effect registration from static JSON placements. Explicitly state that blocker HP, path blocking/rerouting, stacking rules, obstacle lifetime, tower cooldown spawning, enemy blocker attacks, production placement UI, rewards, damage, and balance remain out of scope.

- [x] **Step 2: Run full Godot smoke**

Run the existing full Godot smoke command for all smoke scripts under `shadow-conquest/tests`.

Expected: all smoke scripts pass. The known root certificate warning is environmental if exit code is `0`.

- [x] **Step 3: Run browser reference tests**

Run from repo root:

```powershell
npm.cmd test
```

Expected: all npm tests pass.
