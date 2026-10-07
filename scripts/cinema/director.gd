extends RefCounted

var follow_center := Vector3.ZERO
var shot := "ESTABLISHING"
var age := 0.0
var cuts := 0
var cost_ms := 0.0
var history: Array[Dictionary]=[]
var position_goal := Vector3(8,10,66)
var look_goal := Vector3(0,14,0)
var lens := 48.0
var initialized := false
var impact_age := 100.0
var impact_tier := 0
var next_shot := 11.0
var battle: Node3D

func reset() -> void:
	initialized=false
	age=0
	cuts=0
	history.clear()
	shot="ESTABLISHING"
	next_shot=11

func notify_impact(_at: Vector3, tier: int) -> void:
	impact_tier=tier
	impact_age=0

func blocked(a: Vector3, b: Vector3) -> bool:
	for box: AABB in battle.arena.occluders:
		var low := 0.0
		var high := 1.0
		var delta := b-a
		for axis in 3:
			if absf(delta[axis])<0.0001:
				if a[axis]<box.position[axis] or a[axis]>box.end[axis]: low=2; break
			else:
				var t1 := (box.position[axis]-a[axis])/delta[axis]
				var t2 := (box.end[axis]-a[axis])/delta[axis]
				low=maxf(low,minf(t1,t2))
				high=minf(high,maxf(t1,t2))
		if low<=high and high>0 and low<1: return true
	return false

func coverage(at: Vector3, aim: Vector3, fov_degrees: float) -> float:
	var forward := (aim-at).normalized()
	var right := forward.cross(Vector3.UP).normalized()
	var up := right.cross(forward)
	var tangent := tan(deg_to_rad(fov_degrees)*0.5)
	var worst := 0.0
	for monster in battle.monsters:
		if monster.defeated: continue
		var top: Vector3=monster.region_target("head")+Vector3.UP*3
		for point in [top,monster.global_position+Vector3.UP,top+Vector3.RIGHT*4,top-Vector3.RIGHT*4,monster.region_target("chest")+Vector3.RIGHT*7,monster.region_target("chest")-Vector3.RIGHT*7]:
			var rel: Vector3=point-at
			var depth := maxf(0.1,rel.dot(forward))
			worst=maxf(worst,absf(rel.dot(up))/(depth*tangent))
			worst=maxf(worst,absf(rel.dot(right))/(depth*tangent*16.0/9.0))
	return worst

func choose(camera: Camera3D) -> void:
	var center: Vector3=(battle.monsters[0].global_position+battle.monsters[1].global_position)*0.5
	center.y=0
	var height := 0.0
	for monster in battle.monsters:
		if not monster.defeated: height=maxf(height,monster.region_target("head").y+3)
	var aim := center+Vector3.UP*maxf(7,height*0.52)
	var specs := [["STREET",Vector3(3,3.5,36),52.0],["TWO_SHOT",Vector3(-10,11,39),48.0],["RIM_SIDE",Vector3(17,7,32),53.0],["ELEVATED",Vector3(-12,29,43),46.0],["OVER_SHOULDER",Vector3(-19,18,26),56.0]]
	if battle.elapsed<10: specs=[["ESTABLISHING",Vector3(8,10,66),48.0]]
	if battle.finished:
		var survivor= battle.monsters[0] if not battle.monsters[0].defeated else battle.monsters[1]
		center=survivor.global_position
		center.y=0
		aim=center+Vector3.UP*maxf(5,survivor.region_target("head").y*0.48)
		specs=[["AFTERMATH",Vector3(11,5,35),48.0],["AFTERMATH_WIDE",Vector3(-10,13,47),48.0]]
	if not battle.monsters[0].archetype.is_empty():
		var axis: Vector3=battle.monsters[1].position-battle.monsters[0].position
		var orientation := atan2(axis.z,axis.x)
		for spec in specs: spec[1]=spec[1].rotated(Vector3.UP,orientation)
	var selected: Array=[]
	var best := -1000.0
	for i in specs.size():
		var spec: Array=specs[i]
		var at: Vector3=center+spec[1]
		var frame := coverage(at,aim,spec[2])
		if frame>0.90: at=aim+(at-aim)*(frame/0.84)
		if blocked(at,aim): continue
		var obstructed := false
		for monster in battle.monsters:
			if not monster.defeated and blocked(at,monster.region_target("chest")): obstructed=true
		if obstructed: continue
		var safe := true
		for monster in battle.monsters:
			if Vector2(at.x-monster.position.x,at.z-monster.position.z).length()<12: safe=false
		if not safe: continue
		var preference := 1.0-coverage(at,aim,spec[2])*0.15
		if spec[0]==shot: preference-=0.6
		preference+=0.15*sin(battle.elapsed*0.18+i*2.1)
		if spec[0]=="STREET" and impact_age<6 and impact_tier==2: preference+=0.20
		if preference>best:
			best=preference
			selected=[spec[0],at,aim,spec[2]]
	if selected.is_empty(): selected=["SAFE_WIDE",center+Vector3(0,36,76),aim,54.0]
	shot=selected[0]
	follow_center=center
	position_goal=selected[1]
	look_goal=selected[2]
	lens=selected[3]
	camera.global_position=position_goal
	camera.look_at(look_goal)
	camera.fov=lens
	age=0
	next_shot=10.0 if not battle.finished else 18.0
	initialized=true
	cuts+=1
	history.append({"time":snappedf(battle.elapsed,0.1),"shot":shot,"coverage":coverage(position_goal,look_goal,lens),"blocked":blocked(position_goal,look_goal),"position":str(position_goal)})

func update(dt: float, camera: Camera3D) -> void:
	var started := Time.get_ticks_usec()
	if not initialized: choose(camera)
	if battle.paused: return
	age+=dt
	impact_age+=dt
	var committed := false
	for monster in battle.monsters:
		if monster.attack_motion.running and monster.attack_motion.phase in ["WIND-UP","COMMIT"]: committed=true
	var needs_aftermath: bool=battle.finished and not shot.begins_with("AFTERMATH") and battle.elapsed-battle.finish_time>4
	var collapse_hold: bool=battle.finished and battle.elapsed-battle.finish_time<=4
	if needs_aftermath or (age>next_shot and not committed and not collapse_hold): choose(camera)
	var center: Vector3=(battle.monsters[0].region_target("chest")+battle.monsters[1].region_target("chest"))*0.5
	if battle.finished:
		var survivor= battle.monsters[0] if not battle.monsters[0].defeated else battle.monsters[1]
		center=survivor.region_target("chest")
	if not battle.monsters[0].archetype.is_empty():
		var current_middle: Vector3=(battle.monsters[0].position+battle.monsters[1].position)*.5
		current_middle.y=0
		if battle.finished:
			current_middle=battle.monsters[0].position if not battle.monsters[0].defeated else battle.monsters[1].position
			current_middle.y=0
		var shift := current_middle-follow_center
		position_goal+=shift
		look_goal+=shift
		follow_center=current_middle
		if age>2 and (coverage(position_goal,look_goal,lens)>1.05 or blocked(position_goal,center)): choose(camera)
	var aim := look_goal.lerp(center,0.15)
	var drift := Vector3(sin(age*0.10)*0.8,0,0)
	var frame := coverage(position_goal+drift,aim,lens)
	if frame>.91:
		position_goal=aim+(position_goal-aim)*(1+dt*.4)
	camera.position=camera.position.lerp(position_goal+drift,1-exp(-dt*0.8))
	camera.look_at(aim)
	cost_ms=(Time.get_ticks_usec()-started)/1000.0
