class_name CombatMonster
extends PixelMonster

var rig := MonsterRig.new()
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

func setup_fighter(color: Color, debris_manager: Node3D, spawn: Vector3, facing: float) -> void:
	dynamic_pose=true
	position=spawn
	rotation.y=facing
	spawn_yaw=facing
	initialize(color,debris_manager)
	reset_motion()

func reset_motion() -> void:
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
		feet[side]=to_global(Vector3(-2 if side=="left" else 2,1,-0.9))
	rig.apply(self)

func speed_factor() -> float:
	var left := structure.leg_quality("left")
	var right := structure.leg_quality("right")
	if left==0 and right==0: return 0.12
	if left==0 or right==0: return 0.32*maxf(left,right)
	return clampf((left+right)*0.5,0.25,1)

func request_move(world_velocity: Vector3, facing: float) -> void:
	desired_velocity=world_velocity
	facing_target=facing

func request_attack(command: String, opponent: CombatMonster, region: String, side: String) -> bool:
	if defeated or opponent.defeated or attack_motion.running or cooldown>0 or stagger>0.25: return false
	if not MonsterMoves.available(self,command): return false
	if MonsterMoves.MOVES[command].limb=="arm" and not MonsterMoves.functional_arm(self,side): return false
	if MonsterMoves.MOVES[command].limb=="leg" and structure.leg_quality(side)<=0.45: return false
	attack_motion.begin(self,opponent,command,region,side)
	attack_history.append(command)
	if attack_history.size()>4: attack_history.pop_front()
	commands+=1
	guarding=false
	state=MonsterMoves.MOVES[command].label
	return true

func effector(command: String, side: String) -> Vector3:
	var key: String=side+"_leg" if command=="kick" else "head" if command=="headbutt" else "torso" if command=="body_charge" else side+"_arm"
	return rig.effectors.get(key,to_global(Vector3(0,18,-2)))

func update_motor(dt: float) -> void:
	var start := Time.get_ticks_usec()
	clock+=dt
	if defeated:
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
	if stagger>0: desired*=0.15
	if attack_motion.running: desired*=0.12
	velocity=velocity.move_toward(desired,dt*0.85)
	knock_velocity=knock_velocity.move_toward(Vector3.ZERO,dt*1.7)
	position+=(velocity+knock_velocity)*dt
	position.x=clampf(position.x,-24,24)
	position.z=clampf(position.z,-16,16)
	var yaw_delta := angle_difference(rotation.y,facing_target)
	var wanted_turn := clampf(yaw_delta*0.8,-0.44,0.44)*maxf(speed,0.35)
	if attack_motion.running and attack_motion.phase!="WIND-UP": wanted_turn*=0.15
	angular_velocity=move_toward(angular_velocity,wanted_turn,dt*0.6)
	rotation.y+=angular_velocity*dt
	var legs_lost := int(structure.disabled.left_leg)+int(structure.disabled.right_leg)
	var stance_height := -0.6 if legs_lost==0 else -3.5 if legs_lost==1 else -support_height+0.4
	if legs_lost==0: stance_height-=clampf(0.7-speed,0,0.7)*2.5
	position.y=move_toward(position.y,stance_height,dt*1.9)
	lean=lerpf(lean,clampf(stagger*0.15,0,0.18),1-exp(-5*dt))
	sway=sin(clock*2.2)*0.012*velocity.length()+sin(clock*7)*stagger*0.025
	bob=sin(clock*2.2)*0.08*velocity.length()+sin(clock*0.8)*0.025
	update_feet(dt)
	var was_running := attack_motion.running
	attack_motion.update(dt,self)
	if was_running and not attack_motion.running:
		cooldown=0.75
		missed_attacks=0 if attack_motion.hit else missed_attacks+1
	motor_ms=(Time.get_ticks_usec()-start)/1000.0

func update_feet(dt: float) -> void:
	if stepping!="":
		step_age+=dt
		var duration := 0.95+(1-speed_factor())*0.35
		var t := clampf(step_age/duration,0,1)
		feet[stepping]=step_start.lerp(step_goal,smoothstep(0,1,t))+Vector3.UP*sin(t*PI)*(0.8 if speed_factor()>0.6 else 0.35)
		if t>=1:
			feet[stepping]=step_goal
			next_foot="right" if stepping=="left" else "left"
			stepping=""
		return
	if attack_motion.running and attack_motion.move=="kick": return
	for choice in [next_foot,"right" if next_foot=="left" else "left"]:
		if structure.disabled[choice+"_leg"]: continue
		var desired: Vector3=to_global(Vector3(-2 if choice=="left" else 2,1-position.y,-0.9))
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
	var result := super.damage(contact,radius,force)
	if result.direct>0:
		stagger=maxf(stagger,0.45+radius*0.12)
		head_recoil=1.0 if to_local(contact).y>21 else 0.3
		var planar := Vector3(force.x,0,force.z)
		knock_velocity+=planar.normalized()*clampf(radius*0.38,0.4,1.4)
		if attack_motion.running and attack_motion.phase=="WIND-UP" and radius>2.2:
			attack_motion.cancel()
			cooldown=1.0
		var reason := structure.fatal_reason()
		if reason!="": defeat(reason)
	return result

func defeat(reason: String) -> void:
	defeated=true
	defeat_reason=reason
	state="COLLAPSING"
	attack_motion.cancel()
	velocity=Vector3.ZERO
	desired_velocity=Vector3.ZERO
	collapse_side=-1.0 if position.x<0 else 1.0

func _process(_dt: float) -> void:
	pass
