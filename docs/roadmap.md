# Roadmap

## Current Phase

Prepare the Godot migration path for a mobile-app-first version while preserving the current browser prototype as a rules, data, balance, and UX reference.

## Next Steps

1. Refactor for portability.
   - Split camera/projection out of `src/main.js`. Done: `src/camera.js` now owns projection, scaling, visible tile bounds, picking, and camera clamping.
   - Keep `gameData.js` and `gameLogic.js` clean and data-oriented.
   - Prepare renderer boundaries before adding more tower art. Done: `src/renderer.js` owns canvas draw order and scene layers, while `src/ui.js` owns DOM rendering for HUD, level selection, tower buttons, and selection actions.
   - Browser adapters are being split out of `src/main.js`. Done: `src/storage.js` owns localStorage access, `src/audio.js` owns WebAudio, and `src/input.js` owns DOM event wiring.
   - Simulation logic has been moved out of `src/main.js`. Done: `src/simulation.js` owns spawning timers, enemy creation, enemy movement, target selection helpers, tower placement, tower upgrades, tower selling/refund value, tower cooldown/attack orchestration, damage application with hit/slow/splash handling, projectile/beam/mark/shockwave effect creation, kill rewards/effects, outcome transitions, projectile aging, and effect aging.
   - Resume checkpoint before returning to feature work is complete:
     1. Move `upgradeTower` handling from `src/main.js` into `src/simulation.js`. Done.
     2. Move `sellTower` handling from `src/main.js` into `src/simulation.js`. Done.
     3. Do one cleanup pass so `src/main.js` is mainly composition root, state/game loop wiring, browser callbacks, and UI sync. Done for the upgrade/sell boundary.
   - Recommended next feature block: faction pivot with Shadow framing, dark tower families, and Free Peoples enemies.
   - Keep Obsidian docs current on every development step; update this roadmap and `docs/changelog.md` whenever architecture boundaries move.
   - Resume handoffs after context cleanup should be concise: reference required Obsidian notes and only include the last completed step plus the next recommended step, instead of repeating the whole project state.

2. Faction pivot.
   - Rename UI and campaign framing from defense of Middle-earth to conquest by Shadow. Done for the first data/UI slice.
   - Replace enemy catalog with Free Peoples. Done for the first data/UI slice.
   - Replace tower families with dark factions and structures. Done for the first data/UI slice.
   - Next: dark tower visual pass and later obstacle mechanics.

3. Dark tower visual pass.
   - Redesign the Gondor-style tower into dark towers.
   - Avoid tall rocket-like silhouettes.
   - Prefer squat, heavy, readable structures with strong material identity.

4. Terrain pass.
   - Improve large-tile grass, ash, dirt, stone, road, and corruption textures.
   - Keep trees as triangles until the terrain base is stable.

5. Terrain blending.
   - Add neighboring terrain awareness.
   - Blend road/grass, ash/grass, stone/dirt, and biome borders.

6. Level authoring.
   - Replace generated path extensions with more intentional paths per level.
   - Make map layouts support tower placement pockets and long enemy movement.

7. Godot migration spike.
   - Use Godot with GDScript as the accepted production direction.
   - Godot Standard `4.6.2` and matching export templates are installed under `D:\Godot`.
   - Codex has the Godot skill installed and GoPeak MCP configured in compact mode.
   - Android export toolchain is installed under `D:\Godot`: OpenJDK 17, Android SDK Platform 35, Build-Tools 35.0.1, Platform-Tools 37.0.0, NDK 28.1.13356709, CMake 3.10.2.4988404, and command-line tools.
   - Godot project exists at `shadow-conquest/`, named `ShadowConquest`, using `gl_compatibility`.
   - Accepted presentation: 2.5D in a `Node3D` world with fixed orthographic `Camera3D`; gameplay remains tile/data-driven.
   - Primary target: Android mobile application.
   - Secondary targets: desktop browser export and Windows executable.
   - Non-target: mobile web gameplay.
   - Create a minimal Godot skeleton with 2.5D isometric map view, camera pan/zoom, one tower, one enemy path, and one wave. Done for the first spike slice: first primitive scene exists with a board, path, tower proxy, enemy proxy, portable catalog sections, and a minimal spawn-only wave runner.
   - First implementation step: add `scenes/main.tscn` with `Node3D` root, orthographic camera, simple XZ tile board, and set it as the project run scene. Done.
   - Keep tower, enemy, wave, and balance data externalized through Godot Resources or JSON-backed catalogs.
   - Iteration 1: split the primitive spike into reusable Godot scene/script boundaries. Done: `Main` now loads scenario data and composes `BoardView`, `Towers`, and `Enemies`; primitive board/path rendering lives in `scripts/board_view.gd`; placeholder tower/enemy proxies live in separate entity scenes.
   - Iteration 2: reshape `spike_scenario.json` toward portable board/path/towers/enemies/waves catalog data. Done.
   - Iteration 3: add the first minimal wave runner before richer combat, upgrades, blockers, or final assets. Done: `scripts/wave_runner.gd` schedules spawn requests from the JSON `waves` array, and `Main` instantiates placeholder enemies from those requests.
   - Asset spike: test `Tripo3D -> Blender cleanup -> GLB -> Godot -> Android/Web` with one tower, one terrain prop, one obstacle prop, and one small enemy/proxy.
   - Verify Android export prerequisites before expanding gameplay. Done: Android editor settings were verified, ETC2/ASTC import was enabled for Android validation, an `Android Debug` preset was added, and a signed debug APK smoke export was produced.
   - Next tooling step: add Windows and desktop Web export presets after the Android smoke path remains stable. Done: `Windows Desktop` and `Web Desktop` debug presets now produce local smoke builds under `shadow-conquest/builds/`.
   - Next: run the first asset pipeline spike through Godot import/export with one tower, one terrain prop, one obstacle prop, and one small enemy/proxy. Done for the first representative pass: the first tower GLB is imported, attached to the tower proxy, visually tuned with local fit/readability controls, and verified through Android, Web, and Windows smoke exports; `PlaceholderTower` now supports catalog-driven imported tower GLBs, textured OBJ meshes, and a visual-only B4 projectile preview model, with `shadow_tower_b2.glb`, textured `shadow_tower_b3_textured/base.obj`, `shadow_tower_b4.glb`, and `shadow_tower_b4_shot.glb` added as visual proxies; `BoardView` now supports a catalog-driven visual road surface model from `land.zip`; a visual-only corrupted roots/web obstacle proxy is placed from JSON data and verified through Android, Web, and Windows smoke exports; the enemy proxy supports the Godot-native primitive Gondor fallback plus catalog-driven imported Elven archer, Dwarven warrior, and Gondor warrior GLBs, with the Elven archer, Gondor warrior, and Dwarven warrior refreshed from user-provided ZIP PBR exports; a catalog-driven imported Mordor rock cluster terrain prop GLB now spawns under `World/TerrainProps`; current preview captures cover the imported tower, enemy, road, projectile, and terrain-prop candidates.
   - First Godot gameplay state adapter after the asset pipeline spike: enemy lifecycle and health bars are started in `PlaceholderEnemy`, with catalog health, damage API, health fraction, death hiding, and smoke coverage. Done.
   - Thin Godot combat/state adapter: `SpikeCombatAdapter` now registers spawned enemies from `Main`, delegates damage through enemy `apply_damage(amount)`, observes `died(enemy)`, untracks and queues dead enemies for removal, exposes a read-only target list, and tracks minimal kill/reward totals without changing `WaveRunner` scheduling. Done.
   - Thin Godot tower attack adapter: `SpikeTowerAttackAdapter` now registers placed tower proxies, reads catalog range/damage/fireRate/projectileModelPath, targets enemies exposed by `SpikeCombatAdapter`, and applies damage only through `combat_adapter.apply_damage`. Done as a boundary slice; no upgrades, target-priority UI, production projectile physics, wave-completion rewrite, or balance pass is included.
   - Visual-only B4 projectile movement preview: the tower attack adapter now spawns B4 shot visuals with start/end positions, advances them over their short lifetime, and expires them without moving damage ownership out of `SpikeCombatAdapter`. Done as a readability pass, not a production projectile system.
   - Small target-selection/readability pass: tower targeting now has smoke coverage for ignoring dead tracked targets and choosing the nearest live valid enemy, and successful shots spawn a short-lived visual-only tower fire cue. Done without adding target-priority UI, VFX systems, collision, balance changes, or new combat ownership.
   - Thin Godot wave state adapter: `SpikeWaveStateAdapter` now tracks active wave id, expected spawn count, spawned/active/removed enemies, and wave-clear state by listening to `SpikeCombatAdapter.enemy_removed`. Done as a boundary slice; no UI, next-wave automation, path breaches, win/loss logic, rewards, or balance changes are included.
   - Thin Godot game state adapter: `SpikeGameStateAdapter` now sits above wave-state with manual first/next wave hooks, current wave index, and `idle` / `running` / `wave_clear` / `basic_win` states. Done as a boundary slice; no automatic wave scheduling, UI, path breach, loss state, rewards, tower cooldowns, or balance changes are included.
   - Manual Godot next-wave integration: `Main.start_next_wave_manually()` now explicitly bridges a `wave_clear` state to the next `WaveRunner` wave and starts `SpikeWaveStateAdapter` for that wave. Done without UI, auto-advance, path breach, loss state, rewards, cooldown ownership, or balance changes.
   - Tiny debug trigger for manual next-wave review: `Main._unhandled_input` now maps the `N` key to `start_next_wave_manually()` so the local spike can advance from `wave_clear` without production UI. Done without auto-advance, balance, path breaches, loss state, rewards, damage, or tower cooldown ownership.
   - First path-breach/loss boundary: `SpikeGameStateAdapter` now tracks configured base lives, explicit path breach count, and terminal `basic_loss` state through `mark_path_breach()`. Done without endpoint detection, enemy movement changes, UI, automatic wave scheduling, rewards, tower cooldown ownership, or balance changes.
   - Enemy endpoint breach wiring: `PlaceholderEnemy` now emits a one-shot endpoint breach signal at the final path point, and `Main` bridges it to game-state breach accounting plus combat/wave-state removal without rewards or kill accounting. Done without pathing rewrite, production UI, balance changes, or new combat ownership.
   - Scenario-configured base lives: `spike_scenario.json` and the two-wave smoke fixture now include `gameState.baseLives`, and `Main` configures `SpikeGameStateAdapter` from that value before first-wave start with a minimum fallback of 1. Done without UI/HUD, balance pass, pathing rewrite, auto next-wave, or production loss screen.
   - Minimal debug HUD/readout: `Main` now includes a scene-level `HUD` Control using `scripts/spike_hud.gd`, bound read-only to game-state, wave-state, and combat adapters. It shows state, active wave, lives, breaches, and active enemy count for local spike review. Done without buttons, production HUD flow, auto next-wave, balance changes, or new gameplay ownership.
   - HUD visual readability capture: the debug HUD now has a translucent dark backing panel, smoke coverage for the panel/readout nodes, and a capture script that saves `builds/previews/spike_hud_preview.png`. Done without changing gameplay state, adding HUD controls, or choosing production mobile layout.
   - Multi-breach scenario progression fixture: `smoke_scenario_progression.gd` now verifies `baseLives=2` across two fixture waves: first endpoint breach clears wave 1 without loss, manual next-wave starts wave 2, second endpoint breach reaches `basic_loss`, and kills/rewards remain unchanged. Done without production code changes, auto next-wave, production loss UI, balance changes, or pathing rewrite.
   - Tower attack readability review is complete for the current spike:
     1. Capture-only pass: add/run a Godot preview capture for the current tower shot/fire cue/projectile visual state without changing VFX, balance, damage timing, targeting, or projectile behavior. Done: `capture_tower_attack_readability_preview.gd` saves `builds/previews/tower_attack_readability_preview.png` and verified the cue/projectile nodes.
     2. Readability tuning pass: done as a visual-only helper. `ProjectileVisual` now includes a temporary ember glow/trail and a slightly larger B4 projectile model, then expires through the same projectile visual lifetime without changing combat or wave state.
   - First explicit touch/mobile HUD layout decision: done. `SpikeHud` now implements the recommended read-only mobile-safe top bar with state, wave, lives, breaches, and active enemy count, including a two-row narrow layout and refreshed desktop plus rotated-phone landscape preview captures.
   - Narrow manual restart/reset boundary after terminal states: done. `Main.restart_current_scenario_manually()` rebuilds the current spike scenario after `basic_win` or `basic_loss`, resets runtime adapter state, and starts the first wave again without UI or automatic retry.
   - Tiny debug trigger for manual restart review: `Main._unhandled_input` now maps the `R` key to `restart_current_scenario_manually()`, so local review can reset only after `basic_win` or `basic_loss`. Done without HUD buttons, production restart screen, auto-retry, balance changes, or ownership changes.
   - First production HUD action shell: `SpikeHud` now shows a compact `ActionButton` only when player action is valid: `Next wave` at `wave_clear`, `Restart` at `basic_win` or `basic_loss`. The button emits HUD signals, while `Main` keeps ownership of the existing manual next-wave and restart hooks. Done without auto-advance, restart screens, balance changes, pathing changes, rewards, damage, or wave/combat ownership changes.
   - Terminal HUD action shell visual/test lock: done. `tests/capture_spike_hud_action_states.gd` now captures `wave_clear`, `basic_win`, and `basic_loss` in desktop and rotated-phone landscape, verifying `Next wave` / `Restart` text before saving the PNGs.
   - First obstacle/slow-zone gameplay spike: done. Existing corrupted-roots obstacle placements now act as slow zones through JSON `effect: "slow-zone"`, `slowMultiplier`, and `radius`; `Main` passes world-space zones to spawned enemies, and `PlaceholderEnemy` applies the active multiplier during local path movement. Done without path blocking, rerouting, blocker HP, enemy blocker attacks, production placement UI, auto-advance, restart changes, rewards, damage, or balance changes.
   - Slow-zone readability capture: done. `capture_spike_slow_zone_preview.gd` saves `builds/previews/spike_slow_zone_preview.png` after validating an active slow multiplier, with capture-only marker/label helpers for local review. Done without production UI, placement UI, blocker HP, path rerouting, combat ownership, wave-state ownership, or balance changes.
   - Obstacle tower ownership design pass: done. The accepted next slice is a narrow `SpikeObstacleTowerAdapter` boundary that registers existing JSON obstacle placements as runtime obstacle effects and exposes read-only slow-zone data, without blocker HP, stacking rules, pathing changes, enemy blocker attacks, obstacle lifetime, tower cooldown spawning, or production placement UI.
   - `SpikeObstacleTowerAdapter` implementation: done. The adapter is present in `scenes/main.tscn`, owns runtime slow-zone registration from existing obstacle placements, and `Main` now passes adapter-provided slow zones to spawned enemies instead of collecting `_slow_zones` itself.
   - First tower-owned obstacle behavior decision: timed slow-zone spawning is accepted as the next narrow spike. One existing tower candidate may periodically create temporary runtime slow zones through `SpikeObstacleTowerAdapter`, without blocker HP, pathing changes, stacking rules, enemy blocker attacks, visual spawned props, production placement UI, or balance changes.
   - Timed slow-zone spawning implementation: done. `shadow-tower-b2` now creates temporary runtime slow zones through `SpikeObstacleTowerAdapter` on a timer, using nearby path points and expiring zones after a configured lifetime.
   - Live slow-zone propagation decision: accepted as the next narrow slice. `Main` may push current adapter slow zones into already-spawned enemies so timed zones affect active movement, without blocker HP, pathing changes, stacking rules, enemy blocker attacks, visual spawned props, production placement UI, or balance changes.
   - Live slow-zone propagation implementation: done. `Main` now synchronizes adapter slow-zone data into spawned enemies after obstacle adapter advancement and at enemy creation, preserving `PlaceholderEnemy` as the movement slow owner.
   - Timed-spawn slow-zone readability capture: done. `capture_timed_slow_zone_preview.gd` waits for a tower-owned temporary slow zone, verifies an already-spawned enemy has an active slow multiplier inside it, and saves `builds/previews/timed_slow_zone_preview.png` with capture-only marker helpers.
   - Temporary blocker HP contract design: done. The accepted next implementation boundary is HP/lifetime lifecycle inside `SpikeObstacleTowerAdapter`, with read-only blocker output and explicit damage/removal APIs, while enemy movement blocking, enemy blocker attacks, path rerouting, stacking policy, rewards, balance, production placement UI, and final spawned blocker visuals stay out of scope.
   - Temporary blocker HP lifecycle implementation: done. `SpikeObstacleTowerAdapter` now spawns runtime blockers from `effect: "temporary-blocker"` catalog data, exposes read-only blocker output, supports explicit damage/removal, ages optional lifetimes, and clears blockers on reset. `shadow-tower-b3` uses the `orc-blockade` fixture effect for main-scene smoke coverage. Done without enemy movement blocking, enemy blocker attacks, path rerouting, stacking rules, tower retargeting, rewards, wave/game-state ownership, production placement UI, balance, or final spawned blocker visuals.
   - Enemy/blocker contact design and implementation: done. `Main` now pushes adapter blocker snapshots into spawned enemies, `PlaceholderEnemy` stops while touching a blocker radius, emits blocker damage requests, and `Main` bridges those requests back into `SpikeObstacleTowerAdapter.apply_blocker_damage()`. Done without path rerouting, stacking policy, attack animations, final VFX, spawned blocker visuals, rewards, score, gold, wave/game-state ownership, tower retargeting, balance, upgrades, costs, or production placement UI.
   - Blocker-contact readability capture: done. `tests/capture_blocker_contact_preview.gd` waits for the existing tower-owned `orc-blockade` runtime blocker, verifies an already-spawned enemy reports `current_blocker_id()` while placed at the blocker, verifies the existing damage bridge affects blocker HP, and saves `builds/previews/blocker_contact_preview.png` with capture-only marker helpers. Done without production blocker visuals, attack animations, path rerouting, stacking rules, rewards, balance, or placement UI.
   - Scenario selection/loading foundation for the two-map desktop MVP corridor: done. `res://data/scenario_index.json` owns `mvp-map-1` / `Black Gate Muster` and `mvp-map-2` / `Ithilien Pressure`, `SpikeScenarioCatalog` loads scenario index data, `Main.load_scenario_by_id(id)` rebuilds the current runtime by scenario id, and `SpikeHud` exposes a compact desktop scenario selector. This remains scenario loading only; build spots, tower purchasing, economy, upgrades, balance, and campaign persistence stay in later MVP blocks.
   - Next recommended MVP block: add data-driven build spots and tower purchasing for the selected scenario, keeping placement rules outside `Main` and leaving free tile placement out of scope.

8. Downloadable content and monetization foundation.
   - Accepted product model: isolated gameplay expansions plus cosmetic monetization. Paid gameplay DLC must not affect base campaign balance.
   - Seasonal/free packs may be claimable; claimed event content remains owned forever.
   - Architecture direction: `ContentPackManifest`, `ContentRegistry`, `EntitlementService`, `ContentInstaller`, platform `DeliveryProvider` adapters, and store adapters.
   - Inheritance should be used for behavior contracts only, while downloadable packs are data/resources plus manifest entries.
   - First implementation should start with local/dev content packs and entitlement tests before adding Google Play Asset Delivery, Steam depots, itch.io, or direct CDN providers.
