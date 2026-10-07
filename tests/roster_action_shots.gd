extends SceneTree
# Rendered action stills: ranged streams, projectiles, reassembly, swarm climb. Needs a display / software GL.
var battle: Node3D

func _initialize() -> void:
	root.size=Vector2i(900,620)
	battle=load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	call_deferred("run")

func frame_on(point: Vector3, offset: Vector3) -> void:
	var cam: Camera3D=battle.camera
	cam.fov=50
	cam.global_position=point+offset
	cam.look_at(point)

func shoot(name: String, out: String) -> void:
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png(out.path_join(name+".png"))
	print("shot ",name)

func run() -> void:
	var out := OS.get_environment("PM_OUT") if OS.get_environment("PM_OUT")!="" else "user://actions"
	DirAccess.make_dir_recursive_absolute(out)
	battle.set_physics_process(false)
	# 1. fire breath
	battle.restart(5,["fire_reptile","giant_ape"])
	battle.camera.director_enabled=false
	var guard := 0
	while battle.ranged.streams.is_empty() and guard<9000:
		battle.simulate_step(1.0/60.0); guard+=1
	frame_on((battle.monsters[0].global_position+battle.monsters[1].global_position)*0.5+Vector3(0,12,0),Vector3(45,6,0))
	battle.camera.set_process(false)
	for i in 40:
		battle.simulate_step(1.0/60.0)
		await process_frame
	await shoot("fire_breath",out)
	# 2. rocket fist
	battle.restart(6,["giant_robot","stone_colossus"])
	battle.camera.director_enabled=false
	guard=0
	while battle.ranged.shots.is_empty() and guard<9000:
		battle.simulate_step(1.0/60.0); guard+=1
	for i in 14: battle.simulate_step(1.0/60.0)
	frame_on((battle.monsters[0].global_position+battle.monsters[1].global_position)*0.5+Vector3(0,12,0),Vector3(45,6,0))
	battle.camera.set_process(false)
	await shoot("rocket_fist",out)
	# 3. skeleton reassembly
	battle.restart(7,["giant_skeleton","giant_ape"])
	battle.camera.director_enabled=false
	var skel: CombatMonster=battle.monsters[0]
	for i in 400: battle.simulate_step(1.0/60.0)
	skel.damage(skel.region_target("chest"),6.0,Vector3.RIGHT*14)
	skel.damage(skel.region_target("left_thigh"),4.0,Vector3.RIGHT*14)
	for i in 330: battle.simulate_step(1.0/60.0)
	frame_on(skel.global_position+Vector3(0,16,0),Vector3(48,6,-10))
	battle.camera.set_process(false)
	await shoot("skeleton_reassembly",out)
	# 4. army climb
	battle.restart(8,["army_of_ten","giant_robot"])
	battle.camera.director_enabled=false
	for i in 1500: battle.simulate_step(1.0/60.0)
	frame_on(battle.monsters[1].global_position+Vector3(0,12,0),Vector3(40,4,-8))
	battle.camera.set_process(false)
	await shoot("army_climb",out)
	# 5. dragon airborne
	battle.restart(9,["flying_dragon","giant_ape"])
	battle.camera.director_enabled=false
	guard=0
	while battle.monsters[0].flight.state!="FLYING" and guard<9000:
		battle.simulate_step(1.0/60.0); guard+=1
	for i in 60: battle.simulate_step(1.0/60.0)
	frame_on(battle.monsters[0].global_position+Vector3(0,6,0),Vector3(50,3,-6))
	battle.camera.set_process(false)
	await shoot("dragon_flight",out)
	# 6. anaconda constricting
	battle.restart(10,["giant_anaconda","giant_robot"])
	battle.camera.director_enabled=false
	guard=0
	while battle.monsters[0].hold_target==null and guard<12000:
		battle.simulate_step(1.0/60.0); guard+=1
	for i in 60: battle.simulate_step(1.0/60.0)
	frame_on(battle.monsters[1].global_position+Vector3(0,10,0),Vector3(40,4,-10))
	battle.camera.set_process(false)
	await shoot("anaconda_constrict",out)
	battle.queue_free()
	await process_frame
	quit()
