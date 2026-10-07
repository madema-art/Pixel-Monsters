extends Node3D

var monsters: Array[PixelMonster] = []
var debris: CubeDebris
var camera: ObserverCamera
var strike: MeleeStrike
var selected_region := "head"
var target_index := 1
var status: Label
var metrics: Label
var target_label: Label
var region_buttons := {}
var message := "Select a region, then strike. Body pixels are the health."
var frame_ms: Array[float] = []
var paused := false
var slow := false
var diagnostics := true
var last_hit := {}
var benchmark_results: Array[Dictionary] = []

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	add_child(MiniatureArena.new())
	debris=CubeDebris.new()
	debris.name="Debris"
	debris.process_mode=Node.PROCESS_MODE_PAUSABLE
	add_child(debris)
	for i in 2:
		var monster := PixelMonster.new()
		monster.name="TITAN" if i==0 else "COLOSSUS"
		monster.process_mode=Node.PROCESS_MODE_PAUSABLE
		monster.position=Vector3(-7 if i==0 else 7,0,0)
		monster.rotation.y=-PI/3 if i==0 else PI/3
		add_child(monster)
		monster.initialize(Color("117982") if i==0 else Color("b34524"),debris)
		monsters.append(monster)
	camera=ObserverCamera.new()
	camera.name="Observer"
	camera.fov=55
	camera.far=400
	add_child(camera)
	camera.current=true
	strike=MeleeStrike.new()
	strike.name="Melee"
	strike.process_mode=Node.PROCESS_MODE_PAUSABLE
	strike.observer=camera
	strike.connected.connect(on_hit)
	add_child(strike)
	build_hud()
	print("PIXEL MONSTERS: ready. Exactly ",monsters[0].alive_count()," + ",monsters[1].alive_count()," body cubes.")

func label(parent: Node, text: String, size: int, color: Color=Color("e7e5dc")) -> Label:
	var l := Label.new()
	l.text=text
	l.add_theme_font_size_override("font_size",size)
	l.add_theme_color_override("font_color",color)
	parent.add_child(l)
	return l

func build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name="DeveloperHUD"
	canvas.process_mode=Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	var top := VBoxContainer.new()
	top.position=Vector2(28,20)
	canvas.add_child(top)
	label(top,"PIXEL / MONSTERS",30,Color("f0d3a1"))
	label(top,"DESTRUCTION LAB    /    MILESTONE 01",13,Color("a8c2ca"))
	status=label(top,"",17)
	var right := VBoxContainer.new()
	right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	right.position=Vector2(-238,24)
	right.custom_minimum_size=Vector2(210,0)
	canvas.add_child(right)
	target_label=label(right,"",16,Color("f0d3a1"))
	var regions := {"head":"1   FACE / JAW","chest":"2   CHEST","left_shoulder":"3   LEFT SHOULDER","left_forearm":"4   LEFT ARM","left_thigh":"5   LEFT LEG","abdomen":"6   ABDOMEN"}
	for region in regions:
		var b := Button.new()
		b.text=regions[region]
		b.alignment=HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size=Vector2(210,32)
		b.pressed.connect(select_region.bind(region))
		right.add_child(b)
		region_buttons[region]=b
	for spec in [["F   HEAVY STRIKE",attack],["G   LARGE IMPACT",large_attack],["TAB   SWAP TARGET",swap_target],["R   RESET BOTH",reset_all],["P   PAUSE",toggle_pause],["L   SLOW MOTION",toggle_slow],["C   CAMERA HOME",camera.reset_view]]:
		var b := Button.new()
		b.text=spec[0]
		b.custom_minimum_size=Vector2(210,31)
		b.pressed.connect(spec[1])
		right.add_child(b)
	var bottom := VBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	bottom.position=Vector2(28,-167)
	canvas.add_child(bottom)
	metrics=label(bottom,"",14,Color("bed0d1"))
	label(bottom,"WASD fly  ·  Q/E yaw  ·  Hold RMB + mouse look  ·  Shift boost",15)
	label(bottom,"Z/X rise/drop  ·  Wheel zoom  ·  F3 diagnostics",15)
	select_region("head")

func select_region(region: String) -> void:
	selected_region=region
	for key in region_buttons:
		region_buttons[key].modulate=Color("ffd092") if key==region else Color.WHITE

func attack() -> void:
	if paused: return
	if not strike.trigger(monsters[1-target_index],monsters[target_index],selected_region):
		message="Strike unavailable: recovering or striking arm detached."

func large_attack() -> void:
	if not paused: strike.trigger(monsters[1-target_index],monsters[target_index],selected_region,4.3)

func swap_target() -> void:
	if not strike.running: target_index=1-target_index

func on_hit(result: Dictionary) -> void:
	last_hit=result
	message="%s HIT · %d cubes fractured · %d detached" % [result.region.to_upper(),result.direct,result.detached]

func reset_all() -> void:
	strike.cancel()
	debris.clear()
	for monster in monsters: monster.reset_body()
	last_hit={}
	message="RESET VERIFIED · 1,000 + 1,000 cubes"

func toggle_pause() -> void:
	paused=not paused
	get_tree().paused=paused

func toggle_slow() -> void:
	slow=not slow
	Engine.time_scale=0.2 if slow else 1.0

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_1: select_region("head")
		KEY_2: select_region("chest")
		KEY_3: select_region("left_shoulder")
		KEY_4: select_region("left_forearm")
		KEY_5: select_region("left_thigh")
		KEY_6: select_region("abdomen")
		KEY_F: attack()
		KEY_G: large_attack()
		KEY_TAB: swap_target()
		KEY_R: reset_all()
		KEY_P: toggle_pause()
		KEY_L: toggle_slow()
		KEY_C: camera.reset_view()
		KEY_F3: diagnostics=not diagnostics

func _process(dt: float) -> void:
	frame_ms.append(dt/maxf(Engine.time_scale,0.01)*1000)
	if frame_ms.size()>240: frame_ms.pop_front()
	status.text="TITAN  %d / 1000    |    COLOSSUS  %d / 1000\n%s" % [monsters[0].alive_count(),monsters[1].alive_count(),message]
	target_label.text="TARGET: "+monsters[target_index].name
	var disabled: Dictionary=monsters[target_index].structure.disabled
	metrics.visible=diagnostics
	metrics.text="%d FPS  ·  %.2f ms  ·  %s\nPhysical debris %d / %d  ·  Rubble %d  ·  Removed %d / 2000\nQuery %.3f ms  ·  Event %.3f ms  ·  Arms L:%s R:%s  ·  %s" % [Engine.get_frames_per_second(),average(frame_ms),"PAUSED" if paused else "1/5 SPEED" if slow else "LIVE",debris.active.size(),debris.max_physical,debris.rubble.size(),2000-monsters[0].alive_count()-monsters[1].alive_count(),monsters[target_index].last_query_ms,monsters[target_index].last_event_ms,"LOST" if disabled.left_arm else "OK","LOST" if disabled.right_arm else "OK",strike.phase]

func average(values: Array[float]) -> float:
	var sum := 0.0
	for v in values: sum+=v
	return sum/maxi(1,values.size())

func snapshot() -> Dictionary:
	return {"counts":[monsters[0].alive_count(),monsters[1].alive_count()],"destroyed":2000-monsters[0].alive_count()-monsters[1].alive_count(),"physical_debris":debris.active.size(),"peak_debris":debris.peak_active,"active_collision_bodies":debris.active.size()+1,"rubble":debris.rubble.size(),"fps":Engine.get_frames_per_second(),"frame_ms":average(frame_ms),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"render_objects":Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),"physics_active_monitor":Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS),"query_ms":monsters[target_index].last_query_ms,"event_ms":monsters[target_index].last_event_ms,"arms":[monsters[0].structure.disabled,monsters[1].structure.disabled],"last_hit":last_hit}

func sample_performance(seconds: float=3.0) -> Dictionary:
	var samples: Array[float]=[]
	var begin := Time.get_ticks_usec()
	var prior := begin
	var sum_draw := 0.0
	var peak_physical := 0
	while Time.get_ticks_usec()-begin<seconds*1000000:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		samples.append((now-prior)/1000.0)
		prior=now
		sum_draw+=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		peak_physical=maxi(peak_physical,debris.active.size())
	samples.sort()
	var result := snapshot()
	result.mean_ms=average(samples)
	result.p95_ms=samples[int(samples.size()*0.95)]
	result.mean_fps=1000.0/result.mean_ms
	result.mean_draw_calls=sum_draw/samples.size()
	result.sample_frames=samples.size()
	result.sample_seconds=seconds
	result.sample_peak_physical=peak_physical
	return result

# Stress fixture applies real spatial damage volumes; it is not a combat move.
func stress_to_destroyed(goal: int) -> Dictionary:
	strike.cancel()
	var event_times: Array[float]=[]
	var query_times: Array[float]=[]
	var hits := 0
	while 2000-monsters[0].alive_count()-monsters[1].alive_count()<goal and hits<120:
		var m := monsters[hits%2]
		var ids: Array[int]=[]
		for i in m.cubes.size():
			if m.cubes[i].alive: ids.append(i)
		if ids.is_empty(): break
		var id: int=ids[(hits*71)%ids.size()]
		var point := m.to_global(m.cubes[id].pose)
		var hit_result := m.damage(point,2.3,Vector3(4,9,7))
		event_times.append(hit_result.event_ms)
		query_times.append(hit_result.query_ms)
		hits+=1
		await get_tree().physics_frame
	var result := snapshot()
	result.stress_hits=hits
	result.mean_event_ms=average(event_times)
	result.max_event_ms=event_times.max() if not event_times.is_empty() else 0
	result.mean_query_ms=average(query_times)
	return result
