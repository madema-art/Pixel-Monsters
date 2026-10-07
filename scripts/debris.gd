class_name CubeDebris
extends Node3D

@export var max_physical := 192
@export var simulation_seconds := 3.5
@export var rubble_seconds := 28.0
@export var persistent_rubble := false
var pool: Array[RigidBody3D] = []
var active: Array[Dictionary] = []
var rubble: Array[Dictionary] = []
var renderer: MultiMeshInstance3D
var physical_renderer: MultiMeshInstance3D
var born := 0
var peak_active := 0
var material: StandardMaterial3D

func _ready() -> void:
	material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.8
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE*BodyLayout.CUBE_SIZE
	mesh.material = material
	renderer = MultiMeshInstance3D.new()
	renderer.multimesh = MultiMesh.new()
	renderer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	renderer.multimesh.use_colors = true
	renderer.multimesh.mesh = mesh
	add_child(renderer)
	physical_renderer=MultiMeshInstance3D.new()
	physical_renderer.multimesh=MultiMesh.new()
	physical_renderer.multimesh.transform_format=MultiMesh.TRANSFORM_3D
	physical_renderer.multimesh.use_colors=true
	physical_renderer.multimesh.mesh=mesh
	physical_renderer.multimesh.instance_count=max_physical
	physical_renderer.multimesh.visible_instance_count=0
	add_child(physical_renderer)
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	for i in max_physical:
		var body := RigidBody3D.new()
		body.mass = 60.0
		body.gravity_scale = 1.5
		body.linear_damp = 0.18
		body.angular_damp = 0.7
		body.collision_layer = 0
		body.collision_mask = 0
		body.freeze = true
		body.physics_material_override = PhysicsMaterial.new()
		body.physics_material_override.bounce = 0.28
		body.physics_material_override.friction = 0.8
		var collider := CollisionShape3D.new()
		collider.shape = shape
		body.add_child(collider)
		add_child(body)
		body.visible = false
		pool.append(body)

func spawn_cube(p: Vector3, color: Color, contact: Vector3, force: Vector3) -> void:
	if pool.is_empty(): retire(0)
	var body: RigidBody3D = pool.pop_back()
	body.global_transform = Transform3D(Basis.IDENTITY,p)
	body.visible = true
	body.freeze = false
	body.sleeping = false
	body.collision_layer = 2
	body.collision_mask = 1
	var outward := (p-contact).normalized()
	if outward.length_squared()<0.1: outward=Vector3.UP
	body.linear_velocity = force+outward*randf_range(3,9)+Vector3.UP*randf_range(3,8)
	body.angular_velocity = Vector3(randf_range(-8,8),randf_range(-8,8),randf_range(-8,8))
	active.append({"body":body,"age":0.0,"color":color})
	born+=1
	peak_active=maxi(peak_active,active.size())

func retire(index: int) -> void:
	var item: Dictionary = active[index]
	var body: RigidBody3D = item.body
	# Budget overflow/expired simulation retains motion in a cheap ballistic phase.
	rubble.append({"transform":body.global_transform,"color":item.color,"age":0.0,"velocity":body.linear_velocity,"spin":body.angular_velocity,"moving":not body.sleeping})
	body.freeze=true
	body.collision_layer=0
	body.collision_mask=0
	body.visible=false
	pool.append(body)
	active.remove_at(index)

func _physics_process(dt: float) -> void:
	var dirty := false
	for i in range(active.size()-1,-1,-1):
		active[i].age+=dt
		if active[i].age>=simulation_seconds or (active[i].age>0.7 and active[i].body.sleeping):
			retire(i)
			dirty=true
	for i in range(rubble.size()-1,-1,-1):
		rubble[i].age+=dt
		if rubble[i].moving:
			var item: Dictionary=rubble[i]
			item.velocity.y-=14.7*dt
			item.transform.origin+=item.velocity*dt
			var spin: Vector3=item.spin
			if spin.length()>0.01:
				item.transform.basis=Basis(spin.normalized(),spin.length()*dt)*item.transform.basis
			if item.transform.origin.y<=0.52:
				item.transform.origin.y=0.52
				item.velocity.y=absf(item.velocity.y)*0.22
				item.velocity.x*=0.6
				item.velocity.z*=0.6
				item.spin*=0.5
				if item.velocity.length()<1.0 or item.age>6:
					item.moving=false
					item.transform.basis=Basis.IDENTITY
			dirty=true
		if not persistent_rubble and rubble[i].age>rubble_seconds:
			rubble.remove_at(i)
			dirty=true
	if renderer.multimesh.instance_count != rubble.size(): dirty=true
	if dirty:
		var mm := renderer.multimesh
		mm.instance_count=rubble.size()
		for i in rubble.size():
			mm.set_instance_transform(i,rubble[i].transform)
			mm.set_instance_color(i,rubble[i].color)
	var physical_mm := physical_renderer.multimesh
	physical_mm.visible_instance_count=active.size()
	for i in active.size():
		physical_mm.set_instance_transform(i,active[i].body.global_transform)
		physical_mm.set_instance_color(i,active[i].color)

func clear() -> void:
	while not active.is_empty(): retire(0)
	rubble.clear()
	renderer.multimesh.instance_count=0
	physical_renderer.multimesh.visible_instance_count=0
	born=0
	peak_active=0
