# Tournament roster build (16 entrants)

Visual overhaul at `fb60109` is untouched. This pass adds the 16 playable entrants as data + modular runtime capabilities. Entrant table: `docs/ROSTER.md` (generated). Validation: `tests/roster_validation.gd` (anatomy), `tests/roster_matrix.gd` (autonomy), `tests/roster_gallery.gd` / `tests/roster_action_shots.gd` (stills; need a display or software GL).

## Pipeline (cloud-reproducible, no Blender)

`tools/roster/` is a procedural substitute for the Blender studio loop:

- `voxel.py` – regions are unions of ellipsoids/boxes; every lattice cell goes to the best-fitting region, the whole design is uniformly scaled until >=1000 cells exist, stray parts are joined with real body cells (no hidden bridge cubes), then outermost cells are trimmed (connectivity preserving) to **exactly 1,000**. Rig anchors are scaled by the same factor. Army of 10 compiles ten 100-cube units separately.
- `biped.py` – parametric builder for the 19 standard regions + rig anchors (right side +x, front -z).
- `specs_tier1..4.py` – one function per entrant: volumes, look palette/tags, rig data, behavior, attacks, limbs, fatal rules, notes.
- `compile_roster.py [id...]` writes `data/creatures/<id>.json`; `preview.py` draws region silhouettes; `make_roster_doc.py` regenerates `docs/ROSTER.md`.
- Edited Blender volumes can later replace a spec's volume list; the JSON schema is unchanged. Restart Godot after recompiling (definitions are cached).

Run after editing specs: `python tools/roster/compile_roster.py && python tools/roster/make_roster_doc.py`.

## Data schema additions (all optional; the three Milestone 4 archetypes still load unchanged)

`rig_type` (`biped|multi|serpent|swarm`), `look` (palette, `tones`, `interior_glow`, `face`), cell `tag` (`glow|dark|accent`), `aliases` (head/chest → region names for camera/AI), `target_regions`, `limbs` (breakable groups: id, regions, kind, fail fraction), `fatal` (data-driven defeat rules incl. `limb_kind` counts), `locomotion` (`legs|serpent|swarm|mass`), `extras` (chained tails/wings), `follow`, `tips` (weapon-tip effectors), `special.{regen,flight,swarm}`, `rig_multi`, `rig_serpent`, `leg_fail`, `proportional_limbs`. Attack entries: `base` (`custom` or `ranged` new), `effector`, `needs` (anatomy fractions), `flight`, `both_arms`, `hold`, `status`, `quake`, `cooldown`, `lunge`, `hop`, trajectories `leap`/`spin`.

## Runtime modules

| Module | File | Used by |
|---|---|---|
| Ranged manager (streams, cube-cluster projectiles, meteor telegraph, web bolt, beam) | `scripts/combat/ranged.gd` | Reptile, Dragon, Robot, Wizard, Colossus, Eyeball, Tarantula, Demon |
| Hold / throw / constrict / engulf / pin | `combatant.gd` `begin_hold/update_hold`, `hold` in attack data | Ape, Robot, Eyeball, Blob, Tarantula, Anaconda |
| Bone regeneration (attached / loose / shattered) | `scripts/combat/regen.gd` | Skeleton |
| Flight (wing-lift, takeoff, dive, landing) | `scripts/combat/flight.gd` | Dragon |
| Multi-limb IK rig, gait, weapons, squash | `scripts/combat/rig_multi.gd` | Tarantula, Rider, Eyeball, Blob |
| Serpent rig (trail follow, wave, wrap) | `scripts/combat/rig_serpent.gd` | Anaconda |
| Swarm units | `scripts/combat/swarm.gd`, `rig_swarm.gd` | Army of 10 |
| Chained extras / tips on the biped rig | `scripts/combat/rig.gd` | Reptile, Dragon, Demon |
| Generalised structure (limbs, fatal rules, potential counts) | `scripts/structure.gd` | all |

`light_hit` (set around flame/army ticks) lets continuous damage kill without stun-locking the victim.

## Entrants and their unfair advantage / sacrifice

See `docs/ROSTER.md` (allocations are generated from the JSON). Ranged set (exactly 8): Reptile (sustained fire breath), Dragon (short aerial bursts), Robot (launchable fist, arm unusable until it returns), Wizard (bolt / telekinetic blast / meteor), Colossus (slow lobbed boulder), Eyeball (tracking gaze beam, degraded by eye damage), Tarantula (web = slow/tether, little damage), Demon (slow explosive fireball). All ranged attacks have wind-up >=0.8 s, recovery >=0.9 s and cooldown >=5 s (checked by the validation test), plus close-range weight penalties and anatomy requirements.

## Skeleton reassembly

States per cube: 0 attached, 1 loose/recoverable, 2 shattered. Cubes knocked off become loose bone pixels (own cheap ballistic sim, instanced in one MultiMesh). After `delay` (3.6 s) they twitch, shimmer and fly back at a rate-limited pace, joints included in order of detach; when >=14 are returning the Skeleton is `reassembling` (cannot attack, slowed - vulnerable). Smashing a loose pixel shatters it permanently: any attack effector sweeping through it, footfalls (2.6 m), body crush (every 12 ticks), damage radius events (fire, projectiles). Only original cubes ever return, so alive+loose+shattered = 1,000. Fatal rules and limb/leg failure use potential (alive + recoverable) so temporary blasts do not end the fight, but function (arms, legs, speed) uses alive cubes. Opponent AI aims at loose bones (`_loose` target) when >=10 are recoverable. Not implemented: secondary damage from airborne debris impacts.

## Known limitations / honest status

- **No visual acceptance.** Stills were taken with software GL (Compatibility renderer, no SSAO; particles not verified). Needs local Forward+ inspection: silhouettes, flame/beam/web/meteor visuals, regen shimmer, constrict wrap, climbing units, wing silhouettes.
- Rider: horse death or rider death ends the entrant (no dismount rule).
- Rocket fist hides the fist but its cubes still exist for contact while away.
- Army: units hit at each opponent's shins then climb; Army of 10 is the weakest entrant in the headless matrix.
- Balance is not tuned (only "AI can finish, no endless standoffs"). Wizard/Eyeball/Tarantula lean strong in the matrix.
- Serpent/Blob/Eyeball are geometry-rigged approximations; segments are rigid slabs, so tight bends show seams.
- Sound reuses the existing cues; no new audio, adaptive score untouched.
- Blender hooks: replace spec volumes with exported Blender volumes; keep region names and rig anchors.

## Test results (cloud, Godot 4.7.2 headless)

- Regression: import clean; destruction 6/6; combat 20/20; archetype 47/47; presentation 20/20; `compile_creatures.py` reproduces the three Milestone 4 bodies.
- `roster_validation`: 207/207 (exact 1,000 cubes, allocation, connectivity, ranged set == 8, ranged limits, localized damage, anatomy-gated attacks, Skeleton regen/shatter/cap, Army 10x100, Dragon wings/flight, Tarantula progressive legs, Rider 1,000 split + lance loss, Anaconda serpent, Blob).
- `roster_matrix` (32 fights, 2 per entrant): all 32 finish (shortest 21 s, longest 331 s); longest gap between connecting hits 38 s (one fight over the Milestone 4 30 s bar); average headless sim cost 0.7-1.9 ms per 60 Hz step, worst single step ~60 ms (Army/Wizard during multi-hit events). In that sample `rolling_crush`, `trample`, `waddle_charge` and `wing_buffet` never connected; `dive_attack` was fixed afterwards (verified separately). Wins are uneven (Blob 4, Dragon/Wizard/Demon/Ape 1): balance is NOT tuned.
- Matrix JSON in `docs/roster-matrix.json` predates the last dragon tuning commit.
