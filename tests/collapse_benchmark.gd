extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var battle=load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	battle.set_physics_process(false)
	# Worst-case emission workload: all 1000 cubes, before any normal battle damage.
	battle.monsters[1].defeat("BENCHMARK")
	var started := Time.get_ticks_usec()
	battle.monsters[1].update_motor(1.9)
	var work_ms := (Time.get_ticks_usec()-started)/1000.0
	var report := {"headless":true,"emitted":battle.debris.born,"work_ms":work_ms,"active":battle.debris.active.size(),"rubble":battle.debris.rubble.size(),"collapsed":battle.monsters[1].collapsed}
	FileAccess.open("res://docs/collapse-benchmark.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	var passed: bool=report.collapsed and report.emitted==1000 and report.active<=192
	battle.queue_free()
	await process_frame
	quit(0 if passed else 1)
