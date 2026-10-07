"""Parametric biped: builds the 19 standard regions + rig anchors (right side +x, front is -z)."""
from voxel import E, B, cap, math

def capbox(p0,p1,r):
    d=math.dist(p0,p1); n=max(1,int(d/(r*0.9)))
    return [B(*(p0[k]+(p1[k]-p0[k])*i/n for k in range(3)),r,r,r) for i in range(n+1)]

REG = ["chest","abdomen","pelvis","neck","head"]
SIDE_PARTS = ["shoulder","upper_arm","forearm","fist","thigh","shin","foot"]

def major(name):
    if name.startswith("left_") or name.startswith("right_"):
        part=name.split("_",1)[1]
        arm=part in ("shoulder","upper_arm","forearm","fist")
        return ("left_" if name.startswith("left_") else "right_")+("arm" if arm else "leg")
    return "head" if name in ("head","neck") else "torso"

DEFAULT = dict(
    hip_x=2.0, hip_y=11.0, knee_dx=0.0, knee_y=6.2, knee_z=0.0, foot_dx=0.0, foot_z=-1.0, foot_w=1.8, foot_l=2.3,
    thigh_r=1.9, shin_r=1.5,
    pelvis=(0,11.8,0,3.4,1.7,2.1), abdomen=(0,14.8,0,2.8,2.1,2.0), chest=(0,19.0,0,4.4,3.2,2.5),
    neck=(0,22.4,-0.2,1.5,1.1,1.5), head=(0,25.2,-0.4,2.5,2.8,2.2),
    sh_x=4.8, sh_y=20.0, sh_r=(1.9,1.8,1.7),
    elbow=(6.0,15.6,-0.2), wrist=(6.4,12.4,-0.6), fist=(6.5,10.6,-0.8,1.5,1.2,1.5),
    ua_r=1.5, fa_r=1.5,
    boxy=False,
)

def build(**over):
    p=dict(DEFAULT); p.update(over)
    R={}; rig={}
    def vol(shape,t):
        return [B(*t)] if shape else [E(*t)]
    bx=p['boxy']
    cp=capbox if bx else cap
    SH=B if p.get('boxy_joints',bx) else E
    R['pelvis']={'major':'torso','vols':[ (B if bx else E)(*p['pelvis']) ]}
    R['abdomen']={'major':'torso','vols':[ (B if bx else E)(*p['abdomen']) ]}
    R['chest']={'major':'torso','vols':[ (B if bx else E)(*p['chest']) ]}
    R['neck']={'major':'head','vols':[ E(*p['neck']) ]}
    R['head']={'major':'head','vols':[ (B if p.get('boxy_head') else E)(*p['head']) ]}
    for side,s in (("left",-1),("right",1)):
        hip=(s*p['hip_x'],p['hip_y'],0.0)
        knee=(s*(p['hip_x']+p['knee_dx']),p['knee_y'],p['knee_z'])
        foot=(s*(p['hip_x']+p['foot_dx']),1.0,p['foot_z'])
        ankle=(foot[0],foot[1]+1.6,foot[2]*0.35)
        R[side+'_thigh']={'major':side+'_leg','vols':cp(hip,knee,p['thigh_r'])}
        R[side+'_shin']={'major':side+'_leg','vols':cp(knee,ankle,p['shin_r'])}
        R[side+'_foot']={'major':side+'_leg','vols':[SH(foot[0],foot[1],foot[2],p['foot_w'],0.9,p['foot_l'])]}
        sh=(s*p['sh_x'],p['sh_y'],0.0)
        el=(s*p['elbow'][0],p['elbow'][1],p['elbow'][2])
        wr=(s*p['wrist'][0],p['wrist'][1],p['wrist'][2])
        f=p['fist']; fc=(s*f[0],f[1],f[2])
        R[side+'_shoulder']={'major':side+'_arm','vols':[SH(*sh,*p['sh_r'])]}
        R[side+'_upper_arm']={'major':side+'_arm','vols':cp(sh,el,p['ua_r'])}
        R[side+'_forearm']={'major':side+'_arm','vols':cp(el,wr,p['fa_r'])}
        R[side+'_fist']={'major':side+'_arm','vols':[SH(*fc,f[3],f[4],f[5])],'w':0.9}
        if side=="right":
            rig.update({"shoulder":list(sh),"elbow":list(el),"hand":list(fc),"hip":list(hip),"knee":list(knee),"foot":list(foot),
                        "idle_hand":[fc[0]*0.85,fc[1]+p.get('idle_lift',2.6),fc[2]-2.4],
                        "guard":[3.0,p['head'][1]+0.5,-3.8]})
    rig["pivot"]=[0.0,p['abdomen'][1],0.0]
    rig["head"]=[0.0,p['head'][1],p['head'][2]-p['head'][5]*0.8]
    rig["head_pivot"]=[0.0,p['neck'][1]-0.6,0.0]
    rig["torso"]=[0.0,p['chest'][1],-p['chest'][5]-0.2]
    rig["stance_lean"]=p.get('lean',0.0)
    return R,rig
