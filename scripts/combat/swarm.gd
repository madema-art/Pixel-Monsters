class_name SwarmUnits
extends RefCounted
# Explicit preloads: no dependence on the editor-generated global class cache.
const CombatMonster = preload("res://scripts/combat/combatant.gd")

# Army of Ten: ten independent 100-cube fighters inside one entrant. Each unit has its own position,
# gait, climb state and strike timer; unit death is decided by that unit's own surviving cubes.
var body: CombatMonster
var data: Dictionary = {}
var units: Array[Dictionary]=[]
var strike_count := 0
var climbing_peak := 0
var rng := RandomNumberGenerator.new()

func setup(owner_body: CombatMonster, params: Dictionary) -> void:
	body=owner_body
	data=params
	rng.seed=4747
	units.clear()
	var count: int=params.get("units",10)
	for i in count:
		var column := i%5
		var row := i/5
		var offset := Vector3((column-2)*3.4,0,(row-0.5)*3.4)
		var rest: Vector3=Vector3(params.rest[i][0],0,params.rest[i][1])
		units.append({"id":i,"pos":body.home+offset,"yaw":0.0,"alive":true,"phase":rng.randf()*TAU,"climb":0.0,"strike":rng.randf_range(0.6,1.6),"state":"RALLY","rest":rest,"ring":float(i)/count*TAU,"jitter":rng.randf_range(0.8,1.25),"striking":0.0})
	body.position=body.home+Vector3(0,-0.6,0)

func alive_count() -> int:
	var n := 0
	for u in units: if u.alive: n+=1
	return n

func nearest_point(from: Vector3) -> Vector3:
	var best := Vector3.ZERO
	var best_d := INF
	for u in units:
		if not u.alive: continue
		var d: float=u.pos.distance_squared_to(from)
		if d<best_d:
			best_d=d
			best=u.pos
	return best if best_d<INF else body.global_position

# Heavy feet landing on a unit crush it (and whatever is under the heel).
func stomp(point: Vector3, radius: float) -> void:
	for u in units:
		if not u.alive: continue
		var planar := Vector2(u.pos.x-point.x,u.pos.z-point.z).length()
		if planar<=radius and u.pos.y<4.0:
			body.damage(Vector3(u.pos.x,body.global_position.y+3.0,u.pos.z),radius*0.9,Vector3.DOWN*6.0)

func sync_alive() -> void:
	for u in units:
		var id := "u%d" % u.id
		if body.structure.disabled.get(id,false) and u.alive:
			u.alive=false
			u.state="DEAD"

func before_damage(_contact: Vector3, _radius: float) -> void:
	pass

func after_damage(_b: Node3D) -> void:
	sync_alive()

func update(dt: float, owner_body: CombatMonster) -> void:
	var opponent: CombatMonster=owner_body.opponent
	sync_alive()
	var alive := alive_count()
	var climbers := 0
	var speed: float=float(data.get("speed",5.4))
	for u in units:
		if not u.alive: continue
		u.phase+=dt*(5.0 if u.state!="CLIMB" else 3.0)
		u.striking=maxf(0.0,u.striking-dt)
		if opponent==null or opponent.defeated or owner_body.defeated:
			u.state="CELEBRATE" if opponent!=null and opponent.defeated else "RALLY"
			continue
		var foe := opponent.position
		var ring_radius: float=(float(data.get("ring_radius",3.9))+opponent.behavior("body_radius",0.0))*u.jitter
		var slot := foe+Vector3(cos(u.ring+owner_body.clock*0.15),0,sin(u.ring+owner_body.clock*0.15))*ring_radius
		var to_slot: Vector3=slot-u.pos
		to_slot.y=0
		var to_foe: Vector3=foe-u.pos
		to_foe.y=0
		var distance: float=to_slot.length()
		var target_yaw := atan2(-to_foe.x,-to_foe.z)
		u.yaw=lerp_angle(u.yaw,target_yaw,1-exp(-dt*6.0))
		if distance>1.2 and u.climb<0.05:
			var step := minf(distance,speed*dt*clampf(owner_body.speed_factor()+0.3,0.5,1.2))
			u.pos+=to_slot.normalized()*step
			u.state="SWARM"
		else:
			u.state="CLIMB"
		if u.state=="CLIMB" or u.climb>0.0:
			var climb_target := 1.0 if u.state=="CLIMB" else 0.0
			u.climb=move_toward(u.climb,climb_target,dt*0.22)
			u.state="CLIMB"
			climbers+=1
		u.pos.y=u.climb*float(data.get("climb_height",13.0))*clampf(opponent.region_target("head").y/30.0,0.5,1.3)
		u.strike-=dt
		if u.strike<=0.0 and (u.climb>0.12 or distance<2.6):
			u.strike=float(data.get("strike_interval",1.5))*rng.randf_range(0.8,1.3)
			u.striking=0.35
			var region := "left_shin" if u.id%2==0 else "right_shin"
			if u.climb>0.5: region="chest"
			if u.climb>0.88: region="head"
			var point := opponent.region_target(region)
			if not opponent.region_centers.has(region): point=opponent.region_target("chest")
			var toward: Vector3=(point-u.pos).normalized()
			opponent.light_hit=true
			var report := opponent.damage(point,float(data.get("strike_radius",1.0)),toward*float(data.get("strike_force",4.0)))
			opponent.light_hit=false
			if report.direct>0:
				strike_count+=1
				var battle: Node3D=owner_body.get_parent()
				if strike_count%3==0: battle.on_impact(owner_body,opponent,"swarm_pummel",point,report,float(data.get("strike_force",4.0)))
				else: battle.effects.burst(point,0,false,Vector3.UP)
	climbing_peak=maxi(climbing_peak,climbers)
	# Destabilisation: enough climbers slow and unbalance the host.
	if climbers>=3 and opponent!=null and not opponent.defeated:
		opponent.status["web"]=0.4
		opponent.status["web_slow"]=clampf(0.92-0.05*climbers,0.5,0.92)
	# Entrant root follows the surviving centroid so AI, camera and separation see one body.
	if alive>0:
		var c := Vector3.ZERO
		for u in units: if u.alive: c+=Vector3(u.pos.x,0,u.pos.z)
		c/=alive
		owner_body.position=Vector3(c.x,-0.6,c.z)
		owner_body.rotation=Vector3.ZERO
	owner_body.state="SWARMING %d/10" % alive
	if alive==0 and not owner_body.defeated: owner_body.defeat("ALL UNITS DESTROYED")
