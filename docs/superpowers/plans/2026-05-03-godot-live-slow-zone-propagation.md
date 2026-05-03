# Godot Live Slow-Zone Propagation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Synchronize current obstacle adapter slow zones into already-spawned enemies so timed tower-owned zones affect active enemies.

**Architecture:** `SpikeObstacleTowerAdapter` remains the owner of runtime slow-zone dictionaries. `Main` acts as the scene coordinator that pushes the adapter's current read-only slow-zone list to active `PlaceholderEnemy` proxies. `PlaceholderEnemy` continues to own movement slow application.

**Tech Stack:** Godot 4.6.2, GDScript, headless Godot smoke scripts, JSON-backed spike scenario, Node `npm.cmd test`.

---

### Task 1: Red Smoke For Live Propagation

**Files:**
- Modify: `shadow-conquest/tests/smoke_obstacle_proxy.gd`

- [x] **Step 1: Write failing smoke assertion**

Extend the main-scene section to:
- capture first spawned enemy slow-zone count after `_ready()`;
- advance `Main._process(1.2)` so the timed tower-owned slow zone spawns;
- assert adapter slow-zone count increased;
- assert the already-spawned enemy slow-zone count also increased.

- [x] **Step 2: Run focused smoke and verify RED**

Run from `shadow-conquest/`:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_obstacle_proxy.gd
```

Expected: FAIL because existing spawned enemies are not updated after timed slow zones spawn.

### Task 2: Main Slow-Zone Synchronization

**Files:**
- Modify: `shadow-conquest/scripts/main.gd`

- [x] **Step 1: Add synchronization helper**

Add a helper in `Main` that reads `obstacle_tower_adapter.get_slow_zones()` and calls `set_slow_zones(zones)` on current children of `World/Enemies` that expose that method.

- [x] **Step 2: Call helper in runtime flow**

Call the helper:
- after `obstacle_tower_adapter.advance(delta)` in `_process(delta)`;
- after `_spawn_enemy_from_request()` configures a new enemy, so immediate spawn behavior remains explicit.

- [x] **Step 3: Run focused smoke and verify GREEN**

Run:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_obstacle_proxy.gd
```

Expected: PASS.

### Task 3: Docs And Verification

**Files:**
- Modify: `docs/decisions.md`
- Modify: `docs/roadmap.md`
- Modify: `docs/mechanics.md`
- Modify: `docs/android-porting.md`
- Modify: `docs/changelog.md`

- [x] **Step 1: Update Obsidian notes**

Record that live slow-zone propagation is implemented through `Main` synchronization. Explicitly keep blocker HP, path blocking/rerouting, stacking policy, enemy blocker attacks, visual spawned props, production placement UI, rewards, damage, and balance out of scope.

- [x] **Step 2: Run full Godot smoke**

Run all `smoke_*.gd` scripts under `shadow-conquest/tests` sequentially with Godot.

Expected: all smoke scripts pass. The known root certificate warning is environmental if exit code is `0`.

- [x] **Step 3: Run npm tests**

Run from repo root:

```powershell
npm.cmd test
```

Expected: all tests pass.
