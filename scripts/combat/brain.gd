class_name MonsterBrain
extends RefCounted

var tactic_age := 0.0
var reposition_wait := 5.0
var spacing_runs := 0
var rng := RandomNumberGenerator.new()
var personality := {"aggression":0.75,"hook":1.4,"kick":0.8,"evade":0.22}
var think_age := 0.0
var decision_age := 0.0
var mode := "ADVANCE"
var circle_sign := 1.0
var navigation_ms := 0.0
var think_ms := 0.0
var decisions := 0

func initialize(seed_value: int, style: Dictionary) -> void:
	rng.seed=seed_value
	personality=style
	think_age=0
	decision_age=0
	circle_sign=-1 if rng.randf()<0.5 else 1
	decisions=0
	tactic_age=0
	reposition_wait=5
	spacing_runs=0

func tick(dt: float, body: CombatMonster, opponent: CombatMonster, battle: Node3D) -> void:
	if not body.archetype.is_empty():
		tick_archetype(dt,body,opponent,battle)
		return
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
	if opponent.regen!=null and opponent.regen.loose_count()>=10 and rng.randf()<0.55: return "_loose"
	var custom: Array=opponent.archetype.get("target_regions",[])
	if not custom.is_empty():
		var open: Array[String]=[]
		for region in custom:
			if opponent.structure.fraction(region)>0.12: open.append(region)
		return open[rng.randi_range(0,open.size()-1)] if not open.is_empty() else String(custom[0])
	var candidates: Array[String]=[]
	if move=="kick": candidates=["left_thigh","right_thigh","left_shin","right_shin","abdomen"]
	elif move=="heavy_hook": candidates=["left_shoulder","right_shoulder","chest","head"]
	elif move in ["headbutt","body_charge"]: candidates=["chest","abdomen","head"]
	else: candidates=["head","head","chest","abdomen","left_shoulder","right_shoulder"]
	if not body.archetype.is_empty() and not opponent.archetype.is_empty() and move in ["heavy_hook","left_punch","right_punch"] and rng.randf()<.38:
		candidates.assign(opponent.archetype.get("priority_targets",candidates))
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

func tick_archetype(dt: float, body: CombatMonster, opponent: CombatMonster, battle: Node3D) -> void:
	think_age-=dt
	tactic_age-=dt
	reposition_wait-=dt
	if think_age>0: return
	think_age=.3+rng.randf()*.12
	var started := Time.get_ticks_usec()
	if body.defeated or opponent.defeated:
		body.request_move(Vector3.ZERO,body.rotation.y)
		if not body.defeated: body.state="VICTORIOUS"
		return
	if body.rig_type=="swarm": return
	var delta := opponent.focus_point(body.position)-body.position
	delta.y=0
	var distance := delta.length()
	var forward := delta.normalized()
	var tangent := forward.rotated(Vector3.UP,circle_sign*PI/2)
	var facing := atan2(-forward.x,-forward.z)
	if body.hold_target!=null or body.held_by!=null:
		body.request_move(Vector3.ZERO,facing)
		return
	if body.flight!=null:
		var wings: FlightState=body.flight
		if wings.state=="GROUNDED" and distance>body.behavior("takeoff_distance",17) and not body.attack_motion.running: wings.request_takeoff(body)
		elif wings.state=="FLYING" and not body.attack_motion.running and (wings.airtime>wings.flight_budget()*0.8 or distance<body.behavior("land_distance",7.5)): wings.request_landing()
	var hands := 2 if body.rig_type!="biped" or not body.structure.has_biped else int(MonsterMoves.functional_arm(body,"left"))+int(MonsterMoves.functional_arm(body,"right"))
	var preferred := body.behavior("preferred_range",10)
	if hands<2 and body.behavior("charge_weight",0)==0: preferred-=2.0*(2-hands)
	preferred=maxf(8.65,preferred-minf(body.missed_attacks*.55,3.5))
	if body.speed_factor()<.45: preferred=minf(preferred,9.1)
	var speed := body.behavior("speed",2.2)
	var desired := Vector3.ZERO
	if battle.elapsed<2.2:
		body.request_move(desired,facing)
		return
	if reposition_wait<=0 and tactic_age<=0 and not body.attack_motion.running and body.speed_factor()>.5:
		reposition_wait=body.behavior("reposition_interval",9)+rng.randf_range(0,3)
		var retreat_weight := body.behavior("retreat",.3)
		mode="BUILD CHARGE" if body.behavior("charge_weight",0)>0 and distance<16 else "GIVE GROUND" if rng.randf()<retreat_weight else "FLANK"
		tactic_age=body.behavior("reposition_seconds",3.8)
		spacing_runs+=1
		if rng.randf()<.3: circle_sign=-circle_sign
	if distance>preferred+.6:
		desired=forward*speed
		body.state="PURSUING"
	elif distance<preferred-1 and body.speed_factor()>.5:
		desired=-forward*speed*.72
		body.state="MAINTAINING RANGE"
	else:
		desired=tangent*speed*.3*body.behavior("circle",.2)
		body.state="STALKING"
	if tactic_age>0:
		if mode=="BUILD CHARGE" and distance<body.behavior("charge_distance",18): desired=(-forward+tangent*.22).normalized()*speed
		elif mode=="GIVE GROUND" and distance<preferred+4: desired=(-forward+tangent*.2).normalized()*speed*.85
		elif mode=="FLANK" and distance<preferred+2: desired=(tangent*.8+forward*.15).normalized()*speed*.65
		body.state=mode
	if body.stagger>.2:
		desired=-forward*.6
		body.state="RECOVERING FOOTING"
	if body.attack_motion.running:
		body.state=body.attack_motion.profile.label+" · "+body.attack_motion.phase
	elif body.cooldown<=0 and body.stagger<=.25 and absf(angle_difference(body.rotation.y,facing))<.3:
		var charge_ready := mode=="BUILD CHARGE" and distance>=15
		var move := choose_archetype_move(body,distance,charge_ready)
		if move!="" and (tactic_age<=0 or mode=="FLANK" or charge_ready or distance<preferred-1.5):
			var family: String=MonsterMoves.profile(body,move).base
			var target_region := choose_target(body,opponent,family)
			# Vertical reach follows the limb, rather than aiming every creature at a high skull.
			if family in ["headbutt","body_charge"]:
				target_region="chest" if absf(body.rig.effectors.get("head",body.position).y-opponent.region_target("chest").y)<8 else "abdomen"
			if body.request_attack(move,opponent,target_region,MonsterMoves.side_for(body,move,rng)):
				decisions+=1
				if charge_ready: tactic_age=0
	# Guide before the emergency bounds; curve naturally into the broad avenue.
	var nav_started := Time.get_ticks_usec()
	var next := body.position+desired*5
	if absf(next.x)>20: desired.x=move_toward(desired.x,-signf(body.position.x)*speed,.9)
	if absf(next.z)>65:
		desired.z=-signf(body.position.z)*speed*.7
		desired.x=tangent.x*speed*.7
		tactic_age=0
		mode="TURN INWARD"
		body.state="TURNING INTO AVENUE"
	navigation_ms=(Time.get_ticks_usec()-nav_started)/1000.0
	body.request_move(desired,facing)
	think_ms=(Time.get_ticks_usec()-started)/1000.0

func choose_archetype_move(body: CombatMonster, distance: float, charge_ready: bool) -> String:
	var weights := {}
	var total := 0.0
	for move in body.archetype.attacks:
		var profile := MonsterMoves.profile(body,move)
		if not MonsterMoves.available(body,move) or distance>profile.range or distance<profile.get("min_range",0): continue
		if profile.get("trajectory","")=="charge" and not charge_ready: continue
		var weight: float=profile.weight*pow(.45,body.attack_history.count(move))
		if distance<float(profile.get("close_distance",0.0)): weight*=float(profile.get("close_weight",0.15))
		if charge_ready and profile.get("trajectory","")=="charge": weight*=8
		weights[move]=weight
		total+=weight
	var roll := rng.randf()*total
	for move in weights:
		roll-=weights[move]
		if roll<=0: return move
	return ""
