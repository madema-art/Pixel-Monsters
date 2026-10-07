class_name BattleSound
extends Node3D

var pool: Array[AudioStreamPlayer3D]=[]
var cursor := 0
var streams := {}
var enabled := true
var cost_ms := 0.0
var events := 0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed=3703
	for cue in ["punch","hook","kick","head","body","foot","fracture","limb","collapse","stagger","clatter","defeat"]:
		streams[cue]=load("res://audio/cinema/"+cue+".wav")
	for i in 32:
		var player := AudioStreamPlayer3D.new()
		player.max_distance=200
		player.unit_size=24
		player.attenuation_filter_cutoff_hz=8000
		add_child(player)
		pool.append(player)

func layer(at: Vector3, cue: String, volume: float, pitch: float=1.0) -> void:
	if not enabled: return
	var player := pool[cursor]
	cursor=(cursor+1)%pool.size()
	player.position=at
	player.stream=streams[cue]
	# Slow motion retains weight without the extreme pitch shifts of time-scaled audio.
	player.pitch_scale=pitch*rng.randf_range(.94,1.06)*lerpf(.9,1.0,Engine.time_scale)
	player.volume_db=volume+rng.randf_range(-1.1,1.1)
	player.play()
	events+=1

func impact(at: Vector3, power: float, removed: int, move: String="punch", tier: int=0, limb: bool=false, timbre: float=1.0) -> void:
	var start := Time.get_ticks_usec()
	var cue := "hook" if move.contains("hook") else "kick" if move.contains("kick") else "head" if move=="headbutt" else "body" if move.contains("body") else "punch"
	layer(at,cue,-3 if tier==2 else -7 if tier==1 else -11,timbre)
	layer(at,"fracture",-12+minf(removed/20.0,5),1.12 if power<16 else .96)
	if removed>30: layer(at,"clatter",-19)
	if tier==2: layer(at,"body",-15,.82)
	if limb: layer(at,"limb",-9,.90)
	cost_ms=(Time.get_ticks_usec()-start)/1000.0

func footfall(at: Vector3) -> void:
	layer(at,"foot",-22,.92)

func collapse(at: Vector3) -> void:
	layer(at,"collapse",-4)
	layer(at,"clatter",-13,.85)

func stagger(at: Vector3) -> void:
	layer(at,"stagger",-22)

func defeat(at: Vector3) -> void:
	layer(at,"defeat",-11)

func clear() -> void:
	events=0
	for player in pool: player.stop()
