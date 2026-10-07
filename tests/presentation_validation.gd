extends SceneTree

var checks: Array[Dictionary]=[]
var failures := 0
var battle: Node3D

func check(label: String, passed: bool) -> void:
	checks.append({"check":label,"passed":passed})
	if not passed: failures+=1

func _initialize() -> void:
	run.call_deferred()

func key(code: int) -> void:
	var event := InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	event.pressed=true
	battle._unhandled_input(event)
	battle.camera._unhandled_input(event)

func run() -> void:
	battle=load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	battle.set_physics_process(false)
	battle.restart(211)
	await process_frame
	check("Exactly 1000 cubes in each cinematic body",battle.monsters[0].alive_count()==1000 and battle.monsters[1].alive_count()==1000)
	check("Director enabled on launch",battle.camera.director_enabled)
	check("Opening framing clear of buildings",not battle.camera.director.blocked(battle.camera.position,battle.camera.director.look_goal))
	check("Opening full-body coverage",battle.camera.director.coverage(battle.camera.position,battle.camera.director.look_goal,battle.camera.fov)<.95)
	var before: Vector3=battle.camera.position
	key(KEY_W)
	check("Movement immediately overrides director",not battle.camera.director_enabled)
	check("Override preserves current camera position",battle.camera.position==before)
	key(KEY_EQUAL)
	check("Camera speed adjustment",battle.camera.target_speed>12)
	key(KEY_SPACE)
	var time_before: float=battle.elapsed
	var position_before: Vector3=battle.camera.position
	battle.camera.velocity=Vector3.RIGHT*5
	await create_timer(.1,true).timeout
	check("Pause freezes battle clock",battle.elapsed==time_before)
	check("Free camera continues during pause",battle.camera.position.distance_to(position_before)>.01)
	check("Pause freezes GPU dust simulation",battle.effects.pool[0].speed_scale==0)
	key(KEY_SPACE)
	key(KEY_L)
	check("Half speed",Engine.time_scale==.5)
	key(KEY_L)
	check("Quarter speed",Engine.time_scale==.25)
	battle.sound.layer(Vector3.ZERO,"hook",-12)
	check("Slow motion keeps impact pitch natural",battle.sound.pool[0].pitch_scale>.8)
	key(KEY_H)
	await process_frame
	await process_frame
	check("HUD off removes canvas",not battle.hud.visible)
	key(KEY_V)
	check("Director can be restored",battle.camera.director_enabled)
	key(KEY_R)
	await process_frame
	await process_frame
	check("Restart restores time and pristine body",Engine.time_scale==1 and battle.monsters[0].alive_count()==1000)
	battle.elapsed=20
	battle.music.decision_age=10
	battle.music._process(.1)
	check("Early battle cue",battle.music.state==1)
	battle.finished=true
	battle.finish_time=battle.elapsed
	battle.music.decision_age=10
	battle.music._process(.1)
	check("Collapse does not trigger spurious desperate cue",battle.music.state==1)
	battle.elapsed+=2.1
	battle.music.decision_age=10
	battle.music._process(.1)
	check("Aftermath cue after collapse breathing room",battle.music.state==5)
	var pos: Vector3=battle.camera.position
	battle.camera.director.age=20
	battle.camera.director.update(.01,battle.camera)
	check("Director holds collapse until four seconds",not battle.camera.director.shot.begins_with("AFTERMATH"))
	FileAccess.open("res://docs/presentation-validation.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("PRESENTATION VALIDATION ",checks.size()-failures,"/",checks.size())
	Engine.time_scale=1
	paused=false
	battle.queue_free()
	await process_frame
	quit(1 if failures else 0)
