# Pixel Monsters — Milestone 3

The standalone Windows build is version **0.3.0.0**. The cinematic director begins automatically, two pristine 1,000-cube monsters fight, the original score escalates, and the defeated monster collapses into persistent wreckage. The survivor and aftermath remain until R.

Development remains in `D:\Godot\Projects\Pixel-Monsters`. Double-click `D:\Pixel Monsters\Play Pixel Monsters.bat` to play. The BAT launches `Pixel Monsters.exe` directly. The tested release reports no command-line arguments, `debug_build: false`, and the window title **Pixel Monsters**. A normal standalone instance has been left running.

## Image, scale and monster surfaces

A warm low directional key, cool opposing rim, blue ambient fill, long shadows, distance haze, ACES tonemapping and an original procedural dusk/cloud sky replace the brighter test-arena presentation. No film-grain, monochrome filter or screen-filling bloom was added.

The city now has façade divisions, selective warm windows, skyline windows and roof silhouettes, rooftop equipment and tanks, buses, utility poles and wires, fences, crossings, benches and signs. These remain inexpensive batched geometry. They support the street and medium compositions rather than becoming a destructible-city project.

Blender produced a shared **0.94 m cube with 0.026 m flat bevels** for bodies and debris. Broad faces remain flat; edges catch light. Revised roughness/metallic response and region coloration emphasize brow, jaw, shoulders and lower torso. Every monster still starts with exactly 1,000 cubes; body topology, damage allocation, attack logic, rig and AI are unchanged. All existing Blender objects and the user's editing mode were preserved. The reproducible mesh generator is included.

## Impacts and sound

Sixteen reusable GPU particle emitters provide soft, directional dust: light hits use 18 particles/0.8 seconds; strong hits 36/1.3 seconds; devastating hits 64/1.8 seconds plus supporting ground dust. Completed footplants use compact 12-particle puffs. Collapse has a heavier dust burst and distance-scaled camera impulse. The original physical cube eruption and persistent cavity remain the main effects.

Tiers derive from actual destruction and attack force. Devastating means more than 45 detached cubes or more than 85 total removed cubes. Strong means power at least 20 or more than 30 removed cubes; remaining contacts are light. Physics/debris allocation is preserved: at most 192 physical cubes, followed by cheap ballistic/settled rubble. Settled cubes persist until restart.

Thirty-two positional audio voices combine **twelve original procedural Foley cues** for punches, hooks, kicks, head/body blows, footplants, fracture, clatter, limb loss, stagger, collapse and defeat. Different spectra and envelopes distinguish events; small pitch/volume variations prevent identical repetitions. Distance attenuation/filtering reduces distant fracture detail while retaining low impact weight. Major blows layer body resonance and debris tails.

## Original adaptive score

Six instrumental cues were generated locally with the installed YuE2/audio.cpp CUDA setup. All generation jobs completed successfully; each produced a 40-second stereo 48 kHz source. Normalized, overlapping endpoints produce approximately 38-second Vorbis loops. No reference movie recording was supplied. Complete prompts, seeds, models, settings, preparation and Foley source are preserved under `tools/`, with provenance in `docs/AUDIO_PROVENANCE.md`.

| State | Trigger |
|---|---|
| Opening | First 12 battle seconds |
| Early | After opening, below 18% total destruction |
| Mid | At least 18% destruction |
| Severe | At least 38% destruction |
| Desperate | At least 60%, or over 30% with both monsters severely impaired in mobility |
| Aftermath | Two seconds after defeat |

Decisions run at 5 Hz, with an eight-second minimum between escalation changes and monotonic progression until restart. Volume crossfades take 5.5 seconds. Large hits briefly duck the score. Pause lowers its volume; slow motion leaves music at its natural tempo. Not every fight must reach every escalation state: an early fatal neck/head failure can go directly from a less damaged battle to aftermath.

The final exported seeded fight reached opening → early → mid → severe → desperate → aftermath at approximately 0.1, 12.2, 73.2, 98.1, 122.4 and 158.8 seconds.

## Observer, director and aftermath

The free camera smooths acceleration, deceleration, mouse/keyboard turning, speed and lens changes. Movement or RMB immediately takes over the current director position and orientation. The director chooses establishing, street, medium two-shots, side/rim, elevated and shoulder views using full-body coverage, distance from the monsters, building occlusion and shot variety. Slow tracking/drift supports held compositions. Normal cuts wait at least ten seconds and avoid wind-up/committed attacks. Coverage pressure gently pulls the camera back. The collapse shot holds four battle seconds; aftermath shots hold eighteen seconds.

The final exported fight had no building-blocked selected shots and a maximum sampled pre-defeat coverage fraction of 0.926, below the screen edge at 1.0. The four-fight suite also had no blocked selected shots. These are heuristic framing checks, not a general-purpose cinematic planner.

Pause freezes battle, debris and dust while free-camera movement continues. The rendered test moved the camera 9.91 m over one second with the battle clock frozen. At quarter speed, 1.2 real seconds advanced 0.304 battle seconds; dust used a 0.25 speed scale and the score pitch remained 1.0. Impact pitch changes remain restrained rather than following time scale down to a quarter pitch. Automatic slow motion and automatic restart were not needed; the aftermath has no timeout.

Normal UI fades after the opening and otherwise appears briefly for relevant changes. F3 retains diagnostics; H hides the entire HUD.

| Control | Action |
|---|---|
| V | Director / free camera |
| WASD, Z/X | Fly, rise/drop |
| Q/E, RMB + mouse | Turn / look |
| Shift, +/−, wheel | Boost, cruise speed, lens |
| C | Home view |
| Space, L | Pause, cycle 1× / 0.5× / 0.25× |
| R | New fight |
| H, F1, F3 | Hide HUD, controls, diagnostics |
| M, K | Music and camera-shake toggles |

## Validation and performance

Milestone 2 checkpoint **7c24191** is preserved. Work is on **codex/milestone-03-cinematic**.

- Six destruction tests passed with 1,093 assertions.
- Twenty combat checks and twenty presentation checks passed.
- Six final seeded simulation fights all finished. Their durations and hit counts exactly match the pre-change baseline: approximately 95.9–173.0 seconds, with a maximum contact gap of 11.5 seconds.
- Six complete rendered fights were evaluated: one initial visual iteration, four seeded real-time suite fights, and one final exported BAT-launched fight. Inspection used live Godot MCP screenshots and recorded stage images/telemetry, rather than a claim of uninterrupted viewing of every frame.
- Rendered suite seeds 211 / 617 / 7907 / 9929 finished in 156.75 / 147.65 / 95.88 / 156.32 seconds. The final exported seed 211 also finished in 156.75 seconds, leaving 340 survivor cubes and 1,660 rubble cubes.
- A fresh 1,000-cube collapse benchmark took 8.44 ms of emission work; physical bodies remained capped at 192.
- The BAT was tested for both the instrumented release and a fresh normal launch. No editor, project manager or F5/F6 step is involved.

Measurements use the RTX 2070 SUPER at **1152×648, uncapped**, with real-time simulation. The freshly remeasured M2 release had an early-fight median of **920 FPS**, versus **714 FPS** for M3's normal presentation. Different seeds and changing compositions make that a presentation comparison, not an isolated identical-shot experiment. The final M3 release had a **697 FPS median** and **518 FPS minimum sampled 1-second rate** across the recorded fight/aftermath. Recording itself adds occasional work; the normal handoff uses VSync.

| Stage | Median sampled FPS | GPU ms | Debris script ms | AI ms |
|---|---:|---:|---:|---:|
| Pristine | 745 | 0.647 | 0.005 | 0.028 |
| 25% destruction | 696 | 0.962 | 0.401 | 0.030 |
| 50% destruction | 656 | 0.758 | 0.683 | 0.030 |
| Severe late combat | 700 | 0.625 | 0.579 | 0.031 |
| Limb loss | 698 | 0.690 | 0.203 | 0.030 |
| Large debris event | 698 | 0.690 | 0.203 | 0.030 |
| Collapse | 659 | 0.633 | 1.543 | 0.029 |
| Settled aftermath | 698 | 0.726 | 0.658 | 0.029 |

Stage windows are short medians around actual events; collapse contains one sampled point. The late-combat row uses the final twelve seconds before defeat because structural failure can precede the 65% total-destruction threshold. GPU timings are viewport measurements. Debris figures measure script work; total physics time includes Jolt, motors, contact resolution and other work.

A fixed-state, fixed-composition benchmark with sustained dust/audio measured **836 FPS**, a **0.971 ms median frame interval**, **2.762 ms 95th percentile**, **0.700 ms GPU rendering**, and approximately **0.024 ms director work**. Its independent ablations were:

| Configuration | FPS | GPU median ms |
|---|---:|---:|
| full | 836 | 0.700 |
| no vfx | 889 | 0.683 |
| no audio | 834 | 0.705 |
| no director | 840 | 0.704 |
| no shadows | 957 | 0.574 |
| no directional lights | 976 | 0.540 |
| no haze | 834 | 0.704 |

Shadows cost roughly 0.13 ms of GPU time in that scene; VFX roughly 0.02 ms. The all-directional-light ablation also removes shadows, so its difference is not an independent lighting-only cost. Audio and director effects on GPU time are within noise; script timings and frame intervals are the relevant measurements. Normal soundtrack processing is approximately 0.005–0.04 ms in sampled release frames, with occasional 5 Hz decision work. Raw telemetry and benchmark records are retained in `docs/`.

## Problems fixed and remaining limits

Visual iteration caught and fixed an incorrectly smoothed OBJ import that made broad cube faces look crystalline; explicit flat face normals, disabled LOD generation and refreshed imports restored the intended bevels. The old permanent camera-help label was removed. Defeat/collapse no longer spuriously escalates the score for a fraction of a second before aftermath, and director cuts now respect the collapse hold. Music's unnecessary per-frame 2,000-cube recount was reduced to five checks per second. Script encoding and test frame-order issues were corrected before the successful final runs.

Known weaknesses: the director uses a small shot vocabulary and can still produce overlapping silhouettes; the city is a theatrical static miniature and has a finite edge; late damage/collapse poses remain inherited approximations. The original score uses short generated cues and needs further musical editing for longer-form development. **Audio playback, formats, signal levels, loop preparation and transitions were verified, but this interface provided no audio input for subjective listening. A human listening pass is still needed for orchestration quality, unwanted vocal artifacts, repetition and final mix balance.** Some headless/editor shutdowns retain the existing ObjectDB/resource cleanup warnings; the exported game launched and completed without a gameplay script failure.

Recommended Milestone 4 targets: improve grounded late-fight/collapse posing and distinct creature silhouettes, refine score/mix after listening, and decide whether limited environmental reactions or a separate destructible-city milestone should follow. Milestone 4 has not been started.

## Screenshots

Opening, medium battle, a devastating impact, limb loss, a low collapse shot and aftermath are supplied alongside this report. The baseline image is retained for comparison. The repository retains the full rendered-suite stage evidence and exported-release capture set.
