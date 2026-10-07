extends RefCounted

const IDS := ["gorgeblock","needlemantle","bastion"]
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
		result.append({"cell":cell,"position":Vector3(cell),"region":entry.region,"major":BodyLayout.major_region(entry.region)})
	return result
