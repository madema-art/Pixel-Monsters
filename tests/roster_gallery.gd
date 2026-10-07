extends SceneTree
# Rendered contact sheet of all 16 entrants (needs a display / GPU or software GL):
#   godot --path . --script res://tests/roster_gallery.gd   (PM_OUT=/path/dir PM_STEPS=150)
var battle: Node3D
var ids: Array=[]

func _initialize() -> void:
	root.size=Vector2i(900,620)
	battle=load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	call_deferred("run")

func run() -> void:
	var out := OS.get_environment("PM_OUT") if OS.get_environment("PM_OUT")!="" else "user://gallery"
	DirAccess.make_dir_recursive_absolute(out)
	battle.set_physics_process(false)
	var steps := int(OS.get_environment("PM_STEPS")) if OS.get_environment("PM_STEPS")!="" else 120
	ids=OS.get_environment("PM_IDS").split(",") if OS.get_environment("PM_IDS")!="" else Array(preload("res://scripts/combat/archetypes.gd").ROSTER)
	for id in ids:
		battle.restart(7,[id,"stone_colossus" if id!="stone_colossus" else "giant_ape"])
		battle.camera.director_enabled=false
		for i in steps: battle.simulate_step(1.0/60.0)
		var fighter: CombatMonster=battle.monsters[0]
		var focus: Vector3=fighter.global_position+Vector3(0,13,0)
		var cam: Camera3D=battle.camera
		cam.fov=48
		cam.global_position=focus+Vector3(52,6,-18)
		cam.look_at(focus)
		battle.camera.set_process(false)
		for k in 3: await process_frame
		var image := root.get_texture().get_image()
		image.save_png(out.path_join(id+".png"))
		print("shot ",id)
	battle.queue_free()
	await process_frame
	quit()
