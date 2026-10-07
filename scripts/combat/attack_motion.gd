class_name MonsterAttack
extends RefCounted

var charge_heading := Vector3.ZERO
var running := false
var age := 0.0
var move := ""
var side := ""
var region := ""
var profile := {}
var target: Node3D
var aim := Vector3.ZERO
var start := Vector3.ZERO
var previous := Vector3.ZERO
var endpoint := Vector3.ZERO
var hit := false
var phase := "READY"
var progress := 0.0
var reach := 0.0

func begin(body: Node3D, opponent: Node3D, command: String, selected: String, selected_side: String) -> void:
	move=command
	profile=MonsterMoves.profile(body,move)
	charge_heading=(opponent.position-body.position).normalized()
	side=selected_side
	region=selected
	target=opponent
	aim=opponent.region_target(region)
	start=body.effector(move,side)
	previous=start
	endpoint=start
	phase="WIND-UP"
	age=0
	hit=false
	running=true

func cancel() -> void:
	running=false
	phase="READY"
	reach=0

func update(dt: float, body: Node3D) -> void:
	if not running: return
	if not MonsterMoves.available(body,move): cancel(); return
	if profile.limb=="arm" and not MonsterMoves.functional_arm(body,side): cancel(); return
	if profile.limb=="leg" and body.structure.leg_quality(side)<=0.45: cancel(); return
	age+=dt
	var w: float=profile.wind
	var c: float=profile.commit
	var f: float=profile.follow
	var r: float=profile.recover
	if age<w:
		phase="WIND-UP"
		progress=smoothstep(0,w,age)
		reach=-0.22*progress
	elif age<w+c:
		phase="COMMIT"
		progress=smoothstep(w,w+c,age)
		reach=progress
	elif age<w+c+f:
		phase="FOLLOW-THROUGH"
		progress=1
		reach=1
	elif age<w+c+f+r:
		phase="RECOVER"
		progress=smoothstep(w+c+f,w+c+f+r,age)
		reach=1-progress
	else: cancel(); return
	# Target tracks during wind-up, then the committed stroke cannot home in.
	if phase=="WIND-UP": aim=target.region_target(region)
	# Head/body attacks commit a deliberate weight transfer into close contact.
	if phase in ["COMMIT","FOLLOW-THROUGH"] and profile.get("base",move) in ["headbutt","body_charge"] and profile.get("trajectory","")!="charge":
		body.position-=body.global_basis.z*dt*(1.3 if profile.get("base",move)=="headbutt" else 1.8)
	var trajectory: String=profile.get("trajectory","")
	var sign_side := -1.0 if side=="left" else 1.0
	var desired := aim
	var direction := (aim-start).normalized()
	var windup := start-direction*1.3+Vector3.UP*2.8
	if profile.get("base",move)=="heavy_hook": windup=start+body.global_basis*Vector3(sign_side*3,4.5,0.8)
	if profile.get("base",move)=="kick": windup=start+Vector3.UP*4+body.global_basis*Vector3(0,0,1.4)
	if trajectory=="overhead": windup=start+Vector3.UP*7+body.global_basis*Vector3(0,0,1)
	if trajectory=="backhand": windup=start+body.global_basis*Vector3(-sign_side*5,2,-1)
	if phase=="WIND-UP": desired=start.lerp(windup,progress)
	elif phase=="COMMIT":
		if profile.get("base",move)=="heavy_hook":
			var control := aim+body.global_basis*Vector3(sign_side*3,1.4,-1.0)
			desired=windup.lerp(control,progress).lerp(control.lerp(aim+direction*0.8,progress),progress)
		else: desired=windup.lerp(aim+direction*0.8,progress)
	elif phase=="FOLLOW-THROUGH": desired=aim+direction*0.8
	else:
		var rest: Vector3=body.feet[side] if profile.get("base",move)=="kick" else body.to_global(body.rig_point("idle_hand",Vector3(sign_side*4,18,-3),side))
		desired=(aim+direction*0.8).lerp(rest,progress)
	endpoint=desired

func resolve(body: Node3D, battle: Node3D) -> void:
	if not running or phase!="COMMIT" or hit or body.defeated: return
	var current: Vector3=body.effector(move,side)
	var contact: Dictionary=target.sweep(previous,current,profile.collider)
	previous=current
	if contact.is_empty(): return
	hit=true
	var force: Vector3=(target.global_position-body.global_position).normalized()*profile.force
	if profile.get("base",move)=="heavy_hook": force+=body.global_basis*Vector3((-1 if side=="left" else 1)*8,2,0)
	var escalation := 1.0+clampf((battle.elapsed-35)/140.0,0,0.32)
	var report: Dictionary=target.damage(contact.point,profile.radius*escalation,force)
	if report.direct==0: return
	battle.on_impact(body,target,move,contact.point,report,profile.force)
