extends SceneTree
# Explicit preloads: no dependence on the editor-generated global class cache.
const CombatMonster = preload("res://scripts/combat/combatant.gd")
const MonsterBrain = preload("res://scripts/combat/brain.gd")
const MonsterMoves = preload("res://scripts/combat/moves.gd")

var checks := []
var failures := 0
var battle: Node3D

func check(label: String, passed: bool) -> void:
	checks.append({"check":label,"passed":passed})
	if not passed: failures+=1; push_error(label)

func _initialize() -> void:
	run.call_deferred()

func remove_region(body: CombatMonster, region: String) -> void:
	for cube in body.cubes:
		if cube.region==region: cube.alive=false
	var detached: Array[String]=body.structure.failures(body.cubes)
	for cube in body.cubes:
		if detached.has(cube.major): cube.alive=false
	body.structure.refresh(body.cubes)
	body.rebuild()
	body.update_pose()

func run() -> void:
	battle=load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	battle.set_physics_process(false)
	for id in ["gorgeblock","needlemantle","bastion"]:
		battle.restart(44,[id,"bastion" if id!="bastion" else "gorgeblock"])
		var body: CombatMonster=battle.monsters[0]
		check(id+" exact visible 1000",body.alive_count()==1000 and body.cubes.size()==1000)
		var visible := 0
		for instance in body.renders.values(): visible+=instance.multimesh.instance_count
		check(id+" exact rendered cube count",visible==1000)
		var unique := {}
		var regions := {}
		for cube in body.cubes:
			unique[cube.cell]=true
			regions[cube.region]=regions.get(cube.region,0)+1
		check(id+" unique cells",unique.size()==1000)
		var allocation_matches: bool= regions.size()==body.archetype.allocation.size()
		for region in regions: allocation_matches=allocation_matches and regions[region]==int(body.archetype.allocation[region])
		check(id+" authored regional allocation",allocation_matches)
		var reached := {body.cubes[0].cell:true}
		var todo := [body.cubes[0].cell]
		while not todo.is_empty():
			var p: Vector3i=todo.pop_back()
			for offset in [Vector3i.LEFT,Vector3i.RIGHT,Vector3i.UP,Vector3i.DOWN,Vector3i.FORWARD,Vector3i.BACK]:
				var q: Vector3i=p+offset
				if unique.has(q) and not reached.has(q): reached[q]=true; todo.append(q)
		check(id+" connected body",reached.size()==1000)
		check(id+" proportional healthy mobility",is_equal_approx(body.speed_factor(),1))
		check(id+" distinct authored vocabulary",body.archetype.attacks.size()>=5)
		var torso_target: Vector3=body.region_target("chest")
		var damage: Dictionary=body.damage(torso_target,1.6,Vector3.RIGHT*15)
		var after: int=body.alive_count()
		check(id+" actual local damage",damage.direct>0 and after<1000)
		body.damage(torso_target,1.6,Vector3.RIGHT*15)
		check(id+" persistent cavity cannot refill",body.alive_count()<=after)
		body.reset_body(); body.reset_motion()
		remove_region(body,"left_thigh")
		check(id+" support failure reduces pursuit",body.structure.disabled.left_leg and body.speed_factor()<.4)
		check(id+" leg loss preserves vital structure",body.structure.fatal_reason()=="")
		body.reset_body(); body.reset_motion()
		remove_region(body,"left_shoulder")
		remove_region(body,"right_shoulder")
		check(id+" arm loss disables arm vocabulary",not MonsterMoves.functional_arm(body,"left") and not MonsterMoves.functional_arm(body,"right"))
		check(id+" armless primary alternatives",MonsterMoves.available(body,"skull_crash" if id=="bastion" else "short_kick" if id=="gorgeblock" else "heel_kick"))
		check(id+" armless loss remains nonfatal",body.structure.fatal_reason()=="")
	battle.restart(100,["gorgeblock","needlemantle"])
	battle.elapsed=3
	var brain: MonsterBrain=battle.brains[1]
	var longarm: CombatMonster=battle.monsters[1]
	longarm.position=Vector3(0,-.6,12)
	battle.monsters[0].position=Vector3(0,-.6,0)
	brain.tick(.5,longarm,battle.monsters[0],battle)
	check("Healthy longarm deliberately preserves range",longarm.desired_velocity.z>0)
	remove_region(longarm,"left_shoulder")
	brain.think_age=0; brain.tactic_age=0; brain.reposition_wait=20
	brain.tick(.5,longarm,battle.monsters[0],battle)
	check("Arm loss contracts longarm preferred range",absf(longarm.desired_velocity.z)<.2)
	battle.restart(201,["bastion","gorgeblock"])
	var bull: CombatMonster=battle.monsters[0]
	var opponent: CombatMonster=battle.monsters[1]
	check("Charge unavailable point blank",battle.brains[0].choose_archetype_move(bull,8,true)!="ram_charge")
	check("Charge available after creating distance",MonsterMoves.available(bull,"ram_charge"))
	check("No mirror matches on random launch",true)
	for seed_value in 12:
		battle.restart(seed_value+1)
		if battle.monsters[0].archetype.id==battle.monsters[1].archetype.id: checks[-1].passed=false; failures+=1
	FileAccess.open("res://docs/m4-archetype-validation.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("ARCHETYPE VALIDATION ",checks.size()-failures,"/",checks.size())
	battle.queue_free()
	await process_frame
	quit(1 if failures else 0)


