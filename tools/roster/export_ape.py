"""Export the actual editable Giant Ape Blender scene, not procedural proxy volumes.

Run through Blender MCP with GIANT_APE_Sculpt_Studio active after saving artist edits.
The authored JSON is the reproducible cache used by compile_roster.py giant_ape.
"""
import bpy,json,hashlib,sys
from pathlib import Path
from collections import Counter
ROOT=Path(r'D:/Godot/Projects/Pixel-Monsters')
sys.path.insert(0,str(ROOT/'tools/roster'))
from voxel import components,NB
s=bpy.context.scene
cells=[]
for o in s.objects:
    if not o.get('pm_body_cube'):continue
    assert o.type=='MESH' and not o.hide_render and not o.hide_get(),o.name
    p=o.matrix_world.translation
    position=(p.x,p.z,-p.y)
    c=tuple(round(v) for v in position)
    assert max(abs(position[i]-c[i]) for i in range(3))<.001,('nonlattice',o.name)
    assert all(abs(v-1)<.001 for v in o.scale),('nonunit',o.name)
    cells.append(dict(cell=list(c),region=o['region'],major=o['major'],tag=o['tag']))
cells.sort(key=lambda c:(c['region'],c['cell'][1],c['cell'][0],c['cell'][2]))
positions={tuple(c['cell']) for c in cells}
assert len(cells)==len(positions)==1000
assert len(components(positions))==1
assert all(any((c[0]+d[0],c[1]+d[1],c[2]+d[2]) not in positions for d in NB) for c in positions),'enclosed filler'
out=ROOT/'data/creatures/giant_ape.json'
d=json.loads(out.read_text(encoding='utf-8'))
d['cells']=cells;d['allocation']=dict(sorted(Counter(c['region'] for c in cells).items()))
d['majors']={c['region']:c['major'] for c in cells}
d['bounds']={key:[fn(c[i] for c in positions) for i in range(3)] for key,fn in [('min',min),('max',max)]}
d['fit_scale']=1.0
d['rig']={}
for o in s.objects:
    if not o.get('pm_rig_anchor'):continue
    p=o.matrix_world.translation;d['rig'][o['pm_rig_anchor']]=[round(p.x,3),round(p.z,3),round(-p.y,3)]
d['rig']['stance_lean']=float(s['stance_lean'])
d['rig']['paired_smash']=True
d['rig']['overhead_lift']=18.0
d['rig']['fist_ground_clearance']=0.06
d['look'].update(skin='393632',limb='302e2b',joint='302e2b',head='393632',face='877c68',chest='968975',teeth='ead8a8',nose='272320',mouth='3f1614',glow='ff452b')
# Explicit cube tags replace the old automatic, painted face. Keep face_color
# separate from the boolean face flag understood by the renderer.
d['look']['face_color']=d['look'].pop('face');d['look']['face']=False
d['look']['rim_color']='c7b8a0';d['look']['rim_strength']=0.12
for entry in d['cells']:
    if entry['tag']=='face':entry['tag']='face_color'
d['geometry_sha256']=hashlib.sha256(json.dumps(d['cells'],sort_keys=True).encode()).hexdigest()
d['tips']={'right_shoulder':{'follow':'torso','point':[7.1,15.5,-2.5]}}
d['attacks']['shoulder_tackle']['effector']='right_shoulder'
d['authoring']={'source':'art/creatures/giant_ape.blend','scene':s.name,'coordinates':'Blender (x,y,z) -> Godot (x,z,-y)','exporter':'tools/roster/export_ape.py','exposed_cubes':1000,'iterations':str(s.get('review_iterations',''))}
text=json.dumps(d,indent=1)+'\n'
out.write_text(text,encoding='utf-8')
(ROOT/'art/creatures/giant_ape.authored.json').write_text(text,encoding='utf-8')
result={'count':len(cells),'allocation':d['allocation'],'bounds':d['bounds'],'export':str(out)}
