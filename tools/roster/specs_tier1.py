"""Tier 1: Giant Ape, Stone Colossus, Giant Robot, Pointy-Hat Wizard (humanoid-slot bodies)."""
from voxel import E, B, cap
import biped

WP = {"shoulder": 0.25, "thigh": 0.21, "shin": 0.16, "foot": 0.17, "neck": 0.17, "head": 0.17, "torso": 0.277}

def finish_biped(R, rig, **kw):
    spec = dict(rig_type="biped", proportional_limbs=True, regions=R, rig=rig, weakpoints=dict(WP, **kw.pop("wp", {})),
                fatal=kw.pop("fatal", [{"regions":["head","neck"],"fraction":0.2,"reason":"HEAD AND NECK DESTROYED"},{"regions":["torso"],"fraction":0.3,"reason":"TORSO STRUCTURE FAILED"}]))
    spec.update(kw)
    return spec

def front_tags(region, columns, tag):
    def fn(live):
        out = {}
        for x, y in columns:
            zs = [c[2] for c, (n, _) in live.items() if n == region and c[0] == x and c[1] == y]
            if zs: out[(x, y, min(zs))] = tag
        return out
    return fn

# ---------------------------------------------------------------- GIANT APE (v2: hunched, knuckle-walking reference)
def giant_ape():
    # Front is -z. Hunched: chest and head project forward, shoulders sit ahead of the hips, arms reach to the ground.
    R, rig = biped.build(hip_x=2.6, hip_y=8.6, knee_dx=0.2, knee_y=4.8, knee_z=-1.6, thigh_r=2.7, shin_r=2.0, foot_w=2.7, foot_l=3.0, foot_z=-2.0,
        pelvis=(0,9.4,0.8,3.8,2.0,2.8), abdomen=(0,13.0,-0.6,3.6,2.6,2.8), chest=(0,17.8,-3.0,7.6,4.8,5.0),
        neck=(0,21.2,-4.2,2.4,1.7,2.4), head=(0,22.6,-7.4,3.8,3.3,3.8),
        sh_x=7.0, sh_y=18.8, sh_r=(4.0,3.7,3.6), elbow=(9.0,12.0,-4.8), wrist=(9.4,5.6,-7.4), fist=(9.6,3.0,-8.4,3.4,2.6,3.6),
        ua_r=3.0, fa_r=3.2, lean=-0.3)
    rig["idle_hand"] = [8.6, 5.2, -9.0]
    rig["guard"] = [4.0, 19.5, -8.0]
    rig["head"] = [0.0, 22.6, -9.4]
    # Back and trapezius: enormous upper-back hump behind the shoulders, shoulder caps swelling outward.
    R["chest"]["vols"] = R["chest"]["vols"] + [E(0,20.4,1.6,8.0,3.8,4.0), E(0,18.2,2.4,6.8,4.0,3.4), E(0,17.0,-6.0,5.6,3.8,2.6)]
    # Brow, muzzle and jaw are added to the head region so the face reads as ape at arena distance.
    R["head"]["vols"] = R["head"]["vols"] + [E(0,24.6,-10.6,3.4,1.4,1.6), E(0,21.9,-12.0,2.4,1.9,2.2), E(0,20.6,-10.0,2.6,1.3,2.3), E(0,25.4,-7.4,3.0,1.2,1.6)]
    def face(live):
        tags = {}
        for c, (n, _) in live.items():
            if n != "head": continue
            if c[2] <= -8 and c[1] in (23, 24) and abs(c[0]) in (1, 2): tags[c] = "dark"              # deep-set eye sockets
            if c[2] <= -8 and c[1] in (23,) and abs(c[0]) == 1: tags[c] = "glow"                     # restrained eye glow
            if c[2] <= -9 and c[1] <= 21 and abs(c[0]) <= 1: tags[c] = "dark"                         # mouth line
        for c, (n, _) in live.items():
            if n == "chest" and c[2] <= -6 and c[1] >= 16 and (c[0]*5+c[1]*3) % 7 == 0: tags[c] = "accent"  # lighter chest plates
        return tags
    return finish_biped(R, rig, id="giant_ape", slim=0.9, name="GIANT APE", kind="brawler", palette="2e2823", tags_fn=face,
        look={"skin":"2e2823","limb":"272220","joint":"1a1614","head":"3a2f27","accent":"8a7258","interior":"2a1612","glow":"ffb347","face":False,
              "tones":{"neck":"joint"}},
        behavior={"speed":2.5,"acceleration":1.0,"turn_rate":0.5,"turn_acceleration":0.7,"step_seconds":0.9,"preferred_range":9.7,"retreat":0.12,"circle":1.1,"reposition_interval":6.0,"reposition_seconds":3.0,"charge_weight":0.0,"charge_distance":16.0,"crush_radius":3.4},
        attacks={
          "hammer_fist":{"base":"heavy_hook","label":"HAMMER FIST","weight":2.0,"range":11.5,"force":26,"radius":2.7,"trajectory":"overhead","sound_pitch":0.85},
          "ape_hook":{"base":"heavy_hook","label":"HOOK","weight":1.8,"range":11.5,"force":21,"radius":2.3,"trajectory":"hook","sound_pitch":0.9},
          "two_hand_smash":{"base":"heavy_hook","label":"TWO-HANDED SMASH","weight":1.0,"range":11.0,"force":32,"radius":3.5,"trajectory":"overhead","wind":1.5,"recover":2.0,"both_arms":True,"sound_pitch":0.78,"quake":{"radius":11.0,"damage":False}},
          "grab_throw":{"base":"heavy_hook","label":"GRAB","weight":1.5,"range":10.5,"force":14,"radius":2.0,"trajectory":"straight","cooldown":13.0,"requires_free":True,
                         "hold":{"label":"GRAPPLED","duration":2.4,"tick":0.55,"tick_radius":1.7,"tick_force":9.0,"region":"chest","end":"throw","throw_speed":21.0,"end_radius":3.4,"end_force":26.0,"distance":6.2}},
          "shoulder_tackle":{"base":"body_charge","label":"SHOULDER TACKLE","weight":1.2,"range":12.0,"force":24,"radius":2.9,"lunge":2.4,"sound_pitch":0.85},
          "leap_attack":{"base":"body_charge","label":"LEAP","weight":1.1,"range":17.0,"min_range":10.0,"force":28,"radius":3.0,"trajectory":"leap","charge_speed":13.0,"hop":4.5,"wind":0.9,"commit":0.75,"recover":1.8,"cooldown":9.0,"sound_pitch":0.8,"quake":{"radius":9.0,"damage":False}},
          "ape_headbutt":{"base":"headbutt","label":"HEADBUTT","weight":0.6,"range":9.4,"force":19,"radius":2.1},
          "ape_kick":{"base":"kick","label":"KICK","weight":0.7,"range":11.0,"force":19,"radius":2.1}},
        priority_targets=["left_shoulder","right_shoulder","head"], notes="Hunched knuckle-walker: shoulder and forearm mass, grapple control, ground-shaking smashes. Sacrifice: short legs, no ranged answer.")

# ---------------------------------------------------------------- STONE COLOSSUS
def stone_colossus():
    R, rig = biped.build(boxy=True, hip_x=3.6, hip_y=8.6, knee_y=5.0, thigh_r=3.2, shin_r=2.8, foot_w=3.2, foot_l=3.6, foot_z=-1.0,
        pelvis=(0,9.6,0,5.2,1.8,3.4), abdomen=(0,13.0,0,4.8,2.0,3.2), chest=(0,18.4,-0.2,8.0,3.8,4.2),
        neck=(0,22.0,-0.4,2.4,0.9,2.4), head=(0,24.2,-1.0,3.4,2.8,3.2), boxy_head=True,
        sh_x=10.2, sh_y=19.6, sh_r=(3.6,3.4,3.3), elbow=(12.0,13.8,-0.8), wrist=(12.4,8.8,-1.8), fist=(12.6,6.2,-2.2,3.8,3.2,3.4),
        ua_r=3.0, fa_r=3.2)
    def moss(live):
        tags = {}
        for c, (n, _) in live.items():
            h = (c[0]*73 + c[1]*151 + c[2]*31) % 13
            if h == 0 and c[1] > 6: tags[c] = "accent"
        for c in front_tags("head", [(-1,28),(1,28)], "glow")(live): tags[c] = "glow"
        return tags
    return finish_biped(R, rig, id="stone_colossus", slim=0.74, name="STONE COLOSSUS", kind="monolith", palette="857f74",
        look={"skin":"857f74","limb":"76716a","joint":"5d5953","head":"8d867a","accent":"7d8f62","interior":"3a3732","glow":"ffcf5a","face":False},
        tags_fn=moss,
        behavior={"speed":1.35,"acceleration":0.45,"turn_rate":0.24,"turn_acceleration":0.35,"step_seconds":1.55,"preferred_range":12.5,"retreat":0.05,"circle":0.15,"reposition_interval":11.0,"reposition_seconds":2.5,"charge_weight":0.0,"crush_radius":4.2},
        attacks={
          "hammer_fist":{"base":"heavy_hook","label":"HAMMER FIST","weight":2.0,"range":11.5,"force":28,"radius":3.0,"trajectory":"overhead","wind":1.4,"recover":1.9,"sound_pitch":0.7},
          "two_hand_smash":{"base":"heavy_hook","label":"TWO-HANDED SMASH","weight":1.1,"range":11.0,"force":34,"radius":3.9,"trajectory":"overhead","wind":1.9,"recover":2.4,"both_arms":True,"sound_pitch":0.62},
          "quake_stomp":{"base":"kick","label":"QUAKE STOMP","weight":1.2,"range":11.0,"force":26,"radius":3.2,"wind":1.3,"recover":1.9,"quake":{"radius":13.0},"sound_pitch":0.65},
          "body_crush":{"base":"body_charge","label":"BODY CRUSH","weight":0.9,"range":11.5,"force":28,"radius":3.3,"wind":1.4,"lunge":1.5,"sound_pitch":0.7},
          "boulder_throw":{"base":"ranged","label":"BOULDER THROW","ranged":"projectile","weight":2.4,"range":42.0,"min_range":15.0,"close_distance":15.0,"close_weight":0.1,
                           "wind":2.5,"commit":0.5,"follow":0.4,"recover":2.4,"cooldown":19.0,"muzzle":"right_arm","side":"right","speed":17.0,"gravity":15.0,"shape":"block","scale":2.0,"tint":"7d786e","hit_radius":2.6,"radius":3.6,"force":30.0,"wreck":4.5,"orb_color":"8a8478","orb":1.8,"charge_orb":False,"life":7.0,"aim_region":"chest"}},
        priority_targets=["left_thigh","right_thigh","abdomen"], notes="Unfair advantage: monumental mass and a rare, slow boulder. Sacrifice: slowest creature; arc is dodgeable.")

# ---------------------------------------------------------------- GIANT ROBOT
def giant_robot():
    R, rig = biped.build(boxy=True, hip_x=3.0, hip_y=11.2, knee_y=6.4, thigh_r=2.4, shin_r=2.0, foot_w=2.6, foot_l=3.4, foot_z=-1.2,
        pelvis=(0,11.8,0,4.0,1.6,2.6), abdomen=(0,15.0,0,3.2,2.2,2.4), chest=(0,20.2,0,5.8,4.0,3.3),
        neck=(0,24.6,-0.2,1.5,0.8,1.5), head=(0,26.6,-0.5,2.7,2.3,2.4), boxy_head=True,
        sh_x=7.6, sh_y=21.6, sh_r=(2.9,2.7,2.7), elbow=(8.8,16.0,-0.5), wrist=(9.2,11.8,-1.0), fist=(9.4,9.4,-1.4,2.7,2.3,2.5), ua_r=2.0, fa_r=2.2)
    def lights(live):
        t = front_tags("head", [(-1,27),(0,27),(1,27)], "glow")(live)
        for c in front_tags("chest", [(-1,20),(0,20),(1,20),(0,21),(0,19)], "glow")(live): t[c] = "glow"
        for c in front_tags("chest", [(-4,22),(4,22),(-4,18),(4,18)], "accent")(live): t[c] = "accent"
        return t
    return finish_biped(R, rig, id="giant_robot", slim=0.76, name="GIANT ROBOT", kind="mechanical", palette="7e8b96",
        look={"skin":"7e8b96","limb":"5f6a74","joint":"2c3138","head":"92a0aa","accent":"d9892b","interior":"ff7a1c","interior_glow":0.75,"glow":"52e0ff","face":False},
        tags_fn=lights,
        behavior={"speed":1.8,"acceleration":0.6,"turn_rate":0.3,"turn_acceleration":0.45,"step_seconds":1.3,"preferred_range":11.0,"retreat":0.1,"circle":0.3,"reposition_interval":8.0,"reposition_seconds":3.0,"charge_weight":0.0},
        attacks={
          "piston_punch":{"base":"right_punch","label":"PISTON PUNCH","weight":2.0,"range":11.0,"force":20,"radius":2.1,"trajectory":"straight","sound_pitch":0.8},
          "piston_jab":{"base":"left_punch","label":"PISTON JAB","weight":1.6,"range":11.0,"force":17,"radius":1.9,"trajectory":"straight","sound_pitch":0.85},
          "mech_kick":{"base":"kick","label":"MECHANICAL KICK","weight":0.9,"range":11.0,"force":21,"radius":2.2,"sound_pitch":0.8},
          "crushing_grab":{"base":"heavy_hook","label":"CRUSHING GRAB","weight":1.2,"range":10.5,"force":14,"radius":2.0,"trajectory":"straight","cooldown":15.0,"requires_free":True,
                           "hold":{"label":"CRUSHED","duration":2.6,"tick":0.45,"tick_radius":1.9,"tick_force":10.0,"region":"chest","end":"slam","end_radius":3.3,"distance":6.0}},
          "shoulder_ram":{"base":"body_charge","label":"SHOULDER RAM","weight":1.0,"range":11.5,"force":25,"radius":2.8},
          "two_hand_crush":{"base":"heavy_hook","label":"TWO-HANDED CRUSH","weight":0.9,"range":10.5,"force":28,"radius":3.2,"trajectory":"overhead","wind":1.5,"recover":1.9,"both_arms":True,"sound_pitch":0.7},
          "rocket_fist":{"base":"ranged","label":"ROCKET FIST","ranged":"projectile","kind":"fist","weight":2.2,"range":34.0,"min_range":12.0,"close_distance":12.0,"close_weight":0.15,
                         "wind":1.5,"commit":0.4,"follow":0.3,"recover":1.5,"cooldown":16.0,"muzzle":"right_arm","side":"right","speed":31.0,"gravity":0.0,"shape":"fist","scale":1.35,"tint":"7e8b96","glow":0.7,
                         "hit_radius":2.0,"radius":3.0,"force":27.0,"return_time":4.4,"return_to":"right_arm","return_speed":24.0,"max_range":38.0,"charge_orb":False,"life":6.0,"aim_region":"chest"}},
        priority_targets=["left_shoulder","right_shoulder","head"], notes="Unfair advantage: a launchable fist and crushing grip. Sacrifice: slow turning; the fist leaves the arm useless until it returns.")

# ---------------------------------------------------------------- WIZARD
def pointy_hat_wizard():
    R, rig = biped.build(hip_x=1.7, hip_y=11.6, knee_y=6.4, thigh_r=1.5, shin_r=1.25, foot_w=1.4, foot_l=2.0, foot_z=-0.9,
        pelvis=(0,12.2,0,2.5,1.4,1.8), abdomen=(0,15.2,0,2.3,1.8,1.7), chest=(0,19.2,0,3.5,2.6,2.0),
        neck=(0,22.0,0,1.1,0.9,1.1), head=(0,24.4,-0.3,2.0,2.2,1.9),
        sh_x=4.1, sh_y=20.4, sh_r=(1.5,1.4,1.4), elbow=(4.9,16.0,-0.6), wrist=(5.5,12.6,-1.2), fist=(5.7,11.2,-1.5,1.2,1.0,1.2), ua_r=1.15, fa_r=1.05)
    R["hat"] = {"major": "head", "vols": cap((0,26.4,0),(0,29.6,0),2.0) + cap((0,30.0,0),(0.6,35.6,-0.2),1.2) + [E(0.9,37.0,-0.3,0.7,1.1,0.7), E(0,26.0,-0.2,4.0,0.6,3.8)]}
    R["beard"] = {"major": "head", "vols": [E(0,21.6,-1.7,1.4,2.8,1.0), E(0,18.8,-2.1,1.0,2.4,0.9)], "w": 1.4}
    R["robe"] = {"major": "torso", "vols": [E(0,8.4,0,3.6,5.2,2.8)], "w": 2.2}
    R["staff"] = {"major": "right_arm", "vols": cap((6.7,4.0,-1.3),(6.7,31.0,-1.3),0.75) + [E(6.7,32.4,-1.3,1.3,1.4,1.3)], "w": 0.8}
    def tags(live):
        t = {}
        for c, (n, _) in live.items():
            if n == "staff" and c[1] >= 32: t[c] = "glow"
        return t
    return finish_biped(R, rig, id="pointy_hat_wizard", slim=1.2, name="POINTY-HAT WIZARD", kind="caster", palette="3f3a68", tags_fn=tags,
        follow={"staff":"right_forearm"},
        look={"skin":"3f3a68","limb":"3f3a68","joint":"2a2749","head":"d3b79b","accent":"e8e4dc","interior":"1a1630","glow":"b080ff",
              "tones":{"hat":"joint","robe":"skin","beard":"accent","staff":"joint"}},
        behavior={"speed":2.9,"acceleration":1.0,"turn_rate":0.5,"turn_acceleration":0.7,"step_seconds":0.9,"preferred_range":22.0,"retreat":0.85,"circle":1.2,"reposition_interval":5.0,"reposition_seconds":3.6,"charge_weight":0.0},
        weakpoints=dict(WP, neck=0.24, head=0.24, torso=0.36, shoulder=0.32),
        attacks={
          "staff_strike":{"base":"right_punch","label":"STAFF STRIKE","weight":1.6,"range":11.0,"force":12,"radius":1.7,"trajectory":"straight"},
          "staff_shove":{"base":"heavy_hook","label":"STAFF SHOVE","weight":1.2,"range":10.8,"force":24,"radius":2.0,"trajectory":"hook","sound_pitch":1.1},
          "arcane_bolt":{"base":"ranged","label":"ARCANE BOLT","ranged":"projectile","weight":2.0,"range":38.0,"min_range":9.0,"close_distance":10.0,"close_weight":0.3,
                         "wind":0.85,"commit":0.3,"follow":0.2,"recover":0.9,"cooldown":5.5,"muzzle":"right_arm","side":"right","speed":42.0,"shape":"cube4","scale":0.75,"tint":"8a6cff","glow":1.8,"hit_radius":1.6,"radius":1.9,"force":13.0,"orb_color":"b080ff","orb":1.1,"life":3.0,"aim_region":"chest"},
          "telekinetic_blast":{"base":"ranged","label":"TELEKINETIC BLAST","ranged":"projectile","weight":1.2,"range":30.0,"min_range":6.0,"close_distance":0.0,
                         "wind":1.1,"commit":0.3,"follow":0.2,"recover":1.3,"cooldown":11.0,"muzzle":"right_arm","side":"right","speed":50.0,"shape":"sphere2","scale":0.7,"tint":"6c9aff","glow":2.0,"hit_radius":2.2,"radius":1.7,"force":46.0,"orb_color":"6c9aff","orb":1.5,"life":2.5,"aim_region":"chest"},
          "meteor":{"base":"ranged","label":"METEOR","ranged":"meteor","weight":2.2,"range":44.0,"min_range":11.0,"close_distance":11.0,"close_weight":0.2,
                         "wind":1.9,"commit":0.4,"follow":0.3,"recover":1.7,"cooldown":17.0,"muzzle":"right_arm","side":"right","aoe":5.4,"force":30.0,"warn":1.9,"fall":0.9,"scale":1.15,"tint":"5a3a2a","glow":1.8,"orb_color":"ff7a2a","orb":1.7}},
        priority_targets=["head","chest"], notes="Unfair advantage: the strongest distance control. Sacrifice: weak torso/neck; if the Ape reaches him he dies quickly.")

SPECS = [dict(**{k: v for k, v in f().items()}) for f in (giant_ape, stone_colossus, giant_robot, pointy_hat_wizard)]
