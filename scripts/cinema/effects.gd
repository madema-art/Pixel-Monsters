extends Node3D

var pool: Array[GPUParticles3D]=[]
var cursor := 0
var enabled := true
var events := 0
var cost_ms := 0.0
var chips: Array[GPUParticles3D]=[]
var chip_cursor := 0
var flashes: Array[OmniLight3D]=[]
var flash_levels: Array[float]=[]
var flash_cursor := 0
const DUST_TONES := [Color(.50,.43,.35),Color(.42,.37,.32),Color(.30,.27,.25)]
const FLASH_ENERGY := [2.5,6.0,14.0]

func _ready() -> void:
	var shader := Shader.new()
	shader.code="""shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;
void vertex() {
 MODELVIEW_MATRIX=mat4(vec4(length(MODEL_MATRIX[0].xyz),0.0,0.0,0.0),vec4(0.0,length(MODEL_MATRIX[1].xyz),0.0,0.0),vec4(0.0,0.0,length(MODEL_MATRIX[2].xyz),0.0),VIEW_MATRIX*MODEL_MATRIX[3]);
}
void fragment() {
 float r=length(UV-vec2(0.5))*2.0;
 float softness=pow(max(0.0,1.0-r*r),2.0);
 ALBEDO=COLOR.rgb;
 ALPHA=softness*COLOR.a*0.22;
}
"""
	for i in 16:
		var particles := GPUParticles3D.new()
		particles.emitting=false
		particles.one_shot=true
		particles.amount=32
		particles.lifetime=1.4
		particles.explosiveness=1
		particles.visibility_aabb=AABB(Vector3(-18,-4,-18),Vector3(36,36,36))
		var quad := QuadMesh.new()
		quad.size=Vector2(1,1)
		var material := ShaderMaterial.new()
		material.shader=shader
		# Particle billboard orientation is handled by the process material.
		quad.material=material
		particles.draw_pass_1=quad
		var process := ParticleProcessMaterial.new()
		process.particle_flag_disable_z=false
		process.particle_flag_rotate_y=true
		process.direction=Vector3.UP
		process.spread=85
		process.gravity=Vector3(0,-1.5,0)
		process.initial_velocity_min=2
		process.initial_velocity_max=5
		process.scale_min=.6
		process.scale_max=1.8
		process.damping_min=1
		process.damping_max=2
		var gradient := Gradient.new()
		gradient.set_color(0,Color(1,1,1,.9))
		gradient.set_color(1,Color(.82,.84,.88,0))
		var texture := GradientTexture1D.new()
		texture.gradient=gradient
		process.color_ramp=texture
		particles.process_material=process
		add_child(particles)
		pool.append(particles)
	# Heavy masonry chips: tiny dark tumbling cubes thrown with directional bias on heavy and devastating hits.
	var chip_shader := Shader.new()
	chip_shader.code="""shader_type spatial;
render_mode unshaded;
void fragment() { ALBEDO=COLOR.rgb*vec3(0.55,0.52,0.5); }
"""
	var chip_mesh := BoxMesh.new()
	chip_mesh.size=Vector3.ONE*.34
	var chip_material := ShaderMaterial.new()
	chip_material.shader=chip_shader
	chip_mesh.material=chip_material
	for i in 6:
		var chip := GPUParticles3D.new()
		chip.emitting=false
		chip.one_shot=true
		chip.amount=18
		chip.lifetime=1.5
		chip.explosiveness=1
		chip.visibility_aabb=AABB(Vector3(-22,-4,-22),Vector3(44,30,44))
		chip.draw_pass_1=chip_mesh
		var chip_process := ParticleProcessMaterial.new()
		chip_process.direction=Vector3.UP
		chip_process.spread=55
		chip_process.gravity=Vector3(0,-12,0)
		chip_process.initial_velocity_min=5
		chip_process.initial_velocity_max=11
		chip_process.angular_velocity_min=-240
		chip_process.angular_velocity_max=240
		chip_process.scale_min=.5
		chip_process.scale_max=1.3
		chip_process.color=Color(.55,.5,.45)
		chip.process_material=chip_process
		add_child(chip)
		chips.append(chip)
	# Brief warm impact flashes light the street and nearby cube faces, then decay.
	for i in 3:
		var flash := OmniLight3D.new()
		flash.light_color=Color("ffb070")
		flash.omni_range=34
		flash.light_energy=0
		flash.shadow_enabled=false
		flash.visible=false
		add_child(flash)
		flashes.append(flash)
		flash_levels.append(0.0)

func burst(at: Vector3, tier: int, floor_event: bool=false, direction: Vector3=Vector3.UP) -> void:
	if not enabled: return
	var start := Time.get_ticks_usec()
	var particles := pool[cursor]
	cursor=(cursor+1)%pool.size()
	particles.position=at
	particles.amount=12 if floor_event else [18,36,64][tier]
	particles.lifetime=1.0 if floor_event else [0.8,1.3,1.8][tier]
	var material: ParticleProcessMaterial=particles.process_material
	material.direction=direction
	material.initial_velocity_min=1.2 if floor_event else 2.0+tier
	material.initial_velocity_max=2.5 if floor_event else 5.0+tier*2
	material.scale_min=.4 if floor_event else .5+tier*.2
	material.scale_max=1.2 if floor_event else 1.5+tier*.7
	material.color=DUST_TONES[0] if floor_event else DUST_TONES[tier]
	material.damping_min=1.0 if tier<2 else 1.6
	material.damping_max=2.0 if tier<2 else 2.8
	particles.restart()
	particles.emitting=true
	if not floor_event and tier>=1:
		var chip := chips[chip_cursor]
		chip_cursor=(chip_cursor+1)%chips.size()
		chip.position=at
		chip.amount=14 if tier==1 else 26
		var chip_material: ParticleProcessMaterial=chip.process_material
		chip_material.direction=direction
		chip.restart()
		chip.emitting=true
	if not floor_event:
		var slot := flash_cursor
		flash_cursor=(flash_cursor+1)%flashes.size()
		flashes[slot].global_position=at+Vector3.UP*1.5
		flash_levels[slot]=FLASH_ENERGY[tier]
		flashes[slot].visible=true
	events+=1
	cost_ms=(Time.get_ticks_usec()-start)/1000.0

func clear() -> void:
	events=0
	for p in pool:
		p.restart()
		p.emitting=false
	for c in chips:
		c.restart()
		c.emitting=false
	for i in flashes.size():
		flash_levels[i]=0.0
		flashes[i].visible=false

func _process(dt: float) -> void:
	for i in flashes.size():
		if flash_levels[i]>0.0:
			flash_levels[i]=maxf(0.0,flash_levels[i]-flash_levels[i]*9.0*dt-0.2*dt)
			flashes[i].light_energy=flash_levels[i]
			if flash_levels[i]<=0.05:
				flash_levels[i]=0.0
				flashes[i].visible=false
	for p in pool:
		p.speed_scale=0 if get_tree().paused else Engine.time_scale
	for c in chips:
		c.speed_scale=0 if get_tree().paused else Engine.time_scale
