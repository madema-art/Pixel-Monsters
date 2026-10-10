extends SceneTree
# Turntable-style review stills for one entrant: front, back, top, 3/4 and low cinematic 3/4.
#   PM_ID=giant_ape PM_OUT=/path godot --path . --script res://tests/creature_stills.gd
const Archetypes = preload("res://scripts/combat/archetypes.gd")
const PixelMonster = preload("res://scripts/monster.gd")
const CombatMonster = preload("res://scripts/combat/combatant.gd")
const ObserverCamera = preload("res://scripts/observer.gd")
var battle: Node3D

func _initialize() -> void:
	root.size=Vector2i(900,700)
	battle=load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	call_deferred("run")

func run() -> void:
	var id := OS.get_environment("PM_ID") if OS.get_environment("PM_ID")!="" else "giant_ape"
	var out := OS.get_environment("PM_OUT") if OS.get_environment("PM_OUT")!="" else "user://stills"
	DirAccess.make_dir_recursive_absolute(out)
	battle.set_physics_process(false)
	battle.restart(7,[id,"fire_reptile" if id!="fire_reptile" else "giant_ape"])
	battle.camera.director_enabled=false
	battle.camera.set_process(false)   # observer would overwrite our framing each frame
	var body: CombatMonster=battle.monsters[0]
	battle.monsters[1].position=Vector3(400,0,400)
	battle.debris.visible=false
	battle.hud.visible=false
	for child in battle.arena.get_children():
		if child is MultiMeshInstance3D: child.visible=false   # keep lights and environment, hide city
	body.home=Vector3.ZERO
	body.spawn_yaw=0.0
	body.reset_motion()
	body.position=Vector3.ZERO
	body.rotation=Vector3.ZERO
	body.update_pose()
	var views := {
		"front":[Vector3(0,0,-1),0.0],
		"back":[Vector3(0,0,1),0.0],
		"side":[Vector3(1,0,0),0.0],
		"three_quarter":[Vector3(0.7,0.25,-0.7).normalized(),0.0],
		"top":[Vector3(0,1,0),0.0],
		"low_cinematic":[Vector3(0.55,0.12,-0.85).normalized(),0.0],
	}
	var top := -INF
	var bottom := INF
	for c in body.cubes:
		top=maxf(top,c.position.y)
		bottom=minf(bottom,c.position.y)
	var centre := Vector3(0,(top+bottom)*0.5,0)
	var frame_height := top-bottom
	for key in views:
		var dir: Vector3=views[key][0]
		var distance := frame_height*1.9 if key!="low_cinematic" else frame_height*1.8
		var cam: Camera3D=battle.camera
		cam.fov=36
		cam.global_position=centre+dir*distance+Vector3(0,0,0)
		cam.look_at(centre)
		for i in 3: await process_frame
		root.get_texture().get_image().save_png(out.path_join(id+"_"+key+".png"))
		print("still ",key)
	battle.queue_free()
	await process_frame
	quit()
