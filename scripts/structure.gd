class_name MonsterStructure
extends RefCounted

var joint_ids := {}
var intact_counts := {}
var disabled := {"left_arm":false,"right_arm":false}
var counts := {}

func build(cubes: Array[Dictionary]) -> void:
	joint_ids.clear()
	intact_counts.clear()
	disabled = {"left_arm":false,"right_arm":false,"left_leg":false,"right_leg":false}
	for region in ["left_shoulder","right_shoulder","neck","left_thigh","right_thigh"]:
		joint_ids[region] = []
	for i in cubes.size():
		var r: String = cubes[i].region
		intact_counts[r] = intact_counts.get(r,0)+1
		if joint_ids.has(r): joint_ids[r].append(i)
	refresh(cubes)

func refresh(cubes: Array[Dictionary]) -> void:
	counts.clear()
	for c in cubes:
		if not c.get("alive",true): continue
		counts[c.region]=counts.get(c.region,0)+1
		counts["major:"+c.major]=counts.get("major:"+c.major,0)+1

func material(region: String) -> int:
	return counts.get(region,0) if BodyLayout.ALLOCATION.has(region) else counts.get("major:"+region,0)

func leg_quality(side: String) -> float:
	if disabled.get(side+"_leg",false): return 0
	return minf(material(side+"_leg")/120.0,minf(material(side+"_shin")/44.0,material(side+"_thigh")/52.0))

func leg_state(side: String) -> String:
	var quality := leg_quality(side)
	if quality<=0: return "LOST"
	if quality<0.45: return "COMPROMISED"
	if quality<0.8: return "DAMAGED"
	return "HEALTHY"

func fatal_reason() -> String:
	if material("neck")<=4: return "NECK CONNECTION FAILED"
	if material("head")<=20: return "HEAD DESTROYED"
	if material("torso")<=104: return "TORSO STRUCTURE FAILED"
	if material("pelvis")<=10 and material("abdomen")<=18: return "CORE SUPPORT FAILED"
	return ""

func remaining(cubes: Array[Dictionary], region: String) -> int:
	var count := 0
	for c in cubes:
		if c.alive and (c.region == region or c.major == region): count += 1
	return count

func failures(cubes: Array[Dictionary]) -> Array[String]:
	refresh(cubes)
	var lost: Array[String] = []
	for side in ["left","right"]:
		var arm: String = side+"_arm"
		if disabled[arm]: continue
		var shoulder: String = side+"_shoulder"
		var count := 0
		for id in joint_ids[shoulder]:
			if cubes[id].alive: count += 1
		# Regional load-bearing approximation; no hidden health damage.
		if count <= 8:
			disabled[arm] = true
			lost.append(arm)
	for side in ["left","right"]:
		var leg: String=side+"_leg"
		if disabled[leg]: continue
		if material(side+"_thigh")<=11 or material(side+"_shin")<=7 or material(side+"_foot")<=4:
			disabled[leg]=true
			lost.append(leg)
	return lost
