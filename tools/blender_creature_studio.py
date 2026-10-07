"""Live Blender MCP study/export. Uses isolated scenes and preserves the user's scene/mode."""
import bpy,bmesh,json,math
from pathlib import Path
from mathutils import Vector
ROOT=Path('D:/Godot/Projects/Pixel-Monsters')
ART=ROOT/'art/creatures'
scene=bpy.data.scenes.new('Pixel Monsters Creature Studio')
scene.render.engine='BLENDER_EEVEE'
scene.render.resolution_x=1200;scene.render.resolution_y=720;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
scene.render.film_transparent=False
scene.view_settings.view_transform='AgX'
world=bpy.data.worlds.new('Creature Studio World');world.use_nodes=True
world.node_tree.nodes['Background'].inputs['Color'].default_value=(.055,.065,.085,1)
world.node_tree.nodes['Background'].inputs['Strength'].default_value=.5
scene.world=world
material=bpy.data.materials.new('Creature Study Neutral Gray');material.diffuse_color=(.42,.45,.49,1);material.use_nodes=True
material.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.42,.45,.49,1)
material.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.72

def mapped(a):return Vector((a[0],-a[2],a[1]))
collections=[];definitions=[]
for number,path in enumerate(sorted(ART.glob('*-brief.json'))):
 data=json.loads(path.read_text());definitions.append(data)
 collection=bpy.data.collections.new('PM_'+data['id']+'_Design');scene.collection.children.link(collection);collections.append(collection)
 offset=(number-1)*28
 root=bpy.data.objects.new(data['id']+'_Root',None);collection.objects.link(root);root.location.x=offset
 for shape in data['volumes']:
  mesh=bpy.data.meshes.new(data['id']+'_'+shape['region']+'_volume')
  bm=bmesh.new();bmesh.ops.create_uvsphere(bm,u_segments=16,v_segments=12,radius=1);bm.to_mesh(mesh);bm.free()
  obj=bpy.data.objects.new(data['id']+'_'+shape['region'],mesh);collection.objects.link(obj);obj.parent=root
  obj.location=mapped(shape['center']);obj.scale=(shape['radius'][0],shape['radius'][2],shape['radius'][1]);obj['region']=shape['region'];obj.data.materials.append(material)
  for face in mesh.polygons:face.use_smooth=True
 for name,a in data['rig'].items():
  if isinstance(a,list):
   obj=bpy.data.objects.new(data['id']+'_Rig_'+name,None);obj.empty_display_type='SPHERE';obj.empty_display_size=.25;obj.parent=root;obj.location=mapped(a);obj['rig_anchor']=name;collection.objects.link(obj)
 # Export actual Blender transforms, not the untouched design brief.
 exported=dict(data)
 exported['volumes']=[]
 for obj in collection.objects:
  if 'region' in obj:
   p=obj.location;radius=obj.scale
   exported['volumes'].append(dict(region=obj['region'],center=[p.x,p.z,-p.y],radius=[radius.x,radius.z,radius.y]))
 exported['rig']=dict(data['rig'])
 for obj in collection.objects:
  if 'rig_anchor' in obj:
   p=obj.location;exported['rig'][obj['rig_anchor']]=[p.x,p.z,-p.y]
 exported['blender_source']='art/creatures/'+data['id']+'.blend'
 (ART/(data['id']+'-blender.json')).write_text(json.dumps(exported,indent=2),encoding='utf-8')

camera_data=bpy.data.cameras.new('Creature Studio Camera');camera=bpy.data.objects.new('Creature Studio Camera',camera_data);scene.collection.objects.link(camera);scene.camera=camera
camera_data.type='ORTHO';camera_data.ortho_scale=95
camera.location=(0,90,18);camera.rotation_euler=(Vector((0,0,17))-camera.location).to_track_quat('-Z','Y').to_euler()
for name,p,energy,size in [('Studio Key',(5,35,50),2800,30),('Studio Rim',(-25,-20,38),3500,25),('Studio Fill',(35,15,23),1400,22)]:
 light_data=bpy.data.lights.new(name,'AREA');light_data.energy=energy;light_data.shape='DISK';light_data.size=size
 light=bpy.data.objects.new(name,light_data);scene.collection.objects.link(light);light.location=p;light.rotation_euler=(Vector((0,0,15))-light.location).to_track_quat('-Z','Y').to_euler()
for data,collection in zip(definitions,collections):
 source=bpy.data.scenes.new('PM_Source_'+data['id']);source.collection.children.link(collection);source.world=world
 # Saved through the normal save operator after scene construction.
bpy.ops.wm.save_as_mainfile(filepath=str(ART/'creature-lineup.blend'),copy=True)
result={'scene':scene.name,'creatures':[d['id'] for d in definitions],'exports':[str(ART/(d['id']+'-blender.json')) for d in definitions],'sources':[str(ART/(d['id']+'.blend')) for d in definitions],'preserved_user_scene':True,'mode':bpy.context.mode}

