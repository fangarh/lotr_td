# Godot Temporary Blocker HP Contract Design

## Purpose

Define the first damageable temporary obstacle contract for the Godot spike without starting path rerouting, stacking rules, enemy attacks against blockers, production placement UI, or balance work.

The current obstacle path proves slow-zone-only behavior: static corrupted-roots placements and tower-owned timed slow zones can slow already-spawned enemies through `SpikeObstacleTowerAdapter` and `PlaceholderEnemy`. The next blocker step should add a runtime HP/lifetime boundary first, so future path blocking and enemy attacks have a clear target contract instead of being mixed into movement or combat code.

## Chosen Approach

Use a narrow HP/lifetime lifecycle contract in `SpikeObstacleTowerAdapter`.

Alternative approaches considered:
- Add full blocking and enemy attacks immediately. This would create more visible gameplay, but it would mix blocker lifecycle, enemy movement interruption, enemy attack behavior, and balance in one slice.
- Treat blockers as plain visual props with no HP. This is too weak for the next mechanics step because it does not establish the damageable runtime contract.
- Add HP/lifetime data first, with explicit adapter APIs and smoke coverage. This is the recommended path because it creates the smallest durable boundary for future blockers.

## Scope

In scope for the first implementation plan:
- one temporary blocker effect type in scenario/catalog data;
- runtime blocker entries owned by `SpikeObstacleTowerAdapter`;
- blocker id, source tower, position, radius/footprint, max HP, current HP, and optional lifetime;
- adapter APIs for diagnostics, read-only blocker output, damage application, and expiry/removal;
- smoke coverage for spawn, HP reduction, lethal removal, lifetime expiry, reset behavior, and main-scene registration.

Out of scope:
- path rerouting;
- enemy movement stopping or collision against blockers;
- enemy attacks against blockers;
- stacking policy for multiple blockers on one path point;
- rewards, kill credit, gold, score, or wave/game-state ownership;
- tower attack retargeting toward blockers;
- production placement UI, costs, upgrades, balance, or final VFX;
- production spawned blocker models beyond possible capture-only review helpers.

## Data Contract

A blocker-capable obstacle catalog entry may use:
- `effect: "temporary-blocker"`;
- `maxHealth`: positive blocker HP;
- `radius`: flat XZ footprint used for future collision/readability;
- `lifetime`: optional seconds before the blocker expires.

A tower catalog entry may later reference that effect through the existing `obstacleEffectId` pattern. The existing slow-zone fields remain valid for `effect: "slow-zone"` entries and should not be overloaded.

For the first implementation, one existing tower candidate may be allowed to spawn a blocker effect only if the implementation plan explicitly keeps slow-zone behavior intact. If that creates too much coupling with the current `shadow-tower-b2` slow-zone candidate, use a separate test-only fixture or a separate catalog entry.

## Runtime Contract

`SpikeObstacleTowerAdapter` owns runtime blocker lifecycle. It may store blocker dictionaries or small internal state records, but external consumers should receive read-only dictionaries rather than live mutable state.

Each runtime blocker should expose at least:
- `id`;
- `position`;
- `radius`;
- `maxHealth`;
- `currentHealth`;
- `remainingLifetime` when lifetime is enabled;
- `sourceTowerId` or an equivalent owner marker when spawned by a tower.

The adapter should expose methods equivalent to:
- `get_blocker_count() -> int`;
- `get_blockers() -> Array[Dictionary]`;
- `apply_blocker_damage(blocker_id: String, amount: float) -> bool`;
- `advance(delta: float)` aging lifetime as part of the existing adapter tick;
- `reset_runtime_state()` clearing blockers along with existing runtime obstacle state.

`apply_blocker_damage()` returns whether the blocker was removed by the damage. Damage must be clamped to non-negative values. Lethal damage removes the blocker from subsequent `get_blockers()` output.

## Ownership Boundaries

`Main` remains the composition root. It may register tower proxies and pass path points into `SpikeObstacleTowerAdapter`, but it should not own blocker HP or removal rules.

`SpikeCombatAdapter` continues to own enemy damage/death/reward tracking only. It should not own blocker HP in the first blocker slice.

`SpikeTowerAttackAdapter` continues to target enemies only. It should not retarget shots to blockers in the first blocker slice.

`PlaceholderEnemy` continues to own its own movement and slow multiplier application. It should not stop for blockers or attack blockers in the first blocker slice.

`PlaceholderObstacle` remains a static visual proxy for JSON obstacle placements. Temporary blocker visuals, if needed for review, should be capture-only or a later explicit visual slice.

## Testing Strategy

Use TDD for implementation:
- first extend focused Godot smoke coverage so it fails while blocker APIs are missing;
- add the smallest adapter implementation that can create a blocker from a configured effect;
- verify HP reduction, lethal removal, lifetime expiry, reset behavior, and read-only output;
- verify existing slow-zone smoke coverage still passes;
- only then consider main-scene wiring for one blocker-capable tower or fixture.

Full verification after code changes remains all Godot smoke scripts plus `npm.cmd test`.

## Open Follow-Up Decisions

- Whether enemies stop at blockers or merely slow near them.
- Whether enemies attack blockers automatically.
- Whether blockers can stack on the same path point.
- Whether blockers grant rewards or score when destroyed.
- Whether tower attacks, global powers, or only enemies can damage blockers.
- What production spawned blocker visuals should look like.
