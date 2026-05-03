# Shadow Data/UI Pivot Design

## Goal

Replace the remaining heroic-defense framing with Shadow conquest framing at the data and UI-text layer while preserving the current combat model.

This is the first faction-pivot slice. It should make the playable prototype read as Mordor/Shadow expanding against the Free Peoples without introducing new combat mechanics, pathing rules, or a full tower-art pass.

## Scope

In scope:
- Rename campaign and UI framing from defense to conquest by Shadow.
- Replace player tower family data with dark tower families and structures.
- Replace enemy type data with Free Peoples attackers.
- Update campaign wave type ids to use the new enemy catalog.
- Update focused tests so they assert the new faction direction and guard against reintroducing the old prototype catalog.
- Update Obsidian project notes to mark the data/UI pivot as complete and keep visual/mechanical follow-ups explicit.

Out of scope:
- New obstacle mechanics such as blockades, webs, or corrupted roots.
- Balance redesign beyond preserving the existing rough stat roles.
- Renderer redesign or detailed dark tower silhouettes.
- Terrain corruption gameplay.
- Campaign path authoring changes.

## Content Mapping

Tower families stay at four families with five tiers and three tier-four branches each:
- Eye of Sauron: precision, marking, fear/fire fantasy; maps to the current precision profile.
- Orc War Camp: fast crude volleys, soldier pressure, future blockade candidate; maps to the current pierce profile.
- Morgul Sorcery: curses, spectral chains, slowing/control; maps to the current chain profile.
- Mordor Forge: heavy fire, metal, siege pressure; maps to the current bombard profile.

Enemy type count remains seven to keep wave and simulation code stable:
- gondor-soldier: baseline disciplined infantry.
- hobbit-scout: small fast scout/swarm role.
- gondor-guard: tougher armored Men.
- rohirrim-rider: fast cavalry pressure.
- dwarf-warrior: slow durable heavy infantry.
- dwarven-sapper: siege and path-clearing fantasy for the current siege role.
- elven-warden: late elite/boss-like magical defender.

Existing stats can be reused by role, then tuned later after the faction pivot settles.

## UI Framing

The interface should use conquest language:
- Page title and heading should refer to Shadow conquest or Mordor's advance.
- Starting status should tell the player to establish a foothold, not defend grass.
- Wave and outcome copy should frame enemies as Free Peoples resistance.
- Campaign progress text can stay functional but should avoid heroic-defense wording.

The UI should remain dense, desktop-oriented, and utilitarian. This slice should not become a landing page or decorative redesign.

## Architecture

Most work should stay in `src/gameData.js`, tests, and a few UI strings in `index.html`/`src/main.js`.

No simulation API changes are expected. The current portable rules should continue to consume tower family ids, enemy type ids, stats, waves, and attack profiles as data.

Renderer changes are intentionally deferred. The renderer may still contain function names and canvas commands from the old tower silhouettes after this slice. That caveat must remain documented until the dark tower visual pass.

## Testing

Use TDD:
- Add a failing test that asserts tower family ids are the four Shadow families and do not include the old Gondor/Rohan/Elven/Dwarven ids.
- Add a failing test that asserts enemy type ids are Free Peoples ids and do not include the old Orc/Goblin/Uruk/Warg/Troll/Siege/Nazgul ids.
- Add or update tests that campaign waves reference only defined enemy ids.
- Run `npm.cmd test` after implementation.

Manual visual QA is optional for this slice because the renderer is not being redesigned. If UI text changes are broad enough to risk obvious layout issues, inspect in browser after tests.

## Documentation Updates

Update:
- `docs/vision.md`: mark the data/UI pivot as complete while noting visuals and mechanics are not final.
- `docs/mechanics.md`: replace the caveat about old tower/enemy catalogs with the new status.
- `docs/lore-and-factions.md`: update implementation status for player/enemy catalogs.
- `docs/roadmap.md`: mark the first faction-pivot slice done and leave dark tower visual pass as next.
- `docs/changelog.md`: record the data/UI pivot.

If a note remains intentionally unchanged, call that out in the final response.
