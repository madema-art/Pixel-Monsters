"""Run through Blender MCP after compile_creatures.py; refresh cube previews and references."""
import bpy,bmesh,json
from pathlib import Path
from mathutils import Vector
ART=Path('D:/Godot/Projects/Pixel-Monsters/art/creatures')
DATA=ART.parent.parent/'data/creatures'
scene=bpy.data.scenes['Pixel Monsters Creature Studio']
camera=scene.camera
for path in DATA.glob('*.json'):
    data=json.loads(path.read_text(encoding='utf-8'))
    collection=bpy.data.collections['PM_'+data['id']+'_Design']
    cube=next(o for o in collection.objects if 'cube_count' in o)
    mesh=bpy.data.meshes.new(data['id']+'_Revised1000Cubes');bm=bmesh.new()
    for entry in data['cells']:
        x,y,z=entry['cell'];verts=bmesh.ops.create_cube(bm,size=.94)['verts']
        bmesh.ops.translate(bm,verts=verts,vec=Vector((x,-z,y)))
    bm.to_mesh(mesh);bm.free();cube.data=mesh
    mesh.materials.append(bpy.data.materials['Creature Study Neutral Gray'])
    source=bpy.data.scenes['PM_Source_'+data['id']]
    source.render.engine=scene.render.engine
    source.render.resolution_x=800;source.render.resolution_y=800
    source.render.resolution_percentage=100;source.view_settings.view_transform='AgX'
    root=next(o for o in collection.objects if o.name.endswith('_Root'))
    center=Vector((root.location.x,0,17));camera.data.ortho_scale=42
    for view,relative in [('front',(0,80,0)),('side',(80,0,0)),('three-quarter',(55,75,10))]:
        camera.location=center+Vector(relative)
        camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler()
        source.render.filepath=str(ART/(data['id']+'-'+view+'.png'))
        bpy.ops.render.render(scene=source.name,write_still=True)
    bpy.context.window.scene=source
    bpy.ops.wm.save_as_mainfile(filepath=str(ART/(data['id']+'.blend')),copy=True)
bpy.context.window.scene=scene
camera.data.ortho_scale=95;camera.location=(0,90,18)
camera.rotation_euler=(Vector((0,0,17))-camera.location).to_track_quat('-Z','Y').to_euler()
scene.render.filepath=str(ART/'cubes-front.png');bpy.ops.render.render(scene=scene.name,write_still=True)
material=bpy.data.materials['Creature Study Neutral Gray']
color=material.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value[:]
material.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.005,.005,.005,1)
scene.render.filepath=str(ART/'cubes-silhouette.png');bpy.ops.render.render(scene=scene.name,write_still=True)
material.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=color
bpy.ops.wm.save_as_mainfile(filepath=str(ART/'creature-lineup.blend'),copy=True)
result={'sources':[str(ART/(id+'.blend')) for id in ['gorgeblock','needlemantle','bastion']], 'preview_cubes_per_creature':1000,'revision':'Godot feedback incorporated'}
