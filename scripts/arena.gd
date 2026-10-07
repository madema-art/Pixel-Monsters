class_name MiniatureArena
extends Node3D

var batches := {}

func box(p: Vector3, size: Vector3, color: Color, emissive: bool=false) -> void:
	var key := color.to_html()+str(emissive)
	if not batches.has(key): batches[key]={"color":color,"emissive":emissive,"transforms":[]}
	batches[key].transforms.append(Transform3D(Basis.from_scale(size),p))

func render_batches() -> void:
	for entry in batches.values():
		var node := MultiMeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size=Vector3.ONE
		var mat := StandardMaterial3D.new()
		mat.albedo_color=entry.color
		mat.roughness=0.9
		if entry.emissive:
			mat.emission_enabled=true
			mat.emission=entry.color
			mat.emission_energy_multiplier=1.8
		mesh.material=mat
		node.multimesh=MultiMesh.new()
		node.multimesh.transform_format=MultiMesh.TRANSFORM_3D
		node.multimesh.mesh=mesh
		node.multimesh.instance_count=entry.transforms.size()
		for i in entry.transforms.size(): node.multimesh.set_instance_transform(i,entry.transforms[i])
		add_child(node)

func _ready() -> void:
	box(Vector3(0,-0.3,0),Vector3(240,0.6,240),Color("384248"))
	var ground := StaticBody3D.new()
	ground.collision_layer=1
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size=Vector3(240,0.6,240)
	collision.shape=shape
	ground.position.y=-0.3
	ground.add_child(collision)
	add_child(ground)
	box(Vector3(0,0.015,0),Vector3(24,0.03,160),Color("242b30"))
	box(Vector3(0,0.035,16),Vector3(160,0.03,8),Color("242b30"))
	for side in [-1,1]:
		box(Vector3(side*15.5,0.10,0),Vector3(3,0.2,150),Color("687074"))
		box(Vector3(side*17.1,0.18,32),Vector3(0.3,0.36,85),Color("959487"))
		box(Vector3(side*19,0.7,25),Vector3(0.8,1.4,0.65),Color("52636b"))
		box(Vector3(side*17.5,1.5,21),Vector3(0.08,3,0.08),Color("7b8586"))
		box(Vector3(side*17.5,2.6,21),Vector3(0.7,0.7,0.08),Color("9f4d35"))
	for z in range(-75,80,6):
		box(Vector3(0,0.04,z),Vector3(0.15,0.02,2),Color("b4ada0"))
	for s in [-1,1]:
		for z in range(-64,65,16):
			var x: float=s*18.0
			box(Vector3(x,2,z),Vector3(0.12,4,0.12),Color("788489"))
			box(Vector3(x-s*0.65,3.9,z),Vector3(1.5,0.1,0.1),Color("788489"))
			box(Vector3(x-s*1.2,3.8,z),Vector3(0.5,0.12,0.25),Color("ffd29d"),true)
		for j in 9:
			var x: float=s*(28+(j%3)*14)
			var z: float=-58+floor(j/3.0)*36
			var h: float=3+(j*5)%7
			box(Vector3(x,h/2,z),Vector3(9,h,12),Color("536068").darkened(j*0.015))
			box(Vector3(x,h+0.2,z),Vector3(9.4,0.4,12.4),Color("3c484e"))
			for floor_id in int(h/1.5):
				for w in 4:
					box(Vector3(x-3+w*2,1+floor_id*1.5,z+6.03),Vector3(0.6,0.6,0.04),Color("b0a78b").darkened(0.3))
	for i in 12:
		var x: float=-85+i*16
		var h: float=8+(i*13)%18
		box(Vector3(x,h/2,-92),Vector3(12,h,12),Color("45535c"))
	for i in 7:
		var p := Vector3(14 if i%2 else -14,0.6,27+i*5)
		box(p,Vector3(1.5,1.0,3.2),Color("9d8e77") if i%2 else Color("637c89"))
		box(p+Vector3(0,0.7,-0.15),Vector3(1.25,0.6,1.7),Color("334551"))
	for x in [-21,21]:
		for z in range(-10,17,4):
			box(Vector3(x,0.5,z),Vector3(1,1,2.6),Color("969891"))
	render_batches()
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode=Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color=Color("192c42")
	sky_mat.sky_horizon_color=Color("a29e90")
	sky_mat.ground_bottom_color=Color("28343c")
	sky_mat.ground_horizon_color=Color("a29e90")
	sky.sky_material=sky_mat
	env.sky=sky
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("8ab0ce")
	env.ambient_light_energy=0.3
	env.tonemap_mode=Environment.TONE_MAPPER_ACES
	env.fog_enabled=true
	env.fog_light_color=Color("87949e")
	env.fog_density=0.0013
	env.fog_sky_affect=0.15
	world.environment=env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-32,-38,0)
	sun.light_color=Color("ffe0b1")
	sun.light_energy=1.1
	sun.shadow_enabled=true
	sun.directional_shadow_max_distance=170
	add_child(sun)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees=Vector3(-25,135,0)
	rim.light_color=Color("76a9c6")
	rim.light_energy=0.5
	add_child(rim)
