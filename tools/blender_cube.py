"""Reproduce the original shared mesh in Blender without touching existing objects."""
import bpy, bmesh
from pathlib import Path

collection=bpy.data.collections.new('Pixel Monsters Export Assets')
bpy.context.scene.collection.children.link(collection)
mesh=bpy.data.meshes.new('PixelMonster_BevelCube')
bm=bmesh.new()
bmesh.ops.create_cube(bm,size=.94)
bmesh.ops.bevel(bm,geom=list(bm.edges),offset=.026,segments=1,affect='EDGES')
bm.to_mesh(mesh);bm.free();mesh.update()
obj=bpy.data.objects.new('PixelMonster_BevelCube',mesh)
collection.objects.link(obj)
mesh.calc_loop_triangles()
path=Path('D:/Godot/Projects/Pixel-Monsters/meshes/body_cube.obj')
path.parent.mkdir(parents=True,exist_ok=True)
with path.open('w') as f:
    f.write('# Original Pixel Monsters flat-faced beveled cube\ns off\n')
    index=1
    for triangle in mesh.loop_triangles:
        normal=mesh.polygons[triangle.polygon_index].normal
        for vi in triangle.vertices: f.write('v %f %f %f\n'%tuple(mesh.vertices[vi].co))
        for vi in triangle.vertices: f.write('vn %f %f %f\n'%tuple(normal))
        f.write('f '+' '.join('%d//%d'%(v,v) for v in range(index,index+3))+'\n')
        index+=3
print(path)
