class_name MeleeStrike
extends Node3D
# Explicit preloads: no dependence on the editor-generated global class cache.
const ObserverCamera = preload("res://scripts/observer.gd")
const PixelMonster = preload("res://scripts/monster.gd")

signal connected(result: Dictionary)
var attacker: PixelMonster
var victim: PixelMonster
var observer: ObserverCamera
var running := false
var phase := "READY"
var age := 0.0
var start := Vector3.ZERO
var aim := Vector3.ZERO
var previous := Vector3.ZERO
var hit := false
var radius := 2.6
var hand := Vector3.ZERO
var attack_origin := Vector3.ZERO
var windup := Vector3.ZERO
var approach := Vector3.ZERO
var audio: AudioStreamPlayer3D
var fracture: AudioStreamPlayer3D

func _ready() -> void:
	audio=AudioStreamPlayer3D.new()
	audio.stream=load("res://audio/impact.wav")
	audio.unit_size=60
	audio.max_distance=250
	audio.volume_db=-2
	add_child(audio)
	fracture=AudioStreamPlayer3D.new()
	fracture.stream=load("res://audio/fracture.wav")
	fracture.unit_size=50
	fracture.volume_db=-7
	add_child(fracture)

func trigger(source: PixelMonster, target: PixelMonster, region: String, power: float=2.6) -> bool:
	if running or source.structure.disabled.right_arm: return false
	attacker=source
	victim=target
	radius=power
	attack_origin=attacker.position
	start=attacker.region_target("right_fist")
	var goal := victim.region_target(region)
	var local_normal := Vector3(0,0,-1)
	if region.begins_with("left_"): local_normal=Vector3.LEFT
	if region.begins_with("right_"): local_normal=Vector3.RIGHT
	approach=-(victim.global_basis*local_normal).normalized()
	windup=goal-approach*7.0
	# Aim may be behind the near surface. The subsequent sweep determines contact.
	aim=goal
	previous=start
	age=0
	hit=false
	running=true
	phase="WIND-UP"
	return true

func cancel() -> void:
	if is_instance_valid(attacker):
		attacker.position=attack_origin
		attacker.clear_pose()
	running=false
	phase="READY"

func _physics_process(dt: float) -> void:
	if not running: return
	age+=dt
	var direction := approach
	if age<0.65:
		phase="WIND-UP"
		hand=start.lerp(windup,smoothstep(0,0.65,age))
	elif age<1.03:
		phase="COMMIT"
		var t := smoothstep(0.65,1.03,age)
		hand=windup.lerp(aim+direction*2,t)
	elif age<1.4:
		phase="FOLLOW-THROUGH"
		hand=aim+direction*2
	else:
		phase="RECOVER"
		var t := smoothstep(1.4,2.5,age)
		hand=(aim+direction*2).lerp(start,t)
	# Move the rooted test rig into reach; the arm itself has fixed bone lengths.
	var shoulder_home := attacker.global_basis*Vector3(5,19.5,0)+attack_origin
	attacker.crouch=clampf(shoulder_home.y-hand.y-6,0,5)
	var difference := hand-(shoulder_home-Vector3.UP*attacker.crouch)
	var horizontal := Vector3(difference.x,0,difference.z)
	var horizontal_reach := sqrt(maxf(1,7.8*7.8-difference.y*difference.y))
	var step := maxf(0,horizontal.length()-horizontal_reach)
	var desired_step := horizontal.normalized()*minf(step,8)
	attacker.position=attack_origin+desired_step
	hand=attacker.pose_arm(hand,1.0)
	if age>=0.65 and age<1.03 and not hit:
		var contact := victim.sweep(previous,hand,0.9)
		if not contact.is_empty():
			hit=true
			var result := victim.damage(contact.point,radius,direction*17)
			result["contact"]=contact.point
			result["region"]=victim.cubes[contact.id].region
			global_position=contact.point
			audio.pitch_scale=randf_range(0.88,1.03)
			audio.play()
			fracture.play()
			observer.shake=1.0
			connected.emit(result)
	previous=hand
	if age>=2.5: cancel()
