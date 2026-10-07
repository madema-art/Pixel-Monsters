extends Node

const STATES=["opening","early","mid","severe","desperate","aftermath"]
var players: Array[AudioStreamPlayer]=[]
var streams: Array[AudioStream]=[]
var state := -1
var desired := 0
var gains: Array[float]=[0.,0.,0.,0.,0.,0.]
var history: Array[Dictionary]=[]
var last_change := -100.0
var duck := 0.0
var enabled := true
var cost_ms := 0.0
var battle: Node3D
var decision_age := 10.0

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	for cue in STATES:
		var stream: AudioStreamOggVorbis=load("res://audio/cinema/"+cue+".ogg")
		stream.loop=true
		streams.append(stream)
		var player := AudioStreamPlayer.new()
		player.stream=stream
		player.volume_db=-80
		add_child(player)
		players.append(player)

func reset() -> void:
	state=-1
	desired=0
	last_change=-100
	decision_age=10
	history.clear()
	for i in 6:
		players[i].stop()
		gains[i]=0

func impact(tier: int) -> void:
	duck=maxf(duck,0.3 if tier==2 else 0.15)

func _process(dt: float) -> void:
	var started := Time.get_ticks_usec()
	var wall_dt := minf(.1,dt/maxf(.01,Engine.time_scale))
	decision_age+=wall_dt
	if decision_age>=.2:
		decision_age=0
		var damage: float=1.0-float(battle.monsters[0].alive_count()+battle.monsters[1].alive_count())/2000.0
		desired=0 if battle.elapsed<12 else 1 if damage<.18 else 2 if damage<.38 else 3 if damage<.60 else 4
		if damage>.3 and battle.monsters[0].speed_factor()<.3 and battle.monsters[1].speed_factor()<.3: desired=4
		if battle.finished: desired=5 if battle.elapsed-battle.finish_time>2 else maxi(0,state)
		if desired>state and (battle.elapsed-last_change>8 or desired==5):
			state=desired
			last_change=battle.elapsed
			players[state].play()
			history.append({"time":snappedf(battle.elapsed,.1),"state":STATES[state],"damage":damage})
	duck=maxf(0,duck-wall_dt*.45)
	for i in 6:
		var target := 1.0 if i==state and enabled else 0.0
		gains[i]=move_toward(gains[i],target,wall_dt/5.5)
		var volume := linear_to_db(maxf(.0001,gains[i]))-13-duck*8-(7 if battle.paused else 0)
		if absf(players[i].volume_db-volume)>.02: players[i].volume_db=volume
		if gains[i]<=0 and i!=state and players[i].playing: players[i].stop()
	cost_ms=(Time.get_ticks_usec()-started)/1000.0
