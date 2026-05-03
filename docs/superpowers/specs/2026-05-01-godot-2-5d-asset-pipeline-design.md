# Godot 2.5D And Asset Pipeline Design

Date: 2026-05-01

## Accepted Direction

Shadow Conquest will be built in Godot as a 2.5D tower-defense game using a 3D scene with a fixed orthographic camera.

The game should not become a free-camera full 3D game. The gameplay remains tile/grid/data-driven, while the presentation uses 3D space for depth, tower silhouettes, lighting, terrain height, and stronger dark-fantasy material identity.

## Camera And View

- Main scene root should be `Node3D`.
- The world should use a 3D ground plane, with gameplay tiles mapped onto the XZ plane.
- Camera should be `Camera3D` in orthographic mode.
- Camera angle should be fixed to an isometric/three-quarter view.
- Player camera controls should support pan and zoom.
- Free rotation should be avoided for the first production slice to preserve mobile readability and reduce UI/pathing complexity.

## Gameplay Model

The simulation should remain logically tile-based:
- tower placement resolves to grid cells;
- road/path definitions remain data-driven;
- enemy movement follows path data;
- tower targeting uses simple world/grid conversions;
- blockers and slow zones are gameplay entities tied to path/tile positions.

3D objects are presentation for those data-backed entities, not the source of game rules.

## Renderer

Keep `gl_compatibility` as the project renderer.

Reasoning:
- Godot desktop Web export requires Compatibility/WebGL 2.0.
- The game is a stylized 2.5D TD and does not need advanced Forward+ features.
- Compatibility keeps the widest hardware support for Android and desktop Web.

## Asset Pipeline

Tripo3D can be used as a fast source of rough 3D assets and concept models.

Preferred pipeline:
1. Generate a model in Tripo3D.
2. Export as GLB / glTF 2.0.
3. Open in Blender.
4. Clean and optimize:
   - reduce polygon count;
   - fix normals;
   - simplify materials;
   - set origin and scale;
   - create low-poly/mobile-friendly variants when needed.
5. Import the cleaned GLB into Godot under `res://assets/models/`.

Use Tripo3D first for:
- dark towers;
- terrain props;
- ruins, rocks, barricades, and corrupted objects;
- blocker/obstacle prototypes;
- small enemy proxies if they read well from the fixed camera.

Use caution for:
- animated humanoids;
- final hero-quality enemy models;
- rigged characters;
- assets that will be viewed very close to the camera.

## Licensing

Generated model licensing must be tracked. Free Tripo3D outputs should not be assumed usable for a commercial game. If Tripo3D assets become part of the shipping game, store the relevant paid-plan/license evidence and generation metadata outside runtime assets.

## First Spike

Build the first Godot scene around the accepted 2.5D approach:
- `scenes/main.tscn` with `Node3D` root;
- orthographic `Camera3D`;
- simple generated tile board on XZ;
- mouse/touch-ready camera pan;
- one placeholder 3D tower;
- one placeholder enemy moving along a path;
- one externalized wave/tower/enemy data path.

The first spike may use simple Godot primitive meshes before Tripo/Blender assets are imported.

