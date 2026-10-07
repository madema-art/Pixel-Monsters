# Pixel Monsters

Godot 4.7.2 core destruction prototype. Open project.godot and press F5 to launch the lab.

Press 1–6 to select a target region, F to strike, G for a large impact, and R to reset both 1,000-cube monsters. WASD flies the observer; Q/E turns; RMB + mouse looks; Space/Ctrl rises/drops.

See [the milestone report](docs/MILESTONE_01.md) for architecture, exact allocations, controls, performance and limitations. Raw measurements and visual evidence are in docs/.

Fresh core tests: Godot.exe --headless --path this-project-folder --script res://tests/run_headless.gd

Live integration tests: load tests/runtime_validation.gd as a Node, add it to the running root and call run(current_scene). It writes docs/runtime-tests.json when finished.
