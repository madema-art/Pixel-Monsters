class_name RigSwarm
extends RefCounted

var effectors := {}

func reset(_body: Node3D) -> void:
	pass

func apply(body: Node3D) -> void:
	var started := Time.get_ticks_usec()
	var swarm: SwarmUnits=body.swarm
	body.pose_transforms.clear()
	for region in body.renders: body.pose_transforms[region]=Transform3D.IDENTITY
	if swarm==null:
		body.sync_pose()
		return
	var hip := Vector3(0,5.0,0)
	var shoulder := Vector3(0,8.0,0)
	for u in swarm.units:
		if not u.alive: continue
		var local_pos: Vector3=body.to_local(u.pos)
		var pitch: float=u.climb*1.1
		var basis_unit := Basis(Vector3.UP,u.yaw-body.rotation.y)*Basis(Vector3.RIGHT,-pitch)
		var rest: Vector3=u.rest
		var unit_t := Transform3D(basis_unit,local_pos)*Transform3D(Basis.IDENTITY,-Vector3(rest.x,0.0,rest.z))
		var stride: float=sin(u.phase)*(0.7 if u.state!="CELEBRATE" else 0.2)
		var legs_basis := Basis(Vector3.RIGHT,stride)
		var arm_swing: float=sin(u.phase+PI)*0.6-u.striking*2.6
		var arms_basis := Basis(Vector3.RIGHT,arm_swing)
		var rest_hip := Vector3(rest.x,hip.y,rest.z)
		var rest_shoulder := Vector3(rest.x,shoulder.y,rest.z)
		var bob := Transform3D(Basis.IDENTITY,Vector3(0,absf(sin(u.phase))*0.25,0))
		body.pose_transforms["u%d_body" % u.id]=bob*unit_t
		body.pose_transforms["u%d_legs" % u.id]=bob*unit_t*Transform3D(legs_basis,rest_hip-legs_basis*rest_hip)
		body.pose_transforms["u%d_arms" % u.id]=bob*unit_t*Transform3D(arms_basis,rest_shoulder-arms_basis*rest_shoulder)
	effectors.head=body.global_position+Vector3.UP*10
	effectors.torso=body.global_position+Vector3.UP*6
	body.sync_pose()
	body.animation_ms=(Time.get_ticks_usec()-started)/1000.0
