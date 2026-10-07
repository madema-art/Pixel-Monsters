class_name MiniatureArena
extends Node3D

var batches := {}
var occluders: Array[AABB]=[]
var environment: Environment
var sun: DirectionalLight3D
var rim: DirectionalLight3D
var fill: DirectionalLight3D
const SET_SHADER := preload("res://shaders/arena_set.gdshader")

func zone(p: Vector3) -> String:
	if p.z<-38: return "WAREHOUSE GATES"
	if p.z<-12: return "INDUSTRIAL AVENUE"
	if p.z<18: return "CENTRAL INTERSECTION"
	if p.z<46: return "CIVIC PLAZA"
	return "WATERFRONT APPROACH"

func box(p: Vector3, size: Vector3, color: Color, emissive: bool=false) -> void:
	var key := color.to_html()+str(emissive)
	if not batches.has(key): batches[key]={"color":color,"emissive":emissive,"transforms":[]}
	batches[key].transforms.append(Transform3D(Basis.from_scale(size),p))

func render_batches() -> void:
	for entry in batches.values():
		var node := MultiMeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size=Vector3.ONE
		var mat := ShaderMaterial.new()
		mat.shader=SET_SHADER
		mat.set_shader_parameter("base_color",entry.color)
		mat.set_shader_parameter("emissive",1.0 if entry.emissive else 0.0)
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
	box(Vector3(0,0.015,0),Vector3(40,0.03,160),Color("242b30"))
	box(Vector3(0,0.035,16),Vector3(160,0.03,20),Color("242b30"))
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
			var x: float=s*25.0
			box(Vector3(x,2,z),Vector3(0.12,4,0.12),Color("788489"))
			box(Vector3(x-s*0.65,3.9,z),Vector3(1.5,0.1,0.1),Color("788489"))
			box(Vector3(x-s*1.2,3.8,z),Vector3(0.5,0.12,0.25),Color("ffd29d"),true)
		for j in 9:
			var x: float=s*(38+(j%3)*14)
			var z: float=-58+floor(j/3.0)*36
			var h: float=3+(j*5)%7
			occluders.append(AABB(Vector3(x-4.7,0,z-6.2),Vector3(9.4,h+.4,12.4)))
			box(Vector3(x,h/2,z),Vector3(9,h,12),Color("536068").darkened(j*0.015))
			box(Vector3(x,h+0.2,z),Vector3(9.4,0.4,12.4),Color("3c484e"))
			for floor_id in int(h/1.5):
				for w in 4:
					box(Vector3(x-3+w*2,1+floor_id*1.5,z+6.03),Vector3(0.6,0.6,0.04),Color("caa16c") if (w+j+floor_id)%3==0 else Color("344854"),(w+j+floor_id)%3==0)
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
	# Open civic plaza and warehouse apron connect to the avenue.
	box(Vector3(0,.03,34),Vector3(48,.04,26),Color("4d5558"))
	box(Vector3(0,.03,-52),Vector3(46,.04,24),Color("3e494d"))
	for side in [-1,1]:
		box(Vector3(side*30,6,42),Vector3(2,12,2),Color("8c8a79"))
		box(Vector3(side*30,12.4,42),Vector3(4,.8,4),Color("b7a583"))
		box(Vector3(side*32,10,-57),Vector3(1,20,1),Color("747f82"))
		box(Vector3(side*32-5,19,-57),Vector3(12,.8,.8),Color("747f82"))
	scale_details()
	city_dressing()
	render_batches()
	build_atmosphere()

func build_atmosphere() -> void:
	# Smooth, cheap anti-aliasing and large shadow detail so cube edges and long shadows stay crisp.
	get_viewport().msaa_3d=Viewport.MSAA_4X
	RenderingServer.directional_shadow_atlas_set_size(4096,true)
	var world := WorldEnvironment.new()
	var env := Environment.new()
	environment=env
	env.background_mode=Environment.BG_SKY
	var sky := Sky.new()
	var clouds := ShaderMaterial.new()
	clouds.shader=preload("res://shaders/dusk_sky.gdshader")
	sky.sky_material=clouds
	env.sky=sky
	# Cool sky fill; warm key and cold rim supply the drama, so ambient stays modest but never black.
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("6f8fb4")
	env.ambient_light_energy=0.34
	env.tonemap_mode=Environment.TONE_MAPPER_ACES
	env.tonemap_exposure=1.0
	env.tonemap_white=6.0
	env.adjustment_enabled=true
	env.adjustment_contrast=1.08
	env.adjustment_saturation=0.94
	env.fog_enabled=true
	env.fog_light_color=Color("7d8aa0")
	env.fog_density=0.0030
	env.fog_sky_affect=0.28
	env.fog_aerial_perspective=0.35
	env.fog_sun_scatter=0.18
	env.fog_height=5.0
	env.fog_height_density=0.016
	env.ssao_enabled=true
	env.ssao_radius=2.4
	env.ssao_intensity=2.0
	env.ssao_power=1.6
	env.ssao_detail=0.6
	env.glow_enabled=true
	env.glow_intensity=0.55
	env.glow_bloom=0.04
	env.glow_hdr_threshold=1.15
	env.glow_hdr_scale=1.6
	world.environment=env
	add_child(world)
	# Key: low warm sun with long, softened shadows.
	sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-17,-48,0)
	sun.light_color=Color("ffc88f")
	sun.light_energy=1.9
	sun.light_angular_distance=1.1
	sun.shadow_enabled=true
	sun.shadow_blur=1.6
	sun.shadow_normal_bias=1.2
	sun.directional_shadow_max_distance=190
	sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	add_child(sun)
	# Rim: cold back light from the opposite side separates silhouettes from the haze.
	rim=DirectionalLight3D.new()
	rim.rotation_degrees=Vector3(-24,138,0)
	rim.light_color=Color("7fb2d6")
	rim.light_energy=1.0
	rim.light_specular=0.8
	add_child(rim)
	# Fill: weak overhead bounce lifts shadowed face planes without flattening them.
	fill=DirectionalLight3D.new()
	fill.rotation_degrees=Vector3(-70,20,0)
	fill.light_color=Color("8da5c4")
	fill.light_energy=0.18
	fill.light_specular=0.0
	add_child(fill)

func scale_details() -> void:
	# Metre-scale street furniture and rooftop silhouettes communicate giant scale.
	for i in 12:
		var x: float=-85+i*16
		var h: float=8+(i*13)%18
		for y in range(2,int(h),2):
			for w in 5:
				box(Vector3(x-4+w*2,y,-85.97),Vector3(.55,.8,.04),Color("b49b78") if (i+w+y)%5==0 else Color("3b4c5e"),(i+w+y)%5==0)
		box(Vector3(x,h+.25,-92),Vector3(12.4,.5,12.4),Color("36414d"))
		box(Vector3(x+2,h+1,-92),Vector3(2,2,3),Color("475463"))
	for side in [-1,1]:
		for j in 9:
			var x: float=side*(28+(j%3)*14)
			var z: float=-58+floor(j/3.0)*36
			var h: float=3+(j*5)%7
			for w in 5: box(Vector3(x-4+w*2,h*.5,z+6.07),Vector3(.10,h,.08),Color("727675"))
			box(Vector3(x,h+.8,z-2),Vector3(2,1.2,2),Color("647174"))
			box(Vector3(x+2,h+.5,z+1),Vector3(1,.8,1.5),Color("424e56"))
			box(Vector3(x,h*.5,z+6.10),Vector3(9,.15,.12),Color("868071"))
			box(Vector3(x,h-.3,z+6.1),Vector3(9,.15,.12),Color("868071"))
	for side in [-1,1]:
		for z in [34,53,72]:
			var x: float=side*20.0
			box(Vector3(x,3.0,z),Vector3(.16,6,.16),Color("4d555a"))
			for y in [3.5,4.7]:
				box(Vector3(x,y,z),Vector3(.8,.09,.09),Color("343d45"))
			box(Vector3(x,5.9,z),Vector3(1.5,.13,.12),Color("4d555a"))
			# Sparse telephone wires, safely outside the fight lane.
			if z<72: box(Vector3(x,5.5,z+9.5),Vector3(.035,.035,19),Color("333c45"))
		for z in range(27,68,8):
			box(Vector3(side*22,1,z),Vector3(.08,2,.08),Color("687479"))
		for y in [.6,1.3,1.9]:
			box(Vector3(side*22,y,47),Vector3(.05,.05,48),Color("687479"))
		box(Vector3(side*14,.9,64),Vector3(2,1.8,7),Color("8e7451"))
		for z in [61.6,62.8,64,65.2,66.4]:
			box(Vector3(side*15.02,1.45,z),Vector3(.03,.5,.65),Color("314555"))
		for x in [side*28,side*56]:
			for z in [-58,14]:
				box(Vector3(x,11,z),Vector3(.25,5,.25),Color("6a7172"))
				box(Vector3(x,13.6,z),Vector3(3,1.8,3),Color("67574a"))
				box(Vector3(x,14.55,z),Vector3(3.3,.15,3.3),Color("393f44"))
				for k in [-1,1]: box(Vector3(x+k,10,z+1),Vector3(.12,5,.12),Color("4b565b"))
	for x in range(-5,6,2): box(Vector3(x,.05,33),Vector3(1,.02,3),Color("a6a18c"))
	for side in [-1,1]:
		box(Vector3(side*18,1.4,35),Vector3(.1,2.8,.1),Color("586a72"))
		box(Vector3(side*18,2.4,35),Vector3(1,.55,.08),Color("4e7a70"))
		box(Vector3(side*19,.55,40),Vector3(2,.15,.5),Color("7a6650"))
		for z in [39.8,40.2]: box(Vector3(side*19,.3,z),Vector3(1.8,.6,.09),Color("4a5358"))

const CAR_COLORS := ["8f3b32","3d5a74","b9b09a","46504b","a4772f","6a6f73","2f3a46","7d5a68"]

func car(p: Vector3, along_z: bool, color: Color) -> void:
	var length := Vector3(1.3,0.55,2.7) if along_z else Vector3(2.7,0.55,1.3)
	box(p+Vector3(0,0.42,0),length,color)
	box(p+Vector3(0,0.88,0),Vector3(1.1,0.4,1.5) if along_z else Vector3(1.5,0.4,1.1),Color("1f2a33"))
	var tip := Vector3(0,0.5,1.36) if along_z else Vector3(1.36,0.5,0)
	var lamp := Vector3(1.0,0.14,0.05) if along_z else Vector3(0.05,0.14,1.0)
	box(p+tip,lamp,Color("ffe3b0"),true)
	box(p-tip,lamp,Color("c8342b"),true)

func bus(p: Vector3, color: Color) -> void:
	box(p+Vector3(0,1.0,0),Vector3(1.8,1.7,6.8),color)
	box(p+Vector3(0,1.3,0),Vector3(1.84,0.55,6.2),Color("1f2a33"))
	box(p+Vector3(0,0.08,0),Vector3(1.9,0.2,6.9),Color("222a30"))
	box(p+Vector3(0,1.55,3.41),Vector3(1.4,0.3,0.04),Color("ffd9a0"),true)

func shipping_container(p: Vector3, color: Color) -> void:
	box(p,Vector3(2.4,1.25,6.0),color)
	for k in [-2.4,-1.2,0.0,1.2,2.4]: box(p+Vector3(0,0,k),Vector3(2.46,1.2,0.07),color.darkened(0.22))

func lit_tower(x: float, z: float, w: float, d: float, h: float, tone: Color, seed_id: int, facing: int) -> void:
	box(Vector3(x,h/2,z),Vector3(w,h,d),tone)
	box(Vector3(x,h+0.25,z),Vector3(w+0.4,0.5,d+0.4),tone.darkened(0.3))
	var face_z := z+facing*(d/2+0.03)
	for y in range(2,int(h)-1,2):
		for k in int(w/2.0):
			var lit := (seed_id+k*7+y*3)%5==0
			box(Vector3(x-w/2+1.0+k*2.0,y,face_z),Vector3(0.6,0.8,0.04),Color("d8aa6c") if lit else Color("2b3b4b"),lit)
	if seed_id%3==0:
		box(Vector3(x+w*0.2,h+2.0,z),Vector3(0.18,3.2,0.18),Color("9b3d32"))
		box(Vector3(x+w*0.2,h+3.7,z),Vector3(0.4,0.4,0.4),Color("ff4a3a"),true)

func city_dressing() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed=4217
	# Side buildings: setback crowns, rooftop plant, lit shopfronts, awnings and vertical signs.
	for side in [-1,1]:
		for j in 9:
			var x: float=side*(38+(j%3)*14)
			var z: float=-58+floor(j/3.0)*36
			var h: float=3+(j*5)%7
			var tier := 1.4+(j%3)*0.8
			box(Vector3(x,h+0.4+tier/2,z+0.8),Vector3(6.6,tier,8.4),Color("46535a"))
			box(Vector3(x+2,h+0.4+tier+0.5,z),Vector3(1.8,1.0,1.8),Color("5b666b"))
			box(Vector3(x-2.2,h+0.4+tier+0.35,z+1.5),Vector3(1.2,0.7,2.4),Color("3a454b"))
			box(Vector3(x,0.95,z+6.04),Vector3(8.2,1.0,0.05),Color("e0a864") if (j+int(side))%2==0 else Color("8cc4c4"),true)
			box(Vector3(x,1.75,z+6.35),Vector3(8.4,0.14,1.0),Color("6e2f2a") if j%2==0 else Color("2f5a52"))
			if j%3==0:
				box(Vector3(x+side*4.9,h*0.62+1,z+6.3),Vector3(0.45,2.6,0.25),Color("ff5c47") if side<0 else Color("5ce0d0"),true)
			occluders.append(AABB(Vector3(x-3.3,h+0.4,z-3.4),Vector3(6.6,tier,8.4)))
	# Street furniture along the lane edges: parked cars, buses and crosswalks outside the fight corridor.
	for i in 12:
		var z_car := -72.0+i*6.1+rng.randf_range(-0.8,0.8)
		if absf(z_car-16.0)<12.0: continue
		var side_car := -1 if i%2==0 else 1
		car(Vector3(side_car*19.4,0.1,z_car),true,Color(CAR_COLORS[(i*3+1)%CAR_COLORS.size()]))
	bus(Vector3(-19.2,0.1,-46),Color("c79a43"))
	bus(Vector3(19.2,0.1,8),Color("5d7f8a"))
	for z in [4.0,30.0,-24.0]:
		for k in range(-9,10):
			box(Vector3(k*1.7,0.07,z),Vector3(0.9,0.02,2.6),Color("cfc9b6"))
	# Traffic signals at the central intersection.
	for s in [-1,1]:
		for corner_z in [4.0,28.0]:
			var tx: float=s*17.8
			box(Vector3(tx,2.3,corner_z),Vector3(0.14,4.6,0.14),Color("565e63"))
			box(Vector3(tx-s*1.2,4.5,corner_z),Vector3(2.4,0.1,0.1),Color("565e63"))
			box(Vector3(tx-s*2.4,4.15,corner_z),Vector3(0.3,0.9,0.28),Color("22292e"))
			box(Vector3(tx-s*2.4,4.4,corner_z),Vector3(0.18,0.18,0.3),Color("e84a3a") if corner_z<10 else Color("4be07a"),true)
	# Warehouse apron: stacked containers, tanks, smokestacks with hazard lights.
	for k in 4:
		for side in [-1,1]:
			var cz := -44.0-k*8.0
			shipping_container(Vector3(side*27,0.65,cz),Color(["8a4a2e","3b6a70","a8832f","58626a"][(k+int(side*0.5+1))%4]))
			if k%2==0: shipping_container(Vector3(side*27,1.95,cz),Color(["58626a","8a4a2e","3b6a70","a8832f"][k%4]))
	for side in [-1,1]:
		box(Vector3(side*34,4.0,-72),Vector3(6,8,6),Color("707a7d"))
		box(Vector3(side*34,8.3,-72),Vector3(6.6,0.6,6.6),Color("4a5459"))
		box(Vector3(side*62,16,-70),Vector3(3,32,3),Color("8a8d8a"))
		for y in [8.0,17.0,26.0]: box(Vector3(side*62,y,-70),Vector3(3.2,2.4,3.2),Color("a8392f"))
		box(Vector3(side*62,32.6,-70),Vector3(1.2,1.2,1.2),Color("ff4a3a"),true)
	# Skyline ring: far towers on three sides, repeated shapes at modest cost.
	for i in 14:
		var z_far := -80.0+i*13.0
		var h_far := 12.0+float((i*7)%5)*5.0
		lit_tower(-108+rng.randf_range(-3,3),z_far,12,11,h_far,Color("3d4953").darkened(0.02*(i%4)),i,1)
		lit_tower(108+rng.randf_range(-3,3),z_far,12,11,h_far+4,Color("3b4650").darkened(0.02*(i%4)),i+3,1)
	for i in 10:
		var x_far := -92.0+i*20.0
		lit_tower(x_far,104,16,10,7.0+float((i*5)%4)*2.0,Color("414c55"),i+5,-1)
	for x in [-40,12,60]:
		box(Vector3(x,16,98),Vector3(1.2,32,1.2),Color("a8542f"))
		box(Vector3(x+9,31,98),Vector3(24,1.0,1.0),Color("a8542f"))
		box(Vector3(x+19,25,98),Vector3(0.1,12,0.1),Color("2b3238"))
		box(Vector3(x-2.8,31.5,98),Vector3(0.5,0.5,0.5),Color("ff4a3a"),true)
	# Water: dark reflective strip beyond the waterfront approach.
	box(Vector3(0,0.06,118),Vector3(240,0.05,16),Color("1d2a38"))
