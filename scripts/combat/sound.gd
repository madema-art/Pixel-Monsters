class_name BattleSound
extends Node3D

var pool: Array[AudioStreamPlayer3D]=[]
var cursor := 0
var boom = preload("res://audio/impact.wav")
var crack = preload("res://audio/fracture.wav")

func _ready() -> void:
	for i in 16:
		var player := AudioStreamPlayer3D.new()
		player.max_distance=180
		player.unit_size=35
		add_child(player)
		pool.append(player)

func layer(at: Vector3, stream: AudioStream, pitch: float, volume: float) -> void:
	var player := pool[cursor]
	cursor=(cursor+1)%pool.size()
	player.position=at
	player.stream=stream
	player.pitch_scale=pitch
	player.volume_db=volume
	player.play()

func impact(at: Vector3, power: float, removed: int) -> void:
	layer(at,boom,0.75 if power>=20 else 1.0 if power>=16 else 1.15,-3 if power>=20 else -7)
	layer(at,crack,randf_range(0.82,1.13),-10+minf(removed/8.0,5))
	if power>=20:
		await get_tree().create_timer(0.14).timeout
		layer(at,boom,0.53,-16)

func footfall(at: Vector3) -> void:
	layer(at,boom,0.55,-26)
