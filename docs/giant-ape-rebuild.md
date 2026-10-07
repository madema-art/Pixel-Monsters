# Giant Ape rebuild report

Only Giant Ape was rebuilt. The existing 16-creature project was preserved at baseline `5224cdf` after fetch and a clean working-tree check. Work is on `codex/giant-ape-blender-rebuild`.

## Physical body

Exactly **1,000 unique destructible cubes**, one face-connected body, all 1,000 with at least one exposed face. No enclosed filler cubes and no supplementary smooth body mesh. The body is the actual editable Blender cube collection, exported from object world transforms into the normal `giant_ape` roster entry.

| Region | Cubes |
|---|---:|
| abdomen | 40 |
| chest | 190 |
| head | 91 |
| left_fist | 73 |
| left_foot | 18 |
| left_forearm | 69 |
| left_shin | 17 |
| left_shoulder | 58 |
| left_thigh | 38 |
| left_upper_arm | 45 |
| neck | 9 |
| pelvis | 34 |
| right_fist | 73 |
| right_foot | 18 |
| right_forearm | 69 |
| right_shin | 17 |
| right_shoulder | 58 |
| right_thigh | 38 |
| right_upper_arm | 45 |
| **Total** | **1000** |

## Source and renders

- Editable source: `D:/Godot/Projects/Pixel-Monsters/art/creatures/giant_ape.blend`
- Active scene: `GIANT_APE_Sculpt_Studio`
- Body collection: `GIANT_APE_1000_DESTRUCTIBLE_CUBES`, with 19 region collections; individual cube objects carry canonical region, major and color tag properties.
- Reference image is packed into the blend. Rig anchors are editable empties in `APE_RIG_ANCHORS`.
- Runtime body: `D:/Godot/Projects/Pixel-Monsters/data/creatures/giant_ape.json`
- Rebuild cache: `art/creatures/giant_ape.authored.json`; `tools/roster/compile_roster.py giant_ape` reproduces the exported JSON byte for byte rather than regenerating the old proxy.
- Export actual edited Blender scene by running `tools/roster/export_ape.py` through Blender MCP.
- Final studio renders in `D:/Godot/Projects/Pixel-Monsters/art/creatures/renders/`: `giant_ape_front.png`, `giant_ape_back.png`, `giant_ape_top.png`, `giant_ape_front_3q.png`, `giant_ape_rear_3q.png`, `giant_ape_low_cinematic.png`.
- Godot captures use `giant_ape_godot_*.png` in that directory, covering idle, walk, turn, pursuit, hammer fist, hook, paired smash, grab, throw, leap and localized mutilation.

## Proportions and visual iteration

Placeholder bounds were 25 × 24 × 8 cells; the sculpture is **27 × 20 × 13**. It is broader, shorter and substantially deeper. Head allocation rose from 54 to 91, shoulders from 29 each to 58 each, fists from 59 each to 73 each; short thigh allocation fell from 59 each to 38 each. The forward muzzle, recessed eye sockets, broad nose, open mouth cavity, cheek/jaw frame and four cubical teeth are physical destructible cells. Barrel chest, layered shoulder/trap contours, spinal recess, thumb and stepped knuckle contours replace the proxy volumes.

Blender MCP created and inspected the editable scene. Initial orthographic studies showed surface holes caused by budget trimming; the allocation was revised to preserve the exterior and remove only internal cells. A second study widened and lowered the barrel chest. A third live object refinement moved 11 cubes to recess the spinal valley and step the knuckles, preserving count, connectivity and exposure. Front, back, top, front/rear three-quarter and low-angle views were rendered and inspected. Studio materials were corrected to linear shader colors.

Godot AI MCP launched the actual main scene, forced Ape matchups and captured fresh rendered stages. Long arms required an authored overhead lift. Paired smash now animates both arms but retains a single damage strike. Measurements found hanging fists intersected the street while walking and grabbing; an Ape-only opt-in checks actual rotated fist extents and lifts the IK goal enough to clear the floor. Subsequent pose checks pass.

## Rig and game integration

All spatial rig anchors were exported from Blender empties, in Godot coordinates:

| Anchor | Position |
|---|---|
| shoulder | [7.1, 15.5, -0.7] |
| elbow | [9.0, 11.0, -1.8] |
| hand | [10.8, 3.6, -3.7] |
| idle_hand | [10.8, 3.6, -3.7] |
| guard | [6.0, 17.0, -6.0] |
| hip | [3.0, 8.0, 1.5] |
| knee | [3.1, 4.5, -0.6] |
| foot | [3.3, 1.0, -1.3] |
| pivot | [0.0, 8.0, 1.5] |
| head | [0.0, 18.0, -7.0] |
| head_pivot | [0.0, 16.0, -3.0] |
| torso | [0.0, 15.0, -3.0] |
| neck | [0.0, 17.0, -2.0] |
| wrist | [10.5, 5.5, -3.2] |
| fist | [10.8, 3.6, -3.7] |

The idle hand now follows the low resting fist instead of the old elevated boxing position. Stance lean is -0.04. Shoulder tackle uses the authored right shoulder mass at [7.1,15.5,-2.5], via the existing effector/tip system. Optional paired-smash, overhead-lift and floor-clearance settings apply to the Ape only; all other creatures retain existing defaults. Explicit per-cube palette tags provide physical teeth, mouth and muzzle coloring; the old automatic painted face is disabled for this body. Ape rim lighting uses a restrained neutral color.

Original behavior values and every existing attack key/value (weights, timing, power, radius, cooldown and hold/throw tuning) were compared against baseline and are unchanged. The shoulder effector is an additional anatomical binding. All 15 other creature JSON files are unchanged. The normal random roster loads this body; no alternate demo creature was introduced.

## Verification

- Giant Ape validation: **51/51**, including physical cell exposure, actual anchor proximity, localized persistent destruction of chest/face/shoulder/fist/back, arm removal, leg mobility and attack gating, all runtime stages, throwing momentum, leap lift and fist-floor clearance.
- Full roster validation: **207/207**.
- Combat validation: **20/20**.
- Destruction suite: **6/6 tests, 1,093 assertions**.
- Blender exporter: exact 1000, unique cells, one face-connected component, no enclosed cubes.
- Rebuild cache: runtime JSON reproduced byte for byte.
- Baseline invariants: no behavior/attack tuning changes; other 15 JSON files untouched.
- Autonomous seed-101 fights finished: Ape–Colossus at 50.9 s, Ape–Robot at 54.2 s, Ape–Ape at 76.6 s. These are functional checks, not balance conclusions. Hits included hammer fists, hooks, grabs, paired smashes, tackles, leap attacks and kicks.
- Godot rendered grab stage reported an active hold; throw stage imparted 23.21 speed; leap stage reported 4.01 units of hop lift; damage stage retained 962 cubes with visible missing anatomy.
- Standalone Windows release exported into `D:/Pixel Monsters`. Existing `Play Pixel Monsters.bat` was executed and launched the release executable directly with the normal **Pixel Monsters** title. Development project and BAT content were preserved. A tools-engine smoke test loaded the exported PCK and verified the new actual roster body and 1000 physical cubes. The former installed build is backed up under this chat's `work/prior_installed_build`.

## Limits and existing issues

The sculpture uses coarse one-unit cells; fine fur/tooth curvature and the reference illustration's apparent high surface density remain stylized under the exact 1000-cube constraint. Game screenshots retain the existing city's cool atmospheric lighting, so colors read cooler than neutral studio renders.

The development editor still reports existing GdUnit inspector duplicate-signal errors and an unused legacy `archetype_rendered_suite.gd` class-resolution error. The completed main-game review and listed headless suites run successfully; unrelated editor/add-on cleanup was left outside this Ape pass. The old fight runner reports resource leaks at shutdown. Testing the exported pack with the tools engine from a different executable directory reports a DebugDraw DLL lookup error; the installed release has its DLL alongside the executable and was visually verified running normally. No blocking Ape geometry, rig, destruction or standalone-launch issue remains.

No work on Monster #2 was started.
