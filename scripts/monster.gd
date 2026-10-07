class_name PixelMonster
extends Node3D

signal impacted(contact: Vector3, removed: int)
var cubes: Array[Dictionary] = []
var grid := {}
var structure := MonsterStructure.new()
var renders := {}
var tint := Color("2bb6b0")
var debris: Node3D
var last_query_ms := 0.0
var last_event_ms := 0.0
var last_contact := Vector3.ZERO
var last_direct_ids: Array[int] = []
var last_detached := 0
var reaction := 0.0
var home := Vector3.ZERO
var crouch := 0.0
var render_ids := {}
var dynamic_pose := false
var animation_ms := 0.0
var structure_ms := 0.0
var pose_transforms := {}
var pose_index_ready := false
var region_centers := {}
var support_height := 10.0
var generation_ms := 0.0
var archetype := {}
var palette := {}
var cell_ids := {}
var wound_count := -1
var aim_from := Vector3.ZERO
var regen: BoneRegen
var rig_type := "biped"
var move_cd := {}
var held_by: PixelMonster
var hold_target: PixelMonster
var flight: FlightState
var reassembling := false
var fist_away := {}
const FACE_STEPS := [Vector3i(1,0,0),Vector3i(-1,0,0),Vector3i(0,1,0),Vector3i(0,-1,0),Vector3i(0,0,1),Vector3i(0,0,-1)]
const Look = preload("res://scripts/cinema/look.gd")
const Archetypes = preload("res://scripts/combat/archetypes.gd")

func rig_point(key: String, fallback: Vector3, side: String="") -> Vector3:
	if archetype.is_empty() or not archetype.rig.has(key): return fallback
	var p: Array=archetype.rig[key]
	return Vector3((-absf(p[0]) if side=="left" else absf(p[0])) if side!="" else p[0],p[1],p[2])

func behavior(key: String, fallback: float) -> float:
	return float(archetype.behavior.get(key,fallback)) if not archetype.is_empty() else fallback

func initialize(color: Color, debris_manager: Node3D) -> void:
	tint = color
	debris = debris_manager
	home = position
	reset_body()

func reset_body() -> void:
	var generated := Time.get_ticks_usec()
	for child in get_children(): child.queue_free()
	renders.clear()
	render_ids.clear()
	pose_transforms.clear()
	region_centers.clear()
	pose_index_ready=false
	grid.clear()
	cubes = BodyLayout.generate() if archetype.is_empty() else Archetypes.body_cells(archetype)
	var material := Look.make_material()
	var mesh: Mesh=load("res://meshes/body_cube.obj")
	mesh=mesh.duplicate()
	mesh.surface_set_material(0,material)
	palette=Look.palette_for(String(archetype.get("id","")),archetype) if not archetype.is_empty() else {}
	var authored_look := palette.has("skin")
	if not authored_look: palette={"interior":tint.darkened(.78),"glow":Color("fff0b1")}
	cell_ids.clear()
	for i in cubes.size(): cell_ids[cubes[i].cell]=i
	wound_count=-1
	var head_y: int=(26 if archetype.is_empty() else roundi(archetype.rig.get("head",[0,26,0])[1]))
	rig_type=String(archetype.get("rig_type","biped"))
	for i in cubes.size():
		var c: Dictionary = cubes[i]
		c.alive = true
		c.state = 0
		c.pose = c.position
		c.pose_basis=Basis.IDENTITY
		if authored_look:
			c.color=Look.cube_color(palette,c.region,c.cell,head_y,c.get("tag",""),palette.get("face",true))
		else:
			c.color = tint.lightened(float(posmod(i*47,17))/80.0).darkened(float(posmod(i*31,11))/55.0)
			if c.region == "head" and c.cell.y == head_y+(0 if archetype.is_empty() else 1) and c.cell.z <= -1 and absi(c.cell.x)==1:
				c.color = Color("fff0b1")
			elif c.region=="head" and c.cell.y>=head_y+(1 if archetype.is_empty() else 2):
				c.color=tint.darkened(.30)
			elif c.region=="head" and c.cell.y<=head_y-(2 if archetype.is_empty() else 1) and c.cell.z<0:
				c.color=tint.lightened(.24)
			elif c.region in ["abdomen","pelvis"]:
				c.color=c.color.darkened(.13)
			elif c.region.contains("shoulder"):
				c.color=c.color.lightened(.10)
		c.glow=1.0 if c.color==palette.glow else 0.0
		c.render_color=c.color
		c.wound=0.0
		c.cavity=0.0
		var enclosed := true
		for step in FACE_STEPS:
			if not cell_ids.has(c.cell+step): enclosed=false; break
		c.enclosed=enclosed
		grid[c.cell] = i
		var render_key: String=c.region if dynamic_pose else c.major
		if not renders.has(render_key):
			var instance := MultiMeshInstance3D.new()
			instance.name = render_key
			instance.multimesh = MultiMesh.new()
			instance.multimesh.transform_format = MultiMesh.TRANSFORM_3D
			instance.multimesh.use_colors = true
			instance.multimesh.use_custom_data = true
			instance.multimesh.mesh = mesh
			add_child(instance)
			renders[render_key] = instance
	structure.proportional=not archetype.is_empty()
	structure.weakpoints={} if archetype.is_empty() else archetype.weakpoints
	structure.configure(archetype)
	structure.build(cubes)
	if regen!=null: regen.queue_free(); regen=null
	if structure.regenerative:
		regen=BoneRegen.new()
		regen.setup(self,archetype.special.regen)
		add_child(regen)
	rebuild()
	reaction = 0
	last_query_ms=0
	last_event_ms=0
	structure_ms=0
	last_direct_ids.clear()
	last_detached=0
	generation_ms=(Time.get_ticks_usec()-generated)/1000.0
	position = home

# Presentation only: cubes bordering lost material darken into excavated, rougher tissue.
# Enclosed cubes that become exposed show interior material instead of skin.
func update_wound_look() -> void:
	var alive := 0
	for c in cubes:
		if c.alive: alive+=1
	if alive==wound_count: return
	wound_count=alive
	var interior: Color=palette.get("interior",Color("201815"))
	for c in cubes:
		if not c.alive: continue
		var dead := 0
		for step in FACE_STEPS:
			var neighbour: int=cell_ids.get(c.cell+step,-1)
			if neighbour>=0 and not cubes[neighbour].alive: dead+=1
		if dead==0: continue
		c.wound=minf(1.0,0.45+0.2*dead)
		c.cavity=minf(0.5,0.08+0.1*dead)
		if c.glow>0.0:
			c.render_color=c.color.darkened(.5)
			c.glow=0.5
		else:
			c.render_color=c.color.lerp(interior,minf(0.9,(0.82 if c.enclosed else 0.36)+0.06*dead))
			if c.enclosed and float(palette.get("interior_glow",0.0))>0.0: c.glow=float(palette.interior_glow)

func rebuild() -> void:
	update_wound_look()
	region_centers.clear()
	var region_counts := {}
	var grouped_ids := {}
	support_height=100.0
	for key in renders: grouped_ids[key]=[]
	for id in cubes.size():
		var c: Dictionary=cubes[id]
		if c.alive:
			if c.major=="torso": support_height=minf(support_height,c.position.y-BodyLayout.CUBE_SIZE*0.5)
			grouped_ids[c.region if dynamic_pose else c.major].append(id)
			region_centers[c.region]=region_centers.get(c.region,Vector3.ZERO)+c.position
			region_counts[c.region]=region_counts.get(c.region,0)+1
	for region in region_centers: region_centers[region]/=region_counts[region]
	for major in renders:
		var mm: MultiMesh = renders[major].multimesh
		var ids: Array=grouped_ids[major]
		mm.instance_count = ids.size()
		render_ids[major]=ids
		for slot in ids.size():
			var c: Dictionary = cubes[ids[slot]]
			mm.set_instance_transform(slot,Transform3D(Basis.IDENTITY,c.position) if dynamic_pose else Transform3D(c.pose_basis,c.pose))
			mm.set_instance_color(slot,c.render_color)
			mm.set_instance_custom_data(slot,Color(c.wound,c.glow,c.cavity,0))
	if dynamic_pose: pose_index_ready=false

func update_pose_index() -> void:
	grid.clear()
	for i in cubes.size():
		if not cubes[i].alive: continue
		var pose: Transform3D=pose_transforms.get(cubes[i].region,Transform3D.IDENTITY)
		cubes[i].pose=pose*cubes[i].position
		cubes[i].pose_basis=pose.basis
		var cell := Vector3i(cubes[i].pose.floor())
		if not grid.has(cell): grid[cell]=[]
		grid[cell].append(i)
	pose_index_ready=true

func ensure_pose_index() -> void:
	if dynamic_pose and not pose_index_ready: update_pose_index()

func sync_pose() -> void:
	if dynamic_pose:
		for region in renders: renders[region].transform=pose_transforms.get(region,Transform3D.IDENTITY)
		pose_index_ready=false
		return
	for major in renders:
		var ids: Array=render_ids[major]
		var mm: MultiMesh=renders[major].multimesh
		for slot in ids.size():
			var c: Dictionary=cubes[ids[slot]]
			mm.set_instance_transform(slot,Transform3D(c.pose_basis,c.pose))
	if dynamic_pose: update_pose_index()

func alive_count() -> int:
	var count := 0
	for c in cubes:
		if c.alive: count += 1
	return count

func region_target(region: String) -> Vector3:
	var aliases: Dictionary=archetype.get("aliases",{})
	region=aliases.get(region,region)
	if rig_type=="swarm": return swarm_target()
	if region=="_loose" and regen!=null: return regen.nearest_loose_point(aim_from if aim_from!=Vector3.ZERO else global_position)
	if dynamic_pose:
		if region_centers.has(region): return to_global(pose_transforms.get(region,Transform3D.IDENTITY)*region_centers[region])
		var sum := Vector3.ZERO
		var n := 0
		for key in region_centers:
			sum+=to_global(pose_transforms.get(key,Transform3D.IDENTITY)*region_centers[key])
			n+=1
		return sum/n if n>0 else global_position+Vector3.UP*10
	var sum := Vector3.ZERO
	var count := 0
	for c in cubes:
		if c.alive and c.region == region:
			sum += c.pose
			count += 1
	return to_global(sum/maxi(1,count))

# Army entrants: aim at the surviving unit nearest the attacker (units fight as independent bodies).
func swarm_target() -> Vector3:
	var best := Vector3.ZERO
	var best_d := INF
	var origin := aim_from if aim_from!=Vector3.ZERO else global_position
	for key in region_centers:
		var p := to_global(pose_transforms.get(key,Transform3D.IDENTITY)*region_centers[key])
		var d := p.distance_squared_to(origin)
		if key.ends_with("_body") and d<best_d:
			best_d=d
			best=p
	return best if best_d<INF else global_position+Vector3.UP*4

# Swept sphere against actual surviving cube AABBs, in body space.
# No broad-phase body collider can register a hit inside an existing cavity.
func sweep(from: Vector3, to: Vector3, radius: float=0.0) -> Dictionary:
	ensure_pose_index()
	var a := to_local(from)
	var b := to_local(to)
	var direction := b-a
	var margin := Vector3.ONE*(BodyLayout.CUBE_SIZE*0.5+radius)*sqrt(3.0)
	var broadphase := AABB(a.min(b)-margin,a.max(b)-a.min(b)+margin*2)
	var best := 2.0
	var hit_id := -1
	for i in cubes.size():
		var c: Dictionary = cubes[i]
		if not c.alive: continue
		if not broadphase.has_point(c.pose): continue
		var extent := Vector3.ONE*(BodyLayout.CUBE_SIZE*0.5+radius)
		var inverse: Basis=c.pose_basis.inverse()
		var ray_a: Vector3=inverse*(a-c.pose)
		var ray_direction: Vector3=inverse*direction
		var low: Vector3 = -extent
		var high: Vector3 = extent
		var near := 0.0
		var far := 1.0
		for axis in 3:
			if absf(ray_direction[axis])<0.00001:
				if ray_a[axis]<low[axis] or ray_a[axis]>high[axis]: near=2.0; break
			else:
				var t1: float = (low[axis]-ray_a[axis])/ray_direction[axis]
				var t2: float = (high[axis]-ray_a[axis])/ray_direction[axis]
				near = maxf(near,minf(t1,t2))
				far = minf(far,maxf(t1,t2))
		if near<=far and near<best:
			best=near
			hit_id=i
	if hit_id<0: return {}
	var center := from.lerp(to,best)
	var cube_center := to_global(cubes[hit_id].pose)
	# Closest point on the actual cube, not the expanded sweep box.
	var local_center := to_local(center)
	var half := Vector3.ONE*BodyLayout.CUBE_SIZE*0.5
	var hit_cube: Dictionary=cubes[hit_id]
	var cube_local: Vector3=hit_cube.pose_basis.inverse()*(local_center-hit_cube.pose)
	var surface: Vector3=hit_cube.pose+hit_cube.pose_basis*cube_local.clamp(-half,half)
	return {"point":to_global(surface),"center":center,"id":hit_id,"cube_center":cube_center,"t":best}

func damage(contact: Vector3, radius: float, force: Vector3) -> Dictionary:
	ensure_pose_index()
	var started := Time.get_ticks_usec()
	var local := to_local(contact)
	if regen!=null: regen.shatter_near(contact,radius*0.8)
	last_direct_ids.clear()
	last_detached = 0
	# Integer spatial index: enumerate only cells inside the impact bounds.
	var bounds := int(ceil(radius+1.0))
	var origin := Vector3i(local.round())
	for x in range(origin.x-bounds,origin.x+bounds+1):
		for y in range(origin.y-bounds,origin.y+bounds+1):
			for z in range(origin.z-bounds,origin.z+bounds+1):
				var cell := Vector3i(x,y,z)
				if not grid.has(cell): continue
				var ids: Array=grid[cell] if dynamic_pose else [grid[cell]]
				for id in ids:
					var c: Dictionary = cubes[id]
					if c.alive and c.pose.distance_squared_to(local)<=radius*radius:
						last_direct_ids.append(id)
	last_query_ms = (Time.get_ticks_usec()-started)/1000.0
	for id in last_direct_ids: remove_cube(id,contact,force)
	var structural_start := Time.get_ticks_usec()
	for arm in structure.failures(cubes):
		for i in cubes.size():
			if cubes[i].alive and structure.owns(cubes[i],arm):
				remove_cube(i,contact,force*0.35)
				last_detached+=1
	if last_detached>0: structure.refresh(cubes)
	structure_ms=(Time.get_ticks_usec()-structural_start)/1000.0
	rebuild()
	last_contact = contact
	reaction = 0.5
	last_event_ms = (Time.get_ticks_usec()-started)/1000.0
	impacted.emit(contact,last_direct_ids.size())
	return {"direct":last_direct_ids.size(),"detached":last_detached,"remaining":alive_count(),"query_ms":last_query_ms,"event_ms":last_event_ms}

func remove_cube(id: int, contact: Vector3, force: Vector3) -> void:
	var c: Dictionary = cubes[id]
	c.alive = false
	if regen!=null:
		c.state=1
		regen.detach(id,to_global(c.pose),contact,force)
		return
	c.state=2
	debris.spawn_cube(to_global(c.pose),c.render_color,contact,force)

func align_bone(from: Vector3, to: Vector3) -> Basis:
	return Basis(Quaternion(from.normalized(),to.normalized()))

func pose_arm(hand_world: Vector3, _blend: float) -> Vector3:
	var shoulder_rest := Vector3(5,19.5,0)
	var elbow_rest := Vector3(6.2,15.5,-0.1)
	var hand_rest := Vector3(6.5,11.3,-0.6)
	var sum := Vector3.ZERO
	var count := 0
	for c in cubes:
		if c.region=="right_fist": sum+=c.position; count+=1
	hand_rest=sum/maxi(1,count)
	var shoulder := shoulder_rest-Vector3.UP*crouch
	var desired := to_local(hand_world)
	var delta := desired-shoulder
	var upper_length := shoulder_rest.distance_to(elbow_rest)
	var lower_length := elbow_rest.distance_to(hand_rest)
	var distance := clampf(delta.length(),0.5,upper_length+lower_length-0.05)
	var direction := delta.normalized()
	var hand := shoulder+direction*distance
	var along := (upper_length*upper_length-lower_length*lower_length+distance*distance)/(2*distance)
	var height := sqrt(maxf(0,upper_length*upper_length-along*along))
	var bend := Vector3(0,-1,1)
	bend=(bend-direction*bend.dot(direction)).normalized()
	var elbow := shoulder+direction*along+bend*height
	var upper_basis := align_bone(elbow_rest-shoulder_rest,elbow-shoulder)
	var lower_basis := align_bone(hand_rest-elbow_rest,hand-elbow)
	for c in cubes:
		var p: Vector3=c.position
		c.pose_basis=Basis.IDENTITY
		# Test-rig crouch compresses legs, leaving both feet planted.
		var lower_weight := clampf((p.y-1.5)/10.0,0,1)
		c.pose=p-Vector3.UP*crouch*lower_weight
		if c.major.ends_with("leg"):
			c.pose.z-=sin(lower_weight*PI)*crouch*0.25
		if c.major!="right_arm": continue
		if c.region=="right_shoulder": continue
		if c.region=="right_upper_arm":
			c.pose=shoulder+upper_basis*(p-shoulder_rest)
			c.pose_basis=upper_basis
		else:
			c.pose=elbow+lower_basis*(p-elbow_rest)
			c.pose_basis=lower_basis
	rebuild()
	return to_global(hand)

func clear_pose() -> void:
	crouch=0
	for c in cubes:
		c.pose=c.position
		c.pose_basis=Basis.IDENTITY
	rebuild()

func _process(dt: float) -> void:
	reaction = move_toward(reaction,0,dt)
	rotation.z = sin(reaction*PI*4)*reaction*0.035
