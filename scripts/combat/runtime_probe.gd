extends Node

# Optional local verification recorder. The normal launcher supplies no probe path.
var battle: Node3D
var directory := ""
var captures := {}
var history: Array[Dictionary]=[]
var next_sample := 0.0

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	directory=OS.get_environment("PIXEL_MONSTERS_VERIFY_DIR")
	DirAccess.make_dir_recursive_absolute(directory)
	battle=get_parent()
	if OS.get_environment("PIXEL_MONSTERS_VERIFY_UNCAPPED")=="1": DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	FileAccess.open(directory+"/launch.json",FileAccess.WRITE).store_string(JSON.stringify({"executable":OS.get_executable_path(),"debug_build":OS.is_debug_build(),"arguments":OS.get_cmdline_args(),"snapshot":battle.snapshot()},"\t"))

func _process(_dt: float) -> void:
	if battle.elapsed>=next_sample:
		next_sample=battle.elapsed+1
		history.append(battle.snapshot())
		FileAccess.open(directory+"/runtime.json",FileAccess.WRITE).store_string(JSON.stringify({"samples":history,"hits":battle.hits,"stages":battle.stages,"finish_time":battle.finish_time},"\t"))
	var total: int=battle.monsters[0].alive_count()+battle.monsters[1].alive_count()
	for marker in [["opening",battle.elapsed>=0.6],["first-exchanges",battle.hits.size()>=3],["limb-loss",battle.monsters[0].structure.disabled.left_arm or battle.monsters[1].structure.disabled.left_arm],["severe",total<750 and not battle.finished],["collapse",battle.finished and battle.elapsed-battle.finish_time>0.8],["aftermath",battle.finished and battle.elapsed-battle.finish_time>4]]:
		if marker[1] and not captures.has(marker[0]):
			captures[marker[0]]=true
			capture(marker[0])

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory+"/"+label+".png")
