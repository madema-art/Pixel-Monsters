extends SceneTree
const Moves=preload("res://scripts/combat/moves.gd")
const Review=preload("res://tests/giant_ape_review.gd")
var failures:=0
var checks:=[]
var b: Node3D
func check(label: String, ok: bool) -> void:
	checks.append({"check":label,"passed":ok})
	if not ok:
		failures+=1
		push_error(label)
func _initialize() -> void: run.call_deferred()
func fresh() -> Node3D:
	Review.stage(b,"idle")
	return b.monsters[0]
func run() -> void:
	b=load("res://scenes/battle.tscn").instantiate()
	root.add_child(b)
	var m=fresh()
	check("Actual roster actor has 1000 cubes",m.cubes.size()==1000 and m.alive_count()==1000)
	var cells:={}
	for c in m.cubes: cells[c.cell]=true
	check("Unique physical cells",cells.size()==1000)
	var exposed:=true
	for c in m.cubes:
		var visible:=false
		for d in [Vector3i.LEFT,Vector3i.RIGHT,Vector3i.UP,Vector3i.DOWN,Vector3i.FORWARD,Vector3i.BACK]:
			if not cells.has(c.cell+d): visible=true
		exposed=exposed and visible
	check("Every cube has an exposed face; no enclosed filler",exposed)
	for key in ["head","neck","shoulder","elbow","wrist","fist","hip","knee","foot"]:
		var point: Vector3=m.rig_point(key,Vector3.ZERO)
		var nearest:=10000.0
		for c in m.cubes: nearest=minf(nearest,c.position.distance_to(point))
		check("Anatomical anchor "+key,nearest<2.8 and point.is_finite())
	check("Neutral fist remains above ground",m.rig.effectors.right_arm.y>2.8)
	for entry in [{"name":"chest","p":Vector3(3,15,-3)}, {"name":"face","p":Vector3(2,18,-7)}, {"name":"shoulder","p":Vector3(-8,16,-1)}, {"name":"fist","p":Vector3(11,3,-6)}, {"name":"back","p":Vector3(3,15,3)}]:
		m=fresh()
		var before: int=m.alive_count()
		var report: Dictionary=m.damage(m.to_global(entry.p),1.8,Vector3(0,0,6))
		check("Local physical destruction: "+entry.name,report.direct>0 and m.alive_count()<before and m.alive_count()>500)
		var missing: int=m.alive_count()
		m.update_pose()
		check("Persistent missing cubes: "+entry.name,m.alive_count()==missing)
	m=fresh()
	for c in m.cubes:
		if c.major=="left_arm":c.alive=false
	m.structure.refresh(m.cubes)
	m.rebuild()
	check("Arm loss disables paired smash",not Moves.available(m,"two_hand_smash"))
	check("Surviving right fist retains hammer",Moves.available(m,"hammer_fist"))
	for c in m.cubes:
		if c.major=="right_arm":c.alive=false
	m.structure.refresh(m.cubes)
	m.rebuild()
	check("Both arm loss disables hammer/hook/grab",not Moves.available(m,"hammer_fist") and not Moves.available(m,"ape_hook") and not Moves.available(m,"grab_throw"))
	check("Headbutt remains with intact head",Moves.available(m,"ape_headbutt"))
	m=fresh()
	var initial: float=m.speed_factor()
	for c in m.cubes:
		if c.major=="left_leg":c.alive=false
	m.structure.refresh(m.cubes)
	m.rebuild()
	check("Leg loss reduces mobility",m.speed_factor()<initial)
	for c in m.cubes:
		if c.major=="right_leg":c.alive=false
	m.structure.refresh(m.cubes)
	m.rebuild()
	check("Both leg loss disables kick",not Moves.available(m,"ape_kick"))
	for stage in ["walk","turn","pursuit","hammer_fist","ape_hook","two_hand_smash","grab_throw","leap_attack","throw","damage"]:
		var result: Dictionary=Review.stage(b,stage)
		check("Runtime stage "+stage,result.alive>0)
		if stage=="leap_attack":check("Leap lifts the actual actor",result.hop>0)
		if stage=="throw":check("Throw gives victim momentum",b.monsters[1].knock_velocity.length()>10)
	var file=FileAccess.open("res://docs/giant-ape-validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	file.close()
	print("GIANT APE VALIDATION %d/%d"%[checks.size()-failures,checks.size()])
	b.queue_free()
	await process_frame
	quit(1 if failures else 0)
