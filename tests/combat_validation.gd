extends SceneTree

var results: Array[Dictionary]=[]
var battle: Node3D

func check(condition: bool, label: String, evidence: Dictionary={}) -> void:
	results.append({"check":label,"passed":condition,"evidence":evidence})
	if not condition: push_error("VALIDATION FAILED: "+label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	battle=load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	battle.set_physics_process(false)
	battle.restart(8801,[],true)
	check(battle.monsters[0].alive_count()==1000 and battle.monsters[1].alive_count()==1000,"Two pristine 1000 cube monsters")
	for step in 60: battle.simulate_step(1.0/30)
	var opening_delta: Vector3=battle.monsters[0].position-battle.monsters[0].home
	opening_delta.y=0
	check(battle.monsters[0].commands==0 and opening_delta.length()<0.1,"Natural opening standoff")
	for region in ["left_shoulder","right_shoulder"]:
		battle.force_region(0,region,4.0)
	check(battle.monsters[0].structure.disabled.left_arm and battle.monsters[0].structure.disabled.right_arm and not battle.monsters[0].defeated,"Both arm losses are nonfatal")
	check(not MonsterMoves.available(battle.monsters[0],"left_punch") and not MonsterMoves.available(battle.monsters[0],"right_punch") and not MonsterMoves.available(battle.monsters[0],"heavy_hook"),"Missing arms cannot punch or hook")
	for move in ["kick","headbutt","body_charge"]: check(MonsterMoves.available(battle.monsters[0],move),"Armless anatomy supports "+move)
	for step in 2400:
		battle.simulate_step(1.0/30)
		if step%120==0: await process_frame
		if battle.finished: break
	var armless_hits := 0
	for hit in battle.hits:
		if hit.attacker=="TITAN" and hit.move in ["kick","headbutt","body_charge"]: armless_hits+=1
	check(armless_hits>0,"Armless AI actively inflicts real damage",{"hits":armless_hits,"snapshot":battle.snapshot()})
	battle.restart(8802,[],true)
	battle.force_region(0,"left_thigh",4.0)
	check(battle.monsters[0].structure.disabled.left_leg and not battle.monsters[0].defeated,"One leg lost without instant defeat")
	check(battle.monsters[0].speed_factor()<0.4,"Leg loss reduces locomotion speed")
	for step in 150: battle.simulate_step(1.0/30)
	check(battle.monsters[0].position.y<-3,"One leg loss changes visible stance")
	battle.restart(8803,[],true)
	for region in ["left_shoulder","right_shoulder","left_thigh","right_thigh"]: battle.force_region(0,region,4.0)
	var body= battle.monsters[0]
	check(not body.defeated and not MonsterMoves.available(body,"kick"),"No limbs still alive, kicks unavailable")
	for step in 4500:
		battle.simulate_step(1.0/30)
		if step%120==0: await process_frame
		if battle.finished: break
	var ground_hits := 0
	for hit in battle.hits:
		if hit.attacker=="TITAN" and hit.move in ["headbutt","body_charge"]: ground_hits+=1
	check(ground_hits>0,"Grounded limbless creature still connects body/head attacks",{"hits":ground_hits,"snapshot":battle.snapshot()})
	battle.restart(8804,[],true)
	var victim= battle.monsters[1]
	battle.force_region(1,"neck",4)
	check(victim.defeated,"Essential structural loss causes defeat")
	for step in 90: battle.simulate_step(1.0/30)
	check(victim.collapsed and victim.alive_count()==0 and battle.monsters[0].alive_count()==1000,"Loser collapses into rubble, winner remains")
	check(battle.debris.active.size()<=192,"Collapse respects physical debris budget")
	battle.restart(8805,[],true)
	check(battle.monsters[0].alive_count()==1000 and battle.monsters[1].alive_count()==1000 and battle.debris.active.is_empty(),"Reset restores exact anatomy and clears debris")
	var fighter= battle.monsters[0]
	fighter.request_attack("heavy_hook",battle.monsters[1],"chest","left")
	fighter.attack_motion.update(1.2,fighter)
	fighter.update_pose()
	battle.force_region(0,"left_shoulder",4)
	fighter.attack_motion.update(0.02,fighter)
	check(not fighter.attack_motion.running,"Loss of selected arm cancels committed hook even if other arm survives")
	check(not fighter.request_attack("heavy_hook",battle.monsters[1],"chest","left"),"Shared command interface rejects a missing selected arm")
	battle.restart(8806,[],true)
	fighter=battle.monsters[0]
	fighter.request_attack("kick",battle.monsters[1],"left_shin","left")
	fighter.attack_motion.update(1.0,fighter)
	fighter.update_pose()
	battle.force_region(0,"left_thigh",4)
	fighter.attack_motion.update(0.02,fighter)
	check(not fighter.attack_motion.running,"Loss of selected leg cancels committed kick")
	var failed := 0
	for result in results:
		if not result.passed: failed+=1
	var report := {"checks":results.size(),"failed":failed,"results":results}
	FileAccess.open("res://docs/combat-validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("COMBAT VALIDATION ",results.size()-failed,"/",results.size())
	battle.queue_free()
	await process_frame
	quit(1 if failed else 0)
