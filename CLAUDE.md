# Pixel Monsters — Cloud Claude entry point

**Read this file and every file in `docs/handoff/` before substantial changes. First development task: AUDIT AND COMPLETE MILESTONE 4. Do not begin Milestone 5.**

Pixel Monsters is an observer-first autonomous giant-monster game. The player watches or flies a free camera; combat input is not required. Each pristine creature must contain **exactly 1,000 visible, destructible cubes**. Physical body material is health: actual localized cube removal creates permanent cavities, weakens structural connections, detaches limbs, compromises movement, and can cause fatal collapse. Never replace this with invisible HP or cosmetic destruction.

Godot 4.7.2; project root is this repository. Main scene: `scenes/battle.tscn`. Local Windows project: `D:\Godot\Projects\Pixel-Monsters`. Completed Milestone 3 checkpoint: `77321a2`. Continue **`codex/milestone-04-archetypes`**, using the handoff commit at branch HEAD. Milestone 4 is partial, not complete. Export metadata says 0.4.0.0, but the installed Windows executable was not updated during Milestone 4.

The new roster is Gorgeblock (wide brute), Needlemantle (tall longarm), and Bastion (large skull/charge). `data/creatures/*.json` holds compiled 1,000-cell bodies, exported rig anchors, allocations, behavior, attacks, vulnerabilities, and sonic parameters. `art/creatures/*.blend` and reference renders preserve editable Blender studies. See `docs/CREATURE_PIPELINE.md`; the fresh-session studio-to-preview bootstrap still needs auditing.

Important systems: `scripts/monster.gd`, `body_layout.gd`, `structure.gd`, `debris.gd`; `scripts/combat/{archetypes,combatant,rig,moves,attack_motion,brain,sound}.gd`; `scripts/battle.gd`, `arena.gd`, `observer.gd`; `scripts/cinema/{director,effects,music}.gd`. `audio/cinema/` contains the existing original Foley and adaptive orchestral cues; `meshes/body_cube.obj` is the shared Blender beveled cube. Paths and responsibilities are detailed in `docs/handoff/ARCHITECTURE.md`.

Essential fresh-process checks, from repository root (`godot` means a compatible Godot executable):

```text
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/run_headless.gd
godot --headless --path . --script res://tests/combat_validation.gd
godot --headless --path . --script res://tests/archetype_validation.gd
godot --headless --path . --script res://tests/presentation_validation.gd
```

The original combat/presentation fixtures explicitly use legacy anatomy to protect the proven checkpoint. Archetype tests cover the authored bodies separately. Longer tests: `tests/archetype_matrix.gd`, `archetype_extended_matrix.gd`; visual suite: `tests/archetype_rendered_suite.tscn` (2x wall-clock playback, 120 physics ticks/s to preserve 60 Hz simulation steps). Gallery: `tests/archetype_gallery.tscn`. Headless results do not establish visual quality. See handoff documents for exactly which source revisions were tested.

Windows release export requires matching Godot 4.7.2 export templates:

```text
Godot.exe --headless --path . --export-release "Windows Desktop" "D:\Pixel Monsters\Pixel Monsters.exe"
```

`export_presets.cfg` includes creature JSON and excludes development art/docs/tests/tools. `tools/Play Pixel Monsters.bat` launches the exported executable directly; copy it to the installed game folder after a future export and test it. Never replace it with an editor/project-manager launcher. `D:\Pixel Monsters` is not authoritative source and is not tracked.

Inspect first: current uncompleted validation/balance issues in `docs/handoff/CURRENT_STATE.md`, exact scope in `PROMPT_4.txt`, latest matrix artifacts, rig anchors vs posed geometry, and Blender tooling assumptions. Preserve destruction, actual geometry contact, debris limits, adaptive music, observer controls, and the director instead of casually rewriting proven systems. Do not assume local MCP, Windows paths, audio-generation tools, or installed builds exist in cloud execution.

GitHub was unavailable at local handoff: no remote, no authenticated Git Credential Manager GitHub account, no gh executable, and no GH_TOKEN/GITHUB_TOKEN. Publish this branch to a PRIVATE Pixel-Monsters repository before starting Cloud Claude. No CI was added during this preservation task.
