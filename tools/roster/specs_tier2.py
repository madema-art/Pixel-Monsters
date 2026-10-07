"""Tier 2: Giant Skeleton, Giant Mantis, Fire-Breathing Reptile, Shadow-Flame Demon, Giant Diaper Baby."""
import math
from voxel import E, B, cap
import biped
from specs_tier1 import finish_biped, front_tags, WP

def ring(cx, y, cz, a, b, r, steps=14, start=-90, end=90, flat=False):
    """Hollow arc of small spheres (rib)."""
    out = []
    for i in range(steps+1):
        t = math.radians(start+(end-start)*i/steps)
        out.append(E(cx+a*math.sin(t)*(1 if not flat else 1), y, cz-b*math.cos(t), r, r, r))
    return out

# ---------------------------------------------------------------- GIANT SKELETON
def giant_skeleton():
    R, rig = biped.build(hip_x=2.4, hip_y=17.0, knee_y=9.0, knee_z=-0.7, thigh_r=1.25, shin_r=1.05, foot_w=1.2, foot_l=2.6, foot_z=-1.8,
        pelvis=(0,18.4,0,3.2,1.3,1.8), abdomen=(0,22.0,0,1.0,2.4,1.0), chest=(0,26.0,0,1.0,2.0,1.0),
        neck=(0,29.0,-0.4,0.95,1.1,0.95), head=(0,32.2,-0.9,3.1,2.9,2.8),
        sh_x=5.2, sh_y=28.0, sh_r=(1.5,1.4,1.4), elbow=(6.4,21.5,-0.7), wrist=(6.6,15.0,-1.6), fist=(6.7,13.2,-2.0,1.5,1.5,1.5), ua_r=1.05, fa_r=0.95)
    # Hollow rib cage + spine + pelvic bowl: thin arcs of small spheres, mostly empty space.
    ribs = []
    for k, y in enumerate([22.6, 25.0, 27.4]):
        a = 3.3+0.9*(1-abs(k-1)/1.0)
        ribs += ring(0, y, 0, a, 2.5, 0.8, 11, -100, 100)
    R["chest"]["vols"] = ribs + cap((0,23.0,0.8),(0,29.0,0.6),0.95) + cap((0,23.5,-2.2),(0,28.5,-2.2),0.8)
    R["abdomen"]["vols"] = cap((0,19.0,0.7),(0,23.2,0.8),0.95)
    R["pelvis"]["vols"] = ring(0, 18.4, 0, 3.4, 2.2, 1.0, 10, -140, 140)+[E(0,18.6,0.9,1.4,1.2,1.0)]
    def tags(live):
        t = front_tags("head", [(-1,33),(1,33),(-2,33),(2,33)], "glow")(live)
        return t
    return finish_biped(R, rig, id="giant_skeleton", name="GIANT SKELETON", kind="reassembler", palette="d8d0b8", slim=1.0, tags_fn=tags,
        leg_fail={"thigh":0.55,"shin":0.5,"foot":0.35}, wp={"shoulder":0.6,"neck":0.5,"head":0.5},
        fatal=[{"regions":["head"],"fraction":0.18,"reason":"SKULL SHATTERED"},{"regions":["torso"],"fraction":0.25,"reason":"SPINE AND RIBS SHATTERED"}],
        special={"regen":{"delay":3.6,"rate":26.0,"twitch":0.8,"vulnerable_count":14}},
        look={"skin":"d8d0b8","limb":"cfc7ac","joint":"9d9578","head":"e6e0cb","accent":"8a8268","interior":"2a2620","glow":"ff3a2a","face":False,"tones":{"abdomen":"limb","pelvis":"joint"}},
        behavior={"speed":2.5,"acceleration":0.85,"turn_rate":0.46,"turn_acceleration":0.6,"step_seconds":1.0,"preferred_range":11.5,"retreat":0.2,"circle":0.8,"reposition_interval":7.0,"reposition_seconds":3.4,"crush_radius":3.0},
        attacks={
          "bone_club":{"base":"heavy_hook","label":"BONE CLUB","weight":2.0,"range":13.5,"force":20,"radius":2.3,"trajectory":"overhead","sound_pitch":1.15},
          "sweeping_arm":{"base":"heavy_hook","label":"SWEEPING ARM","weight":1.5,"range":14.0,"force":18,"radius":2.2,"trajectory":"hook","sound_pitch":1.15},
          "long_strike":{"base":"right_punch","label":"LONG STRIKE","weight":1.4,"range":14.5,"force":15,"radius":1.7,"trajectory":"straight","sound_pitch":1.2},
          "skeleton_kick":{"base":"kick","label":"KICK","weight":0.8,"range":12.0,"force":18,"radius":2.0,"sound_pitch":1.1},
          "skull_bash":{"base":"headbutt","label":"SKULL BASH","weight":0.9,"range":10.5,"force":22,"radius":2.3,"sound_pitch":1.0}},
        priority_targets=["left_shoulder","right_shoulder","left_thigh","right_thigh"],
        notes="Unfair advantage: reassembly of unshattered bone. Sacrifice: brittle joints; opponent must smash the loose bones.")

# ---------------------------------------------------------------- GIANT MANTIS
def giant_mantis():
    R, rig = biped.build(hip_x=1.8, hip_y=13.5, knee_dx=0.8, knee_y=8.0, knee_z=-1.2, thigh_r=1.45, shin_r=1.15, foot_w=1.3, foot_l=2.2, foot_z=-1.2,
        pelvis=(0,14.0,0.8,2.4,1.5,2.2), abdomen=(0,17.5,0.4,1.9,2.4,2.0), chest=(0,23.0,-0.2,2.7,3.6,2.2),
        neck=(0,27.6,-0.8,1.1,1.0,1.1), head=(0,29.8,-1.4,2.8,2.1,2.0),
        sh_x=3.1, sh_y=25.2, sh_r=(1.5,1.5,1.4), elbow=(5.4,19.6,-2.8), wrist=(4.8,27.0,-8.4), fist=(4.7,27.8,-9.6,1.1,1.5,1.6), ua_r=1.3, fa_r=1.1)
    R["abdomen"]["vols"] = [E(0,17.5,0.8,2.0,2.6,2.4), E(0,13.2,3.0,1.8,2.0,3.4)]
    def tags(live):
        t = front_tags("head", [(-2,30),(2,30),(-2,31),(2,31)], "glow")(live)
        return t
    return finish_biped(R, rig, id="giant_mantis", name="GIANT MANTIS", kind="striker", palette="5a8a3c", slim=1.18, tags_fn=tags,
        wp={"shoulder":0.5,"neck":0.3,"head":0.3,"torso":0.3}, leg_fail={"thigh":0.3,"shin":0.25,"foot":0.15},
        fatal=[{"regions":["head","neck"],"fraction":0.22,"reason":"HEAD AND NECK DESTROYED"},{"regions":["torso"],"fraction":0.32,"reason":"THORAX SHATTERED"}],
        look={"skin":"5a8a3c","limb":"4f7a34","joint":"2e4a22","head":"6aa044","accent":"d8e8a0","interior":"1a2a14","glow":"b8ff4a","face":False,"tones":{"forearm":"accent","fist":"accent"}},
        behavior={"speed":3.1,"acceleration":1.4,"turn_rate":0.62,"turn_acceleration":0.9,"step_seconds":0.7,"preferred_range":13.5,"retreat":0.5,"circle":0.9,"reposition_interval":5.0,"reposition_seconds":2.6,"charge_weight":0.0},
        attacks={
          "scythe_slash":{"base":"heavy_hook","label":"SCYTHE SLASH","weight":2.0,"range":16.5,"force":22,"radius":2.1,"trajectory":"hook","wind":0.8,"recover":1.2,"sound_pitch":1.2},
          "double_scythe":{"base":"heavy_hook","label":"DOUBLE SCYTHE","weight":1.6,"range":16.0,"force":28,"radius":2.7,"trajectory":"backhand","both_arms":True,"wind":0.95,"recover":1.5,"sound_pitch":1.15},
          "mantis_stab":{"base":"right_punch","label":"STAB","weight":1.5,"range":17.5,"force":19,"radius":1.5,"trajectory":"straight","wind":0.6,"recover":1.0,"sound_pitch":1.25},
          "leap_strike":{"base":"body_charge","label":"LEAP STRIKE","weight":1.2,"range":19.0,"min_range":11.0,"force":24,"radius":2.5,"trajectory":"leap","charge_speed":14.0,"hop":3.5,"wind":0.7,"commit":0.65,"recover":1.5,"cooldown":8.0,"sound_pitch":1.1},
          "mantis_kick":{"base":"kick","label":"KICK","weight":0.8,"range":12.0,"force":19,"radius":2.0}},
        priority_targets=["left_shoulder","right_shoulder","head"], notes="Unfair advantage: enormous bladed reach and leaping lunges. Sacrifice: fragile shoulder joints and thorax.")

# ---------------------------------------------------------------- FIRE-BREATHING REPTILE
def fire_reptile():
    R, rig = biped.build(hip_x=3.4, hip_y=10.2, knee_dx=0.4, knee_y=5.8, knee_z=-1.0, thigh_r=3.0, shin_r=2.2, foot_w=3.0, foot_l=3.8, foot_z=-1.8,
        pelvis=(0,11.2,0.6,4.0,2.0,3.2), abdomen=(0,14.8,0,4.4,2.5,3.5), chest=(0,19.4,-0.8,5.0,4.2,4.0),
        neck=(0,23.4,-2.4,2.3,1.6,2.3), head=(0,25.6,-5.0,2.8,2.4,4.4),
        sh_x=5.4, sh_y=20.4, sh_r=(1.9,1.8,1.8), elbow=(6.2,17.4,-3.2), wrist=(6.2,14.8,-5.2), fist=(6.2,13.6,-6.0,1.5,1.2,1.6), ua_r=1.4, fa_r=1.25, lean=0.08)
    R["tail_1"] = {"major":"tail","vols":[E(0,11.4,5.0,3.0,2.7,3.4)]}
    R["tail_2"] = {"major":"tail","vols":[E(0,9.6,9.4,2.4,2.2,3.0)]}
    R["tail_3"] = {"major":"tail","vols":[E(0,7.4,13.4,1.9,1.8,2.8)]}
    R["tail_4"] = {"major":"tail","vols":[E(0,5.2,17.6,1.4,1.3,2.8)]}
    R["dorsal"] = {"major":"torso","vols":[B(0,24.6,0.6,0.7,1.8,1.0),B(0,23.0,1.8,0.7,2.0,1.0),B(0,21.0,2.8,0.7,2.2,1.0),B(0,18.2,3.4,0.7,2.2,1.0),B(0,15.0,3.4,0.7,2.0,0.9)],"w":0.8}
    def tags(live):
        t = front_tags("head", [(-2,26),(2,26)], "glow")(live)
        for c, (n, _) in live.items():
            if n == "dorsal": t[c] = "accent"
        return t
    return finish_biped(R, rig, id="fire_reptile", name="FIRE-BREATHING REPTILE", kind="titan", palette="3f5a3a", slim=0.8, tags_fn=tags,
        follow={"dorsal":"torso"},
        extras=[{"id":"tail","parent":"torso","regions":["tail_1","tail_2","tail_3","tail_4"],"pivots":[[0,11.4,2.6],[0,9.8,7.0],[0,7.8,11.0],[0,5.8,15.0]],"axis":[0,1,0],"sway":{"amp":0.16,"speed":1.3,"lag":0.6},"tip":[0,5.0,20.0],"effector":"tail_tip"}],
        limbs=[{"id":"tail","regions":["tail_1","tail_2","tail_3","tail_4"],"kind":"tail","fail":0.3}],
        fatal=[{"regions":["head","neck"],"fraction":0.16,"reason":"HEAD AND NECK DESTROYED"},{"regions":["torso"],"fraction":0.3,"reason":"TORSO STRUCTURE FAILED"}],
        look={"skin":"3f5a3a","limb":"36502f","joint":"26391f","head":"4a6b42","accent":"c7632a","interior":"3a1d14","glow":"ffb02a","face":False,"tones":{"dorsal":"accent","tail_4":"joint"}},
        behavior={"speed":1.55,"acceleration":0.5,"turn_rate":0.22,"turn_acceleration":0.4,"step_seconds":1.4,"preferred_range":12.5,"retreat":0.05,"circle":0.2,"reposition_interval":10.0,"reposition_seconds":2.5,"crush_radius":4.2},
        attacks={
          "bite":{"base":"headbutt","label":"BITE","weight":2.2,"range":13.0,"force":23,"radius":2.4,"lunge":2.4,"sound_pitch":0.9,"needs":{"head":0.4}},
          "claw":{"base":"right_punch","label":"CLAW","weight":1.0,"range":10.0,"force":14,"radius":1.7},
          "stomp":{"base":"kick","label":"STOMP","weight":1.0,"range":11.0,"force":23,"radius":2.7,"sound_pitch":0.8},
          "body_collision":{"base":"body_charge","label":"BODY COLLISION","weight":0.8,"range":11.5,"force":26,"radius":3.1,"lunge":1.8,"sound_pitch":0.75},
          "tail_sweep":{"base":"custom","label":"TAIL SWEEP","weight":1.4,"range":15.5,"force":25,"radius":2.7,"effector":"tail_tip","trajectory":"spin","spin_turns":0.8,"wind":1.1,"commit":0.8,"follow":0.3,"recover":1.7,"needs":{"tail":0.4},"sound_pitch":0.8},
          "fire_breath":{"base":"ranged","label":"FIRE BREATH","ranged":"stream","weight":2.6,"range":27.0,"min_range":9.0,"close_distance":9.0,"close_weight":0.5,
                         "wind":1.7,"commit":2.6,"follow":0.3,"recover":2.3,"duration":2.6,"cooldown":18.0,"muzzle":"head","depends":["head","neck"],"needs":{"head":0.45,"neck":0.35},
                         "tick":0.2,"tick_radius":1.6,"force":9.0,"track":0.55,"arc_error":0.35,"charge_orb":True,"orb":1.6,"orb_color":"ffb02a","aim_region":"chest","sound_pitch":0.9}},
        priority_targets=["left_thigh","right_thigh","abdomen"], notes="Unfair advantage: sustained fire plus heavy tail sweep. Sacrifice: very slow turning and a long vulnerable wind-up.")

# ---------------------------------------------------------------- SHADOW-FLAME DEMON
def shadow_flame_demon():
    R, rig = biped.build(hip_x=2.5, hip_y=12.0, knee_y=6.8, thigh_r=2.1, shin_r=1.7, foot_w=2.0, foot_l=3.0, foot_z=-1.3,
        pelvis=(0,13.0,0,3.4,1.7,2.3), abdomen=(0,16.4,0,3.0,2.3,2.2), chest=(0,21.4,-0.2,5.4,3.7,3.0),
        neck=(0,25.8,-0.4,1.9,1.0,1.9), head=(0,28.2,-0.9,2.6,2.4,2.3),
        sh_x=6.6, sh_y=22.6, sh_r=(2.3,2.2,2.1), elbow=(7.8,17.4,-0.8), wrist=(8.0,12.6,-1.6), fist=(8.1,10.8,-2.0,1.9,1.6,1.8), ua_r=1.8, fa_r=1.7)
    R["horns"] = {"major":"head","vols":cap((2.0,29.6,-0.6),(4.2,34.0,-1.6),0.75)+cap((-2.0,29.6,-0.6),(-4.2,34.0,-1.6),0.75)+[E(4.6,34.8,-1.9,0.6,0.8,0.6),E(-4.6,34.8,-1.9,0.6,0.8,0.6)],"w":0.8}
    R["whip"] = {"major":"right_arm","vols":cap((8.1,10.8,-2.6),(9.0,8.0,-10.0),0.75)+cap((9.0,8.0,-10.0),(10.0,5.6,-17.0),0.65),"w":0.8}
    R["blade"] = {"major":"left_arm","vols":cap((-8.1,10.8,-2.8),(-8.4,14.6,-9.0),0.95)+cap((-8.4,14.6,-9.0),(-8.8,17.0,-14.0),0.8),"w":0.8}
    def tags(live):
        t = front_tags("head", [(-1,29),(1,29)], "glow")(live)
        for c, (n, _) in live.items():
            if n in ("whip",) and c[2] < -9: t[c] = "glow"
            elif n == "blade": t[c] = "accent"
            elif n in ("chest","abdomen","left_thigh","right_thigh","left_upper_arm","right_upper_arm") and (c[0]*7+c[1]*13+c[2]*5) % 11 == 0: t[c] = "glow"
        return t
    return finish_biped(R, rig, id="shadow_flame_demon", name="SHADOW-FLAME DEMON", kind="infernal", palette="2a2530", slim=1.0, tags_fn=tags,
        follow={"whip":"right_forearm","blade":"left_forearm"},
        tips={"whip_tip":{"follow":"right_forearm","point":[10.0,5.6,-17.0]},"blade_tip":{"follow":"left_forearm","point":[-8.8,17.0,-14.0]}},
        look={"skin":"2a2530","limb":"231f29","joint":"15121a","head":"2d2733","accent":"ff6a1c","interior":"ff5a10","interior_glow":0.9,"glow":"ff7a2a","face":False,"tones":{"horns":"joint","blade":"accent","whip":"joint"}},
        behavior={"speed":2.2,"acceleration":0.7,"turn_rate":0.38,"turn_acceleration":0.55,"step_seconds":1.15,"preferred_range":15.5,"retreat":0.35,"circle":0.7,"reposition_interval":7.0,"reposition_seconds":3.2},
        attacks={
          "flame_whip":{"base":"right_punch","label":"FLAME WHIP","weight":2.2,"range":21.0,"force":20,"radius":2.1,"trajectory":"hook","effector":"whip_tip","wind":0.95,"recover":1.5,"needs":{"right_arm":0.35},"sound_pitch":1.0},
          "fiery_blade":{"base":"left_punch","label":"FIERY BLADE","weight":1.6,"range":16.0,"force":24,"radius":2.3,"trajectory":"overhead","effector":"blade_tip","wind":0.9,"needs":{"left_arm":0.35},"sound_pitch":0.9},
          "demon_claw":{"base":"heavy_hook","label":"CLAW","weight":1.0,"range":11.0,"force":19,"radius":2.1,"trajectory":"hook"},
          "body_strike":{"base":"body_charge","label":"BODY STRIKE","weight":0.8,"range":11.5,"force":23,"radius":2.7},
          "fireball":{"base":"ranged","label":"FIREBALL","ranged":"projectile","weight":2.4,"range":38.0,"min_range":13.0,"close_distance":13.0,"close_weight":0.15,
                      "wind":1.9,"commit":0.4,"follow":0.3,"recover":1.9,"cooldown":14.0,"muzzle":"left_arm","side":"left","speed":16.0,"gravity":2.5,"shape":"sphere2","scale":1.05,"tint":"ff6a1c","glow":2.4,
                      "explosive":True,"hit_radius":2.3,"radius":4.4,"force":28.0,"orb_color":"ff7a2a","orb":2.1,"life":6.0,"aim_region":"chest"}},
        priority_targets=["head","chest"], notes="Unfair advantage: long whip reach plus a telegraphed fireball. Sacrifice: slow fireball, mediocre mobility.")

# ---------------------------------------------------------------- GIANT DIAPER BABY
def diaper_baby():
    R, rig = biped.build(hip_x=3.2, hip_y=8.6, knee_y=5.0, thigh_r=3.2, shin_r=2.4, foot_w=2.6, foot_l=3.0, foot_z=-1.2,
        pelvis=(0,9.6,0,5.4,2.2,4.2), abdomen=(0,13.2,-0.4,5.6,3.0,4.8), chest=(0,17.6,-0.4,5.6,2.9,4.4),
        neck=(0,20.9,-0.5,2.4,0.8,2.4), head=(0,25.0,-0.8,6.0,4.6,5.2),
        sh_x=6.6, sh_y=18.4, sh_r=(2.4,2.3,2.2), elbow=(8.2,14.6,-1.6), wrist=(8.4,11.4,-2.6), fist=(8.5,9.6,-3.0,2.5,2.1,2.3), ua_r=2.3, fa_r=2.3)
    R["diaper"] = {"major":"torso","vols":[E(0,8.9,0,6.4,3.2,5.4)],"w":0.9}
    def tags(live):
        t = {}
        zs = {}
        for c, (n, _) in live.items():
            if n == "head":
                zs[(c[0], c[1])] = min(zs.get((c[0], c[1]), 99), c[2])
        ey = 26
        for x in (-3, -2, 2, 3):
            for yy in (ey, ey+1):
                if (x, yy) in zs: t[(x, yy, zs[(x, yy)])] = "dark"
        for x in (-1, 0, 1):
            if (x, 22) in zs: t[(x, 22, zs[(x, 22)])] = "dark"
        for x in (-5, 5):
            if (x, 24) in zs: t[(x, 24, zs[(x, 24)])] = "accent"
        return t
    return finish_biped(R, rig, id="diaper_baby", name="GIANT DIAPER BABY", kind="toddler", palette="d9a58f", slim=0.78, tags_fn=tags,
        fatal=[{"regions":["head","neck"],"fraction":0.14,"reason":"HEAD AND NECK DESTROYED"},{"regions":["torso"],"fraction":0.26,"reason":"TORSO STRUCTURE FAILED"}],
        look={"skin":"d9a58f","limb":"d2a08a","joint":"bd8b78","head":"e0b09a","accent":"f0a8a0","interior":"6a2a2a","glow":"ffd070","diaper":"f1ede2","face":False,"tones":{"diaper":"diaper"}},
        behavior={"speed":2.3,"acceleration":0.8,"turn_rate":0.5,"turn_acceleration":0.65,"step_seconds":0.95,"preferred_range":9.8,"retreat":0.1,"circle":0.7,"reposition_interval":6.5,"reposition_seconds":3.4,"charge_weight":0.5,"charge_distance":17.0,"crush_radius":3.8},
        attacks={
          "slap":{"base":"right_punch","label":"SLAP","weight":1.8,"range":10.6,"force":15,"radius":2.4,"trajectory":"hook"},
          "tantrum_stomp":{"base":"kick","label":"TANTRUM STOMP","weight":1.2,"range":10.8,"force":24,"radius":3.0,"quake":{"radius":10.0},"wind":1.0,"sound_pitch":0.8},
          "baby_headbutt":{"base":"headbutt","label":"HEADBUTT","weight":1.2,"range":9.8,"force":24,"radius":3.0,"sound_pitch":0.8},
          "wild_pounding":{"base":"heavy_hook","label":"WILD POUNDING","weight":1.5,"range":10.8,"force":25,"radius":3.0,"trajectory":"overhead","both_arms":True,"wind":0.95,"sound_pitch":0.85},
          "belly_flop":{"base":"body_charge","label":"BELLY FLOP","weight":1.4,"range":14.5,"min_range":8.5,"force":34,"radius":4.4,"trajectory":"leap","charge_speed":10.5,"hop":5.2,"wind":1.2,"commit":0.8,"recover":2.4,"cooldown":12.0,"sound_pitch":0.7},
          "waddle_charge":{"base":"body_charge","label":"WADDLING CHARGE","weight":1.0,"range":12.5,"force":27,"radius":3.2,"trajectory":"charge","charge_speed":8.5,"commit":0.9,"sound_pitch":0.8}},
        priority_targets=["head","chest"], notes="Unfair advantage: physically enormous impacts. Sacrifice: short reach and a huge, easy-to-hit head.")

SPECS = [f() for f in (giant_skeleton, giant_mantis, fire_reptile, shadow_flame_demon, diaper_baby)]
