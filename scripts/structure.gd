class_name MonsterStructure
extends RefCounted

var weakpoints := {}
var proportional := false
var joint_ids := {}
var intact_counts := {}
var intact_major := {}
var disabled := {"left_arm":false,"right_arm":false}
var counts := {}
var potential := {}
# Data-driven extensions (tournament roster). Empty for the original archetypes.
var limbs: Array = []
var limb_regions := {}
var fatal_rules: Array = []
var regenerative := false
var has_biped := true
var proportional_limbs := false
var leg_fail := {"thigh":0.22,"shin":0.18,"foot":0.12}

func configure(archetype: Dictionary) -> void:
	limbs=archetype.get("limbs",[])
	fatal_rules=archetype.get("fatal",[])
	regenerative=archetype.get("special",{}).has("regen")
	proportional_limbs=archetype.get("proportional_limbs",false)
	leg_fail=archetype.get("leg_fail",{"thigh":0.22,"shin":0.18,"foot":0.12})
	limb_regions.clear()
	for limb in limbs: limb_regions[limb.id]=limb.regions

func build(cubes: Array[Dictionary]) -> void:
	joint_ids.clear()
	intact_counts.clear()
	intact_major.clear()
	disabled = {"left_arm":false,"right_arm":false,"left_leg":false,"right_leg":false}
	for limb in limbs: disabled[limb.id]=false
	for region in ["left_shoulder","right_shoulder","neck","left_thigh","right_thigh"]:
		joint_ids[region] = []
	for i in cubes.size():
		var r: String = cubes[i].region
		intact_counts[r] = intact_counts.get(r,0)+1
		intact_major[cubes[i].major]=intact_major.get(cubes[i].major,0)+1
		if joint_ids.has(r): joint_ids[r].append(i)
	has_biped=intact_counts.has("left_thigh") and intact_counts.has("left_shoulder") and intact_counts.has("neck")
	refresh(cubes)

func refresh(cubes: Array[Dictionary]) -> void:
	counts.clear()
	potential.clear()
	for c in cubes:
		var alive: bool=c.get("alive",true)
		var recoverable := regenerative and int(c.get("state",0))==1
		if not alive and not recoverable: continue
		potential[c.region]=potential.get(c.region,0)+1
		potential["major:"+c.major]=potential.get("major:"+c.major,0)+1
		if not alive: continue
		counts[c.region]=counts.get(c.region,0)+1
		counts["major:"+c.major]=counts.get("major:"+c.major,0)+1

func material(region: String) -> int:
	if intact_counts.has(region): return counts.get(region,0)
	return counts.get("major:"+region,0)

# Alive material of a region, major group or declared limb as a fraction of its pristine amount.
func fraction(key: String, use_potential: bool=false) -> float:
	var source := potential if use_potential else counts
	if limb_regions.has(key):
		var have := 0
		var total := 0
		for region in limb_regions[key]:
			have+=source.get(region,0)
			total+=intact_counts.get(region,0)
		return float(have)/maxi(1,total)
	if intact_counts.has(key): return float(source.get(key,0))/maxi(1,intact_counts[key])
	if intact_major.has(key): return float(source.get("major:"+key,0))/maxi(1,intact_major[key])
	return 1.0

func limb_quality(id: String) -> float:
	if disabled.get(id,false): return 0.0
	return fraction(id)

func leg_quality(side: String) -> float:
	if not has_biped: return 1.0
	if disabled.get(side+"_leg",false): return 0
	var total: float=intact_counts[side+"_thigh"]+intact_counts[side+"_shin"]+intact_counts[side+"_foot"]
	return minf(material(side+"_leg")/total,minf(material(side+"_shin")/float(intact_counts[side+"_shin"]),material(side+"_thigh")/float(intact_counts[side+"_thigh"])))

func leg_state(side: String) -> String:
	var quality := leg_quality(side)
	if quality<=0: return "LOST"
	if quality<0.45: return "COMPROMISED"
	if quality<0.8: return "DAMAGED"
	return "HEALTHY"

func threshold(region: String, fraction_value: float, legacy: int) -> int:
	if not proportional: return legacy
	var part := region.trim_prefix("left_").trim_prefix("right_")
	fraction_value=float(weakpoints.get(part,fraction_value))
	var total: int=intact_counts.get(region,0)
	if region=="torso": total=intact_counts.get("chest",0)+intact_counts.get("abdomen",0)+intact_counts.get("pelvis",0)
	return maxi(1,int(total*fraction_value))

func alive_limbs(kind: String) -> int:
	var n := 0
	for limb in limbs:
		if limb.get("kind","")==kind and not disabled.get(limb.id,false): n+=1
	return n

func fatal_reason() -> String:
	if not fatal_rules.is_empty():
		for rule in fatal_rules:
			if rule.has("limb_kind"):
				if alive_limbs(rule.limb_kind)<=int(rule.get("max_alive",0)): return rule.reason
				continue
			var have := 0.0
			var total := 0.0
			for key in rule.regions:
				var f := fraction(key,regenerative)
				var weight: float=intact_counts.get(key,intact_major.get(key,0))
				have+=f*weight
				total+=weight
			if total>0 and have/total<=float(rule.fraction): return rule.reason
		return ""
	if not has_biped: return ""
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
	if has_biped:
		for side in ["left","right"]:
			var arm: String = side+"_arm"
			var was_arm: bool=disabled[arm]
			if regenerative: disabled[arm]=false
			elif was_arm: continue
			var shoulder: String = side+"_shoulder"
			var count := 0
			for id in joint_ids[shoulder]:
				if cubes[id].alive: count += 1
			# Regional load-bearing approximation; no hidden health damage.
			if count <= threshold(shoulder,.25,8):
				disabled[arm] = true
				if not was_arm: lost.append(arm)
		for side in ["left","right"]:
			var leg: String=side+"_leg"
			var was_leg: bool=disabled[leg]
			if regenerative: disabled[leg]=false
			elif was_leg: continue
			var broken := (fraction(side+"_thigh")<=float(leg_fail.thigh) or fraction(side+"_shin")<=float(leg_fail.shin) or fraction(side+"_foot")<=float(leg_fail.foot)) if proportional_limbs else (material(side+"_thigh")<=11 or material(side+"_shin")<=7 or material(side+"_foot")<=threshold("neck",.17,4))
			if broken:
				disabled[leg]=true
				if not was_leg: lost.append(leg)
	for limb in limbs:
		var id: String=limb.id
		if regenerative:
			var was: bool=disabled.get(id,false)
			disabled[id]=false
			if fraction(id)<=float(limb.get("fail",0.3)):
				disabled[id]=true
				if not was: lost.append(id)
			continue
		if disabled.get(id,false): continue
		if fraction(id)<=float(limb.get("fail",0.3)):
			disabled[id]=true
			lost.append(id)
	return lost

func owns(cube: Dictionary, limb_id: String) -> bool:
	return cube.major==limb_id or (limb_regions.has(limb_id) and limb_regions[limb_id].has(cube.region))
