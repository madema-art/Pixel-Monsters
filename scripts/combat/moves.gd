class_name MonsterMoves
extends RefCounted

# Commands are shared by autonomous controllers and any future human controller.
const MOVES := {
	"left_punch":{"limb":"left_arm","wind":0.70,"commit":0.38,"follow":0.32,"recover":1.10,"range":10.6,"radius":1.65,"force":12.0,"collider":1.15,"label":"LEFT PUNCH"},
	"right_punch":{"limb":"right_arm","wind":0.76,"commit":0.40,"follow":0.34,"recover":1.15,"range":10.6,"radius":1.70,"force":13.0,"collider":1.15,"label":"RIGHT PUNCH"},
	"heavy_hook":{"limb":"arm","wind":1.12,"commit":0.48,"follow":0.45,"recover":1.50,"range":10.8,"radius":2.45,"force":21.0,"collider":1.25,"label":"HEAVY HOOK"},
	"kick":{"limb":"leg","wind":0.95,"commit":0.46,"follow":0.32,"recover":1.45,"range":10.9,"radius":2.05,"force":17.0,"collider":1.25,"label":"KICK"},
	"headbutt":{"limb":"head","wind":0.78,"commit":0.44,"follow":0.34,"recover":1.30,"range":9.3,"radius":1.95,"force":17.0,"collider":1.65,"label":"HEADBUTT"},
	"body_charge":{"limb":"torso","wind":1.00,"commit":0.70,"follow":0.45,"recover":1.65,"range":11.2,"radius":2.55,"force":22.0,"collider":2.2,"label":"BODY DRIVE"},
	# Roster families: "custom" attacks name their own rig effector and anatomy requirements ("needs").
	"custom":{"limb":"custom","wind":0.95,"commit":0.45,"follow":0.34,"recover":1.35,"range":10.5,"radius":2.0,"force":16.0,"collider":1.3,"label":"STRIKE"},
	"ranged":{"limb":"ranged","wind":1.6,"commit":0.5,"follow":0.3,"recover":1.8,"range":30.0,"radius":2.0,"force":16.0,"collider":1.0,"label":"RANGED"}
}

static func profile(body: PixelMonster, move: String) -> Dictionary:
	if not body.archetype.is_empty() and body.archetype.attacks.has(move):
		var custom: Dictionary=body.archetype.attacks[move]
		var data: Dictionary=MOVES[custom.base].duplicate()
		data.merge(custom,true)
		return data
	return MOVES.get(move,{})

static func needs_met(body: PixelMonster, prof: Dictionary) -> bool:
	for key in prof.get("needs",{}):
		if body.structure.fraction(key)<float(prof.needs[key]) or body.structure.disabled.get(key,false): return false
	if prof.get("both_arms",false) and body.structure.has_biped and not (functional_arm(body,"left") and functional_arm(body,"right")): return false
	var mode: String=prof.get("flight","")
	if mode!="" and body.flight!=null:
		if mode=="air" and not body.flight.airborne(): return false
		if mode=="ground" and body.flight.state!="GROUNDED": return false
	return true

static func available(body: PixelMonster, move: String, ignore_cooldown: bool=false) -> bool:
	if profile(body,move).is_empty(): return false
	if not ignore_cooldown and body.move_cd.get(move,0.0)>0.0: return false
	if not ignore_cooldown and profile(body,move).get("requires_free",false) and (body.held_by!=null or body.hold_target!=null): return false
	if (body.reassembling and not ignore_cooldown) or not needs_met(body,profile(body,move)): return false
	var limb: String=profile(body,move).get("limb","")
	if limb=="custom" or limb=="ranged": return true
	if limb=="arm": return functional_arm(body,"left") or functional_arm(body,"right")
	if limb=="leg": return body.structure.leg_quality("left")>0.45 or body.structure.leg_quality("right")>0.45
	if limb=="head": return body.structure.material("head")>body.structure.threshold("head",.25,30) and body.structure.material("neck")>body.structure.threshold("neck",.17,4)
	if limb=="torso": return body.structure.material("torso")>body.structure.threshold("torso",.277,104)
	return functional_arm(body,"left" if limb=="left_arm" else "right")

static func functional_arm(body: PixelMonster, side: String) -> bool:
	if body.fist_away.get(side,0.0)>0.0: return false
	return not body.structure.disabled.get(side+"_arm",false) and body.structure.material(side+"_fist")>body.structure.threshold(side+"_fist",.15,3) and body.structure.material(side+"_forearm")>body.structure.threshold(side+"_forearm",.17,6) and body.structure.material(side+"_upper_arm")>body.structure.threshold(side+"_upper_arm",.1875,6)

static func side_for(body: PixelMonster, move: String, rng: RandomNumberGenerator) -> String:
	var base: String=profile(body,move).get("base",move)
	if base=="left_punch": return "left"
	if base=="right_punch": return "right"
	if base=="heavy_hook":
		if not functional_arm(body,"right"): return "left"
		if not functional_arm(body,"left"): return "right"
		return "left" if rng.randf()<0.5 else "right"
	if base=="kick":
		return "left" if body.structure.leg_quality("left")>=body.structure.leg_quality("right") else "right"
	return ""
