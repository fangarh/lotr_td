# Godot Timed Slow-Zone Readability Capture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a capture-only Godot preview proving timed tower-owned slow zones affect active enemies and are readable in a PNG review artifact.

**Architecture:** Keep gameplay ownership unchanged. `Main` and `SpikeObstacleTowerAdapter` continue to own the live timed slow-zone behavior; the new script only drives the existing scene, verifies the current runtime state, adds capture-only marker nodes, and saves a PNG.

**Tech Stack:** Godot 4.6 GDScript, existing `SceneTree` smoke/capture scripts, Obsidian project docs.

---

### Task 1: Lock The Capture Contract

**Files:**
- Modify: `shadow-conquest/tests/smoke_obstacle_proxy.gd`
- Test: `shadow-conquest/tests/smoke_obstacle_proxy.gd`

- [ ] Add constants for `res://tests/capture_timed_slow_zone_preview.gd` and `timed_slow_zone_preview.png`.
- [ ] Extend the smoke contract to require the new capture script, desktop `1280x720`, `TimedSlowZoneReviewMarker`, a wait for timed slow-zone spawn, and `current_slow_multiplier()` verification.
- [ ] Run `D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_obstacle_proxy.gd` from `shadow-conquest/` and confirm it fails because the script is missing.

### Task 2: Add The Capture Script

**Files:**
- Create: `shadow-conquest/tests/capture_timed_slow_zone_preview.gd`
- Test: `shadow-conquest/tests/smoke_obstacle_proxy.gd`

- [ ] Instantiate `res://scenes/main.tscn` in a `SceneTree` script.
- [ ] Set desktop viewport size to `1280x720`.
- [ ] Let the main scene spawn its initial enemy, then advance `_process()` until `ObstacleTowerAdapter.get_slow_zone_count()` grows beyond the initial static obstacle count.
- [ ] Move the first active enemy to the newest timed slow zone and assert `current_slow_multiplier() < 1.0`.
- [ ] Add capture-only `TimedSlowZoneReviewMarker` / ring / label helpers.
- [ ] Save `res://builds/previews/timed_slow_zone_preview.png`.
- [ ] Rerun the focused smoke and confirm it passes.

### Task 3: Update Project Memory And Verify

**Files:**
- Modify: `docs/decisions.md`
- Modify: `docs/roadmap.md`
- Modify: `docs/mechanics.md`
- Modify: `docs/visual-style.md`
- Modify: `docs/changelog.md`

- [ ] Record the capture-only decision and out-of-scope boundaries.
- [ ] Update roadmap status so this slice is done and the next recommendation returns to temporary blocker HP contract design.
- [ ] Run all Godot smoke scripts under `shadow-conquest/tests`.
- [ ] Run `npm.cmd test` from the repository root.
