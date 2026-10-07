# Current state at Codex handoff — 2026-10-07

Development stopped on user instruction. Branch: `codex/milestone-04-archetypes`; handoff checkpoint is branch HEAD. Stable completed baseline: `77321a2`. **Milestone 4 is NOT complete.**

## Working and verified

- Latest-source preservation checks: project headless import/load exit 0; destruction **6/6 (1,093 assertions)**; combat **20/20**; archetype **47/47**, all exit 0.
- Three connected, unique 1,000-cell authored bodies; latest tests also verify exactly 1,000 rendered instances each, regional quotas, physical local damage/cavities, structural limb loss, normalized mobility, armless alternatives, contracted longarm range, and no default mirror matches.
- Twelve completed latest gameplay/balance simulated fights (six primary + six extended): all pass the completion/contact-gap check. Durations 107.0–183.1 seconds; largest inter-contact gap 10.79 seconds. Latest matrix midpoint Z spans 29.2–62.8 m. Six instrumented legacy fights provide comparison (Z span 0.2–0.8 m; X span 1.7–10.4 m).
- Four nonempty Blender source files saved inside `art/creatures`: `gorgeblock.blend`, `needlemantle.blend`, `bastion.blend`, `creature-lineup.blend`; actual-transform JSON, compiled data, tools, and references preserved.

## Working but not fully validated

- Pursuit, bounded retreats/flanking/charge preparation, anatomy-specific reach and attacks, actual connecting rams, leg-dependent speed/turning, and moving-midpoint director tracking observed in Godot.
- Earlier rendered suite completed all six pairings/reversed sides. These captures predate the final target-priority, short-contact balance, and impact-timbre edits. A normal-speed live Needlemantle/Bastion fight was inspected at several stages, including armless Bastion, degraded leg mobility, debris migration, and completion. This is not full final-source visual acceptance.
- Existing presentation checks passed **20/20** during development. They were not rerun after the final sound parameter edits in the handoff task.

## In progress

- Final-source rendered matrix, equal-material Godot gallery inspection, systematic foot-slide/pose/occlusion review, acoustic listening, and new standalone performance profiling.
- Version/export metadata is **0.4.0.0**, JSON include filter and art exclusion are updated. **No Milestone 4 release export or BAT test occurred.** Installed executable remains the Milestone 3 build (0.3.0.0).

## Known broken / limitations

- Matchup balance is unfinished. Latest 12 simulations: Needlemantle wins all 8 of its pairings; Bastion beats Gorgeblock 3/4, Gorgeblock wins 1/4. Interesting movement is established; competitive balance is not.
- Cameras can still overlap silhouettes or foreground props. Geometry-only camera blockers cover buildings, not every wire/pole; migrated shots require more review.
- Debug import/combat shutdown reports ObjectDB/resource-in-use warnings (import 6 instances/2 resources; combat 4/2), also seen at the established baseline. No parse error or failing assertion in essential handoff checks. Cleanup deserves a later audit.
- Blender library-write initially disconnected/crashed the session; restored through autosave and normal save-copy. Saved sources exist. Fresh bootstrap scripts were assembled across live steps: refresh assumes preview cube objects and source-scene camera/light links already exist. Saved .blend sources contain them; rebuilding from only a fresh studio script needs a small bootstrap repair/audit.
- Some initial lineup side/three-quarter images precede head revision 2. Per-creature references and final front/silhouette reflect that revision. JSON after later behavior/audio edits remains authoritative for runtime data.
- No GitHub remote/authentication available; no push or cloud CI verification. Cloud transfer needs private repository publication.
