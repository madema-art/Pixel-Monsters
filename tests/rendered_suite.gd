extends "res://scripts/battle.gd"

var results: Array[Dictionary]=[]
var suite_root := ""

func _ready() -> void:
	super._ready()
	suite_root=OS.get_environment("PIXEL_MONSTERS_RENDERED_SUITE")
	if suite_root=="": suite_root="res://docs/evidence/milestone03"
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	run_suite.call_deferred()

func run_suite() -> void:
	for seed_value in [211,617,7907,9929]:
		restart(seed_value)
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
	get_tree().quit()
