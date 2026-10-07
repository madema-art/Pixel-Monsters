class_name MonsterStructure
extends RefCounted

var joint_ids := {}
var intact_counts := {}
var disabled := {"left_arm":false,"right_arm":false}

func build(cubes: Array[Dictionary]) -> void:
	joint_ids.clear()
	intact_counts.clear()
	disabled = {"left_arm":false,"right_arm":false}
	for region in ["left_shoulder","right_shoulder","neck","left_thigh","right_thigh"]:
		joint_ids[region] = []
	for i in cubes.size():
		var r: String = cubes[i].region
		intact_counts[r] = intact_counts.get(r,0)+1
		if joint_ids.has(r): joint_ids[r].append(i)

func remaining(cubes: Array[Dictionary], region: String) -> int:
	var count := 0
	for c in cubes:
		if c.alive and (c.region == region or c.major == region): count += 1
	return count

func failures(cubes: Array[Dictionary]) -> Array[String]:
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
	return lost
