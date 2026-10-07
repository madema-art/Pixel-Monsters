extends Node3D

var monsters: Array[CombatMonster]=[]
var brains: Array[MonsterBrain]=[]
var debris: CubeDebris
var camera: ObserverCamera
var sound: BattleSound
var elapsed := 0.0
var battle_seed := 0
var paused := false
var speed_index := 0
var diagnostics := false
var finished := false
var winner := ""
var finish_time := 0.0
var tick_index := 0
var hits: Array[Dictionary]=[]
var samples: Array[Dictionary]=[]
var stages := {}
var header: Label
var caption: Label
var metrics: Label
var controls: Label
var debug_target := 0
var frame_ms: Array[float]=[]
var sweep_ms := 0.0

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	add_child(MiniatureArena.new())
	debris=CubeDebris.new()
	debris.name="Debris"
	debris.rubble_seconds=120
	debris.persistent_rubble=true
	debris.process_mode=Node.PROCESS_MODE_PAUSABLE
	add_child(debris)
	sound=BattleSound.new()
	sound.process_mode=Node.PROCESS_MODE_PAUSABLE
	add_child(sound)
	for i in 2:
		var fighter := CombatMonster.new()
		fighter.name="TITAN" if i==0 else "COLOSSUS"
		fighter.process_mode=Node.PROCESS_MODE_PAUSABLE
		add_child(fighter)
		fighter.setup_fighter(Color("117982") if i==0 else Color("b34524"),debris,Vector3(-20 if i==0 else 20,0,0),-PI/2 if i==0 else PI/2)
		monsters.append(fighter)
		brains.append(MonsterBrain.new())
	camera=ObserverCamera.new()
	camera.name="Observer"
	camera.fov=55
	camera.far=400
	add_child(camera)
	camera.current=true
	build_hud()
	restart()
	print("PIXEL MONSTERS / AUTONOMOUS BATTLE: 1000 + 1000 cubes. Seed ",battle_seed)
	if OS.get_environment("PIXEL_MONSTERS_VERIFY_DIR")!="": add_child(load("res://scripts/combat/runtime_probe.gd").new())

func restart(seed_value: int=0) -> void:
	paused=false
	get_tree().paused=false
	Engine.time_scale=1
	speed_index=0
	battle_seed=seed_value if seed_value!=0 else int(Time.get_ticks_usec())
	elapsed=0
	finished=false
	winner=""
	finish_time=0
	hits.clear()
	samples.clear()
	stages.clear()
	debris.clear()
	for fighter in monsters:
		fighter.reset_body()
		fighter.reset_motion()
	brains[0].initialize(battle_seed,{"aggression":0.87,"hook":1.7,"kick":0.65,"evade":0.18})
	brains[1].initialize(battle_seed+997,{"aggression":0.78,"hook":0.85,"kick":1.6,"evade":0.28})
	stages["pristine"]=snapshot()

func simulate_step(dt: float) -> void:
	elapsed+=dt
	tick_index+=1
	for i in 2: brains[i].tick(dt,monsters[i],monsters[1-i],self)
	for fighter in monsters:
		var previous_step := fighter.stepping
		fighter.update_motor(dt)
		if previous_step!="" and fighter.stepping=="" and not fighter.defeated: sound.footfall(fighter.feet[previous_step])
	var delta := monsters[1].position-monsters[0].position
	delta.y=0
	var minimum := 8.5
	if delta.length()<minimum and not finished:
		var correction := delta.normalized()*(minimum-delta.length())*0.5
		monsters[0].position-=correction
		monsters[1].position+=correction
	for fighter in monsters: fighter.update_pose()
	var begin := Time.get_ticks_usec()
	for i in 2:
		var index := (tick_index+i)%2
		monsters[index].attack_motion.resolve(monsters[index],self)
	sweep_ms=(Time.get_ticks_usec()-begin)/1000.0
	if not finished:
		for i in 2:
			if monsters[i].defeated:
				finished=true
				winner=monsters[1-i].name
				finish_time=elapsed
				monsters[1-i].attack_motion.cancel()
				monsters[1-i].state="VICTORIOUS"
				print("FIGHT ENDED: ",winner," at ",snappedf(elapsed,0.1),"s; ",monsters[i].defeat_reason)
				break
	var damage := 1.0-float(monsters[0].alive_count()+monsters[1].alive_count())/2000.0
	for pair in [["25_percent",0.25],["50_percent",0.5],["severe",0.65]]:
		if damage>=pair[1] and not stages.has(pair[0]): stages[pair[0]]=snapshot()
	if finished and elapsed-finish_time>3 and not stages.has("aftermath"): stages["aftermath"]=snapshot()

func _physics_process(dt: float) -> void:
	if not paused: simulate_step(dt)

func on_impact(attacker: CombatMonster, victim: CombatMonster, move: String, at: Vector3, report: Dictionary, power: float) -> void:
	attacker.connected_hits+=1
	hits.append({"time":snappedf(elapsed,0.01),"attacker":str(attacker.name),"victim":str(victim.name),"move":move,"region":attacker.attack_motion.region,"direct":report.direct,"detached":report.detached,"remaining":report.remaining,"query_ms":report.query_ms,"event_ms":report.event_ms,"structure_ms":victim.structure_ms})
	sound.impact(at,power,report.direct+report.detached)
	var distance := camera.global_position.distance_to(at)
	camera.shake=maxf(camera.shake,clampf(power/24.0*(report.direct+report.detached)/60.0*25/maxf(10,distance),0.02,0.7))
	if move=="headbutt": attacker.head_recoil=0.35

func snapshot() -> Dictionary:
	var bodies: Array[Dictionary]=[]
	for fighter in monsters:
		bodies.append({"name":str(fighter.name),"cubes":fighter.alive_count(),"state":fighter.state,"arms":[fighter.structure.disabled.left_arm,fighter.structure.disabled.right_arm],"legs":[fighter.structure.leg_state("left"),fighter.structure.leg_state("right")],"speed":fighter.speed_factor(),"commands":fighter.commands,"hits":fighter.connected_hits,"animation_ms":fighter.animation_ms,"motor_ms":fighter.motor_ms,"structure_ms":fighter.structure_ms,"defeated":fighter.defeated,"reason":fighter.defeat_reason})
	return {"time":snappedf(elapsed,0.1),"seed":battle_seed,"finished":finished,"winner":winner,"fps":Engine.get_frames_per_second(),"frame_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000,"physics_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000,"active_debris":debris.active.size(),"rubble":debris.rubble.size(),"collision_bodies":debris.max_physical+1,"ai_ms":brains[0].think_ms+brains[1].think_ms,"sweep_ms":sweep_ms,"monsters":bodies}

func text_label(parent: Node, text: String, size: int) -> Label:
	var item := Label.new()
	item.text=text
	item.add_theme_font_size_override("font_size",size)
	item.add_theme_color_override("font_color",Color("ebdcc0"))
	item.add_theme_color_override("font_shadow_color",Color(0,0,0,0.8))
	item.add_theme_constant_override("shadow_offset_x",2)
	item.add_theme_constant_override("shadow_offset_y",2)
	parent.add_child(item)
	return item

func build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var top := VBoxContainer.new()
	top.position=Vector2(24,20)
	canvas.add_child(top)
	header=text_label(top,"PIXEL MONSTERS",24)
	caption=text_label(top,"",15)
	metrics=text_label(top,"",14)
	metrics.visible=false
	var bottom := VBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	bottom.position=Vector2(24,-66)
	canvas.add_child(bottom)
	controls=text_label(bottom,"",14)
	text_label(bottom,"WASD fly · Q/E yaw · RMB look · Z/X rise/drop · Shift boost · +/- speed · Wheel zoom · C home",13)

func _process(_dt: float) -> void:
	var speed: float=[1.0,0.5,0.25][speed_index]
	controls.text="SPACE %s · L time %.2fx · R new fight · F3 diagnostics" % ["resume" if paused else "pause",speed]
	caption.text="TITAN  /  COLOSSUS" if not finished else "%s REMAINS · R TO WATCH A NEW FIGHT" % winner
	metrics.visible=diagnostics
	if diagnostics:
		metrics.text="%.1fs · seed %d · %d FPS · debris %d/%d\nTITAN %d · %s\nCOLOSSUS %d · %s\nAI %.3fms · rig %.2fms · contact %.2fms\nTAB debug target: %s · 1/2 arms · 3 leg · 4 core · F force hook" % [elapsed,battle_seed,Engine.get_frames_per_second(),debris.active.size(),debris.max_physical,monsters[0].alive_count(),monsters[0].state,monsters[1].alive_count(),monsters[1].state,brains[0].think_ms+brains[1].think_ms,monsters[0].animation_ms+monsters[1].animation_ms,sweep_ms,monsters[debug_target].name]

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_SPACE:
			paused=not paused
			get_tree().paused=paused
		KEY_L:
			speed_index=(speed_index+1)%3
			Engine.time_scale=[1.0,0.5,0.25][speed_index]
		KEY_R: restart()
		KEY_C: camera.reset_view()
		KEY_F3: diagnostics=not diagnostics
		KEY_TAB:
			if diagnostics: debug_target=1-debug_target
		KEY_1:
			if diagnostics: force_region(debug_target,"left_shoulder",4.0)
		KEY_2:
			if diagnostics: force_region(debug_target,"right_shoulder",4.0)
		KEY_3:
			if diagnostics: force_region(debug_target,"left_thigh",4.0)
		KEY_4:
			if diagnostics: force_region(debug_target,"neck",4.0)
		KEY_F:
			if diagnostics: monsters[debug_target].request_attack("heavy_hook",monsters[1-debug_target],"chest",MonsterMoves.side_for(monsters[debug_target],"heavy_hook",brains[debug_target].rng))

func force_region(index: int, region: String, radius: float) -> Dictionary:
	return monsters[index].damage(monsters[index].region_target(region),radius,Vector3.UP*12)
