# Showcase match: Giant Ape vs Fire-Breathing Reptile

Scope: the main game now fights only these two entrants. The 16-entrant pool is still in the code: set `PM_FULL_ROSTER=1` to restore it (`Archetypes.SHOWCASE` vs `ROSTER`).

## Important: no Blender in this session

Blender 5.2 / `bpy` is not available in the cloud session, so the designs below were **not** sculpted in Blender. They were rebuilt in the procedural cube pipeline (`tools/roster/specs_tier1.py`, `specs_tier2.py`), then reviewed with Godot stills (`tests/creature_stills.gd`). No `art/creatures/giant_ape.blend` was produced. Blender refinement still needs the local machine.

## Giant Ape (procedural v2)
- Hunched knuckle-walker: chest and head project forward, shoulders sit ahead of the hips, arms reach toward the ground.
- Bigger shoulder caps, an upper-back hump and a deep chest barrel; massive forearms and oversized fists.
- Face: heavy brow, deep sockets (dark), muzzle and jaw; eyes are the only glow.
- Attacks keep their identity. Two-handed smash and leap now also shake the ground: they break nearby buildings and do **not** add damage.

## Fire-Breathing Reptile (procedural v2)
- Upright titan: deep barrel torso, heavy thighs, wide head with a heavy lower jaw.
- Dorsal ridge of nine plates from neck to tail; heavy tail.
- Fire breath now burns through lane buildings along its whole length. Stomp shakes the ground (no added damage).

## Destruction of the surroundings
- `scripts/wreckage.gd`: 16 lane blocks (6×9×6 cells, 2 m each, 5,184 cubes) line both edges of the walkable avenue (x ≈ ±22–34, z −36 to 48). They don't block the fighters.
- Any blast removes the cubes inside its radius; cubes left without ground support fall as debris. Debris uses the existing pool (192 active, rubble persistent) and spawns at most 28 pieces per physics frame.
- Blast sources:
  - footfalls
  - quake-marked attacks (ape two-handed smash and leap, reptile stomp)
  - the reptile's fire breath along its line
  - projectiles (boulder, fireball, rocket fist, meteor)
  - heavy limbs and tails passing through the blocks during COMMIT
  - bodies knocked hard (throws, slams, tackles) crash into the blocks they are pushed toward
- Measured in headless fights: about 113 cubes removed in one ape-vs-reptile fight, 0 in the mirrored spawn; fights last 78–86 s. The fighters' own destruction is unchanged.

## Main game
- Startup and R pick the ape and the reptile, alternating which side each starts on. Y on a controller does the same.

## Tests (cloud, headless)
- run_headless 6/6, combat 20/20, archetype 47/47, presentation 20/20, roster 207/207 (all 16 still compile), integration 18/18.
- Ape vs reptile fights finish at 78–86 s with the ape winning these seeds. Balance is not tuned in this pass.
- Stills: `art/creatures/renders/giant_ape_*.png`, `fire_reptile_side.png`, `showcase_midfight.png`. Software GL, not visual acceptance.

## Local visual review needed
- Silhouettes: is the ape hunched enough, does the head read as an ape, do the fists read clenched?
- Reptile: head size, jaw, dorsal ridge, tail, and whether it reads as a titan rather than a dinosaur.
- Destruction: do the lane blocks break convincingly, and does debris look heavy rather than confetti?
- Fire breath: does burning the blocks look right in the RTX 2070 SUPER render?
- Frame rate with the 16 blocks and debris during big impacts.
