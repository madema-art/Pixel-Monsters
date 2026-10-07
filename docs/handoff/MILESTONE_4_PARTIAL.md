# Interrupted Milestone 4

**Claude's first development task: AUDIT AND COMPLETE MILESTONE 4. Not Milestone 5.** Full original requirements are preserved in `PROMPT_4.txt`.

## Preserved implementation

- Gorgeblock: low wide chest, large fists, small head; preferred root range 9.2 m; close stalking and occasional flanks. Commands: crush_hook, body_shot, pile_hammer, shove, short_kick.
- Needlemantle: tall narrow body, long arm/leg anchors, blade-like revised skull; preferred range 14.5 m; deliberate giving ground, lateral movement, long effector sweeps. Commands: lance_straight, long_jab, rake_backhand, pendulum, heel_kick.
- Bastion: broad projecting skull, thick neck, small arms; preferred close range 9.7 m, builds toward about 19 m for a ram; skull remains useful without arms. Commands: ram_charge, skull_crash, shoulder_check, stub_hook, push_kick.
- Exactly 1,000 connected, unique cells each. Exact regional quotas, rig anchors, behavior, attacks and geometry hashes live in `data/creatures/*.json`. Latest essential validation verifies authored quotas AND rendered count.
- Blender MCP constructed volume/anchor studies and actual cube previews. Godot visual feedback led to revision 2: Needlemantle's tall capsule head became a shorter blade; Bastion's skull prow moved forward. Sources: `art/creatures/{gorgeblock,needlemantle,bastion,creature-lineup}.blend`; reference PNGs and `*-blender.json` accompany them.
- Conversion: Blender regional transforms -> exported proportions/anchors -> `compile_creatures.py` parent-connected frontier with fixed quotas -> JSON 1,000-cell runtime bodies -> anatomy-driven IK/reach, structure, attacks and AI. See `docs/CREATURE_PIPELINE.md` and bootstrap limitation in CURRENT_STATE.
- Persistent bounded tactics replace planting in one place: pursuit, retreat, spacing, flanks, charge-distance preparation. The central avenue expands Z travel, with five named districts and simple inward boundary steering. Real debris marks prior exchanges.
- Damage contracts longarm range when arms fail; leg quality scales speed and directional turn strength. A normal live fight showed armless Bastion still attacking and Needlemantle mobility degradation. Charge contacts are actual surviving-geometry sweeps, not distance-triggered damage.
- Director follows migrating midpoint, rotates candidate shots relative to fighting axis, adjusts framing and reacts to blockers. Some silhouette overlap/foreground props remain to inspect.
- Initial tests found Bastion close strikes overwhelming Gorgeblock. Current short skull radius reduced 2.3 -> 1.8, skull recovery increased to 1.55 s; shoulder-check radius reduced 2.5 -> 2.1. Running ram retains 2.7 radius. Minority targeting uses opponent-authored priority regions. Balance remains skewed toward Needlemantle.
- Impact pitch accents: brute heavy hooks .82, longarm non-kicks 1.12, Bastion head attacks .76. Existing audio layers/music remain. Subjective listening not completed.

## Tests and evidence

Handoff essential latest-source checks: import/load exit 0; destruction 6/6, 1,093 assertions; combat 20/20; archetype 47/47. Presentation 20/20 earlier, not rerun after final audio edits. Raw test results are repository JSON; transient command logs stay outside source control.

`docs/m4-matchup-matrix.json`: seeds 211,617,1203,4441,7907,9929; every pairing in both spawn orders; 6/6 complete, 112.4–183.1 s. `docs/m4-matchup-extended.json`: seeds 10661,16993,22091,24847,33013,44809; 6/6 complete, 107.0–149.3 s. The latest 12 gameplay/balance runs produce midpoint Z migration 29.2–62.8 m. Earlier 28–63 m observations are consistent with saved artifacts. Instrumented legacy baseline is `docs/m3-movement-baseline.json`.

`docs/evidence/milestone04/suite.json`: six completed rendered fights at 2x wall-clock, 120 physics ticks/s. These predate final target/balance/pitch changes; do NOT treat them as final-source acceptance. Normal-speed live observation evidence is in `live-1203/`. Godot MCP screenshots were inspected during several fight phases; not every saved frame was reviewed. The attempted final gray gallery was interrupted; no completed gallery acceptance claim.

Added tests: archetype_validation, archetype_matrix, archetype_extended_matrix, archetype_rendered_suite, archetype_gallery, m3_movement_baseline. Do not overwrite old evidence and silently attribute it to a new source revision.

## Outstanding Prompt 4 acceptance

Final-source visual matchup matrix; systematic slide/turn/charge/occlusion/boundary review; all matchup balance audit; equivalent-gray Godot comparison; fresh Blender bootstrap reproduction; final authored attack/limb-loss review; standalone performance profiling with migrated debris; acoustic review; release export and direct BAT launch test; final milestone report/checkpoint. Full city destruction/selection menus/roster expansion were deliberately not started.

Immediate order: read requirements and handoff; reproduce essential checks; inspect latest headless results and current data; reproduce fresh authoring bootstrap from preserved .blend files; render current pairings with traceable revision labels; address specific failures; complete final performance/export/BAT acceptance. Keep original regression fixtures intact.
