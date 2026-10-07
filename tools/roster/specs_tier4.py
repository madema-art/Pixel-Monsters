"""Tier 4: Dark Knight Rider (horse + rider + lance), Giant Anaconda (serpent chain), Army of 10 (ten 100-cube bodies)."""
import math
from voxel import E, B, cap
import voxel
from specs_tier1 import front_tags

# ---------------------------------------------------------------- DARK KNIGHT RIDER
def dark_knight_rider():
    R = {}
    R["horse_body"] = {"major":"horse","vols":[E(0,12.2,1.2,3.7,3.5,7.0)]}
    R["horse_chest"] = {"major":"horse","vols":[E(0,13.2,-5.2,3.3,4.0,3.0)],"w":0.95}
    R["horse_neck"] = {"major":"horse","vols":cap((0,15.0,-6.6),(0,21.4,-9.6),2.0)}
    R["horse_head"] = {"major":"horse","vols":[E(0,22.2,-12.4,1.9,2.2,3.3)],"w":0.9}
    R["horse_tail"] = {"major":"horse","vols":cap((0,13.8,8.0),(0,8.0,12.6),0.95),"w":1.2}
    chains = []; limbs = []; leg_ids = []
    legs = [("leg_fl",-1,-5.6,[0,0,-1]),("leg_fr",1,-5.6,[0,0,-1]),("leg_hl",-1,6.8,[0,0,1]),("leg_hr",1,6.8,[0,0,1])]
    for name, s, z, bend in legs:
        root = (s*2.4,9.8,z); mid = (s*2.6,5.8,z+(-0.9 if z<0 else 1.2)); end = (s*2.5,1.0,z+(-0.4 if z<0 else 0.6))
        R[name+"_u"] = {"major":name,"vols":cap(root,mid,1.35)}
        R[name+"_l"] = {"major":name,"vols":cap(mid,end,1.0)}
        chains.append({"id":name,"role":"leg","regions":[name+"_u",name+"_l"],"root":list(root),"mid":list(mid),"end":list(end),"bend":bend})
        limbs.append({"id":name,"regions":[name+"_u",name+"_l"],"kind":"leg","fail":0.3})
        leg_ids.append(name)
    R["rider_torso"] = {"major":"rider","vols":[E(0,19.2,0.8,2.3,3.0,1.9)]}
    R["rider_head"] = {"major":"rider","vols":[E(0,24.0,0.6,1.7,1.8,1.7),E(0,26.0,0.5,0.5,1.4,0.5)],"w":0.9}
    R["rider_arms"] = {"major":"rider","vols":cap((-2.6,20.6,0.6),(-3.0,18.8,-2.6),1.0)+cap((2.6,20.6,0.6),(3.4,19.0,-2.6),1.0)}
    R["lance"] = {"major":"lance","vols":cap((3.5,19.2,-2.0),(3.6,19.8,-18.0),0.75)+[E(3.6,19.9,-20.0,0.7,0.7,2.0)],"w":0.8}
    limbs += [{"id":"lance","regions":["lance"],"kind":"weapon","fail":0.3},
              {"id":"rider","regions":["rider_torso","rider_head","rider_arms"],"kind":"rider","fail":0.0},
              {"id":"horse_core","regions":["horse_body","horse_chest","horse_neck","horse_head"],"kind":"horse","fail":0.0}]
    def tags(live):
        t = front_tags("rider_head", [(-1,24),(1,24)], "glow")(live)
        for c in front_tags("horse_head", [(-1,23),(1,23)], "glow")(live): t[c] = "glow"
        return t
    return dict(id="dark_knight_rider", name="DARK KNIGHT RIDER", kind="cavalry", palette="22242c", rig_type="multi", slim=0.9, regions=R, tags_fn=tags,
        rig={"head":[0,26.0,0.5],"torso":[0,19.2,-1.5],"stance_y":-0.6,"sag":1.0},
        rig_multi={"pivot":[0,12,1],"chains":chains,"head_region":"rider_head",
                   "gait":{"step_seconds":0.38,"threshold":1.9,"max_simultaneous":2,"lift":1.0},
                   "parts":[{"regions":["rider_torso","rider_head","rider_arms"],"pivot":[0,17,1],"lean_gain":0.25},{"regions":["horse_head","horse_neck"],"pivot":[0,15,-6],"recoil":0.1}],
                   "weapons":[{"regions":["lance"],"pivot":[3.5,19.2,-1.0],"tip":[3.6,19.9,-22.0],"thrust":[0,0,-1],"length":4.5,"effector":"lance_tip"}],"attack_lean":0.08},
        aliases={"head":"rider_head","chest":"horse_body"}, target_regions=["horse_body","horse_chest","rider_torso","rider_head","horse_neck","leg_fl","leg_fr","leg_hl","leg_hr"],
        limbs=limbs, locomotion={"type":"legs","legs":leg_ids,"power":1.1},
        fatal=[{"regions":["rider"],"fraction":0.22,"reason":"RIDER DESTROYED"},{"regions":["horse_core"],"fraction":0.22,"reason":"WARHORSE COLLAPSED"}],
        look={"skin":"2b2d36","limb":"3a3c46","joint":"16171c","head":"3a3c46","accent":"a8aab6","interior":"1c1114","glow":"ff3a3a","face":False,
              "tones":{"rider_torso":"joint","rider_head":"joint","rider_arms":"joint","lance":"accent","horse_tail":"joint","horse_head":"head"}},
        behavior={"speed":3.4,"acceleration":1.3,"turn_rate":0.6,"turn_acceleration":0.8,"preferred_range":13.5,"retreat":0.35,"circle":1.3,"reposition_interval":7.0,"reposition_seconds":3.4,"charge_weight":1.5,"charge_distance":23.0,"min_separation":8.5,"crush_radius":4.2},
        attacks={
          "lance_thrust":{"base":"custom","label":"LANCE THRUST","weight":2.0,"range":18.5,"force":21,"radius":1.7,"effector":"lance_tip","trajectory":"straight","needs":{"lance":0.4},"wind":0.85,"recover":1.3,"sound_pitch":1.1},
          "lance_charge":{"base":"custom","label":"LANCE CHARGE","weight":2.4,"range":30.0,"min_range":15.0,"force":32,"radius":2.5,"effector":"lance_tip","trajectory":"charge","charge_speed":16.5,"needs":{"lance":0.4},"wind":1.0,"commit":1.1,"recover":1.9,"sound_pitch":0.9},
          "trample":{"base":"custom","label":"TRAMPLE","weight":1.2,"range":11.5,"force":24,"radius":3.1,"effector":"torso","lunge":2.6,"wind":0.9,"sound_pitch":0.8},
          "horse_kick":{"base":"custom","label":"HORSE KICK","weight":1.0,"range":11.0,"force":22,"radius":2.3,"effector":"leg_hr","trajectory":"straight","needs":{"leg_hr":0.5},"wind":0.8,"sound_pitch":0.9},
          "mounted_strike":{"base":"custom","label":"MOUNTED STRIKE","weight":1.2,"range":15.5,"force":22,"radius":2.5,"effector":"lance_tip","trajectory":"hook","needs":{"lance":0.4},"wind":0.9,"sound_pitch":1.0}},
        priority_targets=["rider_torso","horse_body"], notes="Unfair advantage: charge setup and the longest melee reach. Sacrifice: lance and horse are separate, breakable cube groups; no ranged answer.")

# ---------------------------------------------------------------- GIANT ANACONDA
def giant_anaconda():
    R = {}
    names = ["head"] + [f"seg_{i:02d}" for i in range(1, 11)] + ["tail_1", "tail_2"]
    zs = [-1.5] + [3.6+2.9*(i-1) for i in range(1, 11)] + [32.4, 35.8]
    radii = [(3.2,2.9,3.8)] + [(3.4-0.05*i,3.1-0.04*i,1.9) for i in range(1, 11)] + [(2.3,2.1,2.0),(1.5,1.4,2.2)]
    for n, z, r in zip(names, zs, radii):
        y = 3.8
        R[n] = {"major":n,"vols":[E(0,y,z,*r)]}
    R["head"]["vols"] = [E(0,4.0,-1.4,3.3,2.8,3.8),E(0,3.4,-4.6,2.2,1.8,2.0)]
    limbs = [{"id":n,"regions":[n],"kind":"segment" if n!="head" else "head","fail":0.18} for n in names]
    def tags(live):
        t = front_tags("head", [(-1,5),(1,5)], "glow")(live)
        for c, (n, _) in live.items():
            if n.startswith("seg_") and (int(n[4:])+ (c[0]//2)) % 3 == 0 and c[1] >= 4 and abs(c[0]) <= 1: t[c] = "dark"
        return t
    return dict(id="giant_anaconda", name="GIANT ANACONDA", kind="serpent", palette="55663a", rig_type="serpent", slim=1.0, regions=R, tags_fn=tags,
        rig={"head":[0,3.7,-3.4],"torso":[0,3.6,3.0],"stance_y":-0.6,"sag":0.5},
        rig_serpent={"segments":names,"head_height":4.0,"raise":3.6,"wave":1.15,"rear_falloff":0.5,"mid_index":5,"mouth":2.6,"wrap_segments":[2,3,4,5,6,7,8],"stretch":1.0},
        aliases={"head":"head","chest":"seg_03"}, target_regions=["head","seg_02","seg_04","seg_06","seg_08"],
        limbs=limbs, locomotion={"type":"serpent","power":1.3},
        fatal=[{"regions":["head"],"fraction":0.2,"reason":"HEAD DESTROYED"},{"regions":["seg_01","seg_02","seg_03","seg_04","seg_05","seg_06","seg_07","seg_08","seg_09","seg_10","tail_1","tail_2"],"fraction":0.3,"reason":"SPINE SEVERED"}],
        look={"skin":"55663a","limb":"4a5a32","joint":"2e3a20","head":"6a7a44","accent":"c8b46a","interior":"3a1a1a","glow":"ffd04a","face":False,"tones":{"tail_1":"limb","tail_2":"joint"}},
        behavior={"speed":2.5,"acceleration":1.1,"turn_rate":0.55,"turn_acceleration":0.8,"preferred_range":11.5,"retreat":0.2,"circle":1.5,"reposition_interval":6.0,"reposition_seconds":3.0,"min_separation":8.5,"crush_radius":3.0},
        attacks={
          "bite":{"base":"custom","label":"BITE","weight":2.0,"range":13.5,"force":22,"radius":2.1,"effector":"head","lunge":3.0,"needs":{"head":0.4},"wind":0.8,"recover":1.3,"sound_pitch":1.0},
          "lunge":{"base":"custom","label":"LUNGE","weight":1.5,"range":21.0,"min_range":11.0,"force":26,"radius":2.4,"effector":"head","trajectory":"leap","charge_speed":11.5,"hop":0.4,"needs":{"head":0.45},"wind":0.8,"commit":0.6,"recover":1.5,"cooldown":7.0,"sound_pitch":0.95},
          "constrict":{"base":"custom","label":"CONSTRICT","weight":1.8,"range":13.0,"force":14,"radius":2.2,"effector":"head","lunge":2.6,"needs":{"head":0.4},"wind":0.9,"cooldown":15.0,"requires_free":True,
                       "hold":{"label":"CONSTRICTING","duration":4.4,"tick":0.55,"tick_radius":1.9,"tick_force":9.0,"region":"abdomen","end":"drop","distance":4.6,"drag":3.0},"sound_pitch":0.8},
          "body_sweep":{"base":"custom","label":"BODY SWEEP","weight":1.2,"range":15.5,"force":24,"radius":3.0,"effector":"body_mid","trajectory":"hook","wind":1.0,"recover":1.6,"needs":{"seg_05":0.4},"sound_pitch":0.8},
          "tail_whip":{"base":"custom","label":"TAIL WHIP","weight":1.0,"range":17.0,"force":20,"radius":2.4,"effector":"tail_tip","trajectory":"hook","needs":{"tail_1":0.4},"wind":0.9,"sound_pitch":0.9}},
        priority_targets=["head"], notes="Unfair advantage: wrapping constriction and flexible reach. Sacrifice: no limbs; every segment is its own breakable structure.")

# ---------------------------------------------------------------- ARMY OF 10
def army_of_ten():
    unit = {
        "body": [E(0,7.8,0,1.9,2.6,1.4), E(0,11.4,-0.2,1.3,1.3,1.2)],
        "arms": cap((-2.3,9.0,0),(-2.8,5.8,-0.8),0.8)+cap((2.3,9.0,0),(2.8,5.8,-0.8),0.8),
        "legs": cap((-0.9,5.2,0),(-1.0,1.0,-0.3),1.0)+cap((0.9,5.2,0),(1.0,1.0,-0.3),1.0)}
    def custom():
        regions = {}
        live_all = {}
        rest = []
        for i in range(10):
            ox = (i % 5 - 2) * 10; oz = (i // 5 - 0.5) * 10
            rest.append([ox, oz])
            sub = {"b": {"vols": unit["body"]}, "a": {"vols": unit["arms"]}, "l": {"vols": unit["legs"]}}
            live, s = voxel.compile_regions(sub, target=100)
            for cell, (name, sc) in live.items():
                key = {"b": f"u{i}_body", "a": f"u{i}_arms", "l": f"u{i}_legs"}[name]
                live_all[(cell[0]+ox, cell[1], cell[2]+oz)] = (key, sc)
            for suffix in ("body", "arms", "legs"): regions[f"u{i}_{suffix}"] = {"major": f"u{i}"}
        assert len(live_all) == 1000 and len(voxel.components(set(live_all))) == 10
        custom.rest = rest
        return live_all, regions, 1.0
    live, regions, _ = custom()
    rest = custom.rest
    limbs = [{"id":f"u{i}","regions":[f"u{i}_body",f"u{i}_arms",f"u{i}_legs"],"kind":"unit","fail":0.22} for i in range(10)]
    def build():
        return live, regions, 1.0
    return dict(id="army_of_ten", name="ARMY OF 10", kind="swarm", palette="8a8f9a", rig_type="swarm", regions=regions, custom_build=build, expect_components=10,
        rig={"stance_y":-0.6},
        limbs=limbs, locomotion={"type":"swarm"},
        fatal=[{"limb_kind":"unit","max_alive":0,"reason":"ALL UNITS DESTROYED"}],
        special={"swarm":{"units":10,"speed":5.4,"ring_radius":3.9,"climb_height":13.0,"strike_interval":0.9,"strike_radius":1.9,"strike_force":6.0,"rest":rest}},
        look={"skin":"8a8f9a","limb":"6a707c","joint":"3a3f4a","head":"b8a48a","accent":"c0463a","interior":"3a1a1a","glow":"ffd070","face":False,"tones":{}},
        behavior={"speed":5.4,"min_separation":2.0,"preferred_range":5.0,"crush_radius":1.5},
        attacks={"swarm_pummel":{"base":"custom","label":"SWARM PUMMEL","weight":1.0,"range":8.0,"force":4,"radius":1.0,"effector":"torso","wind":0.5}},
        aliases={}, priority_targets=["chest"], notes="Unfair advantage: ten independent bodies that climb and destabilize. Sacrifice: each 100-cube fighter dies to a single heavy hit.")

SPECS = [f() for f in (dark_knight_rider, giant_anaconda, army_of_ten)]
