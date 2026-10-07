class_name FlightState
extends RefCounted

# Wing-driven flight for the Flying Dragon. All numbers derive from surviving wing cubes.
var state := "GROUNDED"
var timer := 0.0
var airtime := 0.0
var altitude := 0.0
var cooldown := 0.0
var params := {}
var lift := 1.0
var diving := false

func setup(data: Dictionary) -> void:
	params=data
	state="GROUNDED"
	timer=0
	airtime=0
	altitude=0
	cooldown=data.get("initial_cooldown",3.0)
	lift=1.0
	diving=false

func airborne() -> bool:
	return state=="FLYING" or state=="TAKEOFF"

func wing_lift(body: PixelMonster) -> float:
	var left: float=body.structure.limb_quality("left_wing")
	var right: float=body.structure.limb_quality("right_wing")
	return minf(left,right)*0.55+(left+right)*0.5*0.45

func can_take_off(body: PixelMonster) -> bool:
	return cooldown<=0 and state=="GROUNDED" and wing_lift(body)>=float(params.get("min_lift",0.4)) and not body.held_by

func request_takeoff(body: PixelMonster) -> bool:
	if not can_take_off(body): return false
	state="TAKEOFF"
	timer=0
	airtime=0
	return true

func request_landing() -> void:
	if state=="FLYING" or state=="TAKEOFF":
		state="LANDING"
		timer=0

func flight_budget() -> float:
	return float(params.get("duration",14.0))*lift

func speed_multiplier() -> float:
	return 1.0+float(params.get("air_speed_bonus",0.8))*lift if state in ["FLYING","TAKEOFF","LANDING"] else 1.0

func dive_available(body: PixelMonster) -> bool:
	return state=="FLYING" and lift>=float(params.get("dive_lift",0.6))

func update(dt: float, body: PixelMonster) -> void:
	lift=wing_lift(body)
	cooldown=maxf(0,cooldown-dt)
	var hover: float=float(params.get("hover",8.0))*(0.5+0.5*lift)
	match state:
		"TAKEOFF":
			timer+=dt
			if lift<float(params.get("min_lift",0.4))*0.8:
				state="LANDING"; timer=0
			else:
				altitude=lerpf(altitude,hover,1-exp(-dt*1.6))
				if timer>float(params.get("takeoff_seconds",1.6)): state="FLYING"; timer=0
		"FLYING":
			airtime+=dt
			var target := 0.8 if diving else hover
			altitude=lerpf(altitude,target,1-exp(-dt*(4.0 if diving else 1.8)))
			if airtime>flight_budget() or lift<float(params.get("min_lift",0.4))*0.7:
				state="LANDING"; timer=0
		"LANDING":
			timer+=dt
			altitude=lerpf(altitude,0.0,1-exp(-dt*2.0))
			if altitude<0.15:
				altitude=0.0
				state="GROUNDED"
				cooldown=float(params.get("landing_cooldown",9.0))
				if lift<0.3: cooldown=999.0
				body.stagger=maxf(body.stagger,0.6 if airtime>0 else 0.0)
		_:
			altitude=lerpf(altitude,0.0,1-exp(-dt*4.0))
