extends "res://scripts/battle.gd"

var benching := false
var records: Array[Dictionary]=[]
var ticking := 0.0

func _ready() -> void:
	super._ready()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	run_benchmark.call_deferred()

func _physics_process(dt: float) -> void:
	if not benching: super._physics_process(dt)
	ticking+=dt
	if benching and effects.enabled and ticking>.45:
		ticking=0
		effects.burst(Vector3(0,12,0),2)
		effects.burst(Vector3(4,.2,0),1)
		sound.impact(Vector3(0,12,0),24,90,"heavy_hook",2,true)

func run_benchmark() -> void:
	restart(617)
	# Fixed state and composition avoid comparing unrelated camera shots or damage states.
	for i in 5400: simulate_step(1.0/60.0)
	benching=true
	camera.free_camera()
	camera.position=Vector3(-9,13,40)
	camera.look_at(Vector3(0,13,0))
	camera.yaw=camera.rotation.y
	camera.pitch=camera.rotation.x
	camera.target_yaw=camera.yaw
	camera.target_pitch=camera.pitch
	camera.target_fov=50
	for configuration in ["full","no_vfx","no_audio","no_director","no_shadows","no_directional_lights","no_haze"]:
		effects.enabled=configuration!="no_vfx"
		for p in effects.pool: p.visible=effects.enabled
		sound.enabled=configuration!="no_audio"
		music.enabled=configuration!="no_audio"
		music.set_process(configuration!="no_audio")
		if configuration=="no_audio":
			sound.clear()
			for p in music.players: p.stop()
		elif not music.players[maxi(0,music.state)].playing: music.players[maxi(0,music.state)].play()
		arena.sun.shadow_enabled=configuration!="no_shadows"
		arena.sun.visible=configuration!="no_directional_lights"
		arena.rim.visible=configuration!="no_directional_lights"
		arena.environment.fog_enabled=configuration!="no_haze"
		# Run the director calculations on the same fixed camera, restoring it each frame.
		var gpu: Array[float]=[]
		var cpu: Array[float]=[]
		var director_cost: Array[float]=[]
		var frame: Array[float]=[]
		await get_tree().create_timer(3.0).timeout
		var deadline := Time.get_ticks_msec()+4000
		while Time.get_ticks_msec()<deadline:
			if configuration!="no_director":
				var transform_before := camera.transform
				var lens_before := camera.fov
				camera.director.update(0,self.camera)
				director_cost.append(camera.director.cost_ms)
				camera.transform=transform_before
				camera.fov=lens_before
			await RenderingServer.frame_post_draw
			gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()))
			cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(get_viewport().get_viewport_rid()))
			frame.append(get_process_delta_time()*1000)
		gpu.sort();cpu.sort();frame.sort();director_cost.sort()
		records.append({"configuration":configuration,"gpu_median_ms":gpu[gpu.size()/2],"cpu_render_median_ms":cpu[cpu.size()/2],"frame_median_ms":frame[frame.size()/2],"frame_p95_ms":frame[int(frame.size()*.95)],"director_median_ms":0.0 if director_cost.is_empty() else director_cost[director_cost.size()/2],"fps":Engine.get_frames_per_second(),"samples":gpu.size(),"resolution":str(get_viewport().size)})
		FileAccess.open("res://docs/presentation-benchmark.json",FileAccess.WRITE).store_string(JSON.stringify(records,"\t"))
		print("PRESENTATION BENCHMARK ",configuration," ",records[-1])
	get_tree().quit()
