# Android Porting

Android mobile application support is now the primary project goal.

The accepted direction is Godot with GDScript, not a Kotlin port. This note remains as the mobile/platform migration memory and should be renamed or split later if the Godot project becomes the active root.

## Architecture Direction

Keep the game split into portable domain logic and platform-specific adapters.

Portable:
- game data;
- game state;
- tower/enemy stats;
- wave logic;
- upgrade rules;
- coordinate math;
- camera math;
- collision and targeting rules.

Browser-specific:
- DOM;
- CanvasRenderingContext2D calls;
- CSS;
- localStorage;
- Playwright tests;
- browser pointer and wheel events.

Godot-specific future equivalents:
- GDScript scripts;
- Godot Resources or JSON-backed catalogs;
- Node3D world scenes plus Control UI scenes;
- touch and mouse input actions;
- Godot save/progress storage;
- Android export preset and signing configuration;
- desktop executable and desktop Web export presets.
- content-pack manifests, entitlement storage, downloaded-pack installation, and storefront delivery adapters.

## Coding Guidance

- Keep `gameData.js` as simple data where possible.
- Keep `gameLogic.js` free of DOM and canvas dependencies.
- Keep `camera.js` free of DOM and canvas dependencies; it already owns projection, scale, visible tile bounds, picking, and camera clamping.
- Keep moving simulation behavior out of `main.js` into portable functions when practical.
- Avoid embedding complex final artwork only as JavaScript canvas commands if it will need to be ported.
- Prefer sprites or a documented asset pipeline for rich tower art.

## Godot Mapping

Likely future files:
- `resources/content_packs/`
- `resources/towers/`
- `resources/enemies/`
- `resources/waves/`
- `scripts/content_registry.gd`
- `scripts/entitlement_service.gd`
- `scripts/content_installer.gd`
- `scripts/delivery_providers/`
- `scripts/game_state.gd`
- `scripts/game_rules.gd`
- `scripts/iso_projection.gd`
- `scripts/camera_controller.gd`
- `scripts/tile_grid.gd`
- `scripts/world_to_tile.gd`
- `scripts/simulation.gd`
- `scripts/input_controller.gd`
- `scripts/save_adapter.gd`
- `scenes/game.tscn`
- `scenes/ui/hud.tscn`
- `assets/models/`

## Porting Risk

The earlier risk of `src/main.js` mixing input, renderer, camera, UI, storage, audio, and all simulation behavior has been reduced by the current module boundaries:
- `src/camera.js`: portable camera/projection math.
- `src/renderer.js`: browser Canvas 2D drawing.
- `src/ui.js`: browser DOM rendering.
- `src/storage.js`: browser persistence adapter.
- `src/audio.js`: browser WebAudio adapter.
- `src/input.js`: browser input adapter.
- `src/simulation.js`: portable spawning timers, enemy creation, enemy movement, target selection helpers, tower placement, tower upgrades, tower selling/refund value, tower cooldown/attack orchestration, damage application with hit/slow/splash handling, projectile/beam/mark/shockwave effect creation, kill rewards/effects, outcome transitions, projectile aging, and effect aging.

Remaining risks:
- `src/main.js` still owns browser-side outcome callbacks, UI sync, and high-level state/game-loop wiring.
- `src/renderer.js` still contains detailed canvas-only tower art, including temporary heroic tower visuals.
- The first Godot JSON catalog shape now separates board, portable `gameState.baseLives`, path, tower catalog/placements, obstacle catalog/placements, enemy catalog, and wave spawn descriptors; `scripts/wave_runner.gd` consumes the wave descriptors as a portable spawn scheduler, `scripts/placeholder_enemy.gd` owns local path traversal, endpoint breach signaling, the first slow-zone movement multiplier contract, and the first blocker contact stop/damage-request signal, `scripts/spike_combat_adapter.gd` owns enemy damage/death/reward tracking plus non-reward unregister removal and a local runtime reset hook, `scripts/spike_tower_attack_adapter.gd` owns thin tower cooldown/targeting state while delegating damage back to combat and can clear its local review visuals/registrations, `scripts/spike_obstacle_tower_adapter.gd` owns runtime obstacle effect registration from static JSON obstacle placements, timed tower-owned slow-zone spawning, portable slow-zone dictionaries, and temporary blocker HP/lifetime dictionaries with read-only output plus explicit damage/removal APIs, `scripts/spike_wave_state_adapter.gd` owns minimal wave-clear state, `scripts/spike_game_state_adapter.gd` owns minimal scenario progression, manual next-wave state, and explicit path-breach/basic-loss accounting, and `scripts/spike_hud.gd` is a Godot-specific Control adapter over those states with a mobile-safe narrow layout and signal-only `Next wave` / `Restart` action shell. `Main` remains the composition root that spawns obstacle visuals, registers tower proxies with the obstacle adapter, advances the adapter, synchronizes adapter-provided slow zones and blockers into spawned enemies, and bridges enemy blocker damage signals into `SpikeObstacleTowerAdapter.apply_blocker_damage()`. This does not add path rerouting, stacking policy, combat ownership, wave/game-state ownership, rewards, production UI, or balance changes. `Main.start_next_wave_manually()` and `Main.restart_current_scenario_manually()` remain the composition-root hooks behind those HUD signals. `tests/smoke_scenario_progression.gd` covers this split across two waves and two endpoint breaches without adding new production ownership, while `tests/smoke_spike_hud.gd` locks the narrow HUD wrap contract, HUD action signal wiring, and the rotated-phone landscape capture contract. Future Godot Resources and UI scenes can mirror this split while tower/enemy catalogs, obstacle ownership, and production HUD layout continue changing.
- The first accepted blocker HP lifecycle data is portable: blocker ids, source tower ids, positions, radius, max/current HP, and optional lifetime live in adapter-owned dictionaries and scenario catalog data (`orc-blockade`) rather than scene-only visual nodes. The first enemy interaction also stays portable as snapshot input plus `blocker_attack_requested(blocker_id, amount)` signal output. `tests/capture_blocker_contact_preview.gd` is local review instrumentation over those existing APIs, not a new runtime dependency. Path rerouting, stacking, rewards, production UI, and final balance remain separate decisions so the data contract can later be moved to shared rules cleanly.

Before adding many new dark tower visuals, prefer the Godot spike and avoid locking rich art only into browser canvas drawing commands.

## Downloadable Content And Monetization

The accepted monetization model is isolated gameplay expansions plus cosmetic monetization:
- paid gameplay DLC must not grant advantages in the base campaign;
- cosmetic purchases may change towers, enemies, terrain themes, effects, and UI presentation without changing stats or rules;
- free and seasonal packs are allowed;
- claimed event content remains owned permanently after claim.

Use a platform-neutral downloadable content model:
- `ContentPackManifest` declares pack id, version, content ids, dependencies, grant policy, required app version, and integrity metadata;
- `ContentRegistry` loads installed and verified manifests;
- `EntitlementService` decides whether content can be used, claimed, downloaded, or removed;
- `ContentInstaller` handles installation, hash verification, updates, and deletion of downloaded files;
- `DeliveryProvider` adapters bridge stores and distribution channels.

Recommended provider direction:
- Google Play release: prefer Google Play Asset Delivery for large asset packs;
- Steam release: use Steam DLC/depots and scan installed depots for manifests;
- itch.io/direct release: prefer butler/Wharf for build updates, with a direct manifest/CDN provider only when standalone in-game downloads are needed.

Downloaded packs should initially be asset/data-only. They may include manifests, Godot resources, scenes, models, textures, sounds, localization, and JSON data, but should select built-in behavior ids rather than shipping arbitrary new scripts.

## Android Export Prerequisites

Godot Android export requires additional local tooling beyond the editor:
- OpenJDK 17;
- Android SDK;
- Android SDK Platform-Tools 35.0.0 or later;
- Android SDK Build-Tools 35.0.1;
- Android SDK Platform 35;
- Android SDK Command-line Tools;
- NDK r28b;
- CMake 3.10.2.4988404.

These should be installed on a drive with enough free space, preferably not `C:` unless space is cleaned up first.

## Installed Local Tooling

- Godot Standard `4.6.2.stable.official.71f334935`: `D:\Godot\Godot_v4.6.2-stable_win64_console.exe`.
- Godot portable self-contained marker: `D:\Godot\_sc_`.
- Godot export templates: `D:\Godot\editor_data\export_templates\4.6.2.stable`.
- Codex Godot skill: `C:\Users\Fangarh\.codex\skills\godot`.
- GoPeak MCP: configured in `C:\Users\Fangarh\.codex\config.toml`, package version checked as `2.3.6`.
- OpenJDK 17: `D:\Godot\Java\jdk-17.0.18+8`.
- Android SDK root: `D:\Godot\Android\Sdk`.
- Android SDK packages:
  - `platform-tools` `37.0.0`;
  - `build-tools;35.0.1`;
  - `platforms;android-35`;
  - `cmdline-tools;latest` `20.0`;
  - `ndk;28.1.13356709`;
  - `cmake;3.10.2.4988404`.
- Android SDK licenses are accepted.
- User environment variables are set:
  - `JAVA_HOME=D:\Godot\Java\jdk-17.0.18+8`;
  - `ANDROID_HOME=D:\Godot\Android\Sdk`;
  - `ANDROID_SDK_ROOT=D:\Godot\Android\Sdk`.

After opening Godot, verify the editor Android settings use:
- Java SDK Path: `D:\Godot\Java\jdk-17.0.18+8`;
- Android SDK Path: `D:\Godot\Android\Sdk`.

Verified on 2026-05-01 in `D:\Godot\editor_data\editor_settings-4.6.tres`:
- `export/android/java_sdk_path = "D:\\Godot\\Java\\jdk-17.0.18+8"`;
- `export/android/android_sdk_path = "D:\\Godot\\Android\\Sdk"`;
- `export/android/debug_keystore = "D:/Godot/editor_data/keystores/debug.keystore"`.

Android export smoke-test status:
- `shadow-conquest/export_presets.cfg` now has an `Android Debug` preset for APK export.
- `shadow-conquest/project.godot` enables `rendering/textures/vram_compression/import_etc2_astc=true`; Godot Android export validation fails without ETC2/ASTC imports enabled.
- The preset intentionally leaves debug keystore fields empty so credentials are not stored in the project. For local CLI smoke exports, pass:
  - `GODOT_ANDROID_KEYSTORE_DEBUG_PATH=D:\Godot\editor_data\keystores\debug.keystore`;
  - `GODOT_ANDROID_KEYSTORE_DEBUG_USER=androiddebugkey`;
  - `GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD=android`.
- Smoke APK output: `shadow-conquest/builds/android/ShadowConquest-debug.apk`; `builds/` is ignored by `shadow-conquest/.gitignore`.
- `apksigner verify --verbose` confirms the APK verifies with v2 and v3 signature schemes.

Secondary export smoke-test status:
- `shadow-conquest/export_presets.cfg` now has `Windows Desktop` and `Web Desktop` debug presets.
- Windows smoke output: `shadow-conquest/builds/windows/ShadowConquest.exe`, with `ShadowConquest.console.exe` generated for console/headless checks.
- Web smoke output: `shadow-conquest/builds/web/index.html`, plus generated `.wasm`, `.pck`, JavaScript, and icon assets.
- The Windows debug build starts successfully via `ShadowConquest.console.exe --headless --quit-after 10`.
- Web export keeps `variant/thread_support=false` for the current desktop browser prototype path.

## Godot Project

- Project root: `D:\Projects\Games\TD\shadow-conquest`.
- Project name: `ShadowConquest`.
- Renderer: `gl_compatibility` for desktop and mobile.
- Android texture import: ETC2/ASTC import is enabled for mobile export validation.
- Presentation: 2.5D using a `Node3D` world, fixed orthographic `Camera3D`, and tile/grid gameplay on the XZ plane.
- Main scene: `res://scenes/main.tscn`.
- First spike scripts/scenes: `res://scripts/main.gd` loads the JSON catalog scenario, composes/restarts the world, bridges enemy endpoint breach signals to game/combat/wave state, synchronizes current slow-zone data into spawned enemies, and binds the read-only HUD; `res://scripts/wave_runner.gd` schedules spawn requests from JSON wave data, `res://scripts/spike_combat_adapter.gd` owns enemy damage/death/removal/rewards, `res://scripts/spike_tower_attack_adapter.gd` owns thin tower targeting/cooldowns and delegates damage to combat, `res://scripts/spike_obstacle_tower_adapter.gd` owns runtime obstacle effect registration, timed tower-owned slow-zone spawning, and slow-zone data output, `res://scripts/spike_wave_state_adapter.gd` owns minimal active-wave/spawned/removed/clear state, `res://scripts/spike_game_state_adapter.gd` owns minimal progression and explicit path-breach/basic-loss state, `res://scripts/spike_hud.gd` owns a compact top-bar Control readout with desktop and narrow mobile layouts, `res://scripts/board_view.gd` generates the primitive XZ board/path, `res://scenes/entities/placeholder_tower.tscn`, `res://scenes/entities/placeholder_obstacle.tscn`, and `res://scenes/entities/placeholder_enemy.tscn` hold the first proxy entities, and `res://scripts/camera_controller.gd` owns mouse wheel zoom plus mouse/touch drag panning.

## Model Asset Pipeline

Tripo3D can be used for rough model generation and concept assets, but the production pipeline should be:
- Tripo3D export as GLB/glTF 2.0;
- Blender cleanup and optimization;
- Godot import under `res://assets/models/`;
- Android/Web smoke test before the asset type is used broadly.

Track licensing for AI-generated assets. Do not assume free-plan Tripo3D output is suitable for commercial release.

Current asset pipeline status:
- `base.glb` is imported as `res://assets/models/towers/base.glb`.
- `PlaceholderTower` loads the imported GLB at runtime, auto-fits it to the existing one-tile tower footprint, and keeps the previous basalt/ember primitive as a fallback.
- The tower GLB has passed local Android Debug, Web Desktop, and Windows Desktop smoke exports.
- A Godot-native visual-only obstacle proxy now exists under `scenes/entities/placeholder_obstacle.tscn`, is placed from JSON `obstacles.placements`, and has passed local Android Debug, Web Desktop, and Windows Desktop smoke exports; it is not gameplay pathing logic yet.
- A Godot-native primitive enemy proxy now represents a Gondor soldier with simple body, helmet, shield, spear, and banner meshes. It keeps the portable path/speed movement contract and is not a final rigged or animated enemy asset.
- Terrain assets are still primitive pending the rest of the asset spike.
- `shadow-conquest/builds/.gdignore` prevents exported Web/Windows build artifacts from being scanned as Godot resources during import.
