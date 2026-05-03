# Godot Migration Design

Date: 2026-05-01

## Accepted Direction

The project will move toward Godot as the main runtime/editor for the next production direction.

Primary target:
- mobile application, starting with Android.

Secondary targets:
- desktop browser export;
- Windows desktop executable.

Not a target:
- mobile web gameplay.

## Language Choice

Use GDScript for the Godot project.

Reasoning:
- Godot 4 C# cannot currently export to Web.
- Android/iOS C# support is available but still carries experimental limitations.
- GDScript keeps Android, desktop executable, and Web export on the most direct Godot path.

## Migration Strategy

The current JavaScript project remains useful as a prototype and reference for rules, balance, data shape, map scale, UI intent, and Shadow faction framing.

Do not port the Canvas renderer line-by-line. Rebuild the runtime in Godot-native scenes, scripts, resources, input, camera, and UI.

Recommended first spike:
- create a minimal Godot project skeleton;
- add an isometric map view;
- implement camera pan for touch and mouse;
- add one tower, one enemy path, and one wave;
- verify Android-ready structure early;
- verify desktop executable and desktop Web export path after the Android path is understood.

## Architecture

Keep the gameplay data-first:
- tower definitions;
- enemy definitions;
- wave/campaign definitions;
- balance values;
- upgrade rules.

Prefer Godot Resources or JSON-backed data for catalogs instead of baking balance into scenes.

Keep boundaries clear:
- simulation/rules;
- scene presentation;
- input;
- camera/projection;
- UI;
- save/progress;
- export/platform adapters.

## Tooling Direction

Evaluate Godot-focused MCP and skill tooling before installing:
- a Godot development skill for file format and workflow guidance;
- a Godot MCP server for editor/project/runtime feedback loops;
- Godot editor export templates;
- OpenJDK 17 and Android SDK/NDK/CMake for Android export.

MCP servers should be installed only after source review and explicit approval because they can control local files and editor/runtime state.

## Success Criteria For The Spike

- Godot project opens locally.
- A minimal TD scene runs in the editor.
- Camera input works with mouse and is structured for touch.
- Tower/enemy/wave data is externalized enough to stay portable.
- Android export prerequisites are identified and configured or documented.
- Desktop executable and desktop Web export remain viable secondary targets.

