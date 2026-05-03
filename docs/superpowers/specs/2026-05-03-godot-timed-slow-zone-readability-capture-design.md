# Godot Timed Slow-Zone Readability Capture Design

## Goal

Add local visual/test instrumentation for the tower-owned timed slow-zone behavior. The capture should prove that a temporary slow zone spawned by `shadow-tower-b2` can affect an already-spawned enemy and save a review PNG for readability checks.

## Scope

This is capture-only instrumentation. It may add a Godot test/capture script and smoke-test references to that script. It must not change tower damage, slow-zone spawning rules, pathing, blocker HP, stacking policy, enemy blocker attacks, rewards, balance, production placement UI, or production VFX.

## Design

Create a dedicated script at `shadow-conquest/tests/capture_timed_slow_zone_preview.gd`. It will instantiate `res://scenes/main.tscn`, wait for the initial enemy, advance the main scene long enough for `SpikeObstacleTowerAdapter` to spawn a timed tower-owned slow zone, and find the first slow zone count increase beyond the static obstacle placements. The script will move the active enemy to the spawned zone, verify `current_slow_multiplier()` is below `1.0`, add capture-only review marker/label nodes, and save `res://builds/previews/timed_slow_zone_preview.png`.

`smoke_obstacle_proxy.gd` will lock the contract by checking the capture script path, output PNG name, desktop viewport size, timed-zone wait/verification intent, active multiplier assertion, and capture-only marker name.

## Testing

Use TDD by first extending `smoke_obstacle_proxy.gd` so the focused smoke fails while the capture script is missing. Then add the capture script and rerun the focused smoke. Final verification must include all Godot smoke scripts and `npm.cmd test`.

## Out Of Scope

- path blocking or rerouting;
- blocker HP or damage against blockers;
- slow-zone stacking policy;
- enemy attacks against blockers;
- production placement UI;
- balance tuning;
- production spawned obstacle props or final VFX.
