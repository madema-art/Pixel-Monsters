"""Initial cube blocking for the editable Blender sculpture; never the runtime exporter.

Run this file through Blender MCP. The separately saved .blend is the authoring source.
Actual object transforms, region properties and anchor empties are exported by export_ape.py.
"""
import bpy, bmesh, sys, math, json
from pathlib import Path
from mathutils import Vector
ROOT = Path(r'D:/Godot/Projects/Pixel-Monsters')
sys.path.insert(0, str(ROOT/'tools/roster'))
from voxel import E, claim, components, NB

regions = {}
def region(name, major, *vols): regions[name] = dict(major=major, vols=list(vols))
region('pelvis','torso',E(0,8,1.5,3.6,2,2.5))
region('abdomen','torso',E(0,11,0.5,3.8,3,2.6))
region('chest','torso',E(0,14.5,0,6.8,4.4,3.5),E(0,18.6,1,4.1,2.2,2.4))
region('neck','head',E(0,17,-2,2.5,2,2))
region('head','head',E(0,18,-4.8,2.9,2.9,2.4))
for side,s in [('left',-1),('right',1)]:
    region(side+'_shoulder',side+'_arm',E(s*7.1,15.5,-0.7,3.2,3.1,2.8))
    region(side+'_upper_arm',side+'_arm',E(s*8.2,12.5,-1.4,2.5,3.4,2.5))
    region(side+'_forearm',side+'_arm',E(s*10,8,-2.4,2.8,3.5,2.7))
    region(side+'_fist',side+'_arm',E(s*10.8,3.6,-3.7,3.1,2.6,3),E(s*8.5,4,-5,1.3,1.7,1.2))
    region(side+'_thigh',side+'_leg',E(s*3,6.1,1,2.3,2.5,2.4))
    region(side+'_shin',side+'_leg',E(s*3.1,3.4,-0.2,1.6,1.8,1.8))
    region(side+'_foot',side+'_leg',E(s*3.3,1.1,-1.3,2.2,0.8,2.6))
live = claim(regions,1.0)
# An actual open roaring mouth, with a cubical rim and recessed eye sockets.
for c in list(live):
    x,y,z=c
    if abs(x)<=1 and 15<=y<=17 and z<=-5: del live[c]
    if abs(x)==2 and y==19 and z<=-7: del live[c]
tags={}; protected=set()
def face(x,y,z,tag='face'):
    c=(x,y,z); live[c]=('head',0); tags[c]=tag; protected.add(c)
for x in range(-3,4): face(x,20,-7,'skin')
for x in [-2,2]:
    face(x,19,-6,'glow')
    for y in range(15,19): face(x,y,-7)
for x in range(-2,3):
    face(x,18,-7); face(x,14,-7)
    face(x,18,-6); face(x,14,-6)
for x in [-1,1]: face(x,17,-7,'teeth'); face(x,15,-7,'teeth')
face(0,18,-8,'nose'); face(-1,18,-8,'nose'); face(1,18,-8,'nose')
for x in range(-1,2):
    for y in range(15,18): face(x,y,-4,'mouth')
# Remove enclosed cells rather than spending budget on unseen filler. Preserve the
# face-connected sculpture; the shell is itself physical/destructible, not a mesh.
def neighbours(c): return [(c[0]+d[0],c[1]+d[1],c[2]+d[2]) for d in NB]
original=set(live)
inside=[c for c in live if c not in protected and all(n in live for n in neighbours(c))]
for c in sorted(inside,key=lambda c:(c[1],c[0],c[2])):
    old=live.pop(c)
    if len(components(live))!=1: live[c]=old
# Keep all shell surfaces and fill only exposed contours if the budget needs more.
while len(live)<1000:
    options={n for c in live for n in neighbours(c) if n not in original and n not in live and n[1]>=1}
    scored=[]
    for q in options:
        if abs(q[0])<=1 and 15<=q[1]<=17 and q[2]<=-5: continue
        best=min((sum(((q[i]-v[i+1])/v[i+4])**2 for i in range(3)),name) for name,r in regions.items() for v in r['vols'])
        if any(n not in live and n!=q for n in neighbours(q)): scored.append((best,q))
    (sc,name),q=min(scored); live[q]=(name,sc)
if len(live)>1000:
    counts={n:sum(r==n for r,_ in live.values()) for n in regions}
    for c in sorted(live,key=lambda c:live[c][1],reverse=True):
        if len(live)==1000: break
        name,sc=live[c]
        if c in protected or counts[name]<=12: continue
        old=live.pop(c)
        if len(components(live))!=1: live[c]=old
        else: counts[name]-=1
assert len(live)==1000 and len(components(live))==1

scene=bpy.data.scenes.new('GIANT_APE_Sculpt_Studio')
bpy.context.window.scene=scene
scene['authoring']='Exactly 1000 physical cubes. Edit cube locations/region properties, then export actual objects.'
scene.render.engine='CYCLES'; scene.cycles.samples=24
scene.render.resolution_x=1100; scene.render.resolution_y=1000; scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Ape_Studio_World'); scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.22,.24,.27,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.5
scene.view_settings.view_transform='AgX'
body=bpy.data.collections.new('GIANT_APE_1000_DESTRUCTIBLE_CUBES'); scene.collection.children.link(body)
cols={}
for name in regions:
    col=bpy.data.collections.new('APE_'+name); body.children.link(col); cols[name]=col
colors={'skin':'393632','limb':'302e2b','face':'877c68','chest':'968975','teeth':'ead8a8','nose':'272320','mouth':'3f1614','glow':'ff452b'}
materials={}
for tag,color in colors.items():
    rgb=tuple(int(color[i:i+2],16)/255 for i in (0,2,4))
    mat=bpy.data.materials.new('Ape_'+tag); mat.diffuse_color=(*rgb,1); mat.use_nodes=True
    bs=mat.node_tree.nodes.get('Principled BSDF'); bs.inputs['Base Color'].default_value=(*rgb,1); bs.inputs['Roughness'].default_value=.87
    if tag=='glow': bs.inputs['Emission Color'].default_value=(*rgb,1); bs.inputs['Emission Strength'].default_value=2
    materials[tag]=mat
mesh=bpy.data.meshes.new('Ape_Unit_Cube_Bevelled')
bm=bmesh.new(); bmesh.ops.create_cube(bm,size=.96)
bmesh.ops.bevel(bm,geom=list(bm.edges),offset=.022,segments=1,affect='EDGES'); bm.to_mesh(mesh); bm.free()
for mat in materials.values(): mesh.materials.append(mat)
for index,(c,(name,_)) in enumerate(sorted(live.items())):
    x,y,z=c; tag=tags.get(c,'')
    if not tag:
        if name=='chest' and z<=-2 and 11<=y<=17: tag='chest'
        elif name=='head' and z<=-6: tag='face'
        elif name.endswith('fist') and z<=-5: tag='face'
        else: tag='skin' if name in ['head','chest','neck'] else 'limb'
    ob=bpy.data.objects.new(f'Ape_Cube_{index:04}_{name}',mesh); cols[name].objects.link(ob)
    ob.location=(x,-z,y); ob['pm_body_cube']=True; ob['region']=name; ob['major']=regions[name]['major']; ob['tag']=tag
    for slot in ob.material_slots: slot.link='OBJECT'; slot.material=materials[tag]
rig={'shoulder':[7.1,15.5,-.7],'elbow':[9,11,-1.8],'hand':[10.8,3.6,-3.7],
 'idle_hand':[10.8,3.6,-3.7],'guard':[6,17,-6],'hip':[3,8,1.5],'knee':[3.1,4.5,-.6],
 'foot':[3.3,1,-1.3],'pivot':[0,8,1.5],'head':[0,18,-7],'head_pivot':[0,16,-3],
 'torso':[0,15,-3],'neck':[0,17,-2],'wrist':[10.5,5.5,-3.2],'fist':[10.8,3.6,-3.7]}
anchors=bpy.data.collections.new('APE_RIG_ANCHORS'); scene.collection.children.link(anchors)
for name,p in rig.items():
    ob=bpy.data.objects.new('Ape_Anchor_'+name,None); anchors.objects.link(ob)
    ob.location=(p[0],-p[2],p[1]); ob.empty_display_type='SPHERE'; ob.empty_display_size=.35; ob['pm_rig_anchor']=name
scene['stance_lean']=-.04
reference=bpy.data.images.load(r'C:/Users/matta/AppData/Local/Temp/codex-clipboard-ea015cca-0642-4060-a0fb-638e783021d0.png'); reference.pack()
ref=bpy.data.objects.new('Authoritative_Reference_Sheet',None); scene.collection.objects.link(ref); ref.empty_display_type='IMAGE'; ref.data=reference; ref.empty_display_size=30; ref.location=(40,0,12); ref.hide_render=True
for name,pos,power,size in [('Key',(15,25,35),15000,18),('Fill',(-24,16,20),9000,16),('Rim',(8,-22,32),18000,14)]:
    light=bpy.data.lights.new('Ape_Studio_'+name,'AREA'); light.energy=power; light.shape='DISK'; light.size=size
    ob=bpy.data.objects.new(light.name,light); scene.collection.objects.link(ob); ob.location=pos; ob.rotation_euler=(Vector((0,0,11))-ob.location).to_track_quat('-Z','Y').to_euler()
camera=bpy.data.cameras.new('Ape_Review_Camera'); ob=bpy.data.objects.new(camera.name,camera); scene.collection.objects.link(ob); scene.camera=ob
camera.type='ORTHO'; camera.ortho_scale=33; ob.location=(0,65,12); ob.rotation_euler=(Vector((0,1,11))-ob.location).to_track_quat('-Z','Y').to_euler()
scene.render.image_settings.file_format='PNG'
(ROOT/'art/creatures/renders').mkdir(parents=True,exist_ok=True)
bpy.context.view_layer.update()
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/creatures/giant_ape.blend'),copy=True)
result={'cubes':len(live),'regions':{n:sum(r==n for r,_ in live.values()) for n in regions},'scene':scene.name,'enclosed':sum(all(n in live for n in neighbours(c)) for c in live)}
