# Godot Enemy Blocker Contact Design

## Purpose

Add the first gameplay interaction for temporary blockers without starting path rerouting, stacking policy, production UI, rewards, or balance work.

The previous slice made `SpikeObstacleTowerAdapter` the owner of runtime blocker HP and lifetime. This slice lets already-spawned enemies notice those blockers, stop at contact range, and request blocker damage through `Main`, while keeping blocker HP/removal inside the obstacle adapter.

## Chosen Approach

Use a narrow enemy contact-and-attack contract:
- `Main` passes the current `SpikeObstacleTowerAdapter.get_blockers()` output into spawned `PlaceholderEnemy` proxies.
- `PlaceholderEnemy` stores read-only blocker snapshots, detects the nearest blocker overlapping its current XZ position, pauses movement while in contact, and emits a `blocker_attack_requested(blocker_id, amount)` signal on a small attack cadence.
- `Main` receives the signal and calls `SpikeObstacleTowerAdapter.apply_blocker_damage(blocker_id, amount)`.
- After the blocker is removed, the next `Main._process()` sync gives enemies the updated blocker list, and movement resumes through the existing path traversal.

This keeps the first interaction visible in behavior without giving enemies direct ownership of blocker HP or coupling movement to path rerouting.

## Scope

In scope:
- enemy-side blocker snapshot input;
- contact detection by blocker `position` and `radius`;
- paused movement while touching a blocker;
- a small fixed blocker attack damage/cadence inside `PlaceholderEnemy`;
- signal-only bridge from enemy to `Main`;
- adapter-owned blocker HP reduction/removal;
- smoke coverage for enemy stopping, attack signal emission, main-scene blocker damage, and movement resuming after removal.

Out of scope:
- path rerouting;
- blocker stacking policy;
- enemy attack animations or final VFX;
- spawned blocker production visuals;
- rewards, score, kill credit, gold, or wave/game-state ownership;
- tower retargeting toward blockers;
- balance tuning, enemy-specific blocker damage, upgrades, costs, or production placement UI.

## Runtime Contract

`PlaceholderEnemy` adds:
- `set_blockers(blockers: Array) -> void`;
- `get_blocker_count() -> int`;
- `current_blocker_id() -> String`;
- `blocker_attack_requested(blocker_id: String, amount: float)` signal.

The enemy accepts only blocker dictionaries with a non-empty `id`, a `Vector3 position`, and positive `radius`.

While `current_blocker_id()` is non-empty, `_process(delta)` should not advance path movement. It should accumulate attack time and emit blocker damage requests at the configured cadence. This is a local spike constant, not final balance.

`Main` remains the composition root and only bridges the signal into `SpikeObstacleTowerAdapter.apply_blocker_damage()`. It must not store blocker HP, grant rewards, change wave state, or change game state.

## Testing Strategy

Use TDD:
- extend `smoke_enemy_proxy.gd` first so a blocker near the enemy prevents movement and emits one attack request after the cadence;
- extend `smoke_obstacle_proxy.gd` main-scene coverage so an already-spawned enemy receives blocker data and damages/removes a runtime blocker through `Main`;
- implement the smallest code in `PlaceholderEnemy` and `Main` to pass;
- re-run all Godot smoke scripts and `npm.cmd test`.

## Follow-Up Decisions

- Whether enemies should use faction-specific blocker damage.
- Whether blockers should visually show contact/HP.
- Whether blockers can stack or occupy the same path point.
- Whether enemies should reroute, queue, or spread around blockers.
- Whether destroying a blocker should affect rewards, score, or wave state.
