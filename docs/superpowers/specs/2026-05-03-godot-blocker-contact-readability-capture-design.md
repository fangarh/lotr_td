# Godot Blocker Contact Readability Capture Design

## Context

The Godot spike now has adapter-owned temporary blockers and the first enemy/blocker contact interaction. `SpikeObstacleTowerAdapter` spawns `temporary-blocker` dictionaries, `Main` synchronizes those snapshots into spawned enemies, and `PlaceholderEnemy` stops while inside a blocker radius and emits `blocker_attack_requested(blocker_id, amount)`.

There is still no visual review artifact for that interaction. Slow-zone behavior already has capture-only scripts that verify runtime state before saving PNG previews. Blocker contact should follow that pattern before any production VFX, spawned blocker prop, animation, queueing, or pathing work.

## Accepted Approach

Add a capture-only Godot script at `shadow-conquest/tests/capture_blocker_contact_preview.gd`.

The script will:
- instantiate `res://scenes/main.tscn`;
- use a desktop `Vector2i(1280, 720)` viewport;
- disable tower attack auto-advance for a quieter review frame;
- wait for the existing `shadow-tower-b3` / `orc-blockade` temporary blocker fixture;
- use an already-spawned enemy, move it onto the blocker position, and call `set_blockers()` with adapter output;
- verify `current_blocker_id()` is non-empty before saving;
- advance the enemy enough to request blocker damage, then verify adapter HP changed or the blocker was removed by the existing bridge;
- add capture-only `BlockerContactReviewMarker` helpers with a ring and label;
- save `res://builds/previews/blocker_contact_preview.png`.

## Scope

In scope:
- a smoke-test contract for the capture script path and required text markers;
- the capture script itself;
- Obsidian notes that describe the new review artifact.

Out of scope:
- production blocker visuals;
- enemy attack animations;
- final VFX, particles, or UI;
- path rerouting;
- blocker stacking policy;
- enemy queueing or spread behavior;
- tower retargeting;
- rewards, score, gold, balance, upgrades, or costs;
- wave/game-state ownership changes;
- production placement UI.

## Testing

Use TDD through `smoke_obstacle_proxy.gd`:
- RED: add a capture contract that fails because `res://tests/capture_blocker_contact_preview.gd` does not exist.
- GREEN: add the capture script with the expected output filename, viewport, blocker APIs, current blocker assertion, bridge verification, and `BlockerContactReviewMarker`.

Then run:
- focused `smoke_obstacle_proxy.gd`;
- all `smoke_*.gd` scripts under `shadow-conquest/tests`;
- `npm.cmd test` from the repository root.

## Self-Review

No placeholder requirements remain. This is a single capture-only instrumentation slice and does not change gameplay behavior. The script depends only on existing adapter/enemy APIs: `get_blockers()`, `set_blockers()`, `current_blocker_id()`, and `apply_blocker_damage()` through the current `Main` bridge.
