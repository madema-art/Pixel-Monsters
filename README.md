# Pixel Monsters

Godot 4.7.2 autonomous giant-monster observer game. The default scene is `scenes/battle.tscn`: two pristine 1,000-cube monsters fight without combat input.

Standalone Windows release: double-click `D:\Pixel Monsters\Play Pixel Monsters.bat`. It starts the local release executable directly.

WASD flies; Q/E smoothly turns; RMB + mouse looks; Z/X rises/drops; Shift boosts; +/- adjusts camera speed; wheel zooms; C restores the view. Space pauses; L cycles 1x / 0.5x / 0.25x; R starts a fresh fight; F3 reveals diagnostics and manual anatomy tools.

`scenes/prototype.tscn` preserves the Milestone 1 destruction lab. Its vertical camera keys are now Z/X.

See [Milestone 2](docs/MILESTONE_02.md) for combat architecture, validation, performance and limitations; [Milestone 1](docs/MILESTONE_01.md) documents the original body/destruction system. Raw measurements are in docs/.

Fresh core tests: Godot.exe --headless --path this-project-folder --script res://tests/run_headless.gd

Combat anatomy checks: `Godot.exe --headless --path this-project-folder --script res://tests/combat_validation.gd`.

Six seeded complete fights at 60 Hz: `Godot.exe --headless --path this-project-folder --script res://tests/battle_simulation.gd`. Writes `docs/battle-simulation.json` including contact-gap checks and stage measurements. Headless simulation validates logic; rendered runs validate appearance and FPS.

Export: `Godot.exe --headless --path this-project-folder --export-release "Windows Desktop" "D:\Pixel Monsters\Pixel Monsters.exe"`.

Optional verification recorder: set `PIXEL_MONSTERS_VERIFY_DIR` to a local output directory before launching. It saves release identity, telemetry and real framebuffer images. `PIXEL_MONSTERS_VERIFY_UNCAPPED=1` disables VSync for that verification run. Neither variable is supplied by the normal BAT.
