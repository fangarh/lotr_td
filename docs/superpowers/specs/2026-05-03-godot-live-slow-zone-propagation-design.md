# Godot Live Slow-Zone Propagation Design

## Purpose

Make timed tower-spawned slow zones affect enemies that are already active in the scene.

The current timed slow-zone slice creates and expires runtime slow-zone dictionaries in `SpikeObstacleTowerAdapter`, but spawned enemies receive slow-zone data only when they are instantiated. This design adds a narrow propagation step so existing enemies see the current adapter slow-zone list.

## Scope

Synchronize the adapter's current slow-zone list to active enemy proxies during the Godot spike runtime.

In scope:
- a small `Main` helper that pushes `SpikeObstacleTowerAdapter.get_slow_zones()` to existing spawned enemies;
- calling that helper after obstacle adapter advancement and after enemy spawn;
- smoke coverage proving an enemy spawned before a timed zone receives the new zone after the timer advances;
- preserving `PlaceholderEnemy` as the owner of applying `current_slow_multiplier()` during movement.

Out of scope:
- blocker HP, path blocking, path rerouting, or enemy attacks against blockers;
- stacking policy beyond existing enemy-side strongest multiplier behavior;
- production placement UI, costs, upgrades, target priorities, rewards, damage, or balance;
- visual spawned obstacle props or final VFX;
- moving slow application out of `PlaceholderEnemy`;
- changing tower damage/cooldown ownership in `SpikeTowerAttackAdapter`.

## Runtime Contract

`SpikeObstacleTowerAdapter` remains the owner of runtime slow-zone data. `Main` remains the composition root that coordinates scene nodes.

After `obstacle_tower_adapter.advance(delta)`, `Main` reads the current slow-zone array and sends it to active enemy proxies that expose `set_slow_zones(zones)`. When a new enemy is spawned, it receives the same current list immediately.

This is a simple state synchronization step, not a new gameplay rule system. It intentionally does not decide future stacking, immunity, cleansing, path blocking, or obstacle removal interactions.

## Testing

Use TDD with focused Godot smoke coverage:
- instantiate `Main`;
- capture the first spawned enemy's slow-zone count after initial static obstacle wiring;
- advance the main scene long enough for the timed tower-owned slow zone to spawn;
- assert that the adapter slow-zone count increases;
- assert that the already-spawned enemy's slow-zone count also increases.

Full verification remains the full Godot smoke suite plus `npm.cmd test`.

