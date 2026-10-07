class_name RigMulti
extends RefCounted

# Data-driven multi-limb rig: a rigid body mass, N planted two-bone chains (legs / tentacles / arms),
# rigid weapons (lance) and optional squash. Used by the Tarantula, Dark Knight Rider, Eyeball Beast and Blob.
var effectors := {}
var feet := {}
var stepping := {}      # chain id -> {age, start, goal}
var data: Dictionary = {}
var rest := {}          # chain id -> {root, mid, end, upper, lower}
var ready := false

func v3(a: Array) -> Vector3:
	return Vector3(a[0],a[1],a[2])

func reset(body: Node3D) -> void:
	data=body.archetype.get("rig_multi",{})
	feet.clear()
	stepping.clear()
	rest.clear()
	for chain in data.get("chains",[]):
		var r := v3(chain.root)
		var m := v3(chain.mid)
		var e := v3(chain["end"])
		rest[chain.id]={"root":r,"mid":m,"end":e,"upper":r.distance_to(m),"lower":m.distance_to(e)}
		feet[chain.id]=body.to_global(e)
	ready=true

func bone(from: Vector3, to: Vector3) -> Basis:
	if from.length()<0.01 or to.length()<0.01: return Basis.IDENTITY
	return Basis(Quaternion(from.normalized(),to.normalized()))

func solve(root: Vector3, goal: Vector3, upper: float, lower: float, bend_hint: Vector3) -> Array:
	var delta := goal-root
	var distance := clampf(delta.length(),0.5,upper+lower-0.035)
	var direction := delta.normalized() if delta.length()>0.01 else Vector3.DOWN
	var along := (upper*upper-lower*lower+distance*distance)/(2*distance)
	var height := sqrt(maxf(0,upper*upper-along*along))
	var bend := bend_hint-direction*bend_hint.dot(direction)
	if bend.length()<0.01: bend=Vector3.RIGHT.cross(direction)
	return [root+direction*along+bend.normalized()*height,root+direction*distance]

func chain_ok(body: Node3D, id: String) -> bool:
	return not body.structure.disabled.get(id,false)

# Called by the combatant each step: plants feet and alternates steps.
func update_gait(body: Node3D, dt: float) -> void:
	if not ready: return
	var gait: Dictionary=data.get("gait",{})
	var duration: float=float(gait.get("step_seconds",0.6))+(1.0-body.speed_factor())*0.35
	var threshold: float=float(gait.get("threshold",1.7))
	var max_steps := int(gait.get("max_simultaneous",2))
	for id in stepping.keys():
		var s: Dictionary=stepping[id]
		s.age+=dt
		var t := clampf(s.age/duration,0,1)
		feet[id]=s.start.lerp(s.goal,smoothstep(0,1,t))+Vector3.UP*sin(t*PI)*float(gait.get("lift",0.9))
		if t>=1:
			feet[id]=s.goal
			stepping.erase(id)
	if stepping.size()>=max_steps: return
	var attack: MonsterAttack=body.attack_motion
	for chain in data.get("chains",[]):
		var id: String=chain.id
		if chain.get("role","leg")!="leg" or stepping.has(id) or not chain_ok(body,id): continue
		if attack.running and attack.profile.get("effector","")==id: continue
		var desired: Vector3=body.to_global(v3(chain["end"]))
		desired.y=0.95+float(chain.get("foot_height",0.0))
		if feet[id].distance_to(desired)>threshold:
			stepping[id]={"age":0.0,"start":feet[id],"goal":desired+body.velocity*0.45}
			stepping[id].goal.y=desired.y
			if stepping.size()>=max_steps: break

func apply(body: Node3D) -> void:
	var started := Time.get_ticks_usec()
	if not ready: reset(body)
	var attack: MonsterAttack=body.attack_motion
	var swing := attack.reach if attack.running else 0.0
	var pivot := v3(data.get("pivot",[0,8,0]))
	var lean: float=body.lean-maxf(0,swing)*float(data.get("attack_lean",0.1))
	var squash := Vector3.ONE
	if data.has("squash"):
		var q: Dictionary=data.squash
		var wob := sin(body.clock*float(q.get("speed",1.8)))*float(q.amp)
		var slump := clampf(body.velocity.length()*0.05,0.0,0.1)
		squash=Vector3(1.0+wob+slump,1.0-wob-slump*1.6,1.0+wob*0.6+slump)
		lean+=sin(body.clock*0.7)*0.015
	var body_basis := Basis(Vector3.UP,0)*Basis(Vector3.RIGHT,lean)*Basis(Vector3.FORWARD,body.sway)
	if data.has("squash"): body_basis=body_basis*Basis.from_scale(squash)
	var anchor := Vector3(pivot.x,1.0,pivot.z) if data.has("squash") else pivot
	var body_t := Transform3D(body_basis,anchor+Vector3(0,body.bob,0)-body_basis*anchor)
	var transforms := {}
	for region in body.renders: transforms[region]=body_t
	# Rigid parts with their own attack lean (rider leaning into a lance, head lunging).
	for part in data.get("parts",[]):
		var part_t := body_t
		if part.has("lean_gain") and attack.running:
			var pp := v3(part.pivot)
			var tilt := Basis(Vector3.RIGHT,-maxf(0,swing)*float(part.lean_gain))
			part_t=body_t*Transform3D(tilt,pp-tilt*pp)
		if part.has("recoil") and body.head_recoil>0:
			var pr := v3(part.pivot)
			var snap := Basis(Vector3.RIGHT,body.head_recoil*float(part.recoil))
			part_t=part_t*Transform3D(snap,pr-snap*pr)
		for region in part.regions: transforms[region]=part_t
	# Weapons: rigid extension that thrusts along its axis.
	for weapon in data.get("weapons",[]):
		var thrust := v3(weapon.thrust)*float(weapon.get("length",5.0))
		var amount := 0.0
		if attack.running and attack.profile.get("effector","")==weapon.effector: amount=clampf(attack.reach,-0.25,1.0)
		var aim_basis := Basis.IDENTITY
		var weapon_pivot := v3(weapon.pivot) if weapon.has("pivot") else Vector3.ZERO
		var shift := thrust*amount
		if attack.running and attack.profile.get("effector","")==weapon.effector and weapon.has("pivot"):
			# The mounted weapon swings toward its target (bounded) and its contact point travels through it,
			# so a lance can find a smaller opponent instead of only sweeping its far tip.
			var aim_local: Vector3=body.to_local(attack.aim)
			var yaw := clampf(atan2(-aim_local.x,-aim_local.z),-0.38,0.38)
			var pitch := clampf(atan2(aim_local.y-weapon_pivot.y,maxf(1.0,-aim_local.z)),-0.25,0.2)
			aim_basis=Basis(Vector3.UP,yaw)*Basis(Vector3.RIGHT,pitch)
			var tip_rest := v3(weapon.tip)
			var tip_len := weapon_pivot.distance_to(tip_rest)
			var travel := float(weapon.get("length",5.0))
			var hit_len := minf((aim_local-weapon_pivot).length()+0.8,tip_len+travel)
			var reach_len := lerpf(hit_len-travel,hit_len,clampf(attack.reach,-0.25,1.0))
			shift=v3(weapon.thrust).normalized()*(reach_len-tip_len)
		var weapon_t: Transform3D=transforms.get(weapon.regions[0],body_t)*Transform3D(aim_basis,weapon_pivot-aim_basis*weapon_pivot)*Transform3D(Basis.IDENTITY,shift)
		for region in weapon.regions: transforms[region]=weapon_t
		effectors[weapon.effector]=body.to_global(weapon_t*v3(weapon.tip))
	# Chains.
	for chain in data.get("chains",[]):
		var id: String=chain.id
		var r: Dictionary=rest[id]
		var root: Vector3=body_t*r.root
		var role: String=chain.get("role","leg")
		var attacking: bool=attack.running and attack.profile.get("effector","")==id
		var goal: Vector3
		if attacking:
			goal=body.to_local(attack.endpoint)
		elif role=="leg":
			goal=body.to_local(feet[id])
			if not chain_ok(body,id): goal=root+Vector3(0,-3,0)*0.4
		else:
			var idle := v3(chain.get("idle",chain["end"]))
			var wave := Vector3(sin(body.clock*1.3+float(chain.get("phase",0.0))),sin(body.clock*0.9+float(chain.get("phase",0.0))*1.7)*0.6,cos(body.clock*1.1))*float(chain.get("wave",0.8))
			goal=body_t*(idle+wave)
		var pair := solve(root,goal,r.upper,r.lower,v3(chain.get("bend",[0,1,0])))
		var mid: Vector3=pair[0]
		var tip: Vector3=pair[1]
		var upper_basis := bone(r.mid-r.root,mid-root)
		var lower_basis := bone(r["end"]-r.mid,tip-mid)
		var regions: Array=chain.regions
		transforms[regions[0]]=Transform3D(upper_basis,root-upper_basis*r.root)
		var lower_t := Transform3D(lower_basis,mid-lower_basis*r.mid)
		for k in range(1,regions.size()): transforms[regions[k]]=lower_t
		effectors[id]=body.to_global(tip)
	var follow: Dictionary=body.archetype.get("follow",{})
	body.pose_transforms.clear()
	for region in body.renders:
		var source: String=follow.get(region,region)
		body.pose_transforms[region]=transforms.get(source,body_t)
	var head_anchor := v3(body.archetype.rig.get("head",[0,10,-3]))
	var head_t: Transform3D=transforms.get(data.get("head_region","head"),body_t)
	effectors.head=body.to_global(head_t*head_anchor)
	effectors.torso=body.to_global(body_t*v3(body.archetype.rig.get("torso",[0,8,-2])))
	body.sync_pose()
	body.animation_ms=(Time.get_ticks_usec()-started)/1000.0
