extends SceneTree
# Headless fight runner: PM_PAIRS="giant_ape:stone_colossus,..." PM_SEED=101 PM_MAX=240 godot --headless --script res://tests/roster_fight.gd

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var battle: Node3D=load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	battle.set_physics_process(false)
	var seed_value := int(OS.get_environment("PM_SEED")) if OS.get_environment("PM_SEED")!="" else 101
	var max_seconds := float(OS.get_environment("PM_MAX")) if OS.get_environment("PM_MAX")!="" else 240.0
	var failed := 0
	for pair in OS.get_environment("PM_PAIRS").split(","):
		var ids := pair.split(":")
		battle.restart(seed_value,[ids[0],ids[1]])
		var wall := Time.get_ticks_usec()
		var peak_ms := 0.0
		var steps := int(max_seconds*60)
		for step in steps:
			battle.simulate_step(1.0/60.0)
			if step%240==0: await process_frame
			if battle.finished and battle.elapsed-battle.finish_time>3: break
		var line := "%s vs %s | finished=%s winner=%s t=%.1f hits=%d remaining=%d/%d fired=%d proj=%d stream=%d" % [ids[0],ids[1],battle.finished,battle.winner,battle.elapsed,battle.hits.size(),battle.monsters[0].alive_count(),battle.monsters[1].alive_count(),battle.ranged.fired,battle.ranged.projectile_hits,battle.ranged.stream_ticks]
		var moves := {}
		for h in battle.hits: moves[h.attacker.left(3)+":"+h.move]=moves.get(h.attacker.left(3)+":"+h.move,0)+1
		print(line," wall=%.1fs" % ((Time.get_ticks_usec()-wall)/1e6))
		print("   wreck removed=",battle.wreck.cells_removed," blasts=",battle.wreck.blasts)
		print("   moves ",moves)
		for m in battle.monsters:
			if m.regen!=null: print("   regen loose=",m.regen.loose_count()," shattered=",m.regen.shattered," reattached=",m.regen.reattached)
		if not battle.finished: failed+=1
	battle.queue_free()
	await process_frame
	quit(1 if failed else 0)
