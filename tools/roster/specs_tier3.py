"""Tier 3: Eyeball Beast, Blob, Giant Tarantula (multi-limb rig), Flying Dragon (wings + flight)."""
import math
from voxel import E, B, cap
import biped
from specs_tier1 import finish_biped, front_tags, WP

def pair(prefix, sx, regions_fn):
    return [regions_fn(prefix+("l" if s < 0 else "r"), s) for s in (-1, 1)]

# ---------------------------------------------------------------- GIANT EYEBALL BEAST
def eyeball_beast():
    R = {}
    R["sclera"] = {"major":"eye","vols":[E(0,15.0,0,5.6,5.6,5.4)]}
    R["eye"] = {"major":"eye","vols":[E(0,15.0,-4.3,3.4,3.4,1.5)],"w":0.85}
    R["pupil"] = {"major":"eye","vols":[E(0,15.0,-5.2,1.5,1.5,0.9)],"w":0.8}
    R["crown"] = {"major":"eye","vols":cap((-2.5,19.2,0.5),(-4.0,24.5,1.5),0.8)+cap((0,20.2,1.0),(0,26.0,2.0),0.8)+cap((2.5,19.2,0.5),(4.0,24.5,1.5),0.8),"w":1.2}
    chains = []; limbs = []
    legs = [("tent_fl",-1,-2.8),("tent_fr",1,-2.8),("tent_bl",-1,3.0),("tent_br",1,3.0)]
    for name, s, z in legs:
        root = (s*3.4,11.0,z); mid = (s*7.4,8.0,z*1.7); end = (s*9.2,1.0,z*2.5)
        R[name+"_u"] = {"major":name,"vols":cap(root,mid,1.4)}
        R[name+"_l"] = {"major":name,"vols":cap(mid,end,1.2)}
        chains.append({"id":name,"role":"leg","regions":[name+"_u",name+"_l"],"root":list(root),"mid":list(mid),"end":list(end),"bend":[s*0.4,1,0],"foot_height":0.0})
        limbs.append({"id":name,"regions":[name+"_u",name+"_l"],"kind":"leg","fail":0.28})
    for name, s in (("tent_al",-1),("tent_ar",1)):
        root = (s*5.0,16.4,-1.0); mid = (s*9.4,17.0,-5.2); end = (s*12.5,12.0,-9.6)
        R[name+"_u"] = {"major":name,"vols":cap(root,mid,1.3)}
        R[name+"_l"] = {"major":name,"vols":cap(mid,end,1.2)+[E(*end,1.7,1.7,1.7)]}
        chains.append({"id":name,"role":"arm","regions":[name+"_u",name+"_l"],"root":list(root),"mid":list(mid),"end":list(end),"idle":[s*10.5,15.0,-7.0],"wave":1.1,"phase":0.0 if s<0 else 2.1,"bend":[s*0.3,1,0]})
        limbs.append({"id":name,"regions":[name+"_u",name+"_l"],"kind":"arm","fail":0.28})
    limbs.append({"id":"gaze","regions":["eye","pupil"],"kind":"eye","fail":0.0})
    def tags(live):
        t = {}
        for c, (n, _) in live.items():
            if n == "eye":
                r = math.hypot(c[0], c[1]-15.0)
                if 2.0 <= r <= 3.4: t[c] = "glow"
            elif n == "sclera" and (c[0]*5+c[1]*11+c[2]*3) % 9 == 0 and c[2] < 0: t[c] = "accent"
        return t
    return dict(id="eyeball_beast", name="GIANT EYEBALL BEAST", kind="gazer", palette="d8cfae", rig_type="multi", slim=1.0, regions=R, tags_fn=tags,
        proportional_limbs=False,
        rig={"head":[0,15.0,-6.2],"torso":[0,14.0,-5.0],"stance_y":-0.6,"sag":1.0},
        rig_multi={"pivot":[0,12,0],"chains":chains,"gait":{"step_seconds":0.55,"threshold":1.8,"max_simultaneous":2,"lift":1.2},"attack_lean":0.08,"head_region":"sclera"},
        aliases={"head":"eye","chest":"sclera"}, target_regions=["sclera","eye","tent_al","tent_ar","tent_fl","tent_fr"],
        limbs=limbs, locomotion={"type":"legs","legs":["tent_fl","tent_fr","tent_bl","tent_br"],"power":1.15},
        fatal=[{"regions":["sclera","eye","pupil"],"fraction":0.3,"reason":"EYE DESTROYED"}],
        look={"skin":"d8cfae","limb":"8a3a6a","joint":"5a2244","head":"d8cfae","accent":"c23a3a","interior":"4a1a2a","glow":"ff9a2a","face":False,"tones":{"eye":"head","pupil":"joint","crown":"limb","tent_fl_u":"limb","tent_fr_u":"limb"}},
        behavior={"speed":2.5,"acceleration":1.3,"turn_rate":0.75,"turn_acceleration":1.0,"step_seconds":0.6,"preferred_range":11.0,"retreat":0.3,"circle":1.3,"reposition_interval":6.0,"reposition_seconds":2.4,"crush_radius":3.2},
        attacks={
          "tentacle_strike":{"base":"custom","label":"TENTACLE STRIKE","weight":2.0,"range":16.0,"force":18,"radius":1.9,"effector":"tent_ar","trajectory":"straight","needs":{"tent_ar":0.4},"wind":0.7,"recover":1.1,"sound_pitch":1.1},
          "tentacle_lash":{"base":"custom","label":"TENTACLE LASH","weight":1.8,"range":16.0,"force":17,"radius":1.9,"effector":"tent_al","trajectory":"hook","needs":{"tent_al":0.4},"wind":0.7,"recover":1.1,"sound_pitch":1.1},
          "tentacle_grab":{"base":"custom","label":"TENTACLE GRAB","weight":1.2,"range":15.0,"force":12,"radius":1.9,"effector":"tent_ar","trajectory":"straight","needs":{"tent_ar":0.45},"cooldown":14.0,"requires_free":True,
                           "hold":{"label":"ENTANGLED","duration":2.4,"tick":0.6,"tick_radius":1.5,"tick_force":7.0,"region":"chest","end":"drop","distance":7.0}},
          "body_ram":{"base":"custom","label":"BODY RAM","weight":0.9,"range":11.0,"force":23,"radius":2.9,"effector":"torso","lunge":2.6,"wind":1.0},
          "gaze_beam":{"base":"ranged","label":"GAZE BEAM","ranged":"stream","weight":2.6,"range":32.0,"min_range":9.0,"close_distance":9.0,"close_weight":0.5,
                       "wind":1.6,"commit":2.4,"follow":0.3,"recover":1.9,"duration":2.4,"cooldown":15.0,"muzzle":"head","depends":["gaze"],"needs":{"gaze":0.3},
                       "tick":0.18,"tick_radius":1.25,"force":5.0,"track":0.85,"arc_error":0.2,"beam":True,"beam_color":"ff3df0","beam_radius":0.4,"charge_orb":True,"orb":1.4,"orb_color":"ff3df0","aim_region":"chest"}},
        priority_targets=["eye"], notes="Unfair advantage: unpredictable multidirectional movement and a tracking gaze beam. Sacrifice: the eye is a big target, and each eye hit weakens the beam.")

# ---------------------------------------------------------------- BLOB
def blob():
    R = {}
    R["core"] = {"major":"mass","vols":[E(0,7.0,0,8.6,6.0,7.2)]}
    R["lobe_f"] = {"major":"mass","vols":[E(0,4.2,-8.2,5.0,3.8,3.8)],"w":1.05}
    R["lobe_b"] = {"major":"mass","vols":[E(0,4.0,8.4,5.2,3.8,4.0)],"w":1.05}
    R["lobe_l"] = {"major":"mass","vols":[E(-9.4,4.4,0,4.0,4.0,4.6)],"w":1.05}
    R["lobe_r"] = {"major":"mass","vols":[E(9.4,4.4,0,4.0,4.0,4.6)],"w":1.05}
    R["crest"] = {"major":"mass","vols":[E(0,13.6,-1.0,5.4,3.6,4.6),E(-3.0,16.2,-1.0,2.6,2.4,2.6),E(3.0,16.2,-1.0,2.6,2.4,2.6)],"w":0.95}
    R["face"] = {"major":"mass","vols":[E(0,12.6,-5.2,3.6,3.2,2.6)],"w":0.9}
    chains = []; limbs = [{"id":"blob_mass","regions":["core","lobe_f","lobe_b","lobe_l","lobe_r","crest","face"],"kind":"mass","fail":0.0}]
    for name, s in (("pseud_l",-1),("pseud_r",1)):
        root = (s*7.0,9.0,-2.5); mid = (s*11.0,8.0,-7.0); end = (s*13.0,4.0,-11.5)
        R[name+"_u"] = {"major":name,"vols":cap(root,mid,2.1)}
        R[name+"_l"] = {"major":name,"vols":cap(mid,end,2.0)+[E(*end,2.6,2.2,2.6)]}
        chains.append({"id":name,"role":"arm","regions":[name+"_u",name+"_l"],"root":list(root),"mid":list(mid),"end":list(end),"idle":[s*11.5,5.0,-9.5],"wave":0.9,"phase":0.0 if s<0 else 2.5,"bend":[s*0.4,1,0.2]})
        limbs.append({"id":name,"regions":[name+"_u",name+"_l"],"kind":"arm","fail":0.25})
    def tags(live):
        t = {}
        zs = {}
        for c, (n, _) in live.items():
            if n == "face": zs[(c[0], c[1])] = min(zs.get((c[0], c[1]), 99), c[2])
        for x in (-2, -1, 1, 2):
            for y in (14, 15):
                if (x, y) in zs: t[(x, y, zs[(x, y)])] = "dark"
        for x in (-2, -1, 0, 1, 2):
            if (x, 11) in zs: t[(x, 11, zs[(x, 11)])] = "dark"
        for c, (n, _) in live.items():
            if n in ("core","lobe_l","lobe_r","crest") and (c[0]*7+c[1]*3+c[2]*13) % 12 == 0: t[c] = "glow"
        return t
    return dict(id="blob", name="BLOB", kind="mass", palette="4fae3a", rig_type="multi", slim=0.72, regions=R, tags_fn=tags,
        rig={"head":[0,13.0,-6.5],"torso":[0,8.0,-5.5],"stance_y":-0.6,"sag":2.0},
        rig_multi={"pivot":[0,2,0],"chains":chains,"squash":{"amp":0.05,"speed":1.9},"attack_lean":0.12,"gait":{}},
        aliases={"head":"face","chest":"core"}, target_regions=["core","crest","face","lobe_f","lobe_l","lobe_r","lobe_b"],
        limbs=limbs, locomotion={"type":"mass","group":"blob_mass"},
        fatal=[{"regions":["blob_mass"],"fraction":0.24,"reason":"MASS DISPERSED"}],
        look={"skin":"4fae3a","limb":"3e9a30","joint":"2c7424","head":"6fcc50","accent":"9aff6a","interior":"1c4a18","interior_glow":0.55,"glow":"b6ff6a","face":False,"tones":{"face":"head","crest":"head","lobe_f":"limb","lobe_b":"limb"}},
        behavior={"speed":1.7,"acceleration":0.55,"turn_rate":0.34,"turn_acceleration":0.5,"preferred_range":10.2,"retreat":0.05,"circle":0.6,"reposition_interval":8.0,"reposition_seconds":3.0,"charge_weight":0.6,"charge_distance":16.0,"min_separation":7.5,"crush_radius":5.0},
        attacks={
          "body_slam":{"base":"custom","label":"BODY SLAM","weight":1.6,"range":13.0,"min_range":7.0,"force":27,"radius":3.8,"effector":"torso","trajectory":"leap","charge_speed":8.0,"hop":3.2,"wind":1.1,"commit":0.8,"recover":2.0,"cooldown":8.0,"sound_pitch":0.7},
          "engulf":{"base":"custom","label":"ENGULF","weight":1.7,"range":10.5,"force":10,"radius":2.8,"effector":"torso","lunge":2.6,"wind":1.0,"cooldown":15.0,"requires_free":True,
                    "hold":{"label":"ENGULFED","duration":3.2,"tick":0.5,"tick_radius":2.3,"tick_force":7.0,"region":"abdomen","end":"drop","distance":3.4,"drag":3.2},"sound_pitch":0.7},
          "smother":{"base":"custom","label":"SMOTHER","weight":0.9,"range":10.0,"force":12,"radius":3.0,"effector":"torso","lunge":2.2,"wind":0.9,"cooldown":18.0,"requires_free":True,
                    "hold":{"label":"SMOTHERED","duration":2.4,"tick":0.4,"tick_radius":2.0,"tick_force":8.0,"region":"chest","end":"slam","end_radius":3.0,"distance":3.2},"sound_pitch":0.7},
          "rolling_crush":{"base":"custom","label":"ROLLING CRUSH","weight":1.2,"range":14.0,"force":28,"radius":3.6,"effector":"torso","trajectory":"charge","charge_speed":9.0,"wind":1.2,"commit":1.1,"recover":2.2,"sound_pitch":0.65},
          "shove":{"base":"custom","label":"SHOVE","weight":1.4,"range":13.5,"force":24,"radius":2.5,"effector":"pseud_r","trajectory":"straight","needs":{"pseud_r":0.4},"wind":0.9,"sound_pitch":0.8}},
        priority_targets=["core"], notes="Unfair advantage: engulfing holds and a mass that shrugs off limb loss. Sacrifice: slow, huge target; every lost cube is permanent.")

# ---------------------------------------------------------------- GIANT TARANTULA
def tarantula():
    R = {}
    R["thorax"] = {"major":"body","vols":[E(0,7.4,-0.6,3.8,3.2,3.9)]}
    R["head"] = {"major":"body","vols":[E(0,6.6,-4.8,2.5,2.3,2.4)],"w":0.9}
    R["fangs"] = {"major":"body","vols":[B(-1.0,4.4,-7.1,0.55,1.9,0.5),B(1.0,4.4,-7.1,0.55,1.9,0.5)],"w":0.8}
    R["abdomen"] = {"major":"body","vols":[E(0,8.2,7.2,5.2,4.4,6.2)],"w":1.1}
    chains = []; limbs = []; leg_ids = []
    zs = [-2.6, -0.4, 1.8, 4.0]
    for k, z in enumerate(zs):
        for s in (-1, 1):
            side = "l" if s < 0 else "r"
            name = f"leg_{'f' if k==0 else 'a' if k==1 else 'b' if k==2 else 'h'}{side}"
            root = (s*3.2,8.0,z); mid = (s*(8.0+k*0.4),11.4,z+(-1.5 if k==0 else -0.4*k)); end = (s*(11.2+k*0.8),1.0,z+(-3.4 if k==0 else (-1.0 if k==1 else (1.4 if k==2 else 3.6))))
            R[name+"_u"] = {"major":name,"vols":cap(root,mid,1.15)}
            R[name+"_l"] = {"major":name,"vols":cap(mid,end,1.0)}
            chains.append({"id":name,"role":"leg","regions":[name+"_u",name+"_l"],"root":list(root),"mid":list(mid),"end":list(end),"bend":[s*0.5,1.2,0]})
            limbs.append({"id":name,"regions":[name+"_u",name+"_l"],"kind":"leg","fail":0.3})
            leg_ids.append(name)
    def tags(live):
        t = front_tags("head", [(-1,7),(1,7),(-1,6),(1,6),(0,8)], "glow")(live)
        for c, (n, _) in live.items():
            if n == "abdomen" and (c[0]*3+c[2]*5) % 7 == 0 and c[1] >= 10: t[c] = "accent"
        return t
    return dict(id="giant_tarantula", name="GIANT TARANTULA", kind="skitterer", palette="3a2c24", rig_type="multi", slim=0.95, regions=R, tags_fn=tags,
        rig={"head":[0,6.8,-6.6],"torso":[0,7.4,-3.6],"stance_y":-0.6,"sag":1.8},
        rig_multi={"pivot":[0,7,0],"chains":chains,"gait":{"step_seconds":0.42,"threshold":1.5,"max_simultaneous":4,"lift":1.1},"attack_lean":0.1},
        aliases={"chest":"thorax"}, target_regions=["thorax","head","abdomen","leg_fl","leg_fr"],
        limbs=limbs, locomotion={"type":"legs","legs":leg_ids,"power":1.3},
        fatal=[{"regions":["thorax","head"],"fraction":0.28,"reason":"CARAPACE CRUSHED"},{"regions":["abdomen"],"fraction":0.12,"reason":"ABDOMEN DESTROYED"}],
        look={"skin":"3a2c24","limb":"4a382c","joint":"241a14","head":"4a382c","accent":"b4472a","interior":"2a1a12","glow":"ff3a2a","face":False,"tones":{"fangs":"accent","abdomen":"skin"}},
        behavior={"speed":3.3,"acceleration":1.6,"turn_rate":0.65,"turn_acceleration":0.9,"preferred_range":11.0,"retreat":0.25,"circle":1.8,"reposition_interval":5.0,"reposition_seconds":2.8,"min_separation":8.0,"crush_radius":4.5},
        attacks={
          "pounce":{"base":"custom","label":"POUNCE","weight":1.8,"range":19.0,"min_range":9.0,"force":24,"radius":3.2,"effector":"torso","trajectory":"leap","charge_speed":15.0,"hop":3.4,"wind":0.8,"commit":0.7,"recover":1.5,"cooldown":8.0,"sound_pitch":0.9},
          "tarantula_bite":{"base":"custom","label":"BITE","weight":1.6,"range":10.5,"force":21,"radius":2.1,"effector":"head","lunge":2.2,"needs":{"head":0.4},"wind":0.7,"sound_pitch":1.0},
          "leg_strike":{"base":"custom","label":"LEG STRIKE","weight":1.6,"range":14.0,"force":17,"radius":1.8,"effector":"leg_fr","trajectory":"straight","needs":{"leg_fr":0.45},"wind":0.65,"recover":1.0,"sound_pitch":1.1},
          "leg_jab":{"base":"custom","label":"LEG JAB","weight":1.4,"range":14.0,"force":16,"radius":1.8,"effector":"leg_fl","trajectory":"straight","needs":{"leg_fl":0.45},"wind":0.65,"recover":1.0,"sound_pitch":1.1},
          "leg_sweep":{"base":"custom","label":"LEG SWEEP","weight":1.0,"range":13.0,"force":22,"radius":2.7,"effector":"leg_fr","trajectory":"hook","needs":{"leg_fr":0.45},"sound_pitch":1.0},
          "pounce_and_pin":{"base":"custom","label":"POUNCE AND PIN","weight":1.5,"range":12.5,"min_range":7.0,"force":14,"radius":2.6,"effector":"torso","lunge":2.4,"wind":0.9,"cooldown":14.0,"requires_free":True,
                            "hold":{"label":"PINNED","duration":2.8,"tick":0.55,"tick_radius":1.7,"tick_force":8.0,"region":"chest","end":"drop","distance":5.6}},
          "web_spray":{"base":"ranged","label":"WEB SPRAY","ranged":"web","weight":2.0,"range":30.0,"min_range":9.0,"close_distance":9.0,"close_weight":0.4,
                       "wind":1.1,"commit":0.3,"follow":0.2,"recover":1.2,"cooldown":13.0,"muzzle":"head","speed":30.0,"shape":"cube4","scale":0.85,"tint":"e8e8de","glow":0.25,
                       "hit_radius":2.2,"radius":1.8,"force":4.0,"status":{"web":6.5,"web_slow":0.42,"tether":True},"status_reach":10.0,"charge_orb":False,"life":3.0,"aim_region":"chest"}},
        priority_targets=["thorax","head"], notes="Unfair advantage: speed, stability and web control. Sacrifice: thin individually-killable legs and a soft abdomen.")

# ---------------------------------------------------------------- FLYING DRAGON
def flying_dragon():
    R, rig = biped.build(hip_x=2.6, hip_y=11.0, knee_dx=0.2, knee_y=7.0, knee_z=-1.6, thigh_r=2.0, shin_r=1.35, foot_w=1.6, foot_l=3.0, foot_z=-1.6,
        pelvis=(0,12.0,1.0,3.0,1.9,3.0), abdomen=(0,15.2,0.2,2.9,2.4,2.8), chest=(0,19.4,-0.6,3.8,3.4,3.2),
        neck=(0,23.6,-2.8,1.6,2.2,1.6), head=(0,26.2,-5.8,2.3,1.9,3.8),
        sh_x=4.0, sh_y=20.6, sh_r=(1.5,1.5,1.5), elbow=(4.8,17.6,-2.2), wrist=(4.8,15.4,-4.2), fist=(4.8,14.4,-5.0,1.3,1.1,1.6), ua_r=1.1, fa_r=1.0, lean=-0.07)
    R["tail_1"] = {"major":"tail","vols":[E(0,12.0,5.2,2.4,2.2,3.4)]}
    R["tail_2"] = {"major":"tail","vols":[E(0,10.4,9.6,1.9,1.8,3.0)]}
    R["tail_3"] = {"major":"tail","vols":[E(0,8.4,13.6,1.5,1.4,2.8)]}
    R["tail_4"] = {"major":"tail","vols":[E(0,6.4,17.6,1.1,1.0,2.8)]}
    extras = [{"id":"tail","parent":"torso","regions":["tail_1","tail_2","tail_3","tail_4"],"pivots":[[0,12.0,2.6],[0,10.6,7.2],[0,8.8,11.4],[0,6.8,15.4]],"axis":[0,1,0],"sway":{"amp":0.2,"speed":1.5,"lag":0.6},"tip":[0,6.0,20.0],"effector":"tail_tip"}]
    limbs = [{"id":"tail","regions":["tail_1","tail_2","tail_3","tail_4"],"kind":"tail","fail":0.3}]
    for s, side in ((-1,"left"),(1,"right")):
        a = f"{side}_wing_a"; b = f"{side}_wing_b"
        R[a] = {"major":side+"_wing","vols":cap((s*4.2,21.6,0.8),(s*11.0,26.0,2.4),1.0)+[B(s*8.2,24.6,3.2,4.4,0.55,3.4)]}
        R[b] = {"major":side+"_wing","vols":cap((s*11.0,26.0,2.4),(s*19.0,29.5,3.4),0.9)+[B(s*15.6,28.0,4.6,5.0,0.5,4.2)]}
        extras.append({"id":side+"_wing","parent":"torso","regions":[a,b],"pivots":[[s*4.2,21.6,0.8],[s*11.0,26.0,2.4]],"axis":[0,0,1],"sign":float(s),
                       "flap":{"ground":0.10,"air":0.75,"speed":4.6,"lag":0.4,"rest":0.35},"sweep":1.1,"sweep_axis":[0,1,0],"tip":[s*20.0,29.5,3.6],"effector":side+"_wing_tip"})
        limbs.append({"id":side+"_wing","regions":[a,b],"kind":"wing","fail":0.2})
    def tags(live):
        t = front_tags("head", [(-1,27),(1,27)], "glow")(live)
        return t
    return finish_biped(R, rig, id="flying_dragon", name="FLYING DRAGON", kind="aerial", palette="7a2a24", slim=0.9, tags_fn=tags, extras=extras, limbs=limbs,
        special={"flight":{"hover":9.0,"duration":13.0,"min_lift":0.4,"dive_lift":0.6,"takeoff_seconds":1.5,"landing_cooldown":9.0,"air_speed_bonus":0.9,"initial_cooldown":4.0}},
        fatal=[{"regions":["head","neck"],"fraction":0.2,"reason":"HEAD AND NECK DESTROYED"},{"regions":["torso"],"fraction":0.3,"reason":"TORSO STRUCTURE FAILED"}],
        look={"skin":"7a2a24","limb":"6a231f","joint":"2e1210","head":"8a3028","accent":"d8a24a","wing":"a23a30","interior":"2a0f0c","glow":"ffb02a","face":False,
              "tones":{"left_wing_a":"limb","right_wing_a":"limb","left_wing_b":"wing","right_wing_b":"wing","tail_4":"joint"}},
        behavior={"speed":2.7,"acceleration":0.9,"turn_rate":0.5,"turn_acceleration":0.7,"step_seconds":0.9,"preferred_range":12.5,"retreat":0.4,"circle":1.2,"reposition_interval":6.0,"reposition_seconds":3.0,"takeoff_distance":18.0,"land_distance":7.5,"crush_radius":3.2},
        attacks={
          "dragon_bite":{"base":"headbutt","label":"BITE","weight":2.0,"range":12.5,"force":21,"radius":2.2,"lunge":2.2,"flight":"ground","needs":{"head":0.4},"sound_pitch":1.0},
          "dragon_claw":{"base":"right_punch","label":"CLAW","weight":1.4,"range":10.5,"force":16,"radius":1.8,"flight":"ground"},
          "tail_strike":{"base":"custom","label":"TAIL STRIKE","weight":1.2,"range":17.0,"force":20,"radius":2.4,"effector":"tail_tip","trajectory":"spin","spin_turns":0.8,"flight":"ground","needs":{"tail":0.4},"wind":0.9,"commit":0.7,"recover":1.5,"sound_pitch":0.9},
          "wing_buffet":{"base":"custom","label":"WING BUFFET","weight":1.2,"range":19.0,"force":22,"radius":2.8,"effector":"right_wing_tip","trajectory":"straight","flight":"ground","needs":{"right_wing":0.5},"wind":0.85,"sound_pitch":0.8},
          "dive_attack":{"base":"body_charge","label":"DIVE ATTACK","weight":2.4,"range":28.0,"min_range":12.0,"force":28,"radius":3.0,"trajectory":"charge","charge_speed":17.0,"flight":"air","dive":True,"wind":0.9,"commit":1.0,"recover":1.7,"cooldown":9.0,"sound_pitch":0.8},
          "aerial_fire":{"base":"ranged","label":"AERIAL FIRE BLAST","ranged":"stream","weight":2.2,"range":22.0,"min_range":8.0,"close_distance":8.0,"close_weight":0.4,
                         "wind":0.8,"commit":0.6,"follow":0.2,"recover":0.9,"duration":0.6,"cooldown":8.5,"muzzle":"head","depends":["head"],"needs":{"head":0.4},
                         "tick":0.12,"tick_radius":1.35,"force":6.0,"track":1.4,"arc_error":0.2,"charge_orb":False,"aim_region":"chest","sound_pitch":1.0}},
        priority_targets=["left_shoulder","right_shoulder","head"], notes="Unfair advantage: flight, dives and mobile fire. Sacrifice: wings cost real cubes; losing them grounds the dragon.")

SPECS = [f() for f in (eyeball_beast, blob, tarantula, flying_dragon)]
