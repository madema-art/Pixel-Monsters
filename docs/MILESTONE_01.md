# Pixel Monsters — Milestone 01 development report

The playable destruction prototype is built, run, visually inspected, and ready to evaluate. The live Godot scene is left running with TITAN intact and COLOSSUS at 834 cubes, missing its left arm and showing a persistent chest cavity. Press R to restore both.

**Project:** `D:\Godot\Projects\Pixel-Monsters`  
**Launch:** Open `project.godot` in Godot 4.7.2 and press F6/F5, or run `D:\Godot\Godot.exe --path D:\Godot\Projects\Pixel-Monsters`. The main scene launches directly into the lab. Existing template add-ons, MCP runtime helper, and Jolt configuration were retained. The reusable template and unrelated projects were untouched.

**Built:** Two approximately 28-metre humanoids with contrasting teal and rust materials, rounded voxel silhouettes, shaped heads/brows, shoulders, fists and feet. A miniature street set provides cars, streetlights, low buildings, barriers and a distant skyline. Directional shadows, restrained colors and haze provide the initial cinema direction. Procedurally authored boom and fracture WAVs play with recoil and a small camera impulse. Strikes use a 0.65-second wind-up, commitment, follow-through and recovery, totaling 2.5 seconds.

**Exact body allocation per intact monster**

| Subregion | Centerline | Left | Right |
|---|---:|---:|---:|
| Head, including face/brow | 120 | — | — |
| Neck | 24 | — | — |
| Chest | 200 | — | — |
| Abdomen | 92 | — | — |
| Pelvis | 84 | — | — |
| Shoulder | — | 32 | 32 |
| Upper arm | — | 32 | 32 |
| Forearm | — | 36 | 36 |
| Fist | — | 20 | 20 |
| Thigh | — | 52 | 52 |
| Shin | — | 44 | 44 |
| Foot | — | 24 | 24 |
| **Total** | **520** | **240** | **240** |

Major groups are head/neck 144, torso 376, each arm 120 and each leg 120: **1,000**. Ellipsoid-ranked integer cells form a connected silhouette with exact quotas and no duplicate positions. Every body entry has a real rendered cubic mesh instance; eyes recolor existing cubes. A one-metre grid and 0.94-metre cubes make individual pixels readable. Interior pixels are naturally occluded by the solid volume.

**Destruction and integrity:** The moving fist performs a swept volume query against surviving cube geometry, including oriented cubes. The nearest intersection supplies a surface contact. A spatial hash finds live cube centers inside a spherical damage volume at that point; these are removed permanently from body rendering and emitted as debris. No unrelated cube subtraction or hidden health number is used. Existing cavities are absent from subsequent collision queries. The six selected targets were verified to contact their intended regions.

Shoulders are a deliberately simple load-bearing approximation: with eight or fewer of 32 shoulder cubes remaining, the associated arm becomes disabled and its surviving cubes detach. A large test removed 63 cubes directly and detached 68 more, leaving COLOSSUS standing at 869. That damaged monster successfully struck back with its remaining arm. Region tags, joint ID sets and remaining-material queries support later head, leg and connectivity work.

**Debris:** A prewarmed pool caps full Jolt simulation at 192 cubes. Cubes receive linear/angular velocity and bounce on the floor. Their physical rendering uses one MultiMesh. After settling or 3.5 seconds, cubes transfer to a batched rubble renderer; airborne overflow retains a cheaper ballistic fall/bounce rather than freezing in midair. Rubble expires after 28 seconds by default. Pool size, simulation duration, rubble duration and persistent rubble are configurable. Debris does not collide with other debris; rubble is visual rather than a physical obstacle.

**Performance:** Final live samples used an RTX 2070 SUPER, i7-10700F, Forward Plus/D3D12, 1152×648, 60-Hz physics, and VSync disabled. Each sample lasted three seconds and included the arena and HUD. VSync was restored for handoff.

| Condition | Removed / 2000 | Mean FPS | Mean frame ms | p95 ms | Peak physical debris |
|---|---:|---:|---:|---:|---:|
| Pristine | 0 | 761 | 1.31 | 2.00 | 0 |
| Approximately 25% | 504 (25.2%) | 676 | 1.48 | 2.95 | 192 |
| Approximately 50% | 1020 (51.0%) | 656 | 1.52 | 3.53 | 192 |
| Large shoulder impact | 131 | 648 | 1.54 | 4.33 | 131 |

The stress batches averaged 0.187/0.183 ms per damage query and 2.27/2.03 ms per complete destruction event. The large melee event took 3.04 ms, including a 0.374-ms damage query. Active collision bodies cap at 193 including the floor. Initial arena rendering measured 581 scene draw calls; batching brought the final pristine scene to 144. Active debris previously drove stress frames above 700 draw calls; the final samples averaged about 152–153. No isolated monster GPU timing was captured. These are short prototype measurements on one PC, not a finished-game performance guarantee. Jolt's generic active-object monitor returned zero, so explicit pool occupancy supplies the collision count.

**Controls:** WASD fly; Q/E smooth yaw; hold RMB and move mouse to look; Shift boosts speed; Space/Ctrl rise/drop; wheel adjusts FOV. 1–6 select face, chest, left shoulder, left arm, left leg, abdomen. F strikes; G uses a larger impact; Tab swaps attacker/target; R resets both; P pauses; L toggles 1/5 speed; C restores camera; F3 hides diagnostics. The right-side buttons expose the same actions. Camera and developer controls keep working while paused.

**Systems added:** `body_layout.gd` handles geometry and quotas; `monster.gd` handles body state, regional MultiMeshes, collision/damage and poses; `structure.gd` handles joints and arm failure; `strike.gd` handles the melee sequence, fixed-length arm IK, assisted lunge/crouch, sound and hit feedback; `debris.gd` handles pooling and lifecycle; `observer.gd` handles the free camera; `arena.gd` handles the batched miniature set; `prototype.gd` handles the lab UI, diagnostics and profiling. Also added the launch scene, original WAVs and their generation script, three test scripts, raw test/performance reports and screenshots.

**Validation:** Six core tests passed in both live editor testing and a fresh headless process (1,093 assertions). They cover exact unique allocation, face adjacency of all 1,000 cells, local damage/persistent holes, collision through an empty tunnel, nonfatal arm failure/reset, and rendered instance counts. All 17 live integration checks passed: six region strikes, repeated erosion (981 → 943), shoulder detachment, counterstrike after limb loss, debris budget/cleanup, exact reset, WASD, Q/E, mouse look, pause and slow motion. Sound players were observed playing during impact, debris positions/velocities changed under physics, and multiple live screenshots were personally inspected. Raw evidence is in `headless-tests.json`, `runtime-tests.json` and `performance.json`.

**Decisions and limitations:** Geometry was authored procedurally in Godot because exact cube identity is central to destruction; Blender was unnecessary for this milestone. Body pixels use data and regional rendering rather than 2,000 rigid bodies. The test rig remains rooted and uses assisted poses, without walking, balance, full body collision or ragdolls. Shoulder failure uses a regional threshold rather than a complete connectivity/structural solver. Leg material is tracked but cannot yet cause collapse; head disconnection has no behavior. Damage hashes assume the receiving test monster is in its neutral pose. Animation and placeholder audio need artistic tuning. The skyline and materials are intentionally temporary, and frozen rubble simplifies cube orientation.

**Recommended Prompt 2:** Replace assisted poses with grounded locomotion and articulated animation; maintain spatial indices for moving body regions; implement joint connectivity and support failure; add remaining-arm attack selection; refine hit weight and silhouette; repeat profiling at the intended display resolution. Prompt 2 has not begun.

**Git checkpoints:** `5ac5e77` preserves the template copy; `84f0b3a` contains the playable destruction lab. A final validation/documentation checkpoint records the finished diagnostics, evidence and report. Local commits use the explicit author “Codex <codex@local.invalid>”; global Git identity was not changed.

**Visual evidence:** `01-pristine.png`, `02-shoulder-impact.png`, `03-permanent-damage.png`, `04-chest-cavity.png`.

