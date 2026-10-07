extends Node

var results: Array[Dictionary]=[]
var finished := false
var main: Node3D

func check(name: String, passed: bool, details: Dictionary={}) -> void:
	results.append({"test":name,"passed":passed,"details":details})

func run(scene: Node3D) -> void:
	main=scene
	for region in ["head","chest","left_shoulder","left_forearm","left_thigh","abdomen"]:
		main.reset_all()
		main.target_index=1
		main.select_region(region)
		main.attack()
		await get_tree().create_timer(2.6).timeout
		check("melee_"+region,not main.last_hit.is_empty() and main.last_hit.region==region and main.last_hit.direct>0,main.last_hit.duplicate(true))
	main.reset_all()
	main.select_region("head")
	main.attack()
	await get_tree().create_timer(2.6).timeout
	var before: int=main.monsters[1].alive_count()
	main.attack()
	await get_tree().create_timer(2.6).timeout
	check("repeated_erosion",main.monsters[1].alive_count()<before,{"before":before,"after":main.monsters[1].alive_count()})
	main.reset_all()
	main.select_region("left_shoulder")
	main.large_attack()
	await get_tree().create_timer(2.6).timeout
	check("shoulder_detachment",main.monsters[1].structure.disabled.left_arm and main.monsters[1].alive_count()>600,main.snapshot())
	main.target_index=0
	main.select_region("chest")
	main.attack()
	await get_tree().create_timer(2.6).timeout
	check("damaged_monster_can_strike",main.monsters[0].alive_count()<1000,main.last_hit.duplicate(true))
	main.reset_all()
	main.debris.simulation_seconds=0.08
	main.debris.rubble_seconds=0.08
	await main.stress_to_destroyed(500)
	check("debris_budget",main.debris.active.size()<=192,{"active":main.debris.active.size(),"peak":main.debris.peak_active})
	await get_tree().create_timer(0.5).timeout
	check("debris_cleanup",main.debris.active.is_empty() and main.debris.rubble.is_empty(),{"active":main.debris.active.size(),"rubble":main.debris.rubble.size()})
	main.debris.simulation_seconds=3.5
	main.debris.rubble_seconds=28
	main.reset_all()
	check("reset_1000_each",main.monsters[0].alive_count()==1000 and main.monsters[1].alive_count()==1000)
	main.camera.reset_view()
	var initial: Vector3=main.camera.position
	var w := InputEventKey.new()
	w.keycode=KEY_W
	w.physical_keycode=KEY_W
	w.pressed=true
	Input.parse_input_event(w)
	await get_tree().create_timer(0.3).timeout
	w.pressed=false
	Input.parse_input_event(w)
	check("observer_wasd",main.camera.position.distance_to(initial)>1,{"distance":main.camera.position.distance_to(initial)})
	var yaw_before: float=main.camera.yaw
	var q := InputEventKey.new()
	q.keycode=KEY_Q
	q.physical_keycode=KEY_Q
	q.pressed=true
	Input.parse_input_event(q)
	await get_tree().create_timer(0.3).timeout
	q.pressed=false
	Input.parse_input_event(q)
	check("observer_smooth_qe",absf(main.camera.yaw-yaw_before)>0.1,{"yaw_delta":main.camera.yaw-yaw_before})
	var look_before: float=main.camera.target_yaw
	main.camera.looking=true
	var motion := InputEventMouseMotion.new()
	motion.relative=Vector2(40,10)
	Input.parse_input_event(motion)
	await get_tree().process_frame
	main.camera.looking=false
	check("observer_mouse_look",absf(main.camera.target_yaw-look_before)>0.05)
	main.toggle_pause()
	check("pause",get_tree().paused)
	main.toggle_pause()
	main.toggle_slow()
	check("slow_motion",is_equal_approx(Engine.time_scale,0.2))
	main.toggle_slow()
	main.camera.reset_view()
	var failed := 0
	for item in results:
		if not item.passed: failed+=1
	var report := {"total":results.size(),"passed":results.size()-failed,"failed":failed,"results":results}
	var file := FileAccess.open("res://docs/runtime-tests.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	finished=true
	print("RUNTIME VALIDATION: ",report.passed," / ",report.total," passed")
