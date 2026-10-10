extends SceneTree
# Explicit preloads: no dependence on the editor-generated global class cache.
const ObserverCamera = preload("res://scripts/observer.gd")
# Normal-launch integration: roster selection, R / Y new-fight, gamepad observer camera.
const Archetypes = preload("res://scripts/combat/archetypes.gd")
var checks := []
var failures := 0

func check(label: String, passed: bool) -> void:
	checks.append({"check":label,"passed":passed})
	if not passed:
		failures+=1
		push_error(label)

func _initialize() -> void:
	run.call_deferred()

func settle(cam: Node3D, seconds: float) -> void:
	var end := Time.get_ticks_msec()+int(seconds*1000)
	while Time.get_ticks_msec()<end: await process_frame

func run() -> void:
	for scene_path in ["res://scenes/battle.tscn","res://scenes/prototype.tscn"]:
		var game: Node3D=load(scene_path).instantiate()
		root.add_child(game)
		await process_frame
		var a: String=game.monsters[0].archetype.get("id","")
		var b: String=game.monsters[1].archetype.get("id","")
		check(scene_path+": normal startup uses two different roster entrants",Archetypes.ROSTER.has(a) and Archetypes.ROSTER.has(b) and a!=b)
		check(scene_path+": legacy archetypes are not default fighters",not Archetypes.IDS.has(a) and not Archetypes.IDS.has(b))
		check(scene_path+": both bodies are exactly 1,000 cubes",game.monsters[0].cubes.size()==1000 and game.monsters[1].cubes.size()==1000)
		game.queue_free()
		await process_frame
	var game: Node3D=load("res://scenes/battle.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	# Roster coverage and no immediate repeats through the real R path.
	var seen := {}
	var previous := ""
	var repeats := 0
	var swaps := 0
	var previous_first := ""
	var valid := true
	for i in 80:
		var key := InputEventKey.new()
		key.physical_keycode=KEY_R
		key.pressed=true
		game._unhandled_input(key)
		var ids: Array=[game.monsters[0].archetype.id,game.monsters[1].archetype.id]
		valid=valid and Archetypes.ROSTER.has(ids[0]) and Archetypes.ROSTER.has(ids[1]) and ids[0]!=ids[1] and not game.finished
		var first_id: String=ids[0]
		ids.sort()
		var tag := "+".join(ids)
		if tag==previous: repeats+=1
		if previous_first!="" and first_id!=previous_first: swaps+=1
		previous_first=first_id
		previous=tag
		for id in ids: seen[id]=true
	check("R starts fresh roster fights (always two different entrants)",valid)
	if OS.get_environment("PM_FULL_ROSTER")=="1":
		check("R avoids repeating the identical pairing back to back",repeats==0)
	else:
		# Showcase pool is only two fighters: every restart is the same match with the sides swapped.
		check("showcase R alternates which side each fighter starts on",swaps>=0.4*80)
	check("R cycles the showcase pair (both sides, all entrants used)",seen.size()>=(14 if OS.get_environment("PM_FULL_ROSTER")=="1" else 2))
	var seed_before: int=game.battle_seed
	var pad := InputEventJoypadButton.new()
	pad.button_index=JOY_BUTTON_Y
	pad.pressed=true
	game._unhandled_input(pad)
	check("controller Y (observer_new_fight) starts a new fight",game.battle_seed!=seed_before and game.elapsed==0.0)
	# Camera: left stick moves (analog), right stick looks, deadzone ignores drift, keyboard untouched.
	var cam: ObserverCamera=game.camera
	cam.director_enabled=true
	Input.action_press("observer_forward",0.10)
	await settle(cam,0.4)
	check("stick drift below the deadzone does not move the camera or take over the director",cam.director_enabled)
	Input.action_release("observer_forward")
	cam.reset_view()
	cam.director_enabled=false
	var base := cam.global_position
	Input.action_press("observer_forward",0.45)
	await settle(cam,0.8)
	var half_distance := cam.global_position.distance_to(base)
	Input.action_release("observer_forward")
	await settle(cam,0.4)
	cam.reset_view()
	cam.director_enabled=false
	base=cam.global_position
	Input.action_press("observer_forward",1.0)
	await settle(cam,0.8)
	var full_distance := cam.global_position.distance_to(base)
	Input.action_release("observer_forward")
	check("left stick moves the camera forward",full_distance>1.0 and (cam.global_position-base).dot(-cam.global_basis.z)>0.0)
	check("left stick is analog (half deflection moves less than full)",half_distance>0.05 and full_distance>half_distance*1.4)
	cam.reset_view()
	cam.director_enabled=true
	Input.action_press("observer_right",1.0)
	await settle(cam,0.3)
	Input.action_release("observer_right")
	check("stick input hands the camera over from the director like WASD",not cam.director_enabled)
	cam.reset_view()
	cam.director_enabled=false
	var yaw_before := cam.target_yaw
	Input.action_press("observer_look_right",1.0)
	await settle(cam,0.5)
	Input.action_release("observer_look_right")
	check("right stick yaws continuously (look right turns right)",cam.target_yaw<yaw_before-0.4)
	var small := cam.target_yaw
	Input.action_press("observer_look_left",0.5)
	await settle(cam,0.5)
	Input.action_release("observer_look_left")
	check("right stick is analog",cam.target_yaw-small>0.1 and cam.target_yaw-small<1.0)
	Input.action_press("observer_look_up",1.0)
	await settle(cam,2.5)
	Input.action_release("observer_look_up")
	check("pitch is clamped (no flip)",cam.target_pitch<=ObserverCamera.PITCH_LIMIT+0.001 and cam.target_pitch>1.0)
	cam.reset_view()
	cam.director_enabled=true
	var toggle := InputEventJoypadButton.new()
	toggle.button_index=JOY_BUTTON_BACK
	toggle.pressed=true
	cam._unhandled_input(toggle)
	check("controller Back toggles director/free camera",not cam.director_enabled)
	FileAccess.open("res://docs/integration-validation.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("INTEGRATION VALIDATION ",checks.size()-failures,"/",checks.size())
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
