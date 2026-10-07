extends SceneTree
# Autonomy matrix: every entrant fights two opponents to a finish. Writes docs/roster-matrix.json.
# Measures completion, contact gaps (no endless standoffs), which attacks connected, simulation cost per step.
const Archetypes = preload("res://scripts/combat/archetypes.gd")

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var battle: Node3D=load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	battle.set_physics_process(false)
	var ids: Array=Archetypes.ROSTER
	var offsets := [1,6]
	if OS.get_environment("PM_OFFSETS")!="": offsets=Array(OS.get_environment("PM_OFFSETS").split(",")).map(func(v): return int(v))
	var seed_value := int(OS.get_environment("PM_SEED")) if OS.get_environment("PM_SEED")!="" else 2024
	var reports: Array[Dictionary]=[]
	var connected := {}
	var unfinished := 0
	for i in ids.size():
		for offset in offsets:
			var a: String=ids[i]
			var b: String=ids[(i+offset)%ids.size()]
			battle.restart(seed_value+i*13+offset,[a,b])
			var wall := Time.get_ticks_usec()
			var peak_step := 0.0
			var total_step := 0.0
			var step_count := 0
			var peak_active := 0
			for step in 36000:
				var t0 := Time.get_ticks_usec()
				battle.simulate_step(1.0/60.0)
				var spent := (Time.get_ticks_usec()-t0)/1000.0
				peak_step=maxf(peak_step,spent)
				total_step+=spent
				step_count+=1
				peak_active=maxi(peak_active,battle.debris.active.size())
				if step%300==0: await process_frame
				if battle.finished and battle.elapsed-battle.finish_time>3: break
			var gap := 0.0
			for h in range(1,battle.hits.size()): gap=maxf(gap,battle.hits[h].time-battle.hits[h-1].time)
			if battle.hits.is_empty(): gap=battle.elapsed
			for h in battle.hits:
				var owner_id: String=a if h.attacker==battle.monsters[0].name else b
				if not connected.has(owner_id): connected[owner_id]={}
				connected[owner_id][h.move]=true
			var report := {"a":a,"b":b,"finished":battle.finished,"winner":battle.winner,"duration":snappedf(battle.finish_time if battle.finished else battle.elapsed,0.1),"hits":battle.hits.size(),"longest_gap":snappedf(gap,0.1),"peak_step_ms":snappedf(peak_step,0.01),"avg_step_ms":snappedf(total_step/maxf(1,step_count),0.001),"wall_s":snappedf((Time.get_ticks_usec()-wall)/1e6,0.1),"ranged_fired":battle.ranged.fired}
			reports.append(report)
			if not battle.finished or gap>=30: unfinished+=1
			print("MATRIX ",a," vs ",b," finished=",battle.finished," t=",report.duration," winner=",battle.winner," gap=",report.longest_gap," peak_step_ms=",report.peak_step_ms)
	var never := {}
	for id in ids:
		var names: Array=Archetypes.definition(id).attacks.keys()
		var missing: Array=[]
		for n in names: if not connected.get(id,{}).has(n): missing.append(n)
		never[id]=missing
	FileAccess.open("res://docs/roster-matrix.json",FileAccess.WRITE).store_string(JSON.stringify({"fights":reports,"attacks_never_connected":never,"problem_fights":unfinished},"\t"))
	print("MATRIX COMPLETE problem_fights=",unfinished)
	battle.queue_free()
	await process_frame
	quit(1 if unfinished>0 else 0)
