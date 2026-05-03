# Godot Obstacle Slow-Zone Spike Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the first slow-zone gameplay contract for existing Godot corrupted-roots obstacle proxies.

**Architecture:** `Main` keeps composition ownership by translating JSON obstacle placements into world-space slow-zone dictionaries. `PlaceholderEnemy` keeps movement ownership and applies the strongest active slow multiplier during its existing path traversal.

**Tech Stack:** Godot 4.6 GDScript, JSON-backed spike scenario data, headless Godot smoke tests, Node `npm.cmd test`.

---

### Task 1: Slow-Zone Enemy Contract

**Files:**
- Modify: `shadow-conquest/tests/smoke_enemy_proxy.gd`
- Modify: `shadow-conquest/scripts/placeholder_enemy.gd`

- [ ] **Step 1: Write the failing test**

Extend `smoke_enemy_proxy.gd` with a path through a slow zone. The test should call `set_slow_zones()` and `current_slow_multiplier()` on a `PlaceholderEnemy`, then verify slowed movement is shorter than unslowed movement.

- [ ] **Step 2: Run test to verify it fails**

Run from `shadow-conquest/`:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_enemy_proxy.gd
```

Expected: FAIL because the slow-zone methods are missing.

- [ ] **Step 3: Write minimal implementation**

Add `_slow_zones`, `set_slow_zones(zones)`, `current_slow_multiplier()`, and multiply movement distance by the current multiplier in `_process(delta)`.

- [ ] **Step 4: Run test to verify it passes**

Run the same smoke test. Expected: exit code 0 and `smoke_enemy_proxy: ok`.

### Task 2: Scenario Slow-Zone Wiring

**Files:**
- Modify: `shadow-conquest/data/spike_scenario.json`
- Modify: `shadow-conquest/scripts/main.gd`
- Modify: `shadow-conquest/tests/smoke_obstacle_proxy.gd`

- [ ] **Step 1: Write the failing scenario wiring test**

Extend `smoke_obstacle_proxy.gd` to instantiate the main scene, wait for the first enemy spawn, and assert that the spawned enemy exposes at least one active slow zone.

- [ ] **Step 2: Run test to verify it fails**

Run from `shadow-conquest/`:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_obstacle_proxy.gd
```

Expected: FAIL because `Main` does not pass slow zones to enemies and obstacle data is still visual-only.

- [ ] **Step 3: Write minimal implementation**

Add `effect: "slow-zone"`, `slowMultiplier`, and `radius` to the corrupted-roots catalog entry. In `Main`, cache placed slow zones during obstacle spawning and call `enemy.set_slow_zones(_slow_zones)` before adding each spawned enemy.

- [ ] **Step 4: Run test to verify it passes**

Run the same smoke test. Expected: exit code 0 and `smoke_obstacle_proxy: ok`.

### Task 3: Documentation And Verification

**Files:**
- Modify: `docs/decisions.md`
- Modify: `docs/roadmap.md`
- Modify: `docs/mechanics.md`
- Modify: `docs/android-porting.md`
- Modify: `docs/changelog.md`

- [ ] **Step 1: Update Obsidian notes**

Record that the first obstacle gameplay contract is a slow-zone-only spike and explicitly keep pathing rewrite, blocker HP, enemy blocker attacks, balance, and production placement UI out of scope.

- [ ] **Step 2: Run full Godot smoke**

Run the project's full Godot smoke suite from `shadow-conquest/` using the existing test scripts. Expected: all smoke scripts pass; ignore the known root certificate warning when exit code is 0.

- [ ] **Step 3: Run browser prototype tests**

Run from repository root:

```powershell
npm.cmd test
```

Expected: all Node tests pass.
