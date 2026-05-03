# Vision

This project is an isometric tower-defense game about conquest from the side of Shadow.

The player expands Mordor's influence across Middle-earth. Building towers is not only defense: each tower is a foothold of occupation, gradually turning the land darker and pushing out Elves, Men, Dwarves, and other Free Peoples.

Accepted design direction:
- The player controls dark forces rather than the usual heroic factions.
- The production version is a Godot 2.5D tower-defense game: 3D scene presentation with a fixed orthographic isometric camera and tile-based gameplay rules.
- Target enemy waves after the pivot are Free Peoples: Gondor soldiers, Rohirrim, Elves, Dwarves, scouts, and later heavier iconic defenders.
- The Eye of Sauron is a key magical tower or power fantasy anchor.
- The tone should be dark fantasy strategy, not comedy or parody.
- Visual progress should imply corruption and conquest through terrain, towers, smoke, ash, red light, and black stone.

Near-term priority is still prototyping. Keep systems flexible and do not over-polish final balance before the faction pivot, tower catalog, and terrain pipeline settle.

Monetization direction:
- support downloadable content packs for isolated expansions, levels, biomes, and visual sets;
- keep paid gameplay DLC from affecting base campaign balance;
- use cosmetic monetization for visual changes such as tower skins, enemy variants, effects, terrain themes, and UI presentation;
- allow free and seasonal content claims, with claimed event content retained permanently.

## Current Implementation Status

The first Shadow conquest data/UI pivot is complete.

Current playable content now uses:
- player tower families themed around the Eye of Sauron, Orc war camps, Morgul sorcery, and Mordor forges;
- enemy types themed around Free Peoples resistance: Men, Hobbits, Rohirrim, Dwarves, and Elves;
- campaign and UI language focused on Shadow conquest.

Remaining temporary content:
- canvas tower silhouettes still reuse older heroic renderer functions;
- tower attacks and balance still mostly preserve the pre-pivot prototype roles;
- terrain corruption is not yet a gameplay or full visual system.
- the Godot project now has a first primitive 2.5D spike scene with reusable board/tower/obstacle/terrain-prop/enemy scene boundaries, JSON-backed portable sections for board, scenario game state, path, towers, obstacles, terrain props, enemies, and waves, a minimal spawn-only wave runner, catalog-driven imported Shadow tower proxy candidates including textured tower maps and a B4 projectile preview asset, a visual road surface asset on path tiles, refreshed imported Free Peoples enemy proxy candidates for an Elven archer, Dwarven warrior, and Gondor warrior, a first imported Mordor terrain prop proxy, the first enemy lifecycle adapter with health bars and endpoint breach signals, a thin combat/state adapter for enemy damage, death removal, breach removal, and minimal kill/reward totals, a first thin tower attack adapter that delegates damage through combat state and can show short visual-only moving B4 projectile previews with temporary readability helpers plus temporary fire cues, a first obstacle adapter with slow zones, timed slow-zone spawning, temporary blocker HP/lifetime, contact-stop blocker damage requests from enemies, and capture-only blocker-contact readability instrumentation, a first wave-state adapter for minimal wave-clear tracking, a first higher-level game-state adapter with explicit manual next-wave, JSON-configured base lives, and path-breach/basic-loss hooks plus temporary `N` and `R` debug keys, a terminal-state-only manual scenario restart hook for local review, and a compact top HUD bar with desktop/narrow mobile layouts plus a first `Next wave` / `Restart` action shell, but it is not yet a production gameplay slice.
