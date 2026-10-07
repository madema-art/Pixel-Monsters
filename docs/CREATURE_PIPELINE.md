# Blender creature workflow

The three original designs live in `art/creatures`. Godot loads compiled definitions from `data/creatures`, never the concept meshes. Concept files are excluded from the playable export.

1. Open the archetype's `.blend`, or run `tools/blender_creature_studio.py` through Blender MCP to create a new isolated study. Existing scene objects are left alone. `tools/creature_briefs.py` creates initial briefs; do not run it over edited exports unless intentionally beginning a new study.
2. Edit the named region-volume objects and `Rig_*` anchor empties. Coordinates in Blender are X/right, Y/front, Z/up; runtime coordinates are X/right, Y/up, Z/back. Volumes and rig anchors are separate editable design controls.
3. Export actual object transforms into `<id>-blender.json`. Preserve the allocation, behavior, attacks, and other metadata. The initial studio script demonstrates this conversion; edited transforms are authoritative.
4. Run `python tools/compile_creatures.py`. It grows each anatomical region from its parent using a deterministic ellipsoid-ranked frontier. Quotas enforce exactly 1,000 unique cells. Each region attaches through a face neighbor to the body; the compiler checks the complete connected component and records a geometry hash. No hidden connecting cubes are added.
5. Run `tools/blender_creature_refresh.py` through Blender MCP. It regenerates the 1,000-cube previews, per-creature sources, front/side/three-quarter references, and grayscale comparison. Blender's normal save-copy operation is used: library-write caused a connector/process failure in the installed Blender version during the first study.
6. Run Godot's `tests/archetype_gallery.tscn` to compare all three rigs in identical gray materials. Then force a pairing using `battle.restart(seed, ["gorgeblock", "needlemantle"])`, the `PIXEL_MONSTERS_MATCHUP` environment variable, or command-line user argument `-- --matchup=gorgeblock,needlemantle`.
7. Observe actual movement, reach, posture, collisions, and damage. Return to Blender to revise proportions or anchor placement. Recompile and restart the game to clear the definition cache. The second design revision shortened Needlemantle's skull and extended Bastion's skull prow following Godot inspection.
8. Run the anatomical validation, complete matchup matrix, and rendered suite before exporting.

The saved per-creature Blender files contain the study scenes and have the relevant creature source scene active. Concept volumes remain editable, while the preview mesh contains exactly 1,000 visible disconnected cube shells. Runtime anatomy uses 19 regional MultiMeshes, two-bone IK, actual surviving cube geometry for contact, and proportional structural thresholds. JSON attack profiles inherit a shared movement family but override trajectory, timing, range, force, fracture radius, selection weight, and impact timbre.

Anatomical reach comes from the exported shoulder/elbow/hand and hip/knee/foot anchor lengths. A declared range does not grant a remote hit: the moving effector must sweep surviving body cubes. The head and torso use their authored contact anchors. Every body remains subject to permanent cavities, support failure, detachment, knockback, and collapse.

AI uses authored preferred ranges and movement tendencies. Giving ground, flanking, and charge preparation have bounded durations; a slower pursuer keeps following. Loss of long arms contracts preferred range, and damaged leg quality scales acceleration goals and turning toward the affected side. The head-focused creature keeps its primary attacks after losing arms. Opponent-authored priority regions inform a minority of target choices.

Navigation guides roots inside the broad avenue before emergency bounds are reached. Tiny props are not navigation obstacles. Buildings sit outside the fighting corridor. This is intentionally simple local steering, with no full city destruction or street-network pathfinding.

Normal launch selects two distinct archetypes. The legacy procedural body remains available only as a regression fixture; the original destruction, combat, and presentation checks explicitly use it. New anatomy tests separately verify all three authored bodies and their damage adaptation.
