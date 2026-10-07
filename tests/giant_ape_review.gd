extends RefCounted
const Moves=preload("res://scripts/combat/moves.gd")

# Visual fixture runs on the actual main-game actors through Godot MCP.
# Reset each stage so screenshots never substitute a damaged proxy for the roster body.
static func stage(b: Node3D, label: String) -> Dictionary:
	b.restart(101,["giant_ape","stone_colossus"])
	b.set_physics_process(false)
	b.elapsed=4
	b.camera.director_enabled=false
	b.camera.set_process(false)
	var ape=b.monsters[0]
	var other=b.monsters[1]
	other.show()
	ape.home=Vector3.ZERO
	ape.spawn_yaw=0
	ape.reset_motion()
	ape.lean=-.04
	ape.bob=0
	ape.sway=0
	other.home=Vector3(0,0,-17)
	other.spawn_yaw=PI
	other.reset_motion()
	if label in ["walk","turn","pursuit"]:
		ape.desired_velocity=Vector3(1.4,0,-2.3)
		ape.facing_target=.85 if label=="turn" else 0.0
		for i in 90:
			ape.update_motor(1.0/60)
			ape.update_pose()
	elif label in ["hammer_fist","ape_hook","two_hand_smash","grab_throw","leap_attack"]:
		if label=="grab_throw": other.position=Vector3(0,0,-10)
		ape.attack_motion.begin(ape,other,label,"chest","right")
		var seconds: float=ape.attack_motion.profile.wind+ape.attack_motion.profile.commit*.65
		for i in int(seconds*60):
			ape.attack_motion.update(1.0/60,ape)
			ape.update_motor(1.0/60)
			ape.update_pose()
			ape.attack_motion.resolve(ape,b)
	elif label=="throw":
		other.position=Vector3(0,0,-9)
		var hold: Dictionary=ape.archetype.attacks.grab_throw.hold
		ape.begin_hold(other,ape.archetype.attacks.grab_throw,"grab_throw","right")
		for i in 160: ape.update_hold(1.0/60,b)
	elif label=="damage":
		ape.update_pose()
		for point in [Vector3(0,15,-3),Vector3(2,18,-6),Vector3(-7,16,-1),Vector3(10,3,-5),Vector3(2,15,3)]:
			ape.damage(ape.to_global(point),1.7,Vector3(0,0,6))
	ape.update_pose()
	if label in ["idle","walk","turn","pursuit","damage"]: other.hide()
	b.camera.position=ape.position+Vector3(29,22,-44)
	b.camera.look_at(ape.position+Vector3(0,10,0))
	return {"stage":label,"alive":ape.alive_count(),"held":ape.hold_target!=null,"hop":ape.hop_offset,"hand_left":str(ape.rig.effectors.left_arm),"hand_right":str(ape.rig.effectors.right_arm),"target_knock":str(other.knock_velocity)}
