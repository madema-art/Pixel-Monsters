class_name BodyLayout
extends RefCounted

const PITCH := 1.0
const CUBE_SIZE := 0.94
const ALLOCATION := {"head":120, "neck":24, "chest":200, "abdomen":92, "pelvis":84, "left_shoulder":32, "left_upper_arm":32, "left_forearm":36, "left_fist":20, "right_shoulder":32, "right_upper_arm":32, "right_forearm":36, "right_fist":20, "left_thigh":52, "left_shin":44, "left_foot":24, "right_thigh":52, "right_shin":44, "right_foot":24}

static func generate() -> Array[Dictionary]:
	var specs: Array = [
		["chest",Vector3(0,18.5,0),Vector3(4.4,3,2.5)],
		["abdomen",Vector3(0,14.5,0),Vector3(2.7,2.0,2.0)],
		["pelvis",Vector3(0,11.5,0),Vector3(3.4,1.6,2.1)],
		["neck",Vector3(0,22,0),Vector3(1.4,1,1.5)],
		["head",Vector3(0,25, -0.2),Vector3(2.4,2.8,2.0)]]
	for side in ["left", "right"]:
		var s: float = -1.0 if side == "left" else 1.0
		specs.append_array([
			[side+"_shoulder",Vector3(s*4.8,19.5,0),Vector3(1.9,1.8,1.7)],
			[side+"_upper_arm",Vector3(s*6,17,0),Vector3(1.35,2.1,1.4)],
			[side+"_forearm",Vector3(s*6.5,13.8,-0.3),Vector3(1.5,2.1,1.5)],
			[side+"_fist",Vector3(s*6.5,11.3,-0.6),Vector3(1.5,1.1,1.4)],
			[side+"_thigh",Vector3(s*2,8.6,0),Vector3(1.7,2.5,1.7)],
			[side+"_shin",Vector3(s*2,4.5,0),Vector3(1.3,2.5,1.4)],
			[side+"_foot",Vector3(s*2,1,-0.9),Vector3(1.8,0.85,2.2)]])
	var result: Array[Dictionary] = []
	var occupied := {}
	for spec in specs:
		var candidates: Array[Dictionary] = []
		var center: Vector3 = spec[1]
		var radius: Vector3 = spec[2]
		for x in range(int(center.x)-6,int(center.x)+7):
			for y in range(maxi(1,int(center.y)-5),int(center.y)+6):
				for z in range(-5,6):
					var cell := Vector3i(x,y,z)
					if occupied.has(cell): continue
					var p := Vector3(cell)
					var d := (p-center)/radius
					var score := d.length_squared()
					# Strong brow, forward jaw and squared feet within a curved silhouette.
					if spec[0] == "head" and y == 26 and z < 0: score -= 0.24
					candidates.append({"cell":cell,"score":score})
		candidates.sort_custom(func(a,b): return a.score < b.score)
		for i in ALLOCATION[spec[0]]:
			var cell: Vector3i = candidates[i].cell
			occupied[cell] = result.size()
			result.append({"cell":cell,"position":Vector3(cell),"region":spec[0],"major":major_region(spec[0])})
	assert(result.size()==1000)
	return result

static func major_region(region: String) -> String:
	if region.begins_with("left_"): return "left_arm" if region.contains("arm") or region.contains("shoulder") or region.contains("fist") else "left_leg"
	if region.begins_with("right_"): return "right_arm" if region.contains("arm") or region.contains("shoulder") or region.contains("fist") else "right_leg"
	return "head" if region == "head" or region == "neck" else "torso"
