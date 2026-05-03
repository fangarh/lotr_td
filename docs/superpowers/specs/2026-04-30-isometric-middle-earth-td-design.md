# Isometric Middle-earth Tower Defence Design

> Status note, 2026-05-01: this is a historical initial design spec. Current architecture no longer keeps rendering, input, storage, audio, and all simulation behavior in `src/main.js`. Current boundaries are `src/camera.js`, `src/renderer.js`, `src/ui.js`, `src/storage.js`, `src/audio.js`, `src/input.js`, and `src/simulation.js`, with `src/main.js` as the browser composition root and remaining game orchestration.

## Goal

Build a playable browser tower defence game in one static HTML app with an isometric battlefield, a Middle-earth fantasy theme, 4 tower families, 5 upgrade levels, branch specialization from level 4, and at least 10 playable stages.

## Scope

The first implementation must be playable end to end:

- Isometric canvas battlefield with a fixed winding road and buildable grass tiles.
- 10 levels with different wave counts, enemy mixes, starting gold, lives, and map themes.
- 4 tower families: Gondor Archer, Rohan Spear, Elven Light, Dwarven Forge.
- 5 tower levels. Levels 1-3 are linear. At level 4 the player chooses one of 3 branches per family. Level 5 upgrades the chosen branch.
- More upgrade choice opens as campaign level increases:
  - Levels 1-2: tier 2 upgrades only.
  - Levels 3-4: tier 3 upgrades.
  - Levels 5-7: tier 4 branch choices.
  - Levels 8-10: tier 5 branch capstones.
- Tower and unit visuals evolve with level, branch, and enemy tier.
- The game runs from `index.html` without a build step.

## Visual Direction

Visual thesis: carved-stone strategy board, bright readable battlefield, and miniature Middle-earth units with clear silhouettes rather than dark cinematic realism.

The canvas presents the game as an angled tactical map. Towers use recognizable silhouettes: battlements for Gondor, banners and spears for Rohan, glowing white-gold trees for Elves, and forge chimneys for Dwarves. Enemies scale from small orc mobs to trolls, wargs, siege units, and Nazgul-like shadow riders. Visual upgrades add height, metal, banners, glow, smoke, and projectile effects.

## Gameplay Architecture

Pure gameplay rules live in `src/gameLogic.js` so they can be tested independently from rendering. Static content lives in `src/gameData.js`: tower stats, branch definitions, campaign levels, and enemy profiles. Current refactored boundaries move camera math, canvas rendering, DOM UI, browser persistence, audio, input wiring, and part of simulation out of `src/main.js`.

The app keeps one source of truth for state:

- current campaign level
- gold and lives
- towers on buildable tiles
- active enemies
- selected tile or tower
- current wave and spawn timers
- unlocked upgrade tier derived from campaign level

## Testing

Use Node's built-in test runner for logic that should not depend on the browser:

- campaign has at least 10 levels
- every tower family has 5 tiers and 3 branches at tier 4
- upgrade options are locked and unlocked by campaign progress
- tower costs and placement rules behave predictably
- branch selection is required before tier 4 and preserved for tier 5

Browser verification checks that `index.html` loads, the canvas is not blank, and the UI exposes level, tower, wave, and upgrade controls.

## Iteration Strategy

Iteration 1 builds a complete vertical slice and should already be playable. Later iterations can add path variants, sound, save slots, richer balancing, boss abilities, and more authored art, but the first pass must satisfy the requested mechanical requirements.
