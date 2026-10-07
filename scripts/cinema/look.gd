extends RefCounted

# Presentation-only palettes and tone rules. Anatomy and cell data are untouched.
# Each entry: skin (default), limb (arms/legs), joint (shoulders/fists/feet), head, accent,
# interior (exposed material), glow (eyes).
const PALETTES := {
	"gorgeblock": {"skin":"6c4530","limb":"5e3b29","joint":"3b271c","head":"553829","accent":"b07a3e","interior":"2c1812","glow":"ff8a2a"},
	"needlemantle": {"skin":"687f90","limb":"9fb0b6","joint":"2b3944","head":"3e5c76","accent":"c4d2d6","interior":"141e27","glow":"7fe6ff"},
	"bastion": {"skin":"46483d","limb":"3a3c36","joint":"262722","head":"b2a686","accent":"7a705a","interior":"1d1b17","glow":"ff4a2a"},
}
const BODY_SHADER := preload("res://shaders/cube_body.gdshader")

static func make_material(rim: Color=Color("73a0cc"), rim_strength: float=0.55) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader=BODY_SHADER
	material.set_shader_parameter("rim_color",rim)
	material.set_shader_parameter("rim_strength",rim_strength)
	return material

static func part_of(region: String) -> String:
	return region if not (region.begins_with("left_") or region.begins_with("right_")) else region.split("_",true,1)[1]

static func palette_for(id: String, archetype: Dictionary={}) -> Dictionary:
	var source: Dictionary=archetype.get("look",PALETTES.get(id,{}))
	var result := {}
	for key in source:
		if source[key] is String: result[key]=Color(source[key])
	result["tones"]=source.get("tones",{})
	result["face"]=source.get("face",true)
	result["interior_glow"]=float(source.get("interior_glow",0.0))
	return result

# Deterministic low-frequency tonal drift: neighbouring cubes differ slightly, large planes stay coherent.
static func drift(cell: Vector3i) -> float:
	var h := posmod(cell.x*73856093 ^ cell.y*19349663 ^ cell.z*83492791,1000)/1000.0
	var band := sin(cell.y*0.55+cell.x*0.21)*0.5
	return (h-0.5)*0.07+band*0.025

static func cube_color(palette: Dictionary, region: String, cell: Vector3i, head_y: int, tag: String="", authored_face: bool=true) -> Color:
	var part := part_of(region)
	var base: Color=palette.skin
	var tones: Dictionary=palette.get("tones",{})
	if tag=="glow": return palette.glow
	# Optional authored per-cube palette entries, e.g. physical teeth/muzzle cubes.
	if tag!="" and tag not in ["dark","accent"] and palette.get(tag) is Color:
		return palette[tag]
	if tones.has(region) or tones.has(part):
		base=palette[tones.get(region,tones.get(part))]
		var d0 := drift(cell)
		var tinted := base.lightened(maxf(d0,0.0)).darkened(maxf(-d0,0.0))
		return tinted.darkened(.35) if tag=="dark" else tinted.lerp(palette.accent,.5) if tag=="accent" else tinted
	match part:
		"upper_arm","forearm","thigh","shin": base=palette.limb
		"shoulder","fist","foot": base=palette.joint
		"head": base=palette.head
		"abdomen","pelvis": base=palette.skin.darkened(.18)
		"neck": base=palette.joint.lerp(palette.skin,.35)
	if part=="fist" or part=="shoulder":
		# Knuckle / pauldron tops catch an accent so oversized fists and shoulders read in silhouette.
		if region.ends_with("fist") and cell.z<=-1: base=base.lerp(palette.accent,.55)
		elif region.ends_with("shoulder") and cell.y>=roundi(head_y*0.62): base=base.lerp(palette.accent,.35)
	var d := drift(cell)
	var color := base.lightened(maxf(d,0.0)).darkened(maxf(-d,0.0))
	if tag=="dark": return color.darkened(.4)
	if tag=="accent": return color.lerp(palette.accent,.55)
	if part=="head" and authored_face:
		var eye_y := head_y+1
		if cell.z<=-1:
			if cell.y==eye_y and absi(cell.x)==1: return palette.glow
			if cell.y==eye_y+1 and absi(cell.x)<=3: color=color.darkened(.45)   # brow shadow
			elif cell.y==eye_y-2 and absi(cell.x)<=2: color=color.darkened(.55) # mouth slit
			elif cell.y<=eye_y-3: color=color.lightened(.10)
		elif cell.y>=eye_y+2: color=color.darkened(.22)
	return color
