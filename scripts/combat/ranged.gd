class_name RangedManager
extends Node3D
# Explicit preloads: no dependence on the editor-generated global class cache.
const CombatMonster = preload("res://scripts/combat/combatant.gd")
const MonsterAttack = preload("res://scripts/combat/attack_motion.gd")

# Projectiles, sustained streams (flame / gaze beam), telegraphed meteors and web bolts.
# Every ranged attack is a physical object or a swept volume that must touch surviving cubes.
var battle: Node3D
var shots: Array[Dictionary]=[]
var streams: Array[Dictionary]=[]
var strikes: Array[Dictionary]=[]
var fire_pool: Array[GPUParticles3D]=[]
var fire_cursor := 0
var lights: Array[OmniLight3D]=[]
var light_cursor := 0
var charge_orb: Array[MeshInstance3D]=[]
var cube_mesh: Mesh
var glow_mesh_material: StandardMaterial3D
var fired := 0
var projectile_hits := 0
var stream_ticks := 0
const Look = preload("res://scripts/cinema/look.gd")

func _ready() -> void:
	cube_mesh=(load("res://meshes/body_cube.obj") as Mesh)
	var shader := Shader.new()
	shader.code="""shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;
void vertex() {
 MODELVIEW_MATRIX=mat4(vec4(length(MODEL_MATRIX[0].xyz),0.0,0.0,0.0),vec4(0.0,length(MODEL_MATRIX[1].xyz),0.0,0.0),vec4(0.0,0.0,length(MODEL_MATRIX[2].xyz),0.0),VIEW_MATRIX*MODEL_MATRIX[3]);
}
void fragment() {
 float r=length(UV-vec2(0.5))*2.0;
 float soft=pow(max(0.0,1.0-r*r),1.5);
 ALBEDO=COLOR.rgb*1.6;
 ALPHA=soft*COLOR.a;
}
"""
	for i in 6:
		var particles := GPUParticles3D.new()
		particles.emitting=false
		particles.amount=70
		particles.lifetime=0.9
		particles.explosiveness=0.0
		particles.local_coords=false
		particles.visibility_aabb=AABB(Vector3(-40,-10,-40),Vector3(80,50,80))
		var quad := QuadMesh.new()
		quad.size=Vector2(1,1)
		var material := ShaderMaterial.new()
		material.shader=shader
		quad.material=material
		particles.draw_pass_1=quad
		var process := ParticleProcessMaterial.new()
		process.direction=Vector3(0,0,-1)
		process.spread=9
		process.gravity=Vector3(0,3.0,0)
		process.initial_velocity_min=20
		process.initial_velocity_max=28
		process.scale_min=1.4
		process.scale_max=3.2
		var gradient := Gradient.new()
		gradient.set_color(0,Color(1.0,.88,.55,.85))
		gradient.set_color(1,Color(.65,.18,.04,0))
		var texture := GradientTexture1D.new()
		texture.gradient=gradient
		process.color_ramp=texture
		particles.process_material=process
		add_child(particles)
		fire_pool.append(particles)
	for i in 5:
		var light := OmniLight3D.new()
		light.light_color=Color("ff9a45")
		light.omni_range=26
		light.light_energy=0
		light.visible=false
		add_child(light)
		lights.append(light)
	for i in 3:
		var orb := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius=1.0
		sphere.height=2.0
		var mat := StandardMaterial3D.new()
		mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color=Color(1,.6,.2,.8)
		sphere.material=mat
		orb.mesh=sphere
		orb.visible=false
		add_child(orb)
		charge_orb.append(orb)

func clear() -> void:
	for shot in shots: if is_instance_valid(shot.node): shot.node.queue_free()
	for strike in strikes: if is_instance_valid(strike.node): strike.node.queue_free()
	shots.clear()
	strikes.clear()
	for stream in streams: stream_end_visual(stream)
	streams.clear()
	for orb in charge_orb: orb.visible=false
	for l in lights: l.visible=false; l.light_energy=0
	fired=0
	projectile_hits=0
	stream_ticks=0

func quality(shooter: CombatMonster, profile: Dictionary) -> float:
	var depends: Array=profile.get("depends",[])
	if depends.is_empty(): return 1.0
	var q := 1.0
	for key in depends: q=minf(q,shooter.structure.fraction(key))
	return clampf(q,0.0,1.0)

func muzzle(shooter: CombatMonster, profile: Dictionary) -> Vector3:
	var key: String=profile.get("muzzle","head")
	return shooter.rig.effectors.get(key,shooter.position+Vector3.UP*20)

func fire(shooter: CombatMonster, target: CombatMonster, profile: Dictionary, move: String) -> void:
	fired+=1
	var kind: String=profile.ranged
	var origin := muzzle(shooter,profile)
	var q := quality(shooter,profile)
	var aim := target.region_target(profile.get("aim_region","chest"))
	match kind:
		"stream":
			streams.append({"shooter":shooter,"target":target,"profile":profile,"move":move,"age":0.0,"tick":0.0,"dir":(aim-origin).normalized(),"q":q,"slot":claim_fire(),"end":origin})
			shooter_flash(origin,3.5)
		"projectile","web":
			spawn_projectile(shooter,target,profile,move,origin,aim,q)
		"meteor":
			spawn_meteor(shooter,target,profile,move)
		_:
			push_warning("unknown ranged kind "+kind)
	battle.sound.layer(origin,"kick",-8,0.55)

func claim_fire() -> int:
	var slot := fire_cursor
	fire_cursor=(fire_cursor+1)%fire_pool.size()
	return slot

func shooter_flash(at: Vector3, energy: float) -> void:
	var l := lights[light_cursor]
	light_cursor=(light_cursor+1)%lights.size()
	l.global_position=at
	l.light_energy=energy
	l.visible=true

# ---- cube-cluster visuals ----
func make_cluster(shape: String, scale_value: float, tint: Color, glow: float) -> MultiMeshInstance3D:
	var offsets: Array[Vector3]=[]
	match shape:
		"sphere3":
			for x in range(-3,4): for y in range(-3,4): for z in range(-3,4):
				if Vector3(x,y,z).length()<=3.1: offsets.append(Vector3(x,y,z))
		"sphere2":
			for x in range(-2,3): for y in range(-2,3): for z in range(-2,3):
				if Vector3(x,y,z).length()<=2.2: offsets.append(Vector3(x,y,z))
		"block":
			for x in range(-1,2): for y in range(-1,2): for z in range(-1,2):
				if absi(x)+absi(y)+absi(z)<=2: offsets.append(Vector3(x,y,z))
		"fist":
			for x in range(-1,1): for y in range(-1,1): for z in range(-2,2): offsets.append(Vector3(x+0.5,y+0.5,z+0.5))
		_:
			for x in range(-1,1): for y in range(-1,1): for z in range(-1,1): offsets.append(Vector3(x+0.5,y+0.5,z+0.5))
	var node := MultiMeshInstance3D.new()
	node.multimesh=MultiMesh.new()
	node.multimesh.transform_format=MultiMesh.TRANSFORM_3D
	node.multimesh.use_colors=true
	node.multimesh.use_custom_data=true
	var mesh: Mesh=cube_mesh.duplicate()
	mesh.surface_set_material(0,Look.make_material(Color("ffb070"),0.5))
	node.multimesh.mesh=mesh
	node.multimesh.instance_count=offsets.size()
	for i in offsets.size():
		node.multimesh.set_instance_transform(i,Transform3D(Basis.from_scale(Vector3.ONE*scale_value),offsets[i]*scale_value*0.94))
		var jitter := 1.0+0.12*sin(float(i)*12.9)
		node.multimesh.set_instance_color(i,tint*jitter)
		node.multimesh.set_instance_custom_data(i,Color(0,glow*(0.5+0.5*absf(sin(float(i)*3.1))),0,0))
	add_child(node)
	return node

func spawn_projectile(shooter: CombatMonster, target: CombatMonster, profile: Dictionary, move: String, origin: Vector3, aim: Vector3, q: float) -> void:
	var speed: float=profile.get("speed",20.0)
	var gravity: float=profile.get("gravity",0.0)
	var delta := aim-origin
	var flat := Vector3(delta.x,0,delta.z)
	var t: float=maxf(0.2,flat.length()/speed)
	var velocity := flat/t
	velocity.y=(delta.y+0.5*gravity*t*t)/t if gravity>0.0 else delta.y/t
	if gravity==0.0: velocity=delta.normalized()*speed
	var node := make_cluster(profile.get("shape","block"),float(profile.get("scale",1.0)),Color(profile.get("tint","8a8a80")),float(profile.get("glow",0.0)))
	node.global_position=origin
	var item := {"shooter":shooter,"target":target,"profile":profile,"move":move,"pos":origin,"prev":origin,"vel":velocity,"age":0.0,"node":node,"gravity":gravity,"returning":false,"spin":Vector3(1.5,2.0,0.7)}
	if profile.get("kind","")=="fist": item.side=shooter.attack_motion.side
	if profile.has("return_time"):
		shooter.fist_away[shooter.attack_motion.side]=float(profile.return_time)+t+1.0
	shots.append(item)
	shooter_flash(origin,2.5)

func spawn_meteor(shooter: CombatMonster, target: CombatMonster, profile: Dictionary, move: String) -> void:
	var ground := target.position+target.velocity*0.8
	ground.y=0.3
	var node := make_cluster("sphere3",float(profile.get("scale",1.1)),Color(profile.get("tint","5a3a2a")),float(profile.get("glow",1.6)))
	var marker := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius=float(profile.get("aoe",5.0))
	disc.bottom_radius=disc.top_radius
	disc.height=0.12
	var mat := StandardMaterial3D.new()
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color=Color(1,.45,.15,.25)
	disc.material=mat
	marker.mesh=disc
	add_child(marker)
	marker.global_position=ground
	var start := ground+Vector3(-18,float(profile.get("height",75.0)),-10)
	node.global_position=start
	strikes.append({"shooter":shooter,"target":target,"profile":profile,"move":move,"ground":ground,"start":start,"age":0.0,"warn":float(profile.get("warn",1.7)),"fall":float(profile.get("fall",0.9)),"node":node,"marker":marker,"mat":mat})

func stream_end_visual(stream: Dictionary) -> void:
	if stream.has("beam") and is_instance_valid(stream.beam): stream.beam.queue_free()
	var particles := fire_pool[stream.slot]
	particles.emitting=false

# ---- simulation ----
func step(dt: float) -> void:
	step_charges()
	for i in range(streams.size()-1,-1,-1):
		if step_stream(streams[i],dt):
			stream_end_visual(streams[i])
			streams.remove_at(i)
	for i in range(shots.size()-1,-1,-1):
		if step_shot(shots[i],dt):
			if is_instance_valid(shots[i].node): shots[i].node.queue_free()
			shots.remove_at(i)
	for i in range(strikes.size()-1,-1,-1):
		if step_strike(strikes[i],dt):
			strikes[i].node.queue_free()
			strikes[i].marker.queue_free()
			strikes.remove_at(i)
	for l in lights:
		if l.visible:
			l.light_energy=maxf(0.0,l.light_energy-dt*14.0)
			if l.light_energy<=0.05: l.visible=false

func step_charges() -> void:
	var used := 0
	for fighter in battle.monsters:
		var attack: MonsterAttack=fighter.attack_motion
		if attack.running and attack.profile.has("ranged") and attack.phase=="WIND-UP" and attack.profile.get("charge_orb",true) and used<charge_orb.size():
			var orb := charge_orb[used]
			used+=1
			var kind: String=attack.profile.ranged
			orb.visible=kind!="stream" or attack.profile.get("charge_orb",false)
			orb.global_position=muzzle(fighter,attack.profile)+Vector3.UP*0.5
			var radius: float=float(attack.profile.get("orb",1.4))*(0.2+0.8*attack.progress)
			orb.scale=Vector3.ONE*radius
			var mat: StandardMaterial3D=orb.mesh.material
			mat.albedo_color=Color(attack.profile.get("orb_color","ff9a45")).lerp(Color.WHITE,0.25*attack.progress)
			mat.albedo_color.a=0.55+0.35*attack.progress
	for i in range(used,charge_orb.size()): charge_orb[i].visible=false

func step_stream(stream: Dictionary, dt: float) -> bool:
	var shooter: CombatMonster=stream.shooter
	var target: CombatMonster=stream.target
	var profile: Dictionary=stream.profile
	if shooter.defeated or target.defeated: return true
	stream.age+=dt
	stream.tick-=dt
	if stream.age>=float(profile.duration): return true
	# Anatomy: a wrecked head/eye gives a shorter, sloppier, slower-tracking stream.
	var q: float=quality(shooter,profile)
	var origin := muzzle(shooter,profile)
	var aim := target.region_target(profile.get("aim_region","chest"))
	var wanted := (aim-origin).normalized()
	var track: float=float(profile.get("track",0.6))*(0.35+0.65*q)
	var angle: float=stream.dir.angle_to(wanted)
	if angle>0.001: stream.dir=stream.dir.slerp(wanted,minf(1.0,track*dt/angle))
	var length: float=float(profile.range)*(0.45+0.55*q)
	var direction: Vector3=stream.dir
	if profile.get("arc_error",0.0)>0.0:
		direction=direction.rotated(Vector3.UP,sin(stream.age*5.0)*float(profile.arc_error)*(1.0-q))
	var end := origin+direction*length
	# Ground clips the stream.
	if direction.y<-0.02 and origin.y>0.3:
		var t_ground := (origin.y-0.5)/-direction.y
		if t_ground<length: end=origin+direction*t_ground
	var contact := target.sweep(origin,end,float(profile.get("tick_radius",1.5)))
	# Flame and beams burn through lane buildings along their whole length.
	if profile.get("burns",false): battle.wreck.blast_line(origin,end,1.6,2.0)
	var visual_end := end
	if not contact.is_empty(): visual_end=contact.center
	stream.end=visual_end
	update_stream_visual(stream,origin,visual_end,direction)
	if stream.tick<=0.0:
		stream.tick=float(profile.get("tick",0.22))
		if not contact.is_empty():
			stream_ticks+=1
			var radius: float=float(profile.get("tick_radius",1.5))*(0.7+0.3*q)
			target.light_hit=true
			var report := target.damage(contact.point,radius,direction*float(profile.get("force",9.0)))
			target.light_hit=false
			if report.direct>0 and (stream_ticks%3==0):
				battle.on_impact(shooter,target,stream.move,contact.point,report,float(profile.get("force",9.0)))
			elif report.direct>0:
				battle.effects.burst(contact.point,0,false,Vector3.UP)
	return false

func update_stream_visual(stream: Dictionary, origin: Vector3, end: Vector3, dir: Vector3) -> void:
	var profile: Dictionary=stream.profile
	if profile.get("beam",false):
		if not stream.has("beam") or not is_instance_valid(stream.beam):
			var beam := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius=float(profile.get("beam_radius",0.35))
			cylinder.bottom_radius=cylinder.top_radius
			cylinder.height=1.0
			var mat := StandardMaterial3D.new()
			mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.blend_mode=BaseMaterial3D.BLEND_MODE_ADD
			mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color=Color(profile.get("beam_color","ff4ad0"))
			cylinder.material=mat
			beam.mesh=cylinder
			add_child(beam)
			stream.beam=beam
		var length := origin.distance_to(end)
		var beam_node: MeshInstance3D=stream.beam
		var up := dir.normalized()
		var basis := Basis(Quaternion(Vector3.UP,up))
		beam_node.global_transform=Transform3D(basis.scaled(Vector3(1,length,1)),origin+up*length*0.5)
		shooter_flash(end,1.8)
		return
	var particles := fire_pool[stream.slot]
	particles.global_position=origin
	particles.look_at(origin+dir,Vector3.UP)
	var process: ParticleProcessMaterial=particles.process_material
	var reach: float=origin.distance_to(end)
	process.initial_velocity_min=reach*0.9
	process.initial_velocity_max=reach*1.25
	particles.emitting=true
	shooter_flash(origin+dir*minf(reach,6.0),2.4)

func step_shot(shot: Dictionary, dt: float) -> bool:
	var profile: Dictionary=shot.profile
	var shooter: CombatMonster=shot.shooter
	var target: CombatMonster=shot.target
	shot.age+=dt
	if shot.age>float(profile.get("life",6.0)): return true
	shot.prev=shot.pos
	if shot.returning:
		var goal: Vector3=shooter.rig.effectors.get(profile.get("return_to","right_arm"),shooter.position+Vector3.UP*14)
		var to_goal: Vector3=goal-shot.pos
		var travel := float(profile.get("return_speed",24.0))*dt
		if to_goal.length()<=travel+0.6: return true
		shot.pos+=to_goal.normalized()*travel
		shot.node.global_position=shot.pos
		return false
	shot.vel.y-=shot.gravity*dt
	shot.pos+=shot.vel*dt
	shot.node.global_position=shot.pos
	shot.node.rotate(shot.spin.normalized(),shot.spin.length()*dt)
	if shot.age>0.2 and not target.defeated:
		var contact := target.sweep(shot.prev,shot.pos,float(profile.get("hit_radius",1.4)))
		if not contact.is_empty():
			impact_shot(shot,contact.point)
			return not profile.has("return_time")
	if shot.pos.y<=float(profile.get("ground",0.6)) and shot.vel.y<0.0:
		impact_shot(shot,Vector3(shot.pos.x,0.6,shot.pos.z))
		return not profile.has("return_time")
	if profile.has("return_time") and shot.pos.distance_to(shot.shooter.position)>float(profile.get("max_range",34.0)):
		shot.returning=true
	return false

func impact_shot(shot: Dictionary, point: Vector3) -> void:
	var profile: Dictionary=shot.profile
	var shooter: CombatMonster=shot.shooter
	var target: CombatMonster=shot.target
	projectile_hits+=1
	var direction: Vector3=shot.vel.normalized() if shot.vel.length()>0.1 else Vector3.FORWARD
	var radius: float=float(profile.get("radius",2.5))
	var report := target.damage(point,radius,Vector3(direction.x,0.2,direction.z).normalized()*float(profile.get("force",18.0)))
	if profile.has("status") and report.direct>=0:
		if point.distance_to(target.region_target("chest"))<float(profile.get("status_reach",9.0)): battle.apply_status(shooter,target,profile.status)
	if report.direct>0: battle.on_impact(shooter,target,shot.move,point,report,float(profile.get("force",18.0)))
	else:
		battle.effects.burst(point,1 if profile.get("explosive",false) else 0,false,Vector3.UP)
		battle.camera.impulse(point,0.12)
	battle.wreck.blast(point,float(profile.get("wreck",3.0)),float(profile.get("force",18.0)))
	if profile.get("explosive",false):
		shooter_flash(point+Vector3.UP*2,10.0)
		battle.effects.burst(Vector3(point.x,0.3,point.z),1)
	if profile.has("return_time"): shot.returning=true; shot.node.visible=true
	else: shot.node.visible=false

func step_strike(strike: Dictionary, dt: float) -> bool:
	strike.age+=dt
	var target: CombatMonster=strike.target
	var warn: float=strike.warn
	var mat: StandardMaterial3D=strike.mat
	if strike.age<warn:
		mat.albedo_color.a=0.18+0.3*absf(sin(strike.age*9.0))
		strike.node.global_position=strike.start
		return false
	var t: float=clampf((strike.age-warn)/strike.fall,0.0,1.0)
	strike.node.global_position=strike.start.lerp(strike.ground+Vector3.UP*2.0,t*t)
	shooter_flash(strike.node.global_position,5.0)
	if t>=1.0:
		var point: Vector3=strike.ground
		var profile: Dictionary=strike.profile
		var radius: float=float(profile.get("aoe",5.0))
		var report := target.damage(point+Vector3.UP*0.8,radius,Vector3(0,0.3,0)+(target.position-point).normalized()*float(profile.get("force",26.0)))
		if report.direct>0: battle.on_impact(strike.shooter,target,strike.move,point,report,float(profile.get("force",26.0)))
		else:
			battle.effects.burst(point,2)
			battle.camera.impulse(point,0.3)
		shooter_flash(point+Vector3.UP*3,16.0)
		battle.wreck.blast(point,float(profile.get("aoe",5.0))*1.1,20.0)
		battle.effects.burst(Vector3(point.x,0.3,point.z),2)
		return true
	return false
