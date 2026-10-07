class_name MonsterBrain
extends RefCounted

var rng := RandomNumberGenerator.new()
var personality := {"aggression":0.75,"hook":1.4,"kick":0.8,"evade":0.22}
var think_age := 0.0
var decision_age := 0.0
var mode := "ADVANCE"
var circle_sign := 1.0
var think_ms := 0.0
var decisions := 0

func initialize(seed_value: int, style: Dictionary) -> void:
	rng.seed=seed_value
	personality=style
	think_age=0
	decision_age=0
	circle_sign=-1 if rng.randf()<0.5 else 1
	decisions=0

func tick(dt: float, body: CombatMonster, opponent: CombatMonster, battle: Node3D) -> void:
	think_age-=dt
	decision_age-=dt
	if think_age>0: return
	think_age=0.25+rng.randf()*0.15
	var started := Time.get_ticks_usec()
	if body.defeated or opponent.defeated:
		body.request_move(Vector3.ZERO,body.rotation.y)
		if not body.defeated: body.state="VICTORIOUS"
		return
	var difference := opponent.position-body.position
	difference.y=0
	var distance := difference.length()
	var forward := difference.normalized()
	var facing := atan2(-forward.x,-forward.z)
	if battle.elapsed<2.2:
		body.request_move(Vector3.ZERO,facing)
		body.state="STANDOFF"
		return
	var desired := Vector3.ZERO
	var no_hands := not MonsterMoves.functional_arm(body,"left") and not MonsterMoves.functional_arm(body,"right")
	var engage_distance := 9.0 if no_hands or body.position.y<-3 else 10.0
	engage_distance=maxf(8.55,engage_distance-minf(1.5,body.missed_attacks*0.4))
	if distance>engage_distance:
		desired=forward*2.2
		body.state="CLOSING DISTANCE"
	elif distance<8.7:
		desired=-forward*0.8
		body.state="RESETTING FOOTING"
	elif decision_age>0:
		if mode=="CIRCLE": desired=forward.rotated(Vector3.UP,circle_sign*PI/2)*0.7
		elif mode=="EVADE": desired=-forward*1.2
		body.state="CIRCLING" if mode=="CIRCLE" else "EVADING" if mode=="EVADE" else "SIZING UP"
	if body.attack_motion.running:
		desired=Vector3.ZERO
		body.state=body.attack_motion.profile.label+" · "+body.attack_motion.phase
	elif body.stagger>0.2:
		desired=-forward*0.45
		body.state="STAGGERED"
	elif opponent.attack_motion.running and opponent.attack_motion.phase=="WIND-UP" and distance<12 and rng.randf()<personality.evade:
		body.guard_time=1.3
		mode="EVADE" if rng.randf()<0.4 else "GUARD"
		decision_age=0.7
		desired=-forward*0.8 if mode=="EVADE" else Vector3.ZERO
		body.state="BRACING" if mode=="GUARD" else "EVADING"
	elif decision_age<=0 and body.cooldown<=0 and distance<=10.8 and absf(angle_difference(body.rotation.y,facing))<0.28:
		decisions+=1
		if rng.randf()<personality.aggression or battle.elapsed>25:
			var move := choose_move(body,distance)
			if move!="":
				var region := choose_target(body,opponent,move)
				var side := MonsterMoves.side_for(body,move,rng)
				body.request_attack(move,opponent,region,side)
			mode="ATTACK"
			decision_age=0.7
		else:
			mode="CIRCLE"
			circle_sign=-circle_sign if rng.randf()<0.4 else circle_sign
			decision_age=rng.randf_range(0.6,1.3)
	body.request_move(desired,facing)
	think_ms=(Time.get_ticks_usec()-started)/1000.0

func choose_move(body: CombatMonster, distance: float) -> String:
	var weights := {"left_punch":1.0,"right_punch":1.0,"heavy_hook":personality.hook,"kick":personality.kick,"headbutt":0.45,"body_charge":0.30}
	if not MonsterMoves.functional_arm(body,"left") and not MonsterMoves.functional_arm(body,"right"):
		weights.kick=2.0
		weights.headbutt=2.2
		weights.body_charge=1.5
	var total := 0.0
	for move in weights:
		if not MonsterMoves.available(body,move) or distance>MonsterMoves.MOVES[move].range: weights[move]=0.0
		elif body.attack_history.count(move)>0: weights[move]*=pow(0.3,body.attack_history.count(move))
		total+=weights[move]
	if total<=0: return ""
	var roll := rng.randf()*total
	for move in weights:
		roll-=weights[move]
		if roll<=0 and weights[move]>0: return move
	return "body_charge"

func choose_target(body: CombatMonster, opponent: CombatMonster, move: String) -> String:
	var candidates: Array[String]=[]
	if move=="kick": candidates=["left_thigh","right_thigh","left_shin","right_shin","abdomen"]
	elif move=="heavy_hook": candidates=["left_shoulder","right_shoulder","chest","head"]
	elif move in ["headbutt","body_charge"]: candidates=["chest","abdomen","head"]
	else: candidates=["head","head","chest","abdomen","left_shoulder","right_shoulder"]
	if body.position.y<-2.5 and opponent.position.y>-2.5: candidates=["abdomen","pelvis","left_thigh","right_thigh"]
	var viable: Array[String]=[]
	for region in candidates:
		if opponent.structure.material(region)>3: viable.append(region)
	if viable.is_empty(): return "chest"
	# A minority of decisions exploit visibly eroded joints; ordinary choice stays varied.
	if rng.randf()<0.22:
		for region in viable:
			if region.ends_with("shoulder") and opponent.structure.material(region)<22: return region
			if region.ends_with("thigh") and opponent.structure.material(region)<35: return region
	return viable[rng.randi_range(0,viable.size()-1)]
