extends RefCounted
# Explicit preloads: no dependence on the editor-generated global class cache.
const BodyLayout = preload("res://scripts/body_layout.gd")

const IDS := ["gorgeblock","needlemantle","bastion"]
# Tournament roster (Milestone 5 build-out), in bracket-seed order.
const ROSTER := ["giant_ape","fire_reptile","flying_dragon","giant_robot","giant_skeleton","diaper_baby","army_of_ten","pointy_hat_wizard","blob","giant_mantis","stone_colossus","eyeball_beast","giant_tarantula","dark_knight_rider","shadow_flame_demon","giant_anaconda"]
const SHOWCASE := ["giant_ape","fire_reptile"]
const RANGED := ["fire_reptile","flying_dragon","giant_robot","pointy_hat_wizard","stone_colossus","eyeball_beast","giant_tarantula","shadow_flame_demon"]
static var cache := {}

static func definition(id: String) -> Dictionary:
	if not cache.has(id):
		var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/creatures/"+id+".json"))
		assert(data.cells.size()==1000)
		cache[id]=data
	return cache[id]

static func body_cells(data: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for entry in data.cells:
		var p: Array=entry.cell
		var cell := Vector3i(int(p[0]),int(p[1]),int(p[2]))
		result.append({"cell":cell,"position":Vector3(cell),"region":entry.region,"major":entry.get("major",BodyLayout.major_region(entry.region)),"tag":entry.get("tag",""),"state":0})
	return result

# Main game currently showcases the Ape and the Reptile. Set PM_FULL_ROSTER=1 to draw from all 16.
static func available_roster() -> Array:
	var result: Array=[]
	var pool: Array = ROSTER if OS.get_environment("PM_FULL_ROSTER")=="1" else SHOWCASE
	for id in pool:
		if FileAccess.file_exists("res://data/creatures/"+id+".json"): result.append(id)
	return result
