# Godot Two-Map MVP Corridor Design

## Purpose

Define the narrow path from the current Godot spike to a playable desktop MVP with two maps.

The MVP target is a small but real game loop, not another isolated technical spike. A player should be able to choose a map, build towers on marked build spots, start and survive waves, earn gold, upgrade towers once, win or lose, and restart or continue without debug keys.

## Platform Scope

The MVP is desktop-first in Godot.

Primary verification targets:
- local Godot editor/run flow;
- Windows desktop build smoke;
- desktop Web build smoke when practical.

Android, touch-first placement, and mobile-first HUD polish are intentionally out of MVP scope. Data and system boundaries should still avoid decisions that would make a later mobile port harder.

## MVP Content

The MVP includes two authored maps.

Each map should be scenario-driven rather than hardcoded. Scenario data should own board/path/build spots/tower catalog references/enemy catalog references/waves/game state/economy values.

The tower set is limited to four roles:
- Eye tower: direct single-target damage;
- Forge tower: slower area or siege damage;
- Morgul tower: control through slow, curse, or weakening;
- Orc Camp tower: temporary blocker behavior.

The enemy set is limited to four roles:
- Gondor Soldier: baseline enemy;
- Rohirrim Scout or Rider: fast enemy;
- Dwarven Warrior: armored or high-HP enemy;
- Elven Warden or Archer: elite or control-resistant enemy.

Enemy MVP behavior should use simple stats first: health, speed, reward, and optional resistance flags. Complex enemy abilities are out of scope.

## Placement

The MVP uses authored build spots instead of free tile placement.

Rules:
- towers can only be built on scenario-defined build spots;
- a build spot can hold at most one tower;
- the player cannot build without enough gold;
- build spots should be data-driven so both MVP maps exercise the same placement system.

Free placement across all valid tiles remains a later feature.

## Economy And Upgrades

MVP economy includes:
- starting gold;
- tower costs;
- kill rewards;
- live gold display in HUD;
- one upgrade level per tower.

Each tower can be upgraded once. The upgrade should be a clear stat increase, such as damage, fire rate, range, slow strength, blocker HP, or blocker uptime. Upgrade branches are out of scope.

Selling can be deferred unless it becomes necessary for balance or recovery from misclicks.

## Game Flow

The MVP loop is:

1. Player selects one of two maps.
2. Scenario loads with its board, path, build spots, waves, lives, and economy.
3. Player builds towers on available build spots.
4. Player starts or advances waves through HUD actions.
5. Towers attack, control, or block enemies.
6. Kills grant gold.
7. Enemies reaching the end reduce lives.
8. A map ends in win or loss.
9. Player can restart, and after map 1 can proceed to map 2.

Debug keys may remain for local developer review, but MVP completion must not depend on them.

## Map Direction

Map 1 should be a short baseline map. It should prove the basic loop, direct damage, area pressure, and simple control. It should be passable with several sensible tower choices and should teach the player that economy matters.

Map 2 should reuse the same systems but require more deliberate counterplay. It should pressure the player with fast and armored enemies and make control or blocker use meaningfully valuable. It should differ from map 1 in path shape, build spot decisions, wave pressure, and expected tower mix.

## Architecture Boundaries

`Main` should remain the composition root. It may load scenarios, instantiate scene nodes, connect signals, and bridge UI to adapters, but it should not become the owner of economy rules, placement rules, tower balance, or campaign progression details.

Preferred boundaries:
- a scenario/map selection boundary owns choosing and loading scenario data;
- a build spot or placement boundary owns spot state, affordability checks, and occupied checks;
- an economy boundary owns gold, costs, rewards, and upgrade spending;
- existing combat, tower attack, obstacle, wave-state, game-state, and HUD adapters should continue to own their current narrow responsibilities;
- scenario/catalog data should remain the main source for map and balance values.

Blocker behavior remains contact-stop plus HP/lifetime for MVP. Path rerouting, stacking policy, blocker rewards, and final blocker VFX remain separate future decisions.

## Implementation Order

1. Add scenario selection/loading foundation for two maps.
2. Add build spots and tower purchasing.
3. Add economy rewards and one upgrade level.
4. Normalize four MVP enemy roles and wave data.
5. Build map 1 to a complete playable loop.
6. Add map 2 using the same systems.
7. Run balance and readability passes across both maps.

This order is gameplay-first. Visual polish should only be pulled forward when readability blocks playtesting.

## MVP Readiness Criteria

Map 1 is ready when:
- it can be selected without editing code;
- it can be played from start to win/loss without debug keys;
- at least three of the four towers are useful;
- economy creates real choices;
- win, loss, and restart work through UI.

Map 2 is ready when:
- it uses the same systems as map 1 without special hardcode;
- it requires different decisions from map 1;
- fast, armored, control-resistant, or blocker-relevant pressure changes play;
- it can be won and lost through normal play.

The MVP is ready when:
- both maps are playable end to end;
- all four towers can be bought and upgraded once;
- all four enemy roles appear and matter;
- kill rewards update player gold;
- HUD shows gold, lives, wave state, and valid actions;
- smoke coverage protects scenario loading, build spot placement, economy, upgrade, wave progression, win/loss, and restart;
- Windows and, when practical, desktop Web smoke builds still work.

## Explicit Non-Goals

The MVP does not include:
- free tile placement;
- upgrade branches;
- final character animations;
- final VFX;
- Android or touch-first UX;
- path rerouting;
- full campaign progression;
- DLC or monetization systems;
- complex enemy abilities;
- final balance.

## Open Follow-Up Decisions

- Whether selling is needed in MVP for player recovery.
- Exact names and stats for the four MVP towers.
- Exact names and stats for the four MVP enemy roles.
- Whether the Elven role gets a simple control resistance flag in MVP or only higher stats.
- Whether map 1 unlocks map 2 through session state or both maps are always selectable during MVP.
