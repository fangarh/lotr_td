# Elf Archer Blender Asset Design

## Context

The first Blender elf asset should follow the current Shadow conquest direction. The elf is a Free Peoples enemy/proxy, not a player-side unit. The asset should read clearly from a fixed orthographic isometric camera and remain simple enough for later cleanup, GLB export, and Godot mobile use.

## Chosen Direction

Use an Elven archer as the first asset candidate.

Key traits:
- slim upright humanoid silhouette with pointed ears and long blond hair;
- green cloak and muted light armor to contrast against Mordor towers;
- bow and quiver as the primary readability markers;
- light, clean materials rather than dark corruption materials;
- compact footprint suitable for one enemy proxy on a tile/path.

## Blender Scope

Create a procedural low-poly/proxy model directly in Blender:
- named root collection/object group: `Elf_Archer_Proxy`;
- body, head, pointed ears, hair, cloak, legs, arms, bow, bowstring, quiver, arrows, small base marker;
- simple materials with clear names;
- basic lighting and camera for viewport review.

Integration follow-up completed:
- exported the proxy to `shadow-conquest/assets/models/enemies/elf_archer_proxy.glb`;
- imported it as a Godot `PackedScene`;
- wired it through `PlaceholderEnemy.configure_visual(data)` and the spike enemy catalog as `elven-archer`.
- tuned the spike catalog fit to `targetHeight=1.15` and `targetFootprint=0.86` after capturing a Godot preview from the fixed isometric camera.
- completed a second readability pass with exaggerated bow/string/arrow, brighter hair, longer ears, wider cloak panels, silver trim, and an exported base ring for the current full-board prototype camera.

Out of scope for this pass:
- rigging and animation;
- final production topology;
- cloth simulation;
- canon-specific insignia or exact Tolkien character likeness.

## Review Criteria

The asset is acceptable for this pass if it is recognizably an elf archer from a zoomed-out isometric view, has clear Free Peoples/light-side contrast, and can serve as a placeholder for the Godot enemy asset pipeline.
