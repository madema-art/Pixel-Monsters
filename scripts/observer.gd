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
# ---- Gamepad (additive to keyboard/mouse). All tunable in the inspector or from code. ----
@export_range(0.0,0.6) var stick_deadzone := 0.16        # radial deadzone for both sticks
@export_range(0.5,3.0) var stick_response := 1.5          # >1 = finer control near centre
@export var pad_move_scale := 1.0                         # multiplies camera cruise speed for the left stick
@export var pad_yaw_speed := 1.9                          # rad/s at full right-stick deflection
@export var pad_pitch_speed := 1.3                        # rad/s at full right-stick deflection
@export var pad_fast_multiplier := 3.0                    # while observer_fast (left stick click) is held
@export var pad_invert_pitch := false
const PITCH_LIMIT := 1.45

# Radial deadzone with rescaling, so small drift is ignored and the response starts from zero.
func stick_vector(neg_x: String, pos_x: String, neg_y: String, pos_y: String) -> Vector2:
	var raw := Vector2(Input.get_action_raw_strength(pos_x)-Input.get_action_raw_strength(neg_x),Input.get_action_raw_strength(pos_y)-Input.get_action_raw_strength(neg_y))
	var length := raw.length()
	if length<=stick_deadzone: return Vector2.ZERO
	var scaled := clampf((length-stick_deadzone)/(1.0-stick_deadzone),0.0,1.0)
	return raw/length*pow(scaled,stick_response)

func toggle_director() -> void:
	if director_enabled: free_camera()
	else:
		director_enabled=true
		director.initialized=false
		preference_changed.emit("DIRECTOR CAMERA")

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
	if event.is_action_pressed("observer_toggle_director"): toggle_director()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_V: toggle_director()
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
	var pad_move := stick_vector("observer_left","observer_right","observer_forward","observer_back")
	var pad_look := stick_vector("observer_look_left","observer_look_right","observer_look_up","observer_look_down")
	var pad_vertical := Input.get_action_strength("observer_up")-Input.get_action_strength("observer_down")
	# Manual stick input takes over from the director exactly like WASD / RMB do.
	if director_enabled and (pad_move!=Vector2.ZERO or pad_look!=Vector2.ZERO or absf(pad_vertical)>0.5): free_camera()
	if director_enabled and director.battle!=null:
		director.update(dt,self)
	else:
		var turn := float(Input.is_physical_key_pressed(KEY_Q))-float(Input.is_physical_key_pressed(KEY_E))
		target_yaw+=turn*dt*0.72
		target_yaw-=pad_look.x*pad_yaw_speed*dt
		target_pitch=clampf(target_pitch+pad_look.y*(1.0 if pad_invert_pitch else -1.0)*pad_pitch_speed*dt,-PITCH_LIMIT,PITCH_LIMIT)
		yaw=lerp_angle(yaw,target_yaw,1-exp(-7*dt))
		pitch=lerpf(pitch,target_pitch,1-exp(-7*dt))
		var move := Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),0,float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
		move=Basis(Vector3.UP,yaw)*move
		move.y=float(Input.is_physical_key_pressed(KEY_Z))-float(Input.is_physical_key_pressed(KEY_X) or Input.is_physical_key_pressed(KEY_CTRL))
		cruise_speed=lerpf(cruise_speed,target_speed,1-exp(-4*dt))
		var speed := cruise_speed*3.0 if Input.is_physical_key_pressed(KEY_SHIFT) else cruise_speed
		if Input.is_action_pressed("observer_fast"): speed=cruise_speed*pad_fast_multiplier
		# Keys are digital; the left stick adds analog, proportional motion in the same camera-relative frame.
		var key_move := move.normalized()
		var analog := Basis(Vector3.UP,yaw)*Vector3(pad_move.x,0,pad_move.y)*pad_move_scale
		analog.y=pad_vertical
		var combined := key_move+analog
		if combined.length()>1.0 and pad_move_scale<=1.0: combined=combined.normalized()
		velocity=velocity.lerp(combined*speed,1-exp(-3.2*dt))
		position+=velocity*dt
		position.y=maxf(position.y,0.8)
		fov=lerpf(fov,target_fov,1-exp(-5*dt))
		rotation=Vector3(pitch,yaw,0)
	if not get_tree().paused:
		shake=move_toward(shake,0,dt*1.8)
		var t := Time.get_ticks_msec()*0.001
		rotation.x+=(sin(t*24)+sin(t*37)*0.25)*shake*shake_intensity*0.003
		rotation.y+=cos(t*19)*shake*shake_intensity*0.0016
