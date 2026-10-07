class_name BoneRegen
extends Node3D

# Skeleton reassembly. Detached original cubes stay recoverable until something shatters them.
# States on the cube dictionary: 0 attached, 1 loose/recoverable, 2 shattered (permanent).
var body: PixelMonster
var params := {}
var loose: Array[Dictionary]=[]
var renderer: MultiMeshInstance3D
var shattered := 0
var reattached := 0
var returning_peak := 0
var dirty := false
var released := false
var return_budget := 0.0
var rng := RandomNumberGenerator.new()
const Look = preload("res://scripts/cinema/look.gd")

func setup(owner_body: PixelMonster, data: Dictionary) -> void:
	body=owner_body
	params=data
	top_level=true
	rng.seed=9127
	renderer=MultiMeshInstance3D.new()
	renderer.multimesh=MultiMesh.new()
	renderer.multimesh.transform_format=MultiMesh.TRANSFORM_3D
	renderer.multimesh.use_colors=true
	renderer.multimesh.use_custom_data=true
	var mesh: Mesh=(load("res://meshes/body_cube.obj") as Mesh).duplicate()
	mesh.surface_set_material(0,Look.make_material(Color("9fb4c0"),0.3))
	renderer.multimesh.mesh=mesh
	add_child(renderer)

func loose_count() -> int:
	return loose.size()

func returning_count() -> int:
	var n := 0
	for item in loose:
		if item.mode=="RETURNING": n+=1
	return n

func detach(id: int, world_pos: Vector3, contact: Vector3, force: Vector3) -> void:
	var outward := (world_pos-contact).normalized()
	if outward.length_squared()<0.1: outward=Vector3.UP
	var c: Dictionary=body.cubes[id]
	loose.append({"id":id,"pos":world_pos,"vel":force*0.5+outward*rng.randf_range(2,6)+Vector3.UP*rng.randf_range(3,7),"age":0.0,"mode":"LOOSE","spin":Vector3(rng.randf_range(-5,5),rng.randf_range(-5,5),rng.randf_range(-5,5)),"basis":Basis.IDENTITY,"color":c.render_color,"hop":0.0})
	dirty=true

# Anything that smashes a loose pixel destroys it for good (bounded by the original 1,000).
func shatter_near(point: Vector3, radius: float) -> int:
	var n := 0
	for i in range(loose.size()-1,-1,-1):
		var item: Dictionary=loose[i]
		if item.pos.distance_to(point)<=radius:
			shatter(i)
			n+=1
	return n

func shatter(index: int) -> void:
	var item: Dictionary=loose[index]
	body.cubes[item.id].state=2
	shattered+=1
	if body.debris!=null and body.debris.has_method("spawn_cube"):
		body.debris.spawn_cube(item.pos,item.color.darkened(.35),item.pos+Vector3.DOWN,Vector3.UP*2.0)
	loose.remove_at(index)
	dirty=true

func nearest_loose_point(from: Vector3) -> Vector3:
	var best := Vector3(from.x,0.6,from.z)
	var best_d := INF
	for item in loose:
		var d: float=item.pos.distance_squared_to(from)
		if d<best_d:
			best_d=d
			best=item.pos
	return best

func release_all() -> void:
	if released: return
	released=true
	for item in loose:
		body.cubes[item.id].state=2
		if body.debris!=null: body.debris.spawn_cube(item.pos,item.color,item.pos,Vector3.UP)
	loose.clear()
	dirty=true
	renderer.multimesh.instance_count=0

func crush_check(point: Vector3, radius: float) -> void:
	for i in range(loose.size()-1,-1,-1):
		var p: Vector3=loose[i].pos
		if Vector2(p.x-point.x,p.z-point.z).length()<=radius and p.y<2.0: shatter(i)

func update(dt: float) -> void:
	if released: return
	var delay: float=params.get("delay",3.4)
	var rate: float=params.get("rate",26.0)
	return_budget=minf(rate,return_budget+rate*dt)
	var returning := 0
	var reconnect: Array[int]=[]
	# joints first, so knees/hips/shoulders/spine return before ribs and fingers
	var order := []
	for i in loose.size():
		order.append(i)
	for i in loose.size():
		var item: Dictionary=loose[i]
		item.age+=dt
		if item.mode=="LOOSE":
			item.vel.y-=14.7*dt
			item.pos+=item.vel*dt
			if item.pos.y<=0.5:
				item.pos.y=0.5
				item.vel.y=absf(item.vel.y)*0.25
				item.vel.x*=0.65
				item.vel.z*=0.65
				item.spin*=0.5
			item.basis=Basis(item.spin.normalized(),item.spin.length()*dt)*item.basis if item.spin.length()>0.05 else item.basis
			if item.age>delay and not body.defeated and return_budget>=1.0:
				return_budget-=1.0
				item.mode="RETURNING"
				item.age=0.0
				item.hop=params.get("twitch",0.7)
		else:
			returning+=1
			item.basis=item.basis.slerp(Basis.IDENTITY,minf(1.0,dt*3.0))
			if item.hop>0.0:
				item.hop-=dt
				item.pos.y+=sin(item.age*40.0)*0.04+dt*2.2
				item.pos.x+=rng.randf_range(-.03,.03)
			else:
				var c: Dictionary=body.cubes[item.id]
				var goal: Vector3=body.to_global(body.pose_transforms.get(c.region,Transform3D.IDENTITY)*c.position)
				var to_goal: Vector3=goal-item.pos
				var speed: float=minf(40.0,6.0+item.age*32.0)
				if to_goal.length()<speed*dt+0.4:
					reconnect.append(i)
				else:
					item.pos+=to_goal.normalized()*speed*dt
	returning_peak=maxi(returning_peak,returning)
	body.reassembling=returning>=int(params.get("vulnerable_count",14)) and not body.defeated
	for k in range(reconnect.size()-1,-1,-1):
		var item: Dictionary=loose[reconnect[k]]
		var c: Dictionary=body.cubes[item.id]
		c.alive=true
		c.state=0
		reattached+=1
		loose.remove_at(reconnect[k])
		dirty=true
	if dirty and not reconnect.is_empty():
		body.structure.failures(body.cubes)
		body.rebuild()
	dirty=false
	var mm := renderer.multimesh
	if mm.instance_count!=loose.size(): mm.instance_count=loose.size()
	for i in loose.size():
		var item: Dictionary=loose[i]
		mm.set_instance_transform(i,Transform3D(item.basis,item.pos))
		mm.set_instance_color(i,item.color)
		var shimmer := 0.0
		if item.mode=="RETURNING": shimmer=0.7+0.3*sin(item.age*30.0)
		elif item.age>float(params.get("delay",3.4))-1.0: shimmer=0.35
		mm.set_instance_custom_data(i,Color(0,shimmer,0,0))
