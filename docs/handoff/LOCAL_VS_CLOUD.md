# Local versus cloud execution

Local Codex had Windows, `D:\Godot\Godot.exe` (Godot 4.7.2), the live project at `D:\Godot\Projects\Pixel-Monsters`, Godot AI MCP, Blender 5.2.1 LTS with Blender MCP, and the standalone Windows folder `D:\Pixel Monsters`. It could run actual GPU-rendered games and inspect them through Godot MCP. Interactive MCP/editor state is not in Git.

Cloud Claude works from a GitHub checkout. It has no direct D: filesystem, no automatically connected local Godot AI/Blender MCP, no guaranteed Windows executable/export templates, and no assumed installed release. Install a compatible Godot runtime for cloud tests; initial import populates its own `.godot/`. Headless logic passes cannot replace local visual/sonic acceptance. Preserve local Windows/Godot/Blender compatibility.

Runtime resources use `res://`. `compile_creatures.py` derives repository root from its script path and runs with standard Python. Blender study/refresh/brief tools currently assume `D:/Godot/Projects/Pixel-Monsters` (Blender cube authoring also has a D: output path). Adapt those root constants for a cloud checkout without rewriting the creature pipeline. Saved .blend files include the studies, editable volumes/anchor empties, source scenes and preview objects; JSON/runtime assets support development without live Blender.

Original score generation depends on local `D:/YuE2`, CUDA, models and scratch output paths recorded in `tools/generate_score.py` and `score-prompts.json`. Those dependencies/model weights are not required to play the committed audio. Do not regenerate music just to make a cloud checkout run.

`export_presets.cfg` points to the local installed executable. Supply an explicit export output path in cloud jobs. Matching 4.7.2 Windows export templates and a future local launch check are required. Do not commit EXE/PCK output, caches, secrets or `.blend1/.blend2`. A future local checkout should export `D:\Pixel Monsters\Pixel Monsters.exe`, preserve/copy `tools/Play Pixel Monsters.bat`, and test that BAT launches the exported game directly. Installed folder is not source.

No remote/authentication was available at handoff. On an authenticated local machine, create a PRIVATE GitHub repository named Pixel-Monsters, add its remote, and push `codex/milestone-04-archetypes`; verify remote SHA against local HEAD. Cloud Claude must open that branch, not assume an unfinished branch was merged into stable. A Git bundle of the complete local history is provided as a recoverable transfer artifact.

CI was deliberately deferred under the user's preservation-first/time-budget instruction. Add a small import/core/combat/archetype headless workflow after publication, verifying Godot version/platform availability. No GitHub Actions result or cloud compatibility was claimed.
