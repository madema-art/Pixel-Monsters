extends "res://scripts/battle.gd"

var results: Array[Dictionary]=[]
var suite_root := ""

func _ready() -> void:
	super._ready()
	suite_root=OS.get_environment("PIXEL_MONSTERS_RENDERED_SUITE")
	if suite_root=="": suite_root="res://docs/evidence/milestone04"
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.physics_ticks_per_second=120
	run_suite.call_deferred()

func run_suite() -> void:
	for trial in [[211,"gorgeblock","needlemantle"],[617,"needlemantle","gorgeblock"],[1203,"needlemantle","bastion"],[4441,"bastion","needlemantle"],[7907,"bastion","gorgeblock"],[9929,"gorgeblock","bastion"]]:
		var seed_value: int=trial[0]
		restart(seed_value,[trial[1],trial[2]])
		Engine.time_scale=2.0
		var recorder=preload("res://scripts/combat/runtime_probe.gd").new()
		recorder.directory=suite_root+"/"+str(seed_value)
		add_child(recorder)
		var deadline := Time.get_ticks_msec()+360000
		while not finished or elapsed-finish_time<9:
			await get_tree().create_timer(.25).timeout
			if Time.get_ticks_msec()>deadline: break
		results.append({"seed":seed_value,"finished":finished,"duration":finish_time,"snapshot":snapshot(),"director":camera.director.history.duplicate(true),"music":music.history.duplicate(true)})
		FileAccess.open(suite_root+"/suite.json",FileAccess.WRITE).store_string(JSON.stringify(results,"\t"))
		print("RENDERED SUITE: ",seed_value," finished ",finished," duration ",finish_time)
		recorder.queue_free()
		await get_tree().process_frame
	Engine.time_scale=1
	Engine.physics_ticks_per_second=60
	get_tree().quit()
