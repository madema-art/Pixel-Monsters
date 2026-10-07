extends Node3D

const Archetypes = preload("res://scripts/combat/archetypes.gd")
var movement := []
var midpoint_min := Vector3.ZERO
var midpoint_max := Vector3.ZERO
var midpoint_path := 0.0
var last_midpoint := Vector3.ZERO

var arena: MiniatureArena
var effects: Node3D
var music: Node
var hud: CanvasLayer
var hud_off := false
var help_visible := false
var notice := ""
var notice_until := 0
var collapse_seen := {}
var tier_counts := [0,0,0]

var monsters: Array[CombatMonster]=[]
var brains: Array[MonsterBrain]=[]
var debris: CubeDebris
var camera: ObserverCamera
var sound: BattleSound
var ranged: RangedManager
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
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)
	arena=MiniatureArena.new()
	add_child(arena)
	effects=preload("res://scripts/cinema/effects.gd").new()
	effects.process_mode=Node.PROCESS_MODE_ALWAYS
	add_child(effects)
	debris=CubeDebris.new()
	debris.name="Debris"
	debris.rubble_seconds=120
	debris.persistent_rubble=true
	debris.process_mode=Node.PROCESS_MODE_PAUSABLE
	add_child(debris)
	sound=BattleSound.new()
	sound.process_mode=Node.PROCESS_MODE_PAUSABLE
	add_child(sound)
	ranged=RangedManager.new()
	ranged.battle=self
	ranged.process_mode=Node.PROCESS_MODE_PAUSABLE
	add_child(ranged)
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
	camera.near=0.2
	add_child(camera)
	camera.current=true
	camera.director.battle=self
	camera.preference_changed.connect(show_notice)
	music=preload("res://scripts/cinema/music.gd").new()
	music.battle=self
	add_child(music)
	build_hud()
	restart()
	var forced: Array=[]
	var matchup_text := OS.get_environment("PIXEL_MONSTERS_MATCHUP")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--matchup="): matchup_text=argument.trim_prefix("--matchup=")
	if matchup_text!="":
		var names := matchup_text.split(",")
		if names.size()==2 and names[0] in Archetypes.IDS and names[1] in Archetypes.IDS: forced=[names[0],names[1]]
	var verify_seed := int(OS.get_environment("PIXEL_MONSTERS_VERIFY_SEED"))
	if not forced.is_empty() or verify_seed!=0: restart(verify_seed,forced)
	print("PIXEL MONSTERS / AUTONOMOUS BATTLE: 1000 + 1000 cubes. Seed ",battle_seed)
	if OS.get_environment("PIXEL_MONSTERS_VERIFY_DIR")!="": add_child(load("res://scripts/combat/runtime_probe.gd").new())

func restart(seed_value: int=0, matchup: Array=[], legacy: bool=false) -> void:
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
	ranged.clear()
	effects.clear()
	sound.clear()
	music.reset()
	camera.director.reset()
	collapse_seen.clear()
	tier_counts=[0,0,0]
	show_notice("V director / free camera · F1 controls · H hide interface")
	var chosen := matchup.duplicate()
	if chosen.is_empty() and not legacy:
		var random := RandomNumberGenerator.new()
		random.seed=battle_seed
		var pool: Array=Archetypes.available_roster()
		if pool.size()<2: pool=Archetypes.IDS
		var count: int=pool.size()
		var first := random.randi_range(0,count-1)
		chosen=[pool[first],pool[(first+random.randi_range(1,count-1))%count]]
	movement.clear()
	for i in 2: monsters[i].name="Combatant_"+str(i)
	for i in 2:
		var fighter: CombatMonster=monsters[i]
		fighter.archetype={} if legacy else Archetypes.definition(chosen[i])
		fighter.name=("TITAN" if i==0 else "COLOSSUS") if legacy else fighter.archetype.name
		fighter.tint=(Color("117982") if i==0 else Color("b34524")) if legacy else Color(fighter.archetype.palette)
		fighter.home=Vector3(-20 if i==0 else 20,0,0) if legacy else Vector3(0,0,-24 if i==0 else 24)
		fighter.spawn_yaw=(-PI/2 if i==0 else PI/2) if legacy else (PI if i==0 else 0.0)
		movement.append({"distance":0.0,"stationary_seconds":0.0,"pursuit_distance":0.0,"retreat_distance":0.0,"lateral_distance":0.0,"zones":[],"max_displacement":0.0})
		fighter.reset_body()
		fighter.reset_motion()
	monsters[0].opponent=monsters[1]
	monsters[1].opponent=monsters[0]
	brains[0].initialize(battle_seed,{"aggression":0.87,"hook":1.7,"kick":0.65,"evade":0.18})
	brains[1].initialize(battle_seed+997,{"aggression":0.78,"hook":0.85,"kick":1.6,"evade":0.28})
	last_midpoint=(monsters[0].position+monsters[1].position)*.5
	midpoint_min=last_midpoint
	midpoint_max=last_midpoint
	midpoint_path=0
	stages["pristine"]=snapshot()

func simulate_step(dt: float) -> void:
	var before := [monsters[0].position,monsters[1].position]
	elapsed+=dt
	tick_index+=1
	for i in 2: brains[i].tick(dt,monsters[i],monsters[1-i],self)
	for fighter in monsters:
		var previous_step := fighter.stepping
		fighter.update_motor(dt)
		fighter.update_hold(dt,self)
		if previous_step!="" and fighter.stepping=="" and not fighter.defeated:
			var other: CombatMonster=monsters[1-monsters.find(fighter)]
			if other.regen!=null: other.regen.shatter_near(fighter.feet[previous_step],2.6)
			sound.footfall(fighter.feet[previous_step])
			effects.burst(fighter.feet[previous_step]+Vector3.UP*.15,0,true)
			camera.impulse(fighter.feet[previous_step],.018)
		if fighter.collapsed and not collapse_seen.has(fighter.name):
			collapse_seen[fighter.name]=true
			sound.collapse(fighter.position)
			effects.burst(fighter.position+Vector3.UP,2)
			camera.impulse(fighter.position,.55)
			if not stages.has("collapse"): stages["collapse"]=snapshot()
	var delta := monsters[1].position-monsters[0].position
	delta.y=0
	var minimum := minf(monsters[0].behavior("min_separation",8.5),monsters[1].behavior("min_separation",8.5))
	if monsters[0].hold_target!=null or monsters[1].hold_target!=null: minimum=minf(minimum,5.0)
	if delta.length()<minimum and not finished:
		var correction := delta.normalized()*(minimum-delta.length())*0.5
		monsters[0].position-=correction
		monsters[1].position+=correction
	for i in 2:
		var traveled: float=Vector2(monsters[i].position.x-before[i].x,monsters[i].position.z-before[i].z).length()
		var stats: Dictionary=movement[i]
		stats.distance+=traveled
		stats.max_displacement=maxf(stats.max_displacement,Vector2(monsters[i].position.x-monsters[i].home.x,monsters[i].position.z-monsters[i].home.z).length())
		if not finished and traveled<.15*dt: stats.stationary_seconds+=dt
		if monsters[i].state=="PURSUING": stats.pursuit_distance+=traveled
		if monsters[i].state in ["BUILD CHARGE","GIVE GROUND","MAINTAINING RANGE"]: stats.retreat_distance+=traveled
		if monsters[i].state=="FLANK": stats.lateral_distance+=traveled
		var zone: String=arena.zone(monsters[i].position)
		if not stats.zones.has(zone): stats.zones.append(zone)
	var middle: Vector3=(monsters[0].position+monsters[1].position)*.5
	midpoint_path+=Vector2(middle.x-last_midpoint.x,middle.z-last_midpoint.z).length()
	last_midpoint=middle
	midpoint_min=midpoint_min.min(middle)
	midpoint_max=midpoint_max.max(middle)
	for i in 2:
		var big: CombatMonster=monsters[i]
		var small: CombatMonster=monsters[1-i]
		if small.regen!=null and tick_index%12==0: small.regen.crush_check(big.position,big.behavior("crush_radius",3.4))
	ranged.step(dt)
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
				sound.defeat(monsters[i].region_target("chest"))
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

func apply_status(source: CombatMonster, victim: CombatMonster, data: Dictionary) -> void:
	for key in data:
		if key=="tether": victim.status.tether=source
		else: victim.status[key]=data[key]

func on_impact(attacker: CombatMonster, victim: CombatMonster, move: String, at: Vector3, report: Dictionary, power: float) -> void:
	attacker.connected_hits+=1
	hits.append({"time":snappedf(elapsed,0.01),"attacker":str(attacker.name),"victim":str(victim.name),"move":move,"region":attacker.attack_motion.region,"direct":report.direct,"detached":report.detached,"remaining":report.remaining,"query_ms":report.query_ms,"event_ms":report.event_ms,"structure_ms":victim.structure_ms})
	var removed: int=report.direct+report.detached
	var tier := 2 if report.detached>45 or removed>85 else 1 if power>=20 or removed>30 else 0
	tier_counts[tier]+=1
	sound.impact(at,power,removed,MonsterMoves.profile(attacker,move).get("base",move),tier,report.detached>45,float(MonsterMoves.profile(attacker,move).get("sound_pitch",1.0)))
	if victim.stagger>0.1: sound.stagger(victim.position)
	var direction: Vector3=(victim.region_target("chest")-attacker.region_target("chest")).normalized()
	effects.burst(at,tier,false,(direction+Vector3.UP*.6).normalized())
	if tier==2: effects.burst(Vector3(at.x,.3,at.z),1)
	music.impact(tier)
	camera.director.notify_impact(at,tier)
	camera.impulse(at,[.06,.18,.36][tier])
	if report.detached>45 and not stages.has("limb_loss"): stages["limb_loss"]=snapshot()
	if removed>85 and not stages.has("large_debris"): stages["large_debris"]=snapshot()
	if move=="headbutt": attacker.head_recoil=0.35

func snapshot() -> Dictionary:
	var bodies: Array[Dictionary]=[]
	for fighter in monsters:
		bodies.append({"name":str(fighter.name),"archetype":fighter.archetype.get("id","legacy"),"position":[fighter.position.x,fighter.position.y,fighter.position.z],"movement":movement[monsters.find(fighter)].duplicate(true),"cubes":fighter.alive_count(),"state":fighter.state,"arms":[fighter.structure.disabled.left_arm,fighter.structure.disabled.right_arm],"legs":[fighter.structure.leg_state("left"),fighter.structure.leg_state("right")],"speed":fighter.speed_factor(),"commands":fighter.commands,"hits":fighter.connected_hits,"generation_ms":fighter.generation_ms,"animation_ms":fighter.animation_ms,"motor_ms":fighter.motor_ms,"structure_ms":fighter.structure_ms,"defeated":fighter.defeated,"reason":fighter.defeat_reason})
	return {"midpoint_path":midpoint_path,"midpoint_span":[midpoint_max.x-midpoint_min.x,midpoint_max.z-midpoint_min.z],"time":snappedf(elapsed,0.1),"seed":battle_seed,"finished":finished,"winner":winner,"fps":Engine.get_frames_per_second(),"frame_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000,"physics_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000,"gpu_ms":RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()),"render_cpu_ms":RenderingServer.viewport_get_measured_render_time_cpu(get_viewport().get_viewport_rid()),"active_debris":debris.active.size(),"rubble":debris.rubble.size(),"collision_bodies":debris.max_physical+1,"debris_script_ms":debris.physics_script_ms,"ai_ms":brains[0].think_ms+brains[1].think_ms,"navigation_ms":brains[0].navigation_ms+brains[1].navigation_ms,"sweep_ms":sweep_ms,"monsters":bodies,"director_ms":camera.director.cost_ms,"shot":camera.director.shot,"director":camera.director_enabled,"coverage":camera.director.coverage(camera.position,camera.position-camera.global_basis.z*30,camera.fov),"vfx_ms":effects.cost_ms,"vfx_events":effects.events,"audio_ms":sound.cost_ms+music.cost_ms,"audio_events":sound.events,"music":music.STATES[maxi(0,music.state)],"impact_tiers":tier_counts.duplicate()}

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
	hud=canvas
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

func show_notice(message: String) -> void:
	notice=message
	notice_until=Time.get_ticks_msec()+4500

func _process(_dt: float) -> void:
	hud.visible=not hud_off
	header.modulate.a=clampf(1.0-(elapsed-3)/3,0,1)
	caption.modulate.a=header.modulate.a
	caption.text=str(monsters[0].name)+"  /  "+str(monsters[1].name)
	if finished:
		caption.text="%s REMAINS · R new fight" % winner
		caption.modulate.a=clampf(1-(elapsed-finish_time-7)/5,0,1)
	controls.text="PAUSED · SPACE resume" if paused else notice if Time.get_ticks_msec()<notice_until else ""
	if help_visible:
		controls.text="WASD fly · Q/E yaw · RMB look · Z/X rise/drop · Shift boost · +/- speed · Wheel lens\nV director · C home · Space pause · L slow motion · R new fight · M music · K shake · H HUD · F1 help · F3 diagnostics"
	metrics.visible=diagnostics
	if diagnostics:
		metrics.text="%.1fs · seed %d · %d FPS · debris %d/%d\n%s %d · %s\n%s %d · %s\nAI %.3fms · rig %.2fms · contact %.2fms\n%s · score %s · TAB target %s · 1/2 arms · 3 leg · 4 core · F hook" % [elapsed,battle_seed,Engine.get_frames_per_second(),debris.active.size(),debris.max_physical,monsters[0].name,monsters[0].alive_count(),monsters[0].state,monsters[1].name,monsters[1].alive_count(),monsters[1].state,brains[0].think_ms+brains[1].think_ms,monsters[0].animation_ms+monsters[1].animation_ms,sweep_ms,camera.director.shot,music.STATES[maxi(0,music.state)],monsters[debug_target].name]

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_SPACE:
			paused=not paused
			get_tree().paused=paused
		KEY_L:
			speed_index=(speed_index+1)%3
			Engine.time_scale=[1.0,0.5,0.25][speed_index]
			show_notice("Time %.2fx" % Engine.time_scale)
		KEY_H: hud_off=not hud_off
		KEY_F1: help_visible=not help_visible
		KEY_M:
			music.enabled=not music.enabled
			show_notice("Music on" if music.enabled else "Music muted")
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
