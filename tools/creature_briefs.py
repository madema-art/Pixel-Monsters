"""Initial original proportion briefs; Blender export becomes the authoritative geometry."""
import json
from pathlib import Path
ROOT=Path(r'D:\Godot\Projects\Pixel-Monsters')
def volume(name,p,r):return dict(region=name,center=p,radius=r)
def creature(id,name,kind,allocation,core,limbs,anchors,behavior,attacks,color):
 shapes=[volume(k,*v) for k,v in core.items()]
 for side,s in [('left',-1),('right',1)]:
  for region,(p,r) in limbs.items():shapes.append(volume(side+'_'+region,[s*p[0],p[1],p[2]],r))
 alloc=dict(allocation)
 for side in ['left','right']:
  for k,v in allocation['limbs'].items():alloc[side+'_'+k]=v
 del alloc['limbs'];assert sum(alloc.values())==1000
 data=dict(id=id,name=name,kind=kind,palette=color,allocation=alloc,volumes=shapes,rig=anchors,behavior=behavior,attacks=attacks,weakpoints=dict(shoulder=.25,thigh=.21,shin=.16,foot=.17,neck=.17,head=.17,torso=.277))
 (ROOT/'art/creatures'/f'{id}-brief.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
 return data
common=dict(speed=2.2,acceleration=.85,turn_rate=.44,turn_acceleration=.6,step_seconds=1.05,balance=1.,preferred_range=10.,retreat=.3,circle=.2,pursuit=1.,aggression=.85,evade=.18,reposition_seconds=3.8,reposition_interval=9.,charge_weight=0.,charge_distance=18.)
def move(base,label,weight,range,power,radius,trajectory='straight',**extra):return dict(base=base,label=label,weight=weight,range=range,force=power,radius=radius,trajectory=trajectory,**extra)
creature('gorgeblock','GORGEBLOCK','brute',dict(head=96,neck=32,chest=210,abdomen=60,pelvis=54,limbs=dict(shoulder=44,upper_arm=46,forearm=48,fist=44,thigh=34,shin=30,foot=28)),
 dict(chest=([0,15,0],[6.2,2.9,3]),abdomen=([0,11.4,0],[3.6,2.0,2.4]),pelvis=([0,8,0],[3.7,1.5,2.3]),neck=([0,18.2,0],[2,1,2]),head=([0,20.7,-.5],[2.4,2.1,2.2])),
 dict(shoulder=([6.4,15.8,0],[2.3,1.8,2]),upper_arm=([8,13.1,0],[1.8,2.0,1.8]),forearm=([9,10.5,-.4],[2.0,1.9,1.9]),fist=([9,8.0,-.8],[2.3,1.5,2.0]),thigh=([2.4,5.9,0],[1.8,1.8,1.8]),shin=([2.4,3.4,0],[1.5,1.5,1.7]),foot=([2.4,1,-1.0],[2.2,.85,2.5])),
 dict(pivot=[0,8,0],shoulder=[6.3,15.8,0],elbow=[8.5,12,-.2],hand=[9,8,-.8],hip=[2.4,8,0],knee=[2.4,4.8,0],foot=[2.4,1,-1],idle_hand=[7.3,11,-4.5],head=[0,20.7,-2.6],head_pivot=[0,18.2,0],torso=[0,15,-2.8],guard=[4,18,-4],stance_lean=-.06),
 dict(common,preferred_range=9.2,speed=2.15,retreat=.12,circle=.12,balance=1.25,pursuit=1.0),
 dict(crush_hook=move('heavy_hook','CRUSHING HOOK',2.6,11.3,24,2.6,'hook'),body_shot=move('left_punch','BODY SHOT',1.1,10.8,16,1.9),pile_hammer=move('heavy_hook','PILE HAMMER',1.1,11.0,26,2.55,'overhead',wind=1.35,recover=1.8),shove=move('body_charge','SHOULDER SHOVE',.8,9.8,22,2.2,'drive'),short_kick=move('kick','GROUND BREAKER',.45,10.4,18,2.0,'kick')),'9a5d39')
creature('needlemantle','NEEDLEMANTLE','longarm',dict(head=80,neck=20,chest=128,abdomen=54,pelvis=62,limbs=dict(shoulder=20,upper_arm=34,forearm=56,fist=26,thigh=80,shin=72,foot=40)),
 dict(chest=([0,23,0],[3.0,2.9,2.1]),abdomen=([0,18.5,0],[2.1,2.1,1.8]),pelvis=([0,14.8,0],[2.7,1.6,2]),neck=([0,28,0],[1.0,1.2,1.3]),head=([0,31.5,-.3],[1.7,2.6,1.8])),
 dict(shoulder=([4.2,24,0],[1.35,1.6,1.3]),upper_arm=([5.2,20.3,0],[1.0,3.4,1.1]),forearm=([6.2,12.7,-.3],[1.2,4,1.2]),fist=([6.5,8,-.8],[1.4,1.25,1.8]),thigh=([2.0,10.7,0],[1.6,3.7,1.8]),shin=([2.0,5.8,0],[1.3,3.2,1.6]),foot=([2.0,1,-1.3],[2.0,.9,3])),
 dict(pivot=[0,14.8,0],shoulder=[4.2,24,0],elbow=[5.7,16.5,0],hand=[6.5,8,-.8],hip=[2,14.8,0],knee=[2,8.2,0],foot=[2,1,-1.3],idle_hand=[6.5,12.8,-4],head=[0,31.5,-2],head_pivot=[0,28,0],torso=[0,23,-2.1],guard=[3,29,-4],stance_lean=.02),
 dict(common,preferred_range=14.5,speed=2.25,acceleration=.72,turn_rate=.36,retreat=.95,circle=.8,pursuit=.9,balance=.8,evade=.3,reposition_seconds=4.8,reposition_interval=7.8),
 dict(lance_straight=move('right_punch','LANCE STRAIGHT',2.2,16.5,15,1.75),long_jab=move('left_punch','RANGING JAB',1.7,16,13,1.65),rake_backhand=move('heavy_hook','RAKING BACKHAND',1.5,15.8,19,2.1,'backhand'),pendulum=move('heavy_hook','PENDULUM SWEEP',1.1,16,20,2.3,'hook'),heel_kick=move('kick','LONG HEEL',.7,13,18,2.0,'kick')),'446f86')
creature('bastion','BASTION','headbutter',dict(head=248,neck=64,chest=204,abdomen=64,pelvis=56,limbs=dict(shoulder=24,upper_arm=16,forearm=18,fist=12,thigh=48,shin=40,foot=24)),
 dict(chest=([0,14.7,0],[5.0,2.7,3.3]),abdomen=([0,10.9,0],[3.0,2,2.4]),pelvis=([0,8,0],[3.3,1.8,2.2]),neck=([0,18,-.5],[3.2,1.5,2.7]),head=([0,22,-1.9],[4.8,3.5,3.8])),
 dict(shoulder=([5.7,15.2,0],[1.5,1.5,1.5]),upper_arm=([6.3,13.4,0],[1,1.4,1.2]),forearm=([6.4,11.6,-.3],[1.1,1.3,1.2]),fist=([6.4,10,-.8],[1.2,.8,1.2]),thigh=([2.7,5.9,0],[1.8,2,1.8]),shin=([2.7,3.5,0],[1.5,1.6,1.8]),foot=([2.7,1,-1.0],[2.0,.85,2.3])),
 dict(pivot=[0,8,0],shoulder=[5.7,15.2,0],elbow=[6.4,12.7,0],hand=[6.4,10,-.8],hip=[2.7,8,0],knee=[2.7,4.8,0],foot=[2.7,1,-1],idle_hand=[5.8,12,-3.7],head=[0,21.2,-5.3],head_pivot=[0,18,-.5],torso=[0,14.7,-3.0],guard=[4.8,18,-4],stance_lean=-.08),
 dict(common,preferred_range=9.7,speed=2.1,acceleration=.8,retreat=.6,circle=.2,balance=1.4,charge_weight=1.,charge_distance=19.,reposition_interval=8.),
 dict(ram_charge=move('headbutt','BASTION RAM',2.4,21,28,2.7,'charge',wind=1.25,commit=1.6,follow=.35,recover=2.0,min_range=13,charge_speed=6.0,collider=2.2),skull_crash=move('headbutt','SKULL CRASH',2.2,10.5,23,2.3,'head'),shoulder_check=move('body_charge','SHOULDER CHECK',1.6,10.8,25,2.5,'drive'),stub_hook=move('heavy_hook','SHORT ANCHOR HOOK',.6,10.5,15,1.85,'hook'),push_kick=move('kick','BRACING KICK',.5,10.8,17,2,'kick')),'7a8050')
print('Three 1000-cube original creature briefs saved.')
