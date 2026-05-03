# Godot Timed Slow-Zone Spawning Design

## Purpose

Add the first tower-owned obstacle behavior without starting blocker HP, path blocking, path rerouting, stacking rules, enemy blocker attacks, production placement UI, or balance work.

The previous slices proved static slow-zone effects and moved obstacle effect ownership into `SpikeObstacleTowerAdapter`. This slice lets a tower periodically create temporary slow-zone effects through that adapter.

## Scope

Add timed slow-zone spawning for one existing spike tower candidate. The tower remains a visual proxy and still keeps its normal attack behavior through `SpikeTowerAttackAdapter`; the new obstacle behavior is additive and owned by `SpikeObstacleTowerAdapter`.

In scope:
- tower catalog fields for one obstacle-spawning tower candidate;
- adapter registration of towers that declare an obstacle effect id;
- adapter advancement over time;
- creation of runtime slow-zone dictionaries near the path;
- temporary lifetime expiry for spawned slow zones;
- read-only slow-zone output for spawned enemies;
- focused smoke coverage for cadence, lifetime, main-scene wiring, and no damage/reward ownership change.

Out of scope:
- path blocking or rerouting;
- blocker HP, armor, or enemy attacks against blockers;
- stacking rules beyond existing enemy-side strongest multiplier behavior;
- visual spawned obstacle props or final VFX;
- production placement UI, costs, upgrades, target priority UI, rewards, damage, or balance;
- changing `SpikeTowerAttackAdapter` damage/cooldown ownership.

## Data Contract

A tower catalog entry may declare:
- `obstacleEffectId`: id from `obstacles.catalog`;
- `obstacleSpawnInterval`: seconds between runtime effect spawns;
- `obstacleSpawnLifetime`: seconds before a spawned runtime effect expires;
- `obstacleSpawnRange`: maximum flat XZ distance from the tower to a path point where the effect may spawn.

The referenced obstacle catalog entry still owns effect details such as:
- `effect: "slow-zone"`;
- `slowMultiplier`;
- `radius`.

For this spike, one existing tower candidate should opt into the behavior. The data remains JSON-backed and portable.

## Runtime Contract

`Main` remains the composition root. It registers towers with both `SpikeTowerAttackAdapter` and `SpikeObstacleTowerAdapter`, passes obstacle catalog data to the obstacle adapter, and advances the obstacle adapter each frame.

`SpikeObstacleTowerAdapter` owns tower obstacle cadence. It tracks registered tower nodes, resolves their configured obstacle effect, picks a path point within range, creates a runtime slow-zone dictionary, and expires spawned zones after their configured lifetime.

Existing static obstacle placements continue to register as slow zones through `register_obstacle()`. Runtime spawned zones are added to the same `get_slow_zones()` output.

`PlaceholderEnemy` keeps its current movement contract. Existing enemies receive slow-zone data at spawn time for this slice. Dynamic updates to already-spawned enemies are intentionally out of scope unless needed by smoke coverage; this avoids introducing a broader live-buff propagation system before obstacle stacking/lifetime rules are decided.

## Testing

Use TDD with focused Godot smoke coverage:
- first add a failing smoke expectation that the adapter exposes `register_tower()`, `set_path_points()`, and `advance()`;
- verify a configured tower spawns a slow zone on `advance()` only after its interval;
- verify the spawned slow zone expires after its lifetime;
- verify visual-only or missing obstacle effect ids do not spawn zones;
- verify `Main` wires at least one tower into timed slow-zone spawning.

Full verification remains the full Godot smoke suite plus `npm.cmd test`.

