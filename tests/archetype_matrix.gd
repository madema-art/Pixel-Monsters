extends SceneTree

var reports: Array[Dictionary]=[]
var battle: Node3D
var failed := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	battle=load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	battle.set_physics_process(false)
	for trial in [[211,"gorgeblock","needlemantle"],[617,"needlemantle","gorgeblock"],[1203,"needlemantle","bastion"],[4441,"bastion","needlemantle"],[7907,"bastion","gorgeblock"],[9929,"gorgeblock","bastion"]]:
		var seed_value: int=trial[0]
		battle.restart(seed_value,[trial[1],trial[2]])
		var start := Time.get_ticks_usec()
		var peak_animation := 0.0
		var peak_contact := 0.0
		for step in 36000:
			battle.simulate_step(1.0/60.0)
			peak_animation=maxf(peak_animation,battle.monsters[0].animation_ms+battle.monsters[1].animation_ms)
			peak_contact=maxf(peak_contact,battle.sweep_ms)
			if step%90==0: await process_frame
			if battle.finished and battle.elapsed-battle.finish_time>4: break
		var summary: Dictionary=battle.snapshot()
		summary["duration"]=battle.finish_time
		summary["wall_seconds"]=(Time.get_ticks_usec()-start)/1000000.0
		summary["stages"]=battle.stages.duplicate(true)
		summary["hits"]=battle.hits.duplicate(true)
		summary["peak_animation_ms"]=peak_animation
		summary["peak_contact_ms"]=peak_contact
		var longest_gap := 0.0
		for i in range(1,battle.hits.size()): longest_gap=maxf(longest_gap,battle.hits[i].time-battle.hits[i-1].time)
		summary["longest_contact_gap"]=longest_gap
		summary["passed"]=summary.finished and longest_gap<30
		if not summary.passed: failed+=1
		reports.append(summary)
		print("BATCH FIGHT ",seed_value," ",summary.finished," duration ",summary.duration," hits ",summary.hits.size()," longest gap ",longest_gap," cubes ",summary.monsters[0].cubes,"/",summary.monsters[1].cubes)
		FileAccess.open("res://docs/m4-matchup-matrix.json",FileAccess.WRITE).store_string(JSON.stringify(reports,"\t"))
	await create_timer(0.25).timeout
	battle.queue_free()
	await process_frame
	quit(1 if failed else 0)

