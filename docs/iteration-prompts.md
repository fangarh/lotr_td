# Iteration Prompts

## Current Architecture Status

The original iteration prompts are historical starting points. Current code has since been split into modules:
- `src/camera.js` for projection, scale, picking, visible bounds, and camera clamping;
- `src/renderer.js` for Canvas 2D drawing;
- `src/ui.js` for DOM rendering;
- `src/storage.js` for browser persistence;
- `src/audio.js` for WebAudio;
- `src/input.js` for browser input wiring;
- `src/simulation.js` for spawning timers, enemy creation, enemy movement, projectile aging, and effect aging.

New iteration prompts should preserve those boundaries rather than adding new responsibilities back into `src/main.js`.

## Iteration 1: Playable Core

Implement the full static browser game with tested data rules, isometric canvas rendering, 10 campaign levels, 4 tower families, branching upgrades from tier 4, and a complete wave loop. Prioritize readable gameplay and stable mechanics over perfect balance.

## Iteration 2: Balance and Encounter Variety

Tune enemy health, tower damage, rewards, and level pacing. Add map path variants, elite modifiers, and boss wave behavior while keeping the tested tower progression model unchanged.

## Iteration 3: Presentation Upgrade

Add stronger authored visuals, sound toggles, impact effects, campaign save state, tooltips, and more detailed unit animation. Preserve the static no-build deployment path.
