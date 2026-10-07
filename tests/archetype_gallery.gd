extends Node3D
# Explicit preloads: no dependence on the editor-generated global class cache.
const CombatMonster = preload("res://scripts/combat/combatant.gd")
const CubeDebris = preload("res://scripts/debris.gd")
const MiniatureArena = preload("res://scripts/arena.gd")

const Archetypes=preload("res://scripts/combat/archetypes.gd")
var monsters := []

func _ready() -> void:
	add_child(MiniatureArena.new())
	var debris := CubeDebris.new()
	add_child(debris)
	for i in 3:
		var body := CombatMonster.new()
		body.archetype=Archetypes.definition(Archetypes.IDS[i])
		body.name=body.archetype.name
		add_child(body)
		body.setup_fighter(Color(.42,.42,.42),debris,Vector3((i-1)*25,0,0),PI)
		for cube in body.cubes: cube.color=Color(.42,.42,.42)
		body.rebuild()
		body.update_pose()
		monsters.append(body)
	var camera := Camera3D.new()
	add_child(camera)
	camera.position=Vector3(0,19,83)
	camera.look_at(Vector3(0,16,0))
	camera.fov=52
	camera.current=true
