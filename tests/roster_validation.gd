extends SceneTree
# Anatomy / architecture checks for all 16 tournament entrants. Writes docs/roster-validation.json.
const Archetypes = preload("res://scripts/combat/archetypes.gd")
var checks := []
var failures := 0
var battle: Node3D

func check(label: String, passed: bool) -> void:
	checks.append({"check":label,"passed":passed})
	if not passed:
		failures+=1
		push_error(label)

func _initialize() -> void:
	run.call_deferred()

func fresh(id: String, other: String="stone_colossus") -> CombatMonster:
	battle.restart(31,[id,other if other!=id else "giant_ape"])
	battle.elapsed=3
	return battle.monsters[0]

func kill_limb(body: CombatMonster, limb: String) -> void:
	for cube in body.cubes:
		if body.structure.owns(cube,limb): cube.alive=false
	body.structure.failures(body.cubes)
	body.structure.refresh(body.cubes)
	body.rebuild()

func kill_regions(body: CombatMonster, regions: Array) -> void:
	for cube in body.cubes:
		if regions.has(cube.region): cube.alive=false
	for limb in body.structure.failures(body.cubes):
		for cube in body.cubes:
			if cube.alive and body.structure.owns(cube,limb): cube.alive=false
	body.structure.refresh(body.cubes)
	body.rebuild()

func connected_components(body: CombatMonster) -> int:
	var cells := {}
	for c in body.cubes: cells[c.cell]=true
	var seen := {}
	var parts := 0
	for start in cells:
		if seen.has(start): continue
		parts+=1
		seen[start]=true
		var todo := [start]
		while not todo.is_empty():
			var p: Vector3i=todo.pop_back()
			for offset in [Vector3i.LEFT,Vector3i.RIGHT,Vector3i.UP,Vector3i.DOWN,Vector3i.FORWARD,Vector3i.BACK]:
				var q: Vector3i=p+offset
				if cells.has(q) and not seen.has(q):
					seen[q]=true
					todo.append(q)
	return parts

func run() -> void:
	battle=load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	battle.set_physics_process(false)
	var ranged_ids: Array[String]=[]
	var silhouettes := {}
	for id in Archetypes.ROSTER:
		var body := fresh(id)
		check(id+": definition file present",FileAccess.file_exists("res://data/creatures/"+id+".json"))
		var visible := 0
		for instance in body.renders.values(): visible+=instance.multimesh.instance_count
		check(id+": exactly 1,000 cubes",body.cubes.size()==1000 and body.alive_count()==1000 and visible==1000)
		var unique := {}
		var regions := {}
		for c in body.cubes:
			unique[c.cell]=true
			regions[c.region]=regions.get(c.region,0)+1
		check(id+": unique cells",unique.size()==1000)
		var allocation_ok: bool= regions.size()==body.archetype.allocation.size()
		var total := 0
		for region in regions:
			allocation_ok=allocation_ok and regions[region]==int(body.archetype.allocation[region])
			total+=regions[region]
		check(id+": body allocation matches authored data",allocation_ok and total==1000)
		var expected_parts := 10 if id=="army_of_ten" else 1
		check(id+": connected structure ("+str(expected_parts)+" component)",connected_components(body)==expected_parts)
		check(id+": distinct attack identity (>=5 attacks)",body.archetype.attacks.size()>=5 or id=="army_of_ten")
		var has_ranged := false
		for name in body.archetype.attacks:
			var attack: Dictionary=body.archetype.attacks[name]
			if attack.has("ranged"):
				has_ranged=true
				check(id+"/"+name+": ranged attack is limited (wind-up, recovery, cooldown)",float(attack.get("wind",1.0))>=0.8 and float(attack.get("recover",1.0))>=0.9 and float(attack.get("cooldown",0.0))>=5.0)
		if has_ranged: ranged_ids.append(id)
		check(id+": ranged designation matches roster brief",has_ranged==Archetypes.RANGED.has(id))
		# Damage is localized and cavities persist.
		var before := body.alive_count()
		var target_point: Vector3=body.region_target("chest")
		var report: Dictionary=body.damage(target_point,2.2,Vector3.RIGHT*12)
		var after := body.alive_count()
		check(id+": localized damage removes real cubes",report.direct>0 and after<before and after>before-400)
		body.damage(target_point,2.2,Vector3.RIGHT*12)
		check(id+": cavity cannot refill",body.alive_count()<=after or body.regen!=null)
		# Anatomy gates attacks: every attack with 'needs' becomes unavailable when that anatomy is gone.
		for name in body.archetype.attacks:
			var attack: Dictionary=body.archetype.attacks[name]
			if not attack.has("needs"): continue
			for key in attack.needs:
				if not body.structure.limb_regions.has(key): continue
				var victim := fresh(id)
				var ok_before := MonsterMoves.available(victim,name)
				kill_limb(victim,key)
				check(id+"/"+name+": unavailable once "+key+" is destroyed",ok_before and not MonsterMoves.available(victim,name))
		battle.restart(31,[id,"giant_ape" if id!="giant_ape" else "stone_colossus"])
	check("exactly eight entrants have ranged capability",ranged_ids.size()==8)

	# ---- Structural failure changes behaviour ----
	var body := fresh("giant_ape")
	kill_regions(body,["left_shoulder","right_shoulder"])
	check("ape: armless loses arm vocabulary but keeps kicks, tackles and headbutts",not MonsterMoves.functional_arm(body,"left") and MonsterMoves.available(body,"ape_kick") and MonsterMoves.available(body,"shoulder_tackle") and MonsterMoves.available(body,"ape_headbutt") and not MonsterMoves.available(body,"grab_throw"))
	body=fresh("giant_robot")
	check("robot: rocket fist available when healthy",MonsterMoves.available(body,"rocket_fist"))
	body.fist_away["right"]=3.0
	check("robot: rocket fist unavailable while the fist is away",not MonsterMoves.available(body,"rocket_fist") and not MonsterMoves.functional_arm(body,"right"))
	body=fresh("fire_reptile")
	check("reptile: breath available healthy",MonsterMoves.available(body,"fire_breath"))
	kill_regions(body,["head","neck"])
	check("reptile: no fire breath without head/neck",not MonsterMoves.available(body,"fire_breath") and not MonsterMoves.available(body,"bite"))
	body=fresh("fire_reptile")
	var tail_before := MonsterMoves.available(body,"tail_sweep")
	kill_limb(body,"tail")
	check("reptile: tail sweep disappears with the tail",tail_before and not MonsterMoves.available(body,"tail_sweep"))
	body=fresh("eyeball_beast")
	var beam_range_full: float=battle.ranged.quality(body,body.archetype.attacks.gaze_beam)
	kill_regions(body,["eye"])
	var quality_after: float=battle.ranged.quality(body,body.archetype.attacks.gaze_beam)
	check("eyeball: eye damage degrades beam quality without being lethal",quality_after<beam_range_full and body.structure.fatal_reason()=="")
	check("eyeball: beam unavailable once the eye is gone",not MonsterMoves.available(body,"gaze_beam"))

	# ---- Skeleton reassembly ----
	body=fresh("giant_skeleton")
	var regen: BoneRegen=body.regen
	check("skeleton: has reassembly module",regen!=null)
	body.damage(body.region_target("chest"),5.5,Vector3.RIGHT*10)
	var loose_start := regen.loose_count()
	check("skeleton: struck cubes become recoverable loose bone",loose_start>5 and body.alive_count()+loose_start==1000)
	var loose_positions: Array[Vector3]=[]
	for item in regen.loose: loose_positions.append(item.pos)
	var destroyed := 0
	for k in range(0,mini(loose_positions.size(),12)): destroyed+=regen.shatter_near(loose_positions[k],0.05)
	check("skeleton: smashing loose bone shatters it permanently",destroyed>0 and regen.shattered==destroyed)
	var shattered_ids: Array[int]=[]
	for c in range(body.cubes.size()):
		if body.cubes[c].state==2: shattered_ids.append(c)
	for step in 1500: regen.update(1.0/60.0)
	var revived := false
	for id in shattered_ids: revived=revived or body.cubes[id].alive
	check("skeleton: loose pixels return and shattered pixels never do",regen.reattached>0 and not revived and regen.loose_count()==0)
	check("skeleton: never exceeds 1,000 cubes",body.alive_count()<=1000 and body.alive_count()+regen.shattered==1000)
	body.reset_body()
	body.reset_motion()
	kill_regions(body,["left_thigh","right_thigh"])
	check("skeleton: joint loss disables function while disconnected",body.speed_factor()<0.4)
	# detached (not shattered) joint cubes returning restores function
	body=fresh("giant_skeleton")
	body.damage(body.region_target("left_thigh"),3.5,Vector3.RIGHT*10)
	body.damage(body.region_target("right_thigh"),3.5,Vector3.LEFT*10)
	var degraded: float=body.speed_factor()
	for step in 1500: body.regen.update(1.0/60.0)
	check("skeleton: reassembly restores mobility",body.speed_factor()>=degraded and body.regen.loose_count()==0)

	# ---- Army ----
	body=fresh("army_of_ten")
	check("army: ten separate bodies",body.swarm!=null and body.swarm.units.size()==10)
	var unit_counts := {}
	for c in body.cubes: unit_counts[c.major]=unit_counts.get(c.major,0)+1
	var uniform := unit_counts.size()==10
	for key in unit_counts: uniform=uniform and unit_counts[key]==100
	check("army: each unit is exactly 100 cubes (total 1,000)",uniform)
	for cube in body.cubes: if cube.major=="u3": cube.alive=false
	body.structure.failures(body.cubes)
	body.swarm.sync_alive()
	check("army: individual member can die",body.swarm.alive_count()==9 and body.structure.fatal_reason()=="")
	for cube in body.cubes: cube.alive=false
	body.structure.failures(body.cubes)
	check("army: all members dead is fatal",body.structure.fatal_reason()=="ALL UNITS DESTROYED")

	# ---- Dragon ----
	body=fresh("flying_dragon")
	var flight: FlightState=body.flight
	check("dragon: flight state present and can take off healthy",flight!=null and flight.wing_lift(body)>0.95 and flight.cooldown>=0)
	flight.cooldown=0
	check("dragon: takes off with healthy wings",flight.can_take_off(body))
	kill_regions(body,["left_wing_b"])
	var half_lift: float=flight.wing_lift(body)
	check("dragon: damaged wing reduces lift",half_lift<0.95)
	kill_limb(body,"left_wing")
	kill_limb(body,"right_wing")
	check("dragon: destroyed wings ground the dragon",flight.wing_lift(body)<0.05 and not flight.can_take_off(body) and not MonsterMoves.available(body,"dive_attack"))
	body=fresh("flying_dragon")
	body.flight.cooldown=0
	body.flight.state="FLYING"
	body.flight.altitude=8.0
	check("dragon: airborne dragon can dive and cannot claw",body.flight.dive_available(body) and MonsterMoves.available(body,"dive_attack") and not MonsterMoves.available(body,"dragon_claw"))

	# ---- Tarantula ----
	body=fresh("giant_tarantula")
	var speeds: Array[float]=[body.speed_factor()]
	for leg in ["leg_hl","leg_hr","leg_bl","leg_br","leg_al","leg_ar","leg_fl","leg_fr"]:
		kill_limb(body,leg)
		speeds.append(body.speed_factor())
	var monotonic := true
	for i in range(1,speeds.size()): monotonic=monotonic and speeds[i]<=speeds[i-1]+0.0001
	check("tarantula: leg loss progressively reduces speed",monotonic and speeds[1]>=speeds[0]*0.75 and speeds[4]<speeds[1] and speeds[8]<0.2)

	# ---- Rider ----
	body=fresh("dark_knight_rider")
	var groups := {"horse":0,"rider":0,"lance":0}
	for c in body.cubes:
		if c.region.begins_with("horse_") or c.region.begins_with("leg_"): groups.horse+=1
		elif c.region.begins_with("rider_"): groups.rider+=1
		elif c.region=="lance": groups.lance+=1
	check("rider: horse + rider + lance share exactly 1,000 cubes",groups.horse+groups.rider+groups.lance==1000 and groups.horse>groups.rider and groups.lance>=20)
	check("rider: lance charge available with lance",MonsterMoves.available(body,"lance_charge"))
	kill_limb(body,"lance")
	check("rider: losing the lance removes lance attacks but keeps trample",not MonsterMoves.available(body,"lance_charge") and not MonsterMoves.available(body,"lance_thrust") and MonsterMoves.available(body,"trample"))

	# ---- Anaconda ----
	body=fresh("giant_anaconda")
	check("anaconda: serpent architecture with no biped rig",body.rig_type=="serpent" and not body.structure.has_biped and not body.regions_has("left_thigh"))
	var segs := 0
	for limb in body.structure.limbs: if limb.kind=="segment": segs+=1
	check("anaconda: continuous segment chain",segs>=10)
	var mobility_full := body.speed_factor()
	for i in [4,5,6,7,8]: kill_limb(body,"seg_%02d" % i)
	check("anaconda: body damage reduces mobility",body.speed_factor()<mobility_full*0.85)

	# ---- Blob ----
	body=fresh("blob")
	var blob_before := body.alive_count()
	body.damage(body.region_target("chest"),4.0,Vector3.RIGHT*10)
	check("blob: damage excavates mass permanently (no regeneration)",body.alive_count()<blob_before and body.regen==null)

	FileAccess.open("res://docs/roster-validation.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("ROSTER VALIDATION ",checks.size()-failures,"/",checks.size())
	battle.queue_free()
	await process_frame
	quit(1 if failures else 0)
