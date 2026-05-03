# Godot Blocker Contact Readability Capture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a capture-only Godot preview for the existing enemy/blocker contact state.

**Architecture:** Reuse the established smoke-contract pattern in `smoke_obstacle_proxy.gd` and add one self-contained `SceneTree` capture script under `shadow-conquest/tests`. The script observes current runtime state through existing `Main`, `SpikeObstacleTowerAdapter`, and `PlaceholderEnemy` APIs; it does not add production scene nodes or gameplay rules.

**Tech Stack:** Godot 4.6.2, GDScript, local smoke scripts, existing JSON spike scenario.

---

### Task 1: RED Capture Contract

**Files:**
- Modify: `shadow-conquest/tests/smoke_obstacle_proxy.gd`
- Create later: `shadow-conquest/tests/capture_blocker_contact_preview.gd`

- [ ] **Step 1: Add the failing contract**

Add `BLOCKER_CONTACT_CAPTURE_SCRIPT_PATH := "res://tests/capture_blocker_contact_preview.gd"` next to the existing capture constants.

Call `_validate_blocker_contact_capture_contract(failures)` after the slow-zone capture validations.

Add:

```gdscript
func _validate_blocker_contact_capture_contract(failures: Array[String]) -> void:
	var absolute_path := ProjectSettings.globalize_path(BLOCKER_CONTACT_CAPTURE_SCRIPT_PATH)
	if not FileAccess.file_exists(BLOCKER_CONTACT_CAPTURE_SCRIPT_PATH):
		failures.append("Missing blocker-contact capture script at %s" % BLOCKER_CONTACT_CAPTURE_SCRIPT_PATH)
		return

	var script_text := FileAccess.get_file_as_string(absolute_path)
	if not script_text.contains("blocker_contact_preview.png"):
		failures.append("Blocker-contact capture must save blocker_contact_preview.png")
	if not script_text.contains("Vector2i(1280, 720)"):
		failures.append("Blocker-contact capture must use desktop viewport 1280x720")
	if not script_text.contains("get_blockers"):
		failures.append("Blocker-contact capture must read blocker snapshots from the obstacle adapter")
	if not script_text.contains("current_blocker_id"):
		failures.append("Blocker-contact capture must verify current_blocker_id() before saving")
	if not script_text.contains("BlockerContactReviewMarker"):
		failures.append("Blocker-contact capture must add a capture-only BlockerContactReviewMarker")
```

- [ ] **Step 2: Run the focused smoke and verify RED**

Run from `shadow-conquest`:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_obstacle_proxy.gd
```

Expected: FAIL containing `Missing blocker-contact capture script at res://tests/capture_blocker_contact_preview.gd`.

### Task 2: GREEN Capture Script

**Files:**
- Create: `shadow-conquest/tests/capture_blocker_contact_preview.gd`

- [ ] **Step 1: Add the capture script**

Create a `SceneTree` script that:
- loads `res://scenes/main.tscn`;
- sets `DisplayServer.window_set_size(Vector2i(1280, 720))`;
- waits for one spawned enemy;
- waits for a runtime blocker through `ObstacleTowerAdapter.get_blockers()`;
- positions the enemy on the blocker;
- calls `enemy.set_blockers(blockers)`;
- verifies `enemy.current_blocker_id()`;
- advances `Main` and the enemy enough to exercise the existing damage bridge;
- adds a `BlockerContactReviewMarker` ring and label;
- saves `res://builds/previews/blocker_contact_preview.png`.

- [ ] **Step 2: Run the focused smoke and verify GREEN**

Run:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_obstacle_proxy.gd
```

Expected: PASS with `smoke_obstacle_proxy: ok`.

### Task 3: Documentation And Full Verification

**Files:**
- Modify: `docs/decisions.md`
- Modify: `docs/roadmap.md`
- Modify: `docs/changelog.md`
- Modify: `docs/mechanics.md`
- Modify: `docs/visual-style.md`
- Modify: `docs/lore-and-factions.md`
- Modify: `docs/android-porting.md`

- [ ] **Step 1: Update project notes**

Record that blocker-contact readability is capture-only instrumentation and does not add production visuals, path rerouting, stacking rules, rewards, balance, or UI.

- [ ] **Step 2: Run all Godot smoke scripts**

Run each `shadow-conquest/tests/smoke_*.gd` with Godot headless and fail on any non-zero exit code.

- [ ] **Step 3: Run browser/prototype tests**

Run from `D:\Projects\Games\td`:

```powershell
npm.cmd test
```

Expected: all tests pass.

## Self-Review

The plan covers the full design: smoke contract first, capture script second, docs and verification last. It contains exact files, commands, and expected outcomes. No production gameplay, UI, VFX, pathing, balance, or reward behavior is part of this plan.
