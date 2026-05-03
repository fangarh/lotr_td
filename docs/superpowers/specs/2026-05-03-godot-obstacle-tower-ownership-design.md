# Godot Obstacle Tower Ownership Design

## Purpose

Create the first explicit ownership boundary for future obstacle towers before adding blocker HP, stacking rules, path rerouting, production placement UI, or enemy attacks against blockers.

The current slow-zone spike proves that obstacle effects can influence enemy movement, but the runtime ownership still sits inside `Main`. This design moves obstacle effect ownership into a dedicated scene-level adapter while keeping the current gameplay behavior unchanged.

## Scope

Add a narrow `SpikeObstacleTowerAdapter` boundary for the Godot spike. The adapter owns the relationship between tower/obstacle gameplay data and runtime obstacle effects. In this slice it only registers the existing static JSON obstacle placements and exposes their slow-zone effects for spawned enemies.

In scope:
- a scene-level obstacle tower adapter node in `scenes/main.tscn`;
- adapter APIs for reset, registration, diagnostic counts, and read-only slow-zone output;
- moving slow-zone collection out of `Main`;
- preserving `PlaceholderEnemy` as the owner of applying slow multipliers during movement;
- smoke coverage that locks the new scene boundary and main-scene wiring.

Out of scope:
- blocker HP, armor, damage, or enemy attacks against blockers;
- path blocking, path rerouting, or buildability validation;
- obstacle stacking rules beyond the existing enemy-side strongest multiplier behavior;
- tower cooldowns that spawn obstacles over time;
- obstacle lifetime, despawn, upgrades, costs, rewards, or balance;
- production obstacle placement UI.

## Runtime Boundary

`Main` remains the composition root. It still loads the JSON scenario, spawns visual obstacle proxies, translates tile cells to world positions, and passes spawned enemies their current slow-zone list.

`SpikeObstacleTowerAdapter` becomes the owner of obstacle effect registration. It accepts an obstacle node, obstacle catalog data, and world position. For entries with `effect: "slow-zone"`, it stores a world-space slow-zone dictionary with clamped `radius` and `slowMultiplier`.

`PlaceholderObstacle` remains visual-only. It does not own gameplay effects, blocker state, HP, pathing, or enemy interactions.

`PlaceholderEnemy` remains the movement owner. It receives the adapter's read-only slow-zone list when spawned and applies `current_slow_multiplier()` during local path movement.

`SpikeTowerAttackAdapter` remains enemy damage/cooldown ownership. This slice does not merge attack and obstacle effect logic.

## Adapter API

The adapter should expose:
- `reset_runtime_state()`;
- `register_obstacle(obstacle: Node3D, data: Dictionary, world_position: Vector3)`;
- `get_registered_obstacle_count() -> int`;
- `get_slow_zone_count() -> int`;
- `get_slow_zones() -> Array[Dictionary]`.

The returned slow zones are data dictionaries, not live obstacle nodes. This keeps the contract portable and lets future Kotlin/Android or Godot Resource versions keep the same data shape.

## Testing

Use TDD with focused Godot smoke coverage:
- first add a failing smoke expectation that `scenes/main.tscn` contains `ObstacleTowerAdapter`;
- verify the adapter can register a slow-zone obstacle and expose one slow zone;
- verify invalid or visual-only effects do not create slow zones;
- verify main-scene spawned enemies still receive at least one slow zone through the new adapter boundary.

Full verification remains the full Godot smoke suite plus `npm.cmd test`.

