# Godot Obstacle Slow-Zone Spike Design

## Purpose

Add the first gameplay contract for the existing corrupted-roots obstacle proxies without changing pathing, balance, restart flow, wave scheduling, rewards, or tower/combat ownership.

## Scope

The slice turns visual obstacle placements into temporary slow zones. Obstacles remain static corrupted roots/web props. Enemies keep their current path traversal contract, but when their world position is inside a configured slow zone, movement distance for that frame is multiplied by the zone's `slowMultiplier`.

Out of scope:
- path blocking or rerouting;
- obstacle HP, armor, attacks, or enemy attacks against blockers;
- stack rules beyond choosing the strongest single slow multiplier;
- production tower families or obstacle placement UI;
- balance pass, auto-advance, restart screens, or combat reward changes.

## Data Contract

Obstacle catalog entries may declare:
- `effect: "slow-zone"`;
- `slowMultiplier`, clamped to a useful non-negative range and defaulting to `1.0`;
- `radius`, defaulting to a small local footprint.

`Main` remains the composition root. It converts placed obstacle cells into world-space zone dictionaries and passes the resulting array to spawned enemies. The JSON stays portable and renderer-independent.

## Runtime Contract

`PlaceholderEnemy` owns local path movement and applies the current slow multiplier while moving. It exposes `set_slow_zones(zones)` and `current_slow_multiplier()` for smoke coverage. Breached/dead enemies still leave the live targeting pool exactly as before.

## Testing

Use TDD with a focused Godot smoke test:
- instantiate `PlaceholderEnemy`;
- configure a short path through a slow zone;
- verify the enemy moves less than an identical unslowed enemy over the same frame;
- verify movement returns to normal after leaving the zone;
- verify the main scene passes at least one slow zone from obstacle placements to spawned enemies.

Full verification remains the existing full Godot smoke suite plus `npm.cmd test`.
