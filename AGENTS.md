# AGENTS.md

## Project Source Of Truth

This project uses `docs/` as an Obsidian-compatible source of truth. Before significant work, read the relevant files below and keep changes consistent with them.

Documentation is mandatory for every project change, including tiny refactors, pauses, follow-up steps, and housekeeping. After any meaningful action, update the relevant Obsidian notes before claiming the work is complete. If no project note needs a content change, explicitly mention that in the final response.

Always read:
- `docs/vision.md`
- `docs/decisions.md`
- `docs/roadmap.md`

Read when touching factions, story, enemies, towers, or campaign framing:
- `docs/lore-and-factions.md`

Read when touching rendering, terrain, camera, map scale, UI layout, or tower visuals:
- `docs/visual-style.md`

Read when touching tower behavior, enemies, waves, upgrades, blockers, or combat systems:
- `docs/mechanics.md`

Read when refactoring architecture or adding systems that may need to be ported:
- `docs/android-porting.md`

Always update or explicitly re-check when work happens:
- `docs/decisions.md`
- `docs/roadmap.md`
- `docs/changelog.md`

## Current Direction

- Collaboration language: Russian.
- The game is pivoting from heroic defense to Shadow conquest.
- The player expands Mordor's influence across Middle-earth.
- Future enemies should be Free Peoples: Men, Elves, Dwarves, and allies.
- Tower catalog and attacks are not final.
- The Eye of Sauron is a key candidate for a magic tower or global power.
- At least one or two future tower families should create path obstacles, such as Orc blockades, spider webs, or corrupted roots.

## Technical Direction

- Current target is desktop-only.
- Logical tile size is `200x200`, projected as an isometric diamond `400x200` before `viewScale`.
- Large maps and camera panning are expected.
- Campaign maps currently scale from `32x32` to `50x50`.
- Keep game data and rules portable for a future Kotlin/Android port.
- Avoid adding more complex canvas-only art before renderer/camera boundaries are improved.

## Working Rules

- Preserve user changes. Do not revert unrelated edits.
- Prefer small, verifiable steps.
- Run `npm.cmd test` before claiming completion for code changes.
- For visual changes, verify with Playwright screenshots when practical.
- Keep `docs/` as live Obsidian memory on every step, even for small refactors or pauses. Do not let implementation get ahead of documentation.
