# Pixel Monsters

Godot 4.7.2 autonomous giant-monster observer game. The default scene is `scenes/battle.tscn`: two pristine 1,000-cube monsters fight without combat input.

Standalone Windows release: double-click `D:\Pixel Monsters\Play Pixel Monsters.bat`. It starts the local release executable directly.

The cinematic director starts automatically. V toggles director/free camera; moving or looking immediately takes over the current shot. WASD flies; Q/E smoothly turns; RMB + mouse looks; Z/X rises/drops; Shift boosts; +/- adjusts camera speed; wheel changes the lens; C restores the view. Space pauses the fight while the free camera stays usable; L cycles 1x / 0.5x / 0.25x; R starts a fresh fight. H hides all HUD, F1 shows controls, M toggles music, and F3 reveals diagnostics and manual anatomy tools.

Milestone 3 adds dusk atmosphere, a detailed miniature city, Blender beveled cube surfaces, tiered GPU dust, layered original positional Foley, and six original YuE2 orchestral cues. The aftermath persists until R. Music responds to damage and mobility loss with hysteresis and smooth crossfades. Slow motion leaves the score at its natural tempo.

`scenes/prototype.tscn` preserves the Milestone 1 destruction lab. Its vertical camera keys are now Z/X.

See [Milestone 3](docs/MILESTONE_03.md) for the cinematic presentation, soundtrack, camera, performance and validation report. [Milestone 2](docs/MILESTONE_02.md) covers combat architecture; [Milestone 1](docs/MILESTONE_01.md) documents the original body/destruction system. Raw measurements are in docs/.

Fresh core tests: Godot.exe --headless --path this-project-folder --script res://tests/run_headless.gd

Presentation checks: `Godot.exe --headless --path this-project-folder --script res://tests/presentation_validation.gd`.

Four complete real-time rendered fights: run `tests/rendered_suite.tscn`. Stage screenshots and telemetry are saved in `docs/evidence/milestone03/`. The suite is excluded from exports. Component ablation benchmark: run `tests/presentation_benchmark.tscn`.

Combat anatomy checks: `Godot.exe --headless --path this-project-folder --script res://tests/combat_validation.gd`.

Six seeded complete fights at 60 Hz: `Godot.exe --headless --path this-project-folder --script res://tests/battle_simulation.gd`. Writes `docs/battle-simulation.json` including contact-gap checks and stage measurements. Headless simulation validates logic; rendered runs validate appearance and FPS.

Export: `Godot.exe --headless --path this-project-folder --export-release "Windows Desktop" "D:\Pixel Monsters\Pixel Monsters.exe"`.

Optional verification recorder: set `PIXEL_MONSTERS_VERIFY_DIR` to a local output directory before launching. It saves release identity, telemetry and real framebuffer images. `PIXEL_MONSTERS_VERIFY_UNCAPPED=1` disables VSync for that verification run. Neither variable is supplied by the normal BAT.
