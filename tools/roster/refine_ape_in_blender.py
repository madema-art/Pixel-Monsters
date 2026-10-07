"""Documented studio refinement of actual Blender objects after orthographic review."""
import bpy,sys
from pathlib import Path
from mathutils import Vector
ROOT=Path(r'D:/Godot/Projects/Pixel-Monsters')
sys.path.insert(0,str(ROOT/'tools/roster'))
from voxel import components,NB
s=bpy.context.scene
objects=[o for o in s.objects if o.get('pm_body_cube')]
def cell(o): return (round(o.location.x),round(o.location.z),round(-o.location.y))
live={cell(o):o for o in objects}; moves=[]
def exposed(c,cells): return any((c[0]+d[0],c[1]+d[1],c[2]+d[2]) not in cells for d in NB)
def move(a,b):
    if a not in live or b in live:return False
    ob=live.pop(a);live[b]=ob
    if len(components(live))!=1 or not all(exposed(c,live) for c in live):
        del live[b];live[a]=ob;return False
    ob.location=(b[0],-b[2],b[1]);moves.append([list(a),list(b)]);return True
# Recess a spinal valley while leaving both lat contours intact.
for y in range(10,20):
    rear=sorted([c for c,o in live.items() if o['region']=='chest' and c[0]==0 and c[1]==y],key=lambda c:-c[2])
    if rear: move(rear[0],(0,y,rear[0][2]-1))
# Four stepped knuckles and an inboard curled thumb on each physical fist.
for sign in [-1,1]:
    for x in [9,10,11,12]:
        for y in [2,3]:
            front=sorted([c for c,o in live.items() if o['region'].endswith('fist') and c[0]==sign*x and c[1]==y],key=lambda c:c[2])
            if front:move(front[0],(sign*x,y,front[0][2]-1))
# Studio colors are linear shader inputs; convert the authored sRGB palette.
for mat in {o.active_material for o in objects}:
    bs=mat.node_tree.nodes['Principled BSDF']; rgba=bs.inputs['Base Color'].default_value
    bs.inputs['Base Color'].default_value=tuple(v**2.2 for v in rgba[:3])+(1,)
    mat.diffuse_color=bs.inputs['Base Color'].default_value
s['refinement_moves']=str(moves)
s['review_iterations']='1: contour holes corrected; 2: wider lower barrel chest; 3: spine valley and curled knuckles, linear materials.'
# Remove only earlier studies created by this tool, preserving the user's default scene.
for old in list(bpy.data.scenes):
    if old!=s and old.name.startswith('GIANT_APE_Sculpt_Studio'):
        for ob in list(old.objects): bpy.data.objects.remove(ob,do_unlink=True)
        bpy.data.scenes.remove(old)
s.name='GIANT_APE_Sculpt_Studio'
s.camera.location=(0,65,12);s.camera.rotation_euler=(Vector((0,1,11))-s.camera.location).to_track_quat('-Z','Y').to_euler()
bpy.context.view_layer.update()
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/creatures/giant_ape.blend'),copy=True)
result={'cubes':len(objects),'moves':len(moves),'connected':len(components(live)),'exposed':sum(exposed(c,live) for c in live)}
