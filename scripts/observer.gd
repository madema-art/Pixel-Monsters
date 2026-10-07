class_name ObserverCamera
extends Camera3D

signal preference_changed(message: String)
const Director = preload("res://scripts/cinema/director.gd")
var director = Director.new()
var director_enabled := true
var velocity := Vector3.ZERO
var yaw := 0.0
var pitch := 0.0
var target_yaw := 0.0
var target_pitch := 0.0
var shake := 0.0
var looking := false
var cruise_speed := 12.0
var target_speed := 12.0
var target_fov := 52.0
@export var shake_intensity := 0.7

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	reset_view()

func reset_view() -> void:
	position=Vector3(8,10,66)
	target_fov=52
	fov=52
	look_at(Vector3(0,14,0))
	yaw=rotation.y
	pitch=rotation.x
	target_yaw=yaw
	target_pitch=pitch
	velocity=Vector3.ZERO
	director.reset()

func free_camera() -> void:
	if director_enabled:
		director_enabled=false
		yaw=rotation.y
		pitch=rotation.x
		target_yaw=yaw
		target_pitch=pitch
		target_fov=fov
		velocity=Vector3.ZERO
		preference_changed.emit("FREE CAMERA · V returns to director")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_V:
			if director_enabled: free_camera()
			else:
				director_enabled=true
				director.initialized=false
				preference_changed.emit("DIRECTOR CAMERA")
		if event.physical_keycode in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_Q,KEY_E,KEY_Z,KEY_X]: free_camera()
		if event.keycode in [KEY_EQUAL,KEY_KP_ADD]:
			target_speed=minf(90,target_speed*1.4)
			preference_changed.emit("CAMERA SPEED  %.1f m/s" % target_speed)
		if event.keycode in [KEY_MINUS,KEY_KP_SUBTRACT]:
			target_speed=maxf(1.5,target_speed/1.4)
			preference_changed.emit("CAMERA SPEED  %.1f m/s" % target_speed)
		if event.keycode==KEY_ESCAPE:
			looking=false
			Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
		if event.keycode==KEY_K:
			shake_intensity=0.0 if shake_intensity>0 else .7
			preference_changed.emit("Camera shake off" if shake_intensity==0 else "Camera shake on")
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT:
		looking=event.pressed
		if looking: free_camera()
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED if looking else Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseMotion and looking:
		target_yaw-=event.relative.x*0.0025
		target_pitch=clampf(target_pitch-event.relative.y*0.0025,-1.5,1.5)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			free_camera()
			target_fov=clampf(target_fov+(-3 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 3),28,80)

func impulse(at: Vector3, magnitude: float) -> void:
	shake=minf(1.0,maxf(shake,magnitude*25/maxf(12,global_position.distance_to(at))))

func _process(_dt: float) -> void:
	var dt := minf(get_process_delta_time()/maxf(Engine.time_scale,0.01),0.05)
	if director_enabled and director.battle!=null:
		director.update(dt,self)
	else:
		var turn := float(Input.is_physical_key_pressed(KEY_Q))-float(Input.is_physical_key_pressed(KEY_E))
		target_yaw+=turn*dt*0.72
		yaw=lerp_angle(yaw,target_yaw,1-exp(-7*dt))
		pitch=lerpf(pitch,target_pitch,1-exp(-7*dt))
		var move := Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),0,float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
		move=Basis(Vector3.UP,yaw)*move
		move.y=float(Input.is_physical_key_pressed(KEY_Z))-float(Input.is_physical_key_pressed(KEY_X) or Input.is_physical_key_pressed(KEY_CTRL))
		cruise_speed=lerpf(cruise_speed,target_speed,1-exp(-4*dt))
		var speed := cruise_speed*3.0 if Input.is_physical_key_pressed(KEY_SHIFT) else cruise_speed
		velocity=velocity.lerp(move.normalized()*speed,1-exp(-3.2*dt))
		position+=velocity*dt
		position.y=maxf(position.y,0.8)
		fov=lerpf(fov,target_fov,1-exp(-5*dt))
		rotation=Vector3(pitch,yaw,0)
	if not get_tree().paused:
		shake=move_toward(shake,0,dt*1.8)
		var t := Time.get_ticks_msec()*0.001
		rotation.x+=(sin(t*24)+sin(t*37)*0.25)*shake*shake_intensity*0.003
		rotation.y+=cos(t*19)*shake*shake_intensity*0.0016
