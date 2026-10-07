class_name ObserverCamera
extends Camera3D

var velocity := Vector3.ZERO
var yaw := 0.0
var pitch := 0.0
var target_yaw := 0.0
var target_pitch := 0.0
var shake := 0.0
var looking := false
var cruise_speed := 12.0

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	reset_view()

func reset_view() -> void:
	position=Vector3(12,12,56)
	look_at(Vector3(0,13,0))
	yaw=rotation.y
	pitch=rotation.x
	target_yaw=yaw
	target_pitch=pitch
	velocity=Vector3.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT:
		looking=event.pressed
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED if looking else Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseMotion and looking:
		target_yaw-=event.relative.x*0.003
		target_pitch=clampf(target_pitch-event.relative.y*0.003,-1.5,1.5)
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		looking=false
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_EQUAL,KEY_KP_ADD]: cruise_speed=minf(80,cruise_speed*1.3)
		if event.keycode in [KEY_MINUS,KEY_KP_SUBTRACT]: cruise_speed=maxf(2,cruise_speed/1.3)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP: fov=clampf(fov-3,30,85)
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN: fov=clampf(fov+3,30,85)

func _process(_dt: float) -> void:
	# Wall-clock delta preserves observer speed while simulation is paused/slowed.
	var dt := minf(get_process_delta_time()/maxf(Engine.time_scale,0.01),0.05)
	var turn := float(Input.is_physical_key_pressed(KEY_Q))-float(Input.is_physical_key_pressed(KEY_E))
	target_yaw+=turn*dt*0.9
	yaw=lerp_angle(yaw,target_yaw,1-exp(-12*dt))
	pitch=lerpf(pitch,target_pitch,1-exp(-12*dt))
	var move := Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),0,float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	move=Basis(Vector3.UP,yaw)*move
	move.y=float(Input.is_physical_key_pressed(KEY_Z))-float(Input.is_physical_key_pressed(KEY_X) or Input.is_physical_key_pressed(KEY_CTRL))
	var speed := cruise_speed*2.9 if Input.is_physical_key_pressed(KEY_SHIFT) else cruise_speed
	velocity=velocity.lerp(move.normalized()*speed,1-exp(-8*dt))
	position+=velocity*dt
	position.y=maxf(position.y,0.6)
	shake=move_toward(shake,0,dt*1.2)
	rotation=Vector3(pitch+sin(Time.get_ticks_msec()*0.071)*shake*0.005,yaw+cos(Time.get_ticks_msec()*0.061)*shake*0.003,0)
