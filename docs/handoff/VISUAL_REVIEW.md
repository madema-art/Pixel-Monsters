# Visual overhaul — local review checklist

Written in a cloud session with **no GPU, Blender, or human viewing**. Regression checks pass (see bottom), and I looked at a handful of software-rendered (Mesa llvmpipe, `gl_compatibility`) frames, which have no SSAO and approximate glow/tonemapping. **Nothing here is visually accepted.** Run the game locally on Forward+ and judge each item. Every value below is a tunable first guess.

Quick start: `godot --path .` (random pairing), or force one: `PIXEL_MONSTERS_MATCHUP=gorgeblock,bastion` / `-- --matchup=needlemantle,bastion`. `R` restarts, observer free-cam can fly to street level.

## What changed (where to tune)
| Area | File | Main knobs |
|---|---|---|
| Cube shader (bevel normals, edge light, plane contrast, ground grime, rim, eye glow, wound roughness) | `shaders/cube_body.gdshader` | `bevel_*`, `plane_contrast`, `ground_grime`, `rim_*`, `glow_energy` |
| Per-monster palettes, face rules (glow eyes, brow shadow, mouth slit), tonal drift, fist/shoulder accents | `scripts/cinema/look.gd` | `PALETTES`, `drift()` |
| Wound look (cavity-lining cubes darken, exposed interior cubes show interior tone, rougher, deeper occlusion) | `scripts/monster.gd` `update_wound_look()` | blend factors in that function |
| Debris (same shader, dusted rubble, slower tumble) | `scripts/debris.gd` | `dust`, angular velocity range |
| Lighting/atmosphere (key/rim/fill, ACES, SSAO, glow, height + aerial fog, MSAA 4x, 4096 shadow atlas) | `scripts/arena.gd` `build_atmosphere()` | light energies, fog values |
| Sky sun glow band | `shaders/dusk_sky.gdshader` | colors/exponents |
| City surfaces (world grime, street-level darkening, lit-window variation) | `shaders/arena_set.gdshader` | grime scale, window energy |
| City dressing (setback crowns, shopfronts, awnings, signs, parked cars, buses, crosswalks, traffic signals, containers, smokestacks, skyline ring, cranes, water strip) | `scripts/arena.gd` `city_dressing()` | counts/positions |
| Impact VFX (tier-tinted dust, thrown chips on HEAVY/DEVASTATING, brief warm flash light) | `scripts/cinema/effects.gd` | `DUST_TONES`, `FLASH_ENERGY` |
| Camera near plane 0.2 | `scripts/battle.gd` | |

Not changed: cell data, cube counts, damage/structure/AI/movement, director logic, audio, FOV defaults.

## Inspect — silhouettes (use a gray-ish view if helpful; `tests/archetype_gallery.tscn` still gives equal-material comparison)
- [ ] **Gorgeblock**: squat/wide, huge shoulders, big fists. Do knuckle/pauldron accent cubes help or look like noise?
- [ ] **Needlemantle**: tall, narrow, long pale limbs vs dark joints — does it read against the dark sky *and* against the bright horizon? Eerie, or just blue?
- [ ] **Bastion**: pale skull vs dark body — does it read "built around a skull"? Is the skull too bright?
- [ ] Are the three distinguishable at wide-shot distance in 2 seconds, without colour?

## Inspect — cube rendering
- [ ] Individual cubes still clearly readable; bevel edge light not too shiny/plastic.
- [ ] No noisy colour; tonal drift subtle.
- [ ] Rim light separates the shadowed side from haze without a glowing outline.
- [ ] Feet/legs darken toward the ground (grime) — contact grounding OK, not muddy?

## Inspect — faces and damage
- [ ] **Face readability**: glowing eyes visible at medium range; brow shadow and mouth slit read as a face (eyes face −Z). Eyes change to half-glow when adjacent cubes are lost.
- [ ] **Cavity visibility**: holes show dark/rough interior cubes lining them; deeper wounds look excavated (interior tone vs skin).
- [ ] **Late-fight damage**: asymmetry reads as mutilation, not just thinning. Is the interior tone too dark/unreadable against shadow? Adjust `interior` per palette.
- [ ] Detached limbs and fractured silhouettes still readable.

## Inspect — debris and impacts
- [ ] **Debris visibility** on road, plaza, and against the horizon; flying cubes readable, not confetti; slower tumble feels heavier.
- [ ] Settled rubble reads as dusted, heavy masonry and is distinguishable from the road.
- [ ] LIGHT / HEAVY / DEVASTATING tiers distinct: dust tone, thrown dark chips (HEAVY+), warm flash (check it is brief and not strobing; DEVASTATING most intense).
- [ ] Removed cubes remain the primary effect (particles not obscuring them).

## Inspect — environment and lighting
- [ ] **Dusk lighting**: warm low key, cold rim, long shadows, faces/torsos readable (drama *and* visibility). Look for over-bright warm blowout toward the sun and a too-dark opposite sky.
- [ ] **Street-level scale** (fly the observer down to ~2 m): cars, buses, traffic signals, windows, awnings, signs, containers make the monsters feel enormous. Any prop that looks oversized?
- [ ] **Wide shots / skyline**: skyline ring, cranes, smokestacks, water strip; no pop-in, hard edges at ±120 m, or floating objects.
- [ ] Parked cars/buses sit just outside the lane; confirm none clip awkwardly with fighters (they are not navigation obstacles).
- [ ] **Fog/haze**: depth separation without washing out far monsters; ground haze not hiding feet.
- [ ] **Shadows**: soft long shadows; no acne/peter-panning on cubes; no shimmering at distance.
- [ ] Sky: sunset band near the sun side, no banding.
- [ ] Windows: lit-window variation pleasing, not twinkly; signs/lamps bloom slightly but not blow out.
- [ ] **Aftermath** shot after the fight ends.
- [ ] Camera: no near-plane clipping through cubes at close impacts; exposure stable across cuts.

## Performance
- [ ] Compare FPS with Milestone 3/4 numbers at 1152×648 (previous median ~700 FPS standalone). New cost centres: MSAA 4x, SSAO, glow, 4096 shadow atlas, ~3 extra lights in effects (only while flashing), larger city (more MultiMesh instances), chip particles. If needed, disable first: SSAO → MSAA → glow.
- [ ] Check a devastating impact with heavy debris for frame-time spikes.

## Cloud-run regression results (this branch)
Import clean; destruction 6/6; combat 20/20; archetype 47/47; presentation 20/20; `compile_creatures.py` output identical. These do not validate appearance.

## Known risks / likely tweaks
- Palettes and light energies were tuned only from llvmpipe frames; expect to adjust brightness and rim strength.
- `wound_look` recomputes only when the alive-cube count changes (cheap), but check there is no hitch on big collapses.
- The camera-blocker AABBs gained setback crowns on side buildings only; props (cars, signals) are still not blockers.
- Silhouette distinction relies on value/palette/accent cubes and existing anatomy; no cell data was edited.
