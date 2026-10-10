class_name Wreckage
extends Node3D

# Destructible lane buildings. Each building is a grid of 2 m cubes; blasts from quakes, stomps, breath,
# boulders and fireballs remove cubes, and any cube left without ground support falls as physical debris.
# Presentation and destruction only: buildings do not block monsters (fight lanes stay clear).

const CELL := 2.0
const SPAWN_PER_FRAME := 28
const Look = preload("res://scripts/cinema/look.gd")
const SIZE := Vector3i(6, 9, 6)
const HALF := Vector3(6.0, 0.0, 6.0)   # half footprint in metres (SIZE.x * CELL / 2)

var debris: CubeDebris
var buildings: Array[Dictionary] = []
var mesh: Mesh
var material: StandardMaterial3D
var pending_spawn: Array[Dictionary] = []
var battle_occluders: Array[AABB] = []
var cells_removed := 0
var blasts := 0

func setup(debris_node: CubeDebris, placements: Array) -> void:
	debris=debris_node
	material=StandardMaterial3D.new()
	material.vertex_color_use_as_albedo=true
	material.roughness=0.9
	mesh=(load("res://meshes/body_cube.obj") as Mesh).duplicate()
	mesh.surface_set_material(0,material)
	for placement in placements:
		build_building(placement)

func build_building(placement: Dictionary) -> void:
	var origin: Vector3=placement.origin
	var tone: Color=placement.get("tone",Color("5d6a72"))
	var index := {}
	var cells: Array[Dictionary] = []
	for x in SIZE.x:
		for y in SIZE.y:
			for z in SIZE.z:
				var p := Vector3i(x,y,z)
				var exterior := x==0 or z==0 or x==SIZE.x-1 or z==SIZE.z-1
				var color := tone
				if exterior and y>0 and y%2==1 and (x+y+z)%3!=0 and y<SIZE.y-1:
					color=Color("e0b77a") if (x*7+y*3+z)%5==0 else Color("2a3644")   # lit and dark windows
				color=color.darkened(0.04*float((x*13+y*7+z*5)%5))
				if y==SIZE.y-1: color=tone.darkened(0.25)                             # roof
				cells.append({"pos":p,"alive":true,"color":color})
				index[p]=cells.size()-1
	var renderer := MultiMeshInstance3D.new()
	renderer.multimesh=MultiMesh.new()
	renderer.multimesh.transform_format=MultiMesh.TRANSFORM_3D
	renderer.multimesh.use_colors=true
	renderer.multimesh.mesh=mesh
	add_child(renderer)
	var size := Vector3(SIZE)*CELL
	var aabb := AABB(origin,size)
	buildings.append({"origin":origin,"cells":cells,"index":index,"renderer":renderer,"aabb":aabb,"dirty":true,"tone":tone,"ground":SIZE.y})
	renderer.multimesh.instance_count=cells.size()
	# Static collision for the director: buildings block framing lines as they did before.
	battle_occluders.append(aabb)



# New fight: every cube is standing again (no rebuilding of nodes).
func restore() -> void:
	pending_spawn.clear()
	cells_removed=0
	blasts=0
	for building in buildings:
		for cell in building.cells: cell.alive=true
		building.dirty=true

func world_pos(building: Dictionary, p: Vector3i) -> Vector3:
	return building.origin+Vector3(p)*CELL+Vector3.ONE*CELL*0.5

# Remove every standing cube within radius of the point. Physical debris is spawned for a share of them.
func blast(point: Vector3, radius: float, force: float=10.0) -> int:
	var removed := 0
	blasts+=1
	for building in buildings:
		var box: AABB=building.aabb
		if not box.grow(radius+CELL).has_point(point): continue
		var cells: Array=building.cells
		for i in cells.size():
			var cell: Dictionary=cells[i]
			if not cell.alive: continue
			var center := world_pos(building,cell.pos)
			if center.distance_squared_to(point)>radius*radius: continue
			cell.alive=false
			removed+=1
			building.dirty=true
			pending_spawn.append({"pos":center,"color":cell.color,"contact":point,"force":(center-point).normalized()*force})
	cells_removed+=removed
	return removed

# Breath and beams: sample the line so a flame stream burns through whatever it touches.
func blast_line(from: Vector3, to: Vector3, radius: float, force: float=4.0) -> void:
	var length := from.distance_to(to)
	var steps := clampi(int(length/CELL),1,30)
	for k in range(steps+1):
		blast(from.lerp(to,float(k)/steps),radius,force)

func _physics_process(_dt: float) -> void:
	if buildings.is_empty(): return
	var anything := false
	for building in buildings:
		if building.dirty:
			anything=true
			collapse_unsupported(building)
	if anything: flush_spawns()
	for building in buildings:
		if building.dirty:
			rebuild_render(building)

# Cubes with no path of standing cubes down to the ground fall apart as debris.
func collapse_unsupported(building: Dictionary) -> void:
	var cells: Array=building.cells
	var index: Dictionary=building.index
	var supported := {}
	var todo: Array[int]=[]
	for i in cells.size():
		if cells[i].alive and cells[i].pos.y==0:
			supported[i]=true
			todo.append(i)
	while not todo.is_empty():
		var i: int=todo.pop_back()
		var p: Vector3i=cells[i].pos
		for offset in [Vector3i.LEFT,Vector3i.RIGHT,Vector3i.UP,Vector3i.DOWN,Vector3i.FORWARD,Vector3i.BACK]:
			var q: Vector3i=p+offset
			if not index.has(q): continue
			var j: int=index[q]
			if cells[j].alive and not supported.has(j):
				supported[j]=true
				todo.append(j)
	for i in cells.size():
		if cells[i].alive and not supported.has(i):
			cells[i].alive=false
			pending_spawn.append({"pos":world_pos(building,cells[i].pos),"color":cells[i].color,"contact":world_pos(building,cells[i].pos)+Vector3.UP*4.0,"force":Vector3.DOWN*2.0})
	building.dirty=false

func flush_spawns() -> void:
	var spent := 0
	while not pending_spawn.is_empty() and spent<SPAWN_PER_FRAME:
		var item: Dictionary=pending_spawn.pop_back()
		if debris!=null:
			debris.spawn_cube(item.pos,item.color,item.contact,item.force)
		spent+=1
	# Anything left over is dropped: the debris budget is protected.
	if pending_spawn.size()>400: pending_spawn.clear()

func rebuild_render(building: Dictionary) -> void:
	building.dirty=false
	var mm: MultiMesh=building.renderer.multimesh
	var cells: Array=building.cells
	var alive := []
	for cell in cells:
		if cell.alive: alive.append(cell)
	mm.instance_count=alive.size()
	var scale := CELL/BodyLayout.CUBE_SIZE*0.985
	for slot in alive.size():
		var cell: Dictionary=alive[slot]
		mm.set_instance_transform(slot,Transform3D(Basis.from_scale(Vector3.ONE*scale),world_pos(building,cell.pos)))
		mm.set_instance_color(slot,cell.color)
