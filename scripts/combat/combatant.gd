class_name CombatMonster
extends PixelMonster

var rig = MonsterRig.new()
var attack_motion := MonsterAttack.new()
var velocity := Vector3.ZERO
var desired_velocity := Vector3.ZERO
var facing_target := 0.0
var angular_velocity := 0.0
var feet := {"left":Vector3.ZERO,"right":Vector3.ZERO}
var stepping := ""
var step_age := 0.0
var step_start := Vector3.ZERO
var step_goal := Vector3.ZERO
var next_foot := "left"
var guarding := false
var lean := 0.0
var sway := 0.0
var bob := 0.0
var head_recoil := 0.0
var stagger := 0.0
var knock_velocity := Vector3.ZERO
var cooldown := 0.0
var clock := 0.0
var defeated := false
var defeat_reason := ""
var collapse_age := 0.0
var collapsed := false
var collapse_side := 1.0
var state := "STANDOFF"
var attack_history: Array[String]=[]
var commands := 0
var connected_hits := 0
var guard_time := 0.0
var spawn_yaw := 0.0
var motor_ms := 0.0
var missed_attacks := 0
var status := {}
var hold_age := 0.0
var hold_tick := 0.0
var hold_profile := {}
var hold_move := ""
var hold_side := ""
var knock_decay := 1.2
var light_hit := false
var hop_offset := 0.0
var swarm: SwarmUnits
var opponent: CombatMonster
const RigMultiScript = preload("res://scripts/combat/rig_multi.gd")
const RigSerpentScript = preload("res://scripts/combat/rig_serpent.gd")
const RigSwarmScript = preload("res://scripts/combat/rig_swarm.gd")

func setup_fighter(color: Color, debris_manager: Node3D, spawn: Vector3, facing: float) -> void:
	dynamic_pose=true
	position=spawn
	rotation.y=facing
	spawn_yaw=facing
	initialize(color,debris_manager)
	reset_motion()

func make_rig():
	match rig_type:
		"multi": return RigMultiScript.new()
		"serpent": return RigSerpentScript.new()
		"swarm": return RigSwarmScript.new()
	return MonsterRig.new()

func reset_motion() -> void:
	rig=make_rig()
	move_cd.clear()
	status.clear()
	fist_away.clear()
	held_by=null
	hold_target=null
	reassembling=false
	knock_decay=1.2
	hop_offset=0.0
	flight=null
	if archetype.get("special",{}).has("flight"):
		flight=FlightState.new()
		flight.setup(archetype.special.flight)
	swarm=null
	if rig_type=="swarm":
		swarm=SwarmUnits.new()
		swarm.setup(self,archetype.special.swarm)
	position=home
	rotation=Vector3(0,spawn_yaw,0)
	facing_target=spawn_yaw
	velocity=Vector3.ZERO
	desired_velocity=Vector3.ZERO
	angular_velocity=0
	knock_velocity=Vector3.ZERO
	attack_motion.cancel()
	stagger=0
	cooldown=0
	clock=0
	defeated=false
	collapsed=false
	defeat_reason=""
	collapse_age=0
	guarding=false
	guard_time=0
	attack_history.clear()
	commands=0
	connected_hits=0
	state="STANDOFF"
	motor_ms=0
	missed_attacks=0
	stepping=""
	next_foot="left"
	for side in ["left","right"]:
		feet[side]=to_global(rig_point("foot",Vector3(-2 if side=="left" else 2,1,-0.9),side))
	if rig.has_method("reset"): rig.reset(self)
	rig.apply(self)

func speed_factor() -> float:
	var value := mobility()
	if status.get("web",0.0)>0.0: value*=float(status.get("web_slow",0.45))
	if flight!=null: value*=flight.speed_multiplier()
	if held_by!=null: value=0.0
	return value

func mobility() -> float:
	var locomotion: Dictionary=archetype.get("locomotion",{})
	match locomotion.get("type","biped"):
		"legs":
			var total := 0.0
			var ids: Array=locomotion.legs
			for id in ids: total+=structure.limb_quality(id)
			var mean := total/ids.size()
			if mean<=0: return 0.1
			return clampf(pow(mean,float(locomotion.get("power",1.25))),0.12,1.0)
		"serpent":
			var total := 0.0
			var n := 0
			for limb in structure.limbs:
				if limb.get("kind","")=="segment":
					total+=structure.limb_quality(limb.id)
					n+=1
			return clampf(pow(total/maxi(1,n),float(locomotion.get("power",1.3))),0.12,1.0)
		"swarm":
			return clampf(float(swarm.alive_count())/10.0+0.2,0.25,1.0) if swarm!=null else 1.0
		"mass":
			return clampf(structure.fraction(String(locomotion.group))*1.2,0.2,1.0)
	return biped_mobility()

func biped_mobility() -> float:
	var left := structure.leg_quality("left")
	var right := structure.leg_quality("right")
	if left==0 and right==0: return 0.12
	if left==0 or right==0: return 0.32*maxf(left,right)
	return clampf((left+right)*0.5,0.25,1)

func focus_point(from: Vector3) -> Vector3:
	if rig_type=="swarm" and swarm!=null: return swarm.nearest_point(from)
	return position

func request_move(world_velocity: Vector3, facing: float) -> void:
	desired_velocity=world_velocity
	facing_target=facing

func request_attack(command: String, opponent: CombatMonster, region: String, side: String) -> bool:
	if defeated or opponent.defeated or attack_motion.running or cooldown>0 or stagger>0.25 or held_by!=null or reassembling: return false
	if not MonsterMoves.available(self,command): return false
	if MonsterMoves.profile(self,command).limb=="arm" and not MonsterMoves.functional_arm(self,side): return false
	if MonsterMoves.profile(self,command).limb=="leg" and structure.leg_quality(side)<=0.45: return false
	var chosen: Dictionary=MonsterMoves.profile(self,command)
	if chosen.has("cooldown"): move_cd[command]=float(chosen.cooldown)
	opponent.aim_from=position
	attack_motion.begin(self,opponent,command,region,side)
	attack_history.append(command)
	if attack_history.size()>4: attack_history.pop_front()
	commands+=1
	guarding=false
	state=MonsterMoves.profile(self,command).label
	return true

func effector(command: String, side: String) -> Vector3:
	var prof := MonsterMoves.profile(self,command)
	if prof.has("effector"): return rig.effectors.get(prof.effector,position+Vector3.UP*10)
	command=prof.get("base",command)
	var key: String=side+"_leg" if command=="kick" else "head" if command=="headbutt" else "torso" if command=="body_charge" else side+"_arm"
	return rig.effectors.get(key,to_global(Vector3(0,18,-2)))

func tick_timers(dt: float) -> void:
	for key in move_cd.keys(): move_cd[key]=maxf(0.0,float(move_cd[key])-dt)
	for key in status.keys():
		if status[key] is float and key in ["web"]: status[key]=maxf(0.0,float(status[key])-dt)
	for side in fist_away.keys():
		var was: float=fist_away[side]
		fist_away[side]=maxf(0.0,was-dt)
		if renders.has(side+"_fist"): renders[side+"_fist"].visible=fist_away[side]<=0.0
		if was>0 and fist_away[side]<=0:
			pass

func update_motor(dt: float) -> void:
	var start := Time.get_ticks_usec()
	clock+=dt
	tick_timers(dt)
	if regen!=null: regen.update(dt)
	if rig_type=="swarm" and swarm!=null and not defeated:
		swarm.update(dt,self)
		motor_ms=(Time.get_ticks_usec()-start)/1000.0
		return
	if defeated:
		if regen!=null: regen.release_all()
		if rig_type=="swarm":
			collapsed=true
			return
		collapse_age+=dt
		var fall := smoothstep(0,1.8,collapse_age)
		rotation.z=collapse_side*fall*1.15
		position.y=lerpf(position.y,1.7,dt*1.5)
		if collapse_age>=1.8 and not collapsed:
			ensure_pose_index()
			for c in cubes:
				if not c.alive: continue
				var p: Vector3=to_global(c.pose)
				p.y=maxf(p.y,0.6)
				debris.spawn_cube(p,c.color,p+Vector3.UP*8,Vector3.DOWN*4)
				c.alive=false
			collapsed=true
			structure.refresh(cubes)
			rebuild()
		return
	cooldown=move_toward(cooldown,0,dt)
	stagger=move_toward(stagger,0,dt)
	head_recoil=move_toward(head_recoil,0,dt*1.3)
	guard_time=move_toward(guard_time,0,dt)
	guarding=guard_time>0 and not attack_motion.running
	var speed := speed_factor()
	var desired := desired_velocity*speed
	if held_by!=null or hold_target!=null: desired=Vector3.ZERO
	if reassembling: desired*=0.3
	if stagger>0: desired*=0.15
	if attack_motion.running: desired*=0.7 if attack_motion.phase=="RECOVER" and not archetype.is_empty() else 0.12
	var acceleration := behavior("acceleration",.85)
	if attack_motion.running and attack_motion.profile.get("trajectory","") in ["charge","leap"] and attack_motion.phase=="COMMIT":
		desired=attack_motion.charge_heading*attack_motion.profile.charge_speed*speed
		acceleration=4.0
	velocity=velocity.move_toward(desired,dt*acceleration)
	knock_velocity=knock_velocity.move_toward(Vector3.ZERO,dt*(1.7 if archetype.is_empty() else knock_decay))
	if knock_decay>1.2 and knock_velocity.length()<0.6: knock_decay=1.2
	if status.get("tether",null)!=null and status.get("web",0.0)>0.0:
		var anchor: Node3D=status.tether
		if is_instance_valid(anchor):
			var pull := anchor.position-position
			pull.y=0
			if pull.length()>8.6: position+=pull.normalized()*1.1*dt
	position+=(velocity+knock_velocity)*dt
	position.x=clampf(position.x,-24,24) if archetype.is_empty() else clampf(position.x,-24,24)
	position.z=clampf(position.z,-16,16) if archetype.is_empty() else clampf(position.z,-72,72)
	var yaw_delta := angle_difference(rotation.y,facing_target)
	var wanted_turn := clampf(yaw_delta*0.8,-behavior("turn_rate",.44),behavior("turn_rate",.44))*maxf(speed,0.35)
	if not archetype.is_empty():
		var outside_leg := structure.leg_quality("left" if wanted_turn>0 else "right")
		wanted_turn*=.45+.55*outside_leg
	if attack_motion.running and attack_motion.phase!="WIND-UP": wanted_turn*=0.15
	angular_velocity=move_toward(angular_velocity,wanted_turn,dt*behavior("turn_acceleration",.6))
	rotation.y+=angular_velocity*dt
	var legs_lost := int(structure.disabled.left_leg)+int(structure.disabled.right_leg)
	var stance_height := -0.6 if legs_lost==0 else -3.5 if legs_lost==1 else -support_height+0.4
	if legs_lost==0: stance_height-=clampf(0.7-speed,0,0.7)*2.5
	if rig_type!="biped":
		stance_height=float(archetype.rig.get("stance_y",-0.6))-clampf(0.7-speed,0,0.7)*float(archetype.rig.get("sag",1.5))
	if flight!=null:
		flight.diving=attack_motion.running and attack_motion.profile.get("trajectory","")=="charge" and flight.state=="FLYING"
		flight.update(dt,self)
		stance_height+=flight.altitude
	var hop := 0.0
	if attack_motion.running and attack_motion.profile.has("hop") and attack_motion.phase=="COMMIT":
		hop=float(attack_motion.profile.hop)*sin(attack_motion.progress*PI)
	hop_offset=lerpf(hop_offset,hop,1-exp(-dt*12))
	if flight!=null:
		position.y=lerpf(position.y,stance_height,1-exp(-dt*(5 if flight.state!="GROUNDED" else 3)))
	else:
		position.y=move_toward(position.y,stance_height+hop_offset,dt*(1.9 if hop==0 and hop_offset<0.05 else 14.0))
	if attack_motion.running and attack_motion.profile.get("trajectory","")=="spin" and attack_motion.phase=="COMMIT":
		rotation.y+=spin_direction()*TAU*float(attack_motion.profile.get("spin_turns",0.75))*dt/float(attack_motion.profile.commit)
		facing_target=rotation.y
	lean=lerpf(lean,clampf(stagger*0.15,0,0.18)+float(archetype.rig.get("stance_lean",0)) if not archetype.is_empty() else clampf(stagger*0.15,0,0.18),1-exp(-5*dt))
	sway=sin(clock*2.2)*0.012*velocity.length()+sin(clock*7)*stagger*0.025
	bob=sin(clock*2.2)*0.08*velocity.length()+sin(clock*0.8)*0.025
	if rig_type=="biped": update_feet(dt)
	elif rig.has_method("update_gait"): rig.update_gait(self,dt)
	var was_running := attack_motion.running
	attack_motion.update(dt,self)
	if was_running and not attack_motion.running:
		cooldown=0.75*(1.8 if status.get("web",0.0)>0.0 else 1.0)
		missed_attacks=0 if attack_motion.hit else missed_attacks+1
	motor_ms=(Time.get_ticks_usec()-start)/1000.0

func spin_direction() -> float:
	return -1.0 if attack_motion.side=="left" else 1.0

# ---- Grab / hold / throw / constrict / engulf ----
func begin_hold(victim: CombatMonster, prof: Dictionary, move: String, side: String) -> void:
	if hold_target!=null or victim.held_by!=null or victim.defeated: return
	hold_target=victim
	victim.held_by=self
	victim.attack_motion.cancel()
	hold_profile=prof.hold
	hold_move=move
	hold_side=side
	hold_age=0.0
	hold_tick=0.15

func end_hold(finished: bool, battle: Node3D) -> void:
	var victim := hold_target
	hold_target=null
	if victim==null: return
	victim.held_by=null
	if finished and not defeated:
		var away := (victim.position-position)
		away.y=0
		away=away.normalized() if away.length()>0.01 else -global_basis.z
		match hold_profile.get("end","drop"):
			"throw":
				victim.knock_decay=float(hold_profile.get("throw_decay",7.0))
				victim.knock_velocity=away*float(hold_profile.get("throw_speed",20.0))
				victim.stagger=maxf(victim.stagger,1.6)
				var report := victim.damage(victim.region_target("chest"),float(hold_profile.get("end_radius",3.0)),away*float(hold_profile.get("end_force",24.0)))
				if report.direct>0: battle.on_impact(self,victim,hold_move,victim.region_target("chest"),report,float(hold_profile.get("end_force",24.0)))
			"slam":
				victim.stagger=maxf(victim.stagger,1.4)
				var report2 := victim.damage(victim.region_target("abdomen"),float(hold_profile.get("end_radius",3.2)),Vector3.DOWN*20)
				if report2.direct>0: battle.on_impact(self,victim,hold_move,victim.region_target("abdomen"),report2,22.0)
			_:
				victim.stagger=maxf(victim.stagger,0.8)
	cooldown=maxf(cooldown,0.9)

func update_hold(dt: float, battle: Node3D) -> void:
	if hold_target==null: return
	var victim := hold_target
	if defeated or victim.defeated or stagger>1.2:
		end_hold(false,battle)
		return
	hold_age+=dt
	hold_tick-=dt
	state=String(hold_profile.get("label","HOLDING"))
	var forward := -global_basis.z
	var goal := position+forward*float(hold_profile.get("distance",6.5))
	goal.y=victim.position.y
	victim.position=victim.position.lerp(goal,1-exp(-dt*float(hold_profile.get("drag",2.5))))
	victim.stagger=maxf(victim.stagger,0.35)
	victim.desired_velocity=Vector3.ZERO
	if hold_tick<=0.0:
		hold_tick=float(hold_profile.get("tick",0.5))
		var point := victim.region_target(String(hold_profile.get("region","chest")))
		var report := victim.damage(point,float(hold_profile.get("tick_radius",1.5)),(point-global_position).normalized()*float(hold_profile.get("tick_force",8.0)))
		if report.direct>0: battle.on_impact(self,victim,hold_move,point,report,float(hold_profile.get("tick_force",8.0)))
	if hold_age>=float(hold_profile.duration): end_hold(true,battle)

func update_feet(dt: float) -> void:
	if stepping!="":
		step_age+=dt
		var duration := behavior("step_seconds",.95)+(1-speed_factor())*0.35
		var t := clampf(step_age/duration,0,1)
		feet[stepping]=step_start.lerp(step_goal,smoothstep(0,1,t))+Vector3.UP*sin(t*PI)*(0.8 if speed_factor()>0.6 else 0.35)
		if t>=1:
			feet[stepping]=step_goal
			next_foot="right" if stepping=="left" else "left"
			stepping=""
		return
	if attack_motion.running and attack_motion.profile.get("base",attack_motion.move)=="kick": return
	for choice in [next_foot,"right" if next_foot=="left" else "left"]:
		if structure.disabled[choice+"_leg"]: continue
		var desired: Vector3=to_global(rig_point("foot",Vector3(-2 if choice=="left" else 2,1-position.y,-0.9),choice))
		desired.y=1
		if feet[choice].distance_to(desired)>1.3:
			stepping=choice
			step_age=0
			step_start=feet[choice]
			step_goal=desired+velocity*0.5
			step_goal.y=1
			break

func update_pose() -> void:
	if not defeated: rig.apply(self)
	if attack_motion.running and attack_motion.phase=="WIND-UP": attack_motion.previous=effector(attack_motion.move,attack_motion.side)

func damage(contact: Vector3, radius: float, force: Vector3) -> Dictionary:
	if defeated: return {"direct":0,"detached":0,"remaining":alive_count(),"query_ms":0,"event_ms":0}
	if rig_type=="swarm" and swarm!=null: swarm.before_damage(contact,radius)
	var result := super.damage(contact,radius,force)
	if rig_type=="swarm" and swarm!=null: swarm.after_damage(self)
	if result.direct>0 and not light_hit:
		stagger=maxf(stagger,0.45+radius*0.12)
		head_recoil=1.0 if to_local(contact).y>21 else 0.3
		var planar := Vector3(force.x,0,force.z)
		knock_velocity+=planar.normalized()*clampf(radius*(.38 if archetype.is_empty() else .65),0.4,(1.4 if archetype.is_empty() else 2.7))
		if attack_motion.running and attack_motion.phase=="WIND-UP" and radius>2.2:
			attack_motion.cancel()
			cooldown=1.0
	if result.direct>0:
		var reason := structure.fatal_reason()
		if reason!="": defeat(reason)
	return result

func defeat(reason: String) -> void:
	defeated=true
	defeat_reason=reason
	state="COLLAPSING"
	attack_motion.cancel()
	if hold_target!=null: hold_target.held_by=null; hold_target=null
	if held_by!=null: held_by.hold_target=null; held_by=null
	velocity=Vector3.ZERO
	desired_velocity=Vector3.ZERO
	collapse_side=-1.0 if position.x<0 else 1.0

func _process(_dt: float) -> void:
	pass
