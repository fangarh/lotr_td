# Godot Build Spots And Tower Purchasing Design

## Context

The two-map desktop MVP corridor now has scenario selection and two authored scenario files. The next narrow gameplay block is to let the player build towers during a scenario instead of relying only on JSON `towers.placements`.

This design keeps the current Godot spike architecture intact:
- `Main` remains the composition root.
- `PlaceholderTower` remains visual only.
- `SpikeTowerAttackAdapter` keeps tower cooldown/attack ownership.
- `SpikeObstacleTowerAdapter` keeps obstacle effect ownership.
- `SpikeCombatAdapter` keeps kill/reward totals.
- `SpikeHud` remains a Control adapter that emits intent signals only.

## Accepted Scope

Add scenario-driven build spots and first tower purchasing for the desktop MVP path.

The scenario data gains:
- `gameState.startingGold` as the current scenario's starting build currency.
- `towers.buildSpots` as authored cells where player-built towers may be placed.
- `towers.catalog[].cost` as the build cost for each tower type.

The runtime gains:
- a narrow `SpikeBuildStateAdapter` that owns starting/current gold, build spot availability, occupied cells, tower costs, and purchase validation;
- a public `Main.build_tower_at_spot(spot_id, tower_type_id) -> bool` method;
- spawned tower proxies for successful purchases, registered with both tower attack and obstacle adapters exactly like existing JSON placements;
- compact HUD controls for selecting a build spot and tower type, then requesting a build.

## Out Of Scope

This block does not add:
- mouse picking on the 3D board;
- free placement;
- tower upgrades;
- tower selling;
- refund rules;
- balance tuning beyond initial costs/starting gold;
- campaign persistence;
- shop hotkeys;
- final build spot art;
- path rerouting or blocker stacking policy;
- Android/touch-first UI.

## Data Contract

Scenario files use this shape:

```json
{
  "gameState": {
    "baseLives": 5,
    "startingGold": 120
  },
  "towers": {
    "catalog": [
      {
        "id": "eye-of-sauron",
        "name": "Eye of Sauron",
        "cost": 45
      }
    ],
    "placements": [],
    "buildSpots": [
      {
        "id": "m1-spot-1",
        "x": 2,
        "z": 1,
        "allowedTypeIds": ["eye-of-sauron", "shadow-tower-b2"]
      }
    ]
  }
}
```

`allowedTypeIds` is optional. Missing or empty means any catalog tower with a non-negative cost is allowed. `placements` remains supported for prebuilt towers and fixture scenarios.

## Runtime Contract

`SpikeBuildStateAdapter` exposes:
- `configure(build_spots, tower_catalog, starting_gold, occupied_cells := [])`;
- `get_gold()`;
- `get_build_spots()`;
- `get_available_build_spots()`;
- `get_tower_options()`;
- `can_build_at(spot_id, tower_type_id)`;
- `build_at(spot_id, tower_type_id) -> Dictionary`.

`build_at` returns a dictionary with at least:
- `ok: bool`;
- `reason: String`;
- `spot: Dictionary`;
- `tower: Dictionary`;
- `gold: int`.

The adapter does not instantiate scenes and does not register attacks. `Main` consumes a successful result, instantiates the existing tower proxy, and registers it with existing adapters.

## HUD Contract

`SpikeHud` adds a compact desktop-only purchase strip below the existing top bar:
- `BuildSpotSelect` for currently available build spots;
- `TowerTypeSelect` for tower options;
- `GoldValue` readout;
- `BuildButton`.

The HUD emits `build_requested(spot_id, tower_type_id)` only. It does not mutate gold, place towers, or decide validity. On narrow mobile layout the purchase strip may stay compact or hidden; desktop MVP is the target for this block.

## Testing

Use Godot smoke tests as the primary verification:
- adapter test for gold, cost, allowed tower ids, occupied spots, and read-only output;
- main scene test for scenario data shape, successful purchase spawning/registering a tower, unaffordable/refused purchase, and scenario switch reset;
- HUD test for build controls, gold readout, build signal, and option refresh after a purchase.

Run `npm.cmd test` before completion as the project-wide check.

