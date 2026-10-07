class_name MonsterRig
extends RefCounted

var effectors := {}

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

# Chained secondary parts (tails, wings, capes): each segment rotates about its own joint.
func apply_extras(body: Node3D, transforms: Dictionary) -> void:
	var attack: MonsterAttack=body.attack_motion
	for entry in body.archetype.extras:
		var parent: Transform3D=transforms.get(entry.get("parent","torso"),transforms.torso)
		var chain := parent
		var regions: Array=entry.regions
		var pivots: Array=entry.pivots
		var axis := Vector3(entry.axis[0],entry.axis[1],entry.axis[2]).normalized()
		var side_sign := float(entry.get("sign",1.0))
		var amplitude := 0.0
		var speed := 1.0
		var lag := 0.5
		if entry.has("flap"):
			var air := 0.0
			if body.flight!=null: air=1.0 if body.flight.state in ["FLYING","TAKEOFF"] else 0.5 if body.flight.state=="LANDING" else 0.0
			var flap: Dictionary=entry.flap
			amplitude=lerpf(float(flap.ground),float(flap.air),air)
			speed=float(flap.speed)*(1.0+air*0.6)
			lag=float(flap.get("lag",0.35))
		elif entry.has("sway"):
			var sway_data: Dictionary=entry.sway
			amplitude=float(sway_data.amp)*(0.6+min(body.velocity.length(),3.0)*0.2)
			speed=float(sway_data.speed)
			lag=float(sway_data.get("lag",0.55))
		for i in regions.size():
			var angle := side_sign*amplitude*sin(body.clock*speed-i*lag)*(1.0+0.3*i)
			if entry.has("flap"): angle+=side_sign*float(entry.flap.get("rest",0.0))
			var pivot := Vector3(pivots[i][0],pivots[i][1],pivots[i][2])
			var rotation_basis := Basis(axis,angle)
			chain=chain*Transform3D(rotation_basis,pivot-rotation_basis*pivot)
			transforms[regions[i]]=chain
		if entry.has("tip"):
			var tip: Array=entry.tip
			effectors[entry.get("effector",entry.id+"_tip")]=body.to_global(chain*Vector3(tip[0],tip[1],tip[2]))

func apply(body: Node3D) -> void:
	var started := Time.get_ticks_usec()
	var attack: MonsterAttack=body.attack_motion
	var family: String=attack.profile.get("base",attack.move)
	var swing := attack.reach if attack.running else 0.0
	var sign_side := -1.0 if attack.side=="left" else 1.0
	var twist := sign_side*swing*0.28 if attack.running else 0.0
	var lean: float=body.lean
	if attack.running:
		lean-=maxf(0,swing)*(0.34 if family=="headbutt" else 0.24 if family=="body_charge" else 0.12)
	var base: Vector3= body.rig_point("pivot",Vector3(0,12,0))
	var body_basis := Basis(Vector3.UP,twist)*Basis(Vector3.RIGHT,lean)*Basis(Vector3.FORWARD,body.sway)
	var body_offset := Vector3(0,body.bob,0)
	var transforms := {}
	for major in ["torso","head","left_arm","right_arm"]:
		transforms[major]=Transform3D(body_basis,base+body_offset-body_basis*base)
	for side in ["left","right"]:
		var s := -1.0 if side=="left" else 1.0
		var shoulder_rest: Vector3= body.rig_point("shoulder",Vector3(s*5,19.5,0),side)
		var elbow_rest: Vector3= body.rig_point("elbow",Vector3(s*6.2,15.5,-0.1),side)
		var hand_rest: Vector3= body.rig_point("hand",Vector3(s*6.5,11.3,-0.6),side)
		var torso: Transform3D=transforms.torso
		var shoulder: Vector3=torso*shoulder_rest
		var goal: Vector3= torso*body.rig_point("idle_hand",Vector3(s*4.8,17.7,-3.1),side)
		if body.guarding: goal=torso*body.rig_point("guard",Vector3(s*3.0,23.0,-3.5),side)
		if attack.running and attack.side==side and attack.profile.limb in ["arm",side+"_arm"]:
			goal=body.to_local(attack.endpoint)
		var pair := solve(shoulder,goal,shoulder_rest.distance_to(elbow_rest),elbow_rest.distance_to(hand_rest),Vector3(s*0.5,-1,1))
		var elbow: Vector3=pair[0]
		var hand: Vector3=pair[1]
		var upper_basis := bone(elbow_rest-shoulder_rest,elbow-shoulder)
		var lower_basis := bone(hand_rest-elbow_rest,hand-elbow)
		transforms[side+"_upper_arm"]=Transform3D(upper_basis,shoulder-upper_basis*shoulder_rest)
		transforms[side+"_forearm"]=Transform3D(lower_basis,elbow-lower_basis*elbow_rest)
		transforms[side+"_fist"]=transforms[side+"_forearm"]
		effectors[side+"_arm"]=body.to_global(hand)
		var hip_rest: Vector3= body.rig_point("hip",Vector3(s*2,11,0),side)
		var knee_rest: Vector3= body.rig_point("knee",Vector3(s*2,6.5,0),side)
		var foot_rest: Vector3= body.rig_point("foot",Vector3(s*2,1,-0.9),side)
		var hip: Vector3= hip_rest+Vector3(0,body.bob,0)
		var foot: Vector3=body.to_local(body.feet[side])
		if attack.running and family=="kick" and attack.side==side: foot=body.to_local(attack.endpoint)
		var legs := solve(hip,foot,hip_rest.distance_to(knee_rest),knee_rest.distance_to(foot_rest),Vector3(0,0,-1))
		var knee: Vector3=legs[0]
		var ankle: Vector3=legs[1]
		var thigh_basis := bone(knee_rest-hip_rest,knee-hip)
		var shin_basis := bone(foot_rest-knee_rest,ankle-knee)
		transforms[side+"_thigh"]=Transform3D(thigh_basis,hip-thigh_basis*hip_rest)
		transforms[side+"_shin"]=Transform3D(shin_basis,knee-shin_basis*knee_rest)
		transforms[side+"_foot"]=Transform3D(Basis.IDENTITY,ankle-foot_rest)
		effectors[side+"_leg"]=body.to_global(ankle)
	# A separate head snap is visible without throwing the whole creature around.
	if body.head_recoil>0:
		var head_pivot: Vector3=transforms.head*body.rig_point("head_pivot",Vector3(0,22,0))
		var snap := Basis(Vector3.RIGHT,body.head_recoil*0.10)
		transforms.head=Transform3D(snap,head_pivot-snap*head_pivot)*transforms.head
	if not body.archetype.is_empty() and body.archetype.has("extras"): apply_extras(body,transforms)
	var follow: Dictionary={} if body.archetype.is_empty() else body.archetype.get("follow",{})
	if not body.archetype.is_empty() and body.archetype.has("tips"):
		for key in body.archetype.tips:
			var tip: Dictionary=body.archetype.tips[key]
			var source: String=tip.follow
			var point: Array=tip.point
			effectors[key]=body.to_global(transforms.get(source,transforms.torso)*Vector3(point[0],point[1],point[2]))
	body.pose_transforms.clear()
	for region in body.renders:
		var source: String=follow.get(region,region)
		body.pose_transforms[region]=transforms.get(source,transforms.torso if region in ["neck","chest","abdomen","pelvis","left_shoulder","right_shoulder"] else Transform3D.IDENTITY)
	effectors.head=body.to_global(transforms.head*body.rig_point("head",Vector3(0,25,-1.4)))
	effectors.torso=body.to_global(transforms.torso*body.rig_point("torso",Vector3(0,18,-2.4)))
	body.sync_pose()
	body.animation_ms=(Time.get_ticks_usec()-started)/1000.0

