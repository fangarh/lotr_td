# Godot Build Spots Purchasing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add scenario-authored build spots and first tower purchasing for the desktop Godot MVP corridor.

**Architecture:** Add a narrow `SpikeBuildStateAdapter` for build/economy rules, keep `Main` as the scene composition root, and keep `SpikeHud` as an intent-only UI adapter. Existing tower attack and obstacle adapters must receive purchased towers through the same registration path used by JSON `towers.placements`.

**Tech Stack:** Godot 4.6.2, GDScript, JSON scenario data, headless Godot smoke scripts, Node `npm.cmd test`.

---

### Task 1: Build State Adapter

**Files:**
- Create: `shadow-conquest/scripts/spike_build_state_adapter.gd`
- Create: `shadow-conquest/tests/smoke_build_state_adapter.gd`

- [ ] Write `smoke_build_state_adapter.gd` first and verify it fails because `res://scripts/spike_build_state_adapter.gd` is missing.
- [ ] Implement `SpikeBuildStateAdapter` as a `Node` with `configure`, `get_gold`, `get_build_spots`, `get_available_build_spots`, `get_tower_options`, `can_build_at`, and `build_at`.
- [ ] Cover these behaviors in the smoke test: starting gold clamps to zero or above, tower costs clamp to zero or above, occupied cells are unavailable, `allowedTypeIds` is respected, successful build spends gold and marks the spot occupied, unaffordable build returns `ok=false` with `reason="insufficient_gold"`, unknown spot/type returns a refusal, returned arrays are defensive copies.
- [ ] Run `D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_build_state_adapter.gd` from `shadow-conquest`.
- [ ] Commit as `feat: add build state adapter`.

### Task 2: Main Scene And Scenario Data Integration

**Files:**
- Modify: `shadow-conquest/scenes/main.tscn`
- Modify: `shadow-conquest/scripts/main.gd`
- Modify: `shadow-conquest/data/spike_scenario.json`
- Modify: `shadow-conquest/data/scenarios/mvp_map_1.json`
- Modify: `shadow-conquest/data/scenarios/mvp_map_2.json`
- Modify: `shadow-conquest/tests/fixtures/two_wave_scenario.json`
- Modify: `shadow-conquest/tests/fixtures/alternate_scenario.json`
- Modify: `shadow-conquest/tests/smoke_main_scene.gd`
- Create: `shadow-conquest/tests/smoke_build_spots_purchasing.gd`

- [ ] Write `smoke_build_spots_purchasing.gd` first and verify it fails because `Main` has no build adapter/API yet.
- [ ] Add `BuildStateAdapter` to `main.tscn` using `res://scripts/spike_build_state_adapter.gd`.
- [ ] Add `World/BuildSpots` as a separate marker root.
- [ ] Add `_build_state_adapter`, `_build_spots` root, `_spawn_build_spot_markers`, `_scenario_starting_gold`, `_scenario_build_spots`, `_occupied_cells_from_initial_towers`, `_spawn_tower_at_cell`, `build_tower_at_spot`, `get_build_gold`, `get_available_build_spots`, and `get_tower_build_options` to `Main`.
- [ ] Refactor `_spawn_towers` through `_spawn_tower_at_cell` so prebuilt and purchased towers register with attack and obstacle adapters identically.
- [ ] Configure build state during `_start_runtime_from_scenario` after catalogs/path are cached and before HUD binding refresh.
- [ ] Add `gameState.startingGold`, `towers.catalog[].cost`, and `towers.buildSpots` to the default spike scenario and both MVP maps. Keep current `placements` valid for existing visual/attack smoke coverage unless the test explicitly needs an empty fixture.
- [ ] Extend main-scene smoke coverage so data shape requires `startingGold`, tower costs, and build spots for MVP scenarios.
- [ ] Verify successful purchase increases `World/Towers` child count, increments `TowerAttackAdapter.get_registered_tower_count()`, spends gold, and removes the used spot from available build spots.
- [ ] Verify invalid/duplicate/unknown/unaffordable purchase refuses without spawning a tower.
- [ ] Run `smoke_build_spots_purchasing.gd`, `smoke_main_scene.gd`, and `smoke_scenario_selection.gd`.
- [ ] Commit as `feat: wire build spots into main scene`.

### Task 3: HUD Build Controls

**Files:**
- Modify: `shadow-conquest/scripts/spike_hud.gd`
- Modify: `shadow-conquest/scripts/main.gd`
- Modify: `shadow-conquest/tests/smoke_spike_hud.gd`
- Modify: `shadow-conquest/tests/smoke_build_spots_purchasing.gd`

- [ ] Extend `smoke_spike_hud.gd` first and verify it fails because HUD has no build controls or `build_requested` signal.
- [ ] Add `build_requested(spot_id, tower_type_id)` to `SpikeHud`.
- [ ] Add `bind_build_state(gold, build_spots, tower_options)` and `active_build_spot_id()` / `active_tower_type_id()` helpers.
- [ ] Create `BuildSpotSelect`, `TowerTypeSelect`, `GoldValue`, and `BuildButton` under `HudBar` or a compact build strip owned by the HUD.
- [ ] Keep existing scenario selector/action button behavior unchanged.
- [ ] Connect HUD build requests in `Main` to `build_tower_at_spot`, then refresh HUD build state after successful or refused attempts.
- [ ] Ensure narrow layout does not overlap existing top-bar values; hiding the build controls on narrow mobile is acceptable for this desktop block.
- [ ] Run `smoke_spike_hud.gd` and `smoke_build_spots_purchasing.gd`.
- [ ] Commit as `feat: add HUD tower purchase controls`.

### Task 4: Documentation And Final Verification

**Files:**
- Modify: `docs/decisions.md`
- Modify: `docs/roadmap.md`
- Modify: `docs/mechanics.md`
- Modify: `docs/visual-style.md`
- Modify: `docs/android-porting.md`
- Modify: `docs/changelog.md`

- [ ] Update Obsidian notes with the accepted implementation boundary and what remains out of scope.
- [ ] Run focused Godot smokes: `smoke_build_state_adapter.gd`, `smoke_build_spots_purchasing.gd`, `smoke_main_scene.gd`, `smoke_scenario_selection.gd`, `smoke_spike_hud.gd`.
- [ ] Run `npm.cmd test` from the worktree root.
- [ ] Commit as `docs: record build spots purchasing`.

