class_name RigSerpent
extends RefCounted
# Explicit preloads: no dependence on the editor-generated global class cache.
const MonsterAttack = preload("res://scripts/combat/attack_motion.gd")

# True serpentine locomotion: the head leads and every segment follows the recorded trail with a
# slithering wave. Each segment is its own rigid group (and structure limb); no legs, no hidden biped.
var effectors := {}
var data: Dictionary = {}
var segments: Array=[]
var rest_center := []
var distance := []
var trail: Array[Vector3]=[]
var phase := 0.0
var positions: Array[Vector3]=[]
var ready := false
var raise_current := 0.0

func reset(body: Node3D) -> void:
	data=body.archetype.get("rig_serpent",{})
	segments=data.segments
	rest_center.clear()
	distance.clear()
	var sums := {}
	var counts := {}
	for c in body.cubes:
		sums[c.region]=sums.get(c.region,Vector3.ZERO)+c.position
		counts[c.region]=counts.get(c.region,0)+1
	for region in segments: rest_center.append(sums[region]/counts[region])
	for i in segments.size(): distance.append(absf(rest_center[i].z-rest_center[0].z))
	var head_world: Vector3=body.to_global(Vector3(0,float(data.get("head_height",5.0)),0))
	var back := body.global_basis.z
	trail.clear()
	for k in 140: trail.append(Vector3(head_world.x,0.0,head_world.z)+back*float(k)*0.5)
	positions.clear()
	for i in segments.size(): positions.append(head_world)
	raise_current=float(data.get("raise",3.0))
	phase=0.0
	ready=true

func path_point(arc: float) -> Vector3:
	var walked := 0.0
	for i in range(trail.size()-1):
		var seg := trail[i].distance_to(trail[i+1])
		if walked+seg>=arc:
			return trail[i].lerp(trail[i+1],(arc-walked)/maxf(seg,0.001))
		walked+=seg
	return trail[trail.size()-1]

func apply(body: Node3D) -> void:
	var started := Time.get_ticks_usec()
	if not ready: reset(body)
	var attack: MonsterAttack=body.attack_motion
	var head_ground := Vector3(body.global_position.x,0.0,body.global_position.z)
	if trail[0].distance_to(head_ground)>0.5: trail.push_front(head_ground)
	while trail.size()>260: trail.pop_back()
	var speed: float=body.velocity.length()
	phase+=0.016*(2.0+speed*1.8)
	var n := segments.size()
	var raise_target := float(data.get("raise",3.0))
	if attack.running and attack.profile.get("effector","")=="head": raise_target+=2.0*maxf(0.0,attack.reach)
	raise_current=lerpf(raise_current,raise_target,0.08)
	positions.clear()
	for i in n:
		var arc: float=distance[i]*float(data.get("stretch",1.0))
		var p := path_point(arc)
		if arc<0.01: p=head_ground
		var tangent_a := path_point(arc+1.0)-path_point(maxf(0.0,arc-1.0))
		tangent_a.y=0
		var side := Vector3(tangent_a.z,0,-tangent_a.x).normalized() if tangent_a.length()>0.01 else Vector3.RIGHT
		var wave_amp := float(data.get("wave",1.1))*clampf(speed*0.6+0.35,0.35,1.3)*smoothstep(0.0,0.35,float(i)/maxf(1.0,n-1))
		p+=side*sin(phase-float(i)*0.85)*wave_amp
		# Neck rears up; the rest of the body lies along the ground.
		var rear := raise_current*exp(-float(i)*float(data.get("rear_falloff",0.55)))
		p.y=body.global_position.y+rest_center[i].y+rear
		positions.append(p)
	# Attack and constriction goals pull groups of segments toward world points.
	var held: Node3D=body.hold_target
	if held!=null:
		var center := held.global_position
		var wraps: Array=data.get("wrap_segments",[2,3,4,5,6,7,8,9])
		for k in wraps.size():
			var idx: int=wraps[k]
			if idx>=n: continue
			var theta := float(k)*0.95+phase*0.4
			var ring := Vector3(cos(theta)*4.2,2.0+float(k)*1.6,sin(theta)*4.2)
			positions[idx]=positions[idx].lerp(center+ring,0.88)
	elif attack.running:
		var key: String=attack.profile.get("effector","")
		var goal: Vector3=attack.endpoint
		var strength := clampf(attack.reach+0.15,0.0,1.0)
		if key=="head":
			for i in range(0,6):
				var w := pow(1.0-float(i)/6.0,1.6)
				positions[i]=positions[i].lerp(goal,w*strength*(1.0 if i==0 else 0.8))
		elif key=="body_mid":
			var center_i: int=int(data.get("mid_index",6))
			for i in range(maxi(1,center_i-4),mini(n,center_i+5)):
				var w2 := cos(float(i-center_i)/4.5*PI*0.5)
				positions[i]=positions[i].lerp(Vector3(goal.x,positions[i].y,goal.z),clampf(w2,0.0,1.0)*strength*0.85)
		elif key=="tail_tip":
			for i in range(maxi(1,n-5),n):
				var w3 := float(i-(n-6))/5.0
				positions[i]=positions[i].lerp(Vector3(goal.x,positions[i].y,goal.z),w3*strength*0.9)
	body.pose_transforms.clear()
	var origin_t: Transform3D=body.global_transform
	for i in n:
		var prev: Vector3=positions[maxi(0,i-1)]
		var next: Vector3=positions[mini(n-1,i+1)]
		var direction: Vector3=prev-next if i>0 else (positions[0]-positions[1])
		if direction.length()<0.01: direction=-body.global_basis.z
		var basis_world := Basis.looking_at(direction.normalized(),Vector3.UP)
		var local_pos: Vector3=origin_t.affine_inverse()*positions[i]
		var local_basis: Basis=body.global_basis.inverse()*basis_world
		body.pose_transforms[segments[i]]=Transform3D(local_basis,local_pos-local_basis*rest_center[i])
	for region in body.renders:
		if not body.pose_transforms.has(region): body.pose_transforms[region]=Transform3D.IDENTITY
	var head_dir: Vector3=(positions[0]-positions[1]).normalized()
	effectors.head=positions[0]+head_dir*float(data.get("mouth",2.6))
	effectors.torso=positions[mini(3,n-1)]
	effectors.body_mid=positions[int(data.get("mid_index",6))]
	effectors.tail_tip=positions[n-1]
	body.sync_pose()
	body.animation_ms=(Time.get_ticks_usec()-started)/1000.0
