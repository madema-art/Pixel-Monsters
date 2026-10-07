extends Node3D

var pool: Array[GPUParticles3D]=[]
var cursor := 0
var enabled := true
var events := 0
var cost_ms := 0.0

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
		gradient.set_color(0,Color(.52,.43,.33,.9))
		gradient.set_color(1,Color(.43,.41,.39,0))
		var texture := GradientTexture1D.new()
		texture.gradient=gradient
		process.color_ramp=texture
		particles.process_material=process
		add_child(particles)
		pool.append(particles)

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
	particles.restart()
	particles.emitting=true
	events+=1
	cost_ms=(Time.get_ticks_usec()-start)/1000.0

func clear() -> void:
	events=0
	for p in pool:
		p.restart()
		p.emitting=false

func _process(_dt: float) -> void:
	for p in pool:
		p.speed_scale=0 if get_tree().paused else Engine.time_scale
