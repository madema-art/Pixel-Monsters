class_name MonsterStructure
extends RefCounted

var weakpoints := {}
var proportional := false
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
	var total: float=intact_counts[side+"_thigh"]+intact_counts[side+"_shin"]+intact_counts[side+"_foot"]
	return minf(material(side+"_leg")/total,minf(material(side+"_shin")/float(intact_counts[side+"_shin"]),material(side+"_thigh")/float(intact_counts[side+"_thigh"])))

func leg_state(side: String) -> String:
	var quality := leg_quality(side)
	if quality<=0: return "LOST"
	if quality<0.45: return "COMPROMISED"
	if quality<0.8: return "DAMAGED"
	return "HEALTHY"

func threshold(region: String, fraction: float, legacy: int) -> int:
	if not proportional: return legacy
	var part := region.trim_prefix("left_").trim_prefix("right_")
	fraction=float(weakpoints.get(part,fraction))
	var total: int=intact_counts.get(region,0)
	if region=="torso": total=intact_counts.chest+intact_counts.abdomen+intact_counts.pelvis
	return maxi(1,int(total*fraction))

func fatal_reason() -> String:
	if material("neck")<=threshold("neck",.17,4): return "NECK CONNECTION FAILED"
	if material("head")<=threshold("head",.17,20): return "HEAD DESTROYED"
	if material("torso")<=threshold("torso",.277,104): return "TORSO STRUCTURE FAILED"
	if material("pelvis")<=threshold("pelvis",.12,10) and material("abdomen")<=threshold("abdomen",.20,18): return "CORE SUPPORT FAILED"
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
		if count <= threshold(shoulder,.25,8):
			disabled[arm] = true
			lost.append(arm)
	for side in ["left","right"]:
		var leg: String=side+"_leg"
		if disabled[leg]: continue
		if material(side+"_thigh")<=11 or material(side+"_shin")<=7 or material(side+"_foot")<=threshold("neck",.17,4):
			disabled[leg]=true
			lost.append(leg)
	return lost
