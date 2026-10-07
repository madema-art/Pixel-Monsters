@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

class DebrisSink:
	extends Node3D
	var emitted := 0
	func spawn_cube(_p: Vector3,_color: Color,_contact: Vector3,_force: Vector3) -> void:
		emitted+=1

func suite_name() -> String:
	return "destruction"

func make_monster() -> PixelMonster:
	var sink := DebrisSink.new()
	track(sink)
	Engine.get_main_loop().root.add_child(sink)
	var monster := PixelMonster.new()
	track(monster)
	Engine.get_main_loop().root.add_child(monster)
	monster.initialize(Color.CYAN,sink)
	return monster

func test_exact_unique_allocation() -> void:
	var cubes := BodyLayout.generate()
	assert_eq(cubes.size(),1000)
	var cells := {}
	var regions := {}
	for c in cubes:
		assert_false(cells.has(c.cell),"Overlapping body pixels")
		cells[c.cell]=true
		regions[c.region]=regions.get(c.region,0)+1
	for r in BodyLayout.ALLOCATION: assert_eq(regions[r],BodyLayout.ALLOCATION[r],r)

func test_layout_is_connected() -> void:
	var cubes := BodyLayout.generate()
	var cells := {}
	for c in cubes: cells[c.cell]=true
	var queue: Array[Vector3i]=[cubes[0].cell]
	var seen := {cubes[0].cell:true}
	var cursor := 0
	while cursor<queue.size():
		var cell := queue[cursor]
		cursor+=1
		for offset in [Vector3i.LEFT,Vector3i.RIGHT,Vector3i.UP,Vector3i.DOWN,Vector3i.FORWARD,Vector3i.BACK]:
			var next: Vector3i=cell+offset
			if cells.has(next) and not seen.has(next):
				seen[next]=true
				queue.append(next)
	assert_eq(seen.size(),1000,"All intact cubes must connect through face adjacency")

func test_localized_damage_and_persistent_hole() -> void:
	var m := make_monster()
	var contact := m.region_target("chest")+Vector3(0,0,-2.47)
	var before := m.alive_count()
	var report := m.damage(contact,2.4,Vector3.FORWARD*12)
	assert_gt(report.direct,0)
	assert_eq(before-m.alive_count(),report.direct)
	for id in m.last_direct_ids:
		assert_true(m.cubes[id].position.distance_to(m.to_local(contact))<=2.4)
		assert_false(m.cubes[id].alive)
	assert_eq(m.structure.remaining(m.cubes,"left_leg"),120,"Chest hit must not damage distant leg")
	var next := m.damage(contact,2.4,Vector3.ZERO)
	assert_eq(next.direct,0,"Removed cells cannot take damage twice")

func test_sweep_uses_surviving_geometry() -> void:
	var m := make_monster()
	var first := m.sweep(Vector3(0,18,-12),Vector3(0,18,12))
	assert_false(first.is_empty())
	# A narrow tunnel removes only voxels intersecting this center ray.
	for c in m.cubes:
		if c.cell.x==0 and c.cell.y==18: c.alive=false
	var cavity := m.sweep(Vector3(0,18,-12),Vector3(0,18,12))
	assert_true(cavity.is_empty(),"A ray through the permanent hole must miss")

func test_arm_failure_is_local_and_nonfatal() -> void:
	var m := make_monster()
	var contact := m.region_target("left_shoulder")
	var result := m.damage(contact,3.2,Vector3.LEFT*12)
	assert_true(m.structure.disabled.left_arm)
	assert_false(m.structure.disabled.right_arm)
	assert_eq(m.structure.remaining(m.cubes,"left_arm"),0)
	assert_gt(result.detached,0)
	assert_gt(m.alive_count(),600,"Limb loss must leave the rest of the body")
	assert_eq(m.structure.remaining(m.cubes,"right_leg"),120)
	m.reset_body()
	assert_eq(m.alive_count(),1000)
	assert_false(m.structure.disabled.left_arm)

func test_render_count_matches_body() -> void:
	var m := make_monster()
	var count := 0
	for render in m.renders.values(): count+=render.multimesh.instance_count
	assert_eq(count,1000)
	m.damage(m.region_target("head"),2.2,Vector3.ZERO)
	count=0
	for render in m.renders.values(): count+=render.multimesh.instance_count
	assert_eq(count,m.alive_count())
