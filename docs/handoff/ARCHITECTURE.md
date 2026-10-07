# Architecture and paths

All paths below are relative to repository root.

| System | Files | Responsibility |
|---|---|---|
| Battle orchestration | `scenes/battle.tscn`, `scripts/battle.gd` | Creates arena, two combatants/brains, debris, audio, score, camera and HUD; seeds/random distinct roster, forced pairings, restarts, physics sequencing, impacts, victory, telemetry. |
| Legacy body | `scripts/body_layout.gd` | Preserved 19-region 1,000-cube layout and region-to-major mapping; used by original tests/lab. |
| Authored anatomy | `scripts/combat/archetypes.gd`, `data/creatures/{gorgeblock,needlemantle,bastion}.json` | Cached JSON loader; converts precompiled cell lists into runtime cubes. Restart process after editing cached definitions. |
| Body/render/contact | `scripts/monster.gd`, `meshes/body_cube.obj` | Per-cube alive flags, permanent removal, region MultiMeshes, shared beveled geometry, posed spatial buckets, actual surviving-cube swept contact, rebuilding after damage. |
| Structural failure | `scripts/structure.gd` | Regional counts, shoulder/leg support failure, detached major limbs, normalized leg quality and fatal neck/head/core thresholds. Authored profiles use proportional thresholds. |
| Debris | `scripts/debris.gd` | Limited active physical cube pool (192), persistent batched rubble; old debris records where real destruction happened. |
| Motion/rig | `scripts/combat/combatant.gd`, `rig.gd` | Inertial roots/yaw, knockback, planted alternating feet, two-bone limbs using authored anchors, guard/recoil, attack effectors, crippled posture/collapse. |
| Attacks | `scripts/combat/moves.gd`, `attack_motion.gd` | Shared move families inherited by authored commands; wind-up/commit/follow/recovery, fixed commitment after wind-up, real effector sweeps, signature trajectories and running ram. |
| AI/navigation | `scripts/combat/brain.gd` | Think intervals, authored ranges/weights, pursuit, bounded spacing/flanking, charge buildup, damage adaptation, minority priority-region targeting, local boundary guidance. Legacy fixture behavior remains separate. |
| Environment | `scripts/arena.gd` | Batched miniature city, broad avenue/intersection/plaza/warehouse apron, landmarks, named zones, building AABBs for camera occlusion, dusk lighting. Small props are not navigation barriers. |
| Observer/director | `scripts/observer.gd`, `scripts/cinema/director.gd` | Free fly/turn/look/lens, pause/slow motion, director handoff, shot scoring and full-body coverage, blockers, moving-midpoint tracking and fight-axis candidate rotation. |
| Presentation | `scripts/cinema/effects.gd`, `scripts/combat/sound.gd` | Tiered pooled dust/impacts, positional Foley, fracture/limb/collapse layers and authored pitch accents. |
| Adaptive score | `scripts/cinema/music.gd`, `audio/cinema/`, `docs/AUDIO_PROVENANCE.md` | Six original YuE2 cues, damage/mobility intensity decisions, hysteresis and crossfades, aftermath timing; preserve these assets and behavior. |
| Blender pipeline | `art/creatures/`, `tools/{creature_briefs,blender_creature_studio,compile_creatures,blender_creature_refresh}.py`, `docs/CREATURE_PIPELINE.md` | Editable regional volumes/anchors, actual-transform export, deterministic parent-connected allocation/compiler, cube references and .blend save-copy. |
| Original lab | `scenes/prototype.tscn`, `scripts/prototype.gd`, `strike.gd` | Preserved Milestone 1 destruction inspection. |
| Validation/evidence | `tests/`, `docs/*validation.json`, `docs/m4-matchup-*.json`, `docs/evidence/milestone04/` | Fresh core/legacy regressions, authored anatomy checks, headless matrices, rendered screenshots and runtime samples. |
| Export | `export_presets.cfg`, `tools/Play Pixel Monsters.bat` | Windows Desktop release, external EXE/PCK, creature JSON included; art/docs/tests/tools and development addons excluded. |

Cube regional labels: head, neck, chest, abdomen, pelvis; left/right shoulder, upper_arm, forearm, fist, thigh, shin, foot. Major groups are head/torso and each arm/leg. Every compiled creature quota sums to 1,000; no hidden health/bridge cubes.

`tools/compile_creatures.py` is repository-relative Python with no external dependency. Blender/YuE authoring scripts contain documented local paths. Godot runtime loads `res://` resources and does not need D: paths. Export templates are installed outside the repository; `.godot/` caches and Blender automatic backups are ignored.
