class_name Boid extends CharacterBody3D

@export var mass = 1
@export var force = Vector3.ZERO
@export var acceleration = Vector3.ZERO
@export var vel = Vector3.ZERO
@export var speed:float
@export var max_speed: float = 10.0

var behaviors = [] 
@export var max_force = 10
@export var banking = 0.1
@export var damping = 0.1

@export var draw_gizmos = true
@export var pause = false
@export var combat_collision_cooldown: float = 0.35

var count_neighbors = false
var neighbors = [] 

var school = null
var new_force = Vector3.ZERO
var should_calculate = false
var _combat_collision_cooldowns: Dictionary = {}

func draw_gizmos_recursive(dg):
	draw_gizmos = dg
	var children = get_children()
	for child in children:
		if child is SteeringBehavior:
			child.draw_gizmos = dg


func count_neighbors_partitioned():
	neighbors.clear()

	# var cells_around = 1
	var my_cell = school.position_to_cell(transform.origin)
		
	if draw_gizmos:
		var a = school.cell_to_position(my_cell)
		var b = a + Vector3(school.cell_size, school.cell_size, school.cell_size)
		DebugDraw3D.draw_aabb_ab(a, b, Color.CYAN)
						
	# Check center cell first!
	for slice in [0, -1, 1]:
		for row in [0, -1, 1]:
			for col in [0, -1, 1]:
				var pos = global_transform.origin + Vector3(col * school.cell_size, row * school.cell_size, slice * school.cell_size)
				var key = school.position_to_cell(pos)
				
				if draw_gizmos:
					var a = school.cell_to_position(key)
					var b = a + Vector3(school.cell_size, school.cell_size, school.cell_size)
					DebugDraw3D.draw_aabb_ab(a, b, Color.CYAN)
				
				if school.cells.has(key):
					var cell = school.cells[key]
					# print(key)
					for boid in cell:
						if draw_gizmos:
							if boid != self:
								DebugDraw3D.draw_box(boid.global_transform.origin, Quaternion.IDENTITY,  Vector3(3, 3, 3), Color.DARK_GOLDENROD, true)
						if boid != self and boid.global_transform.origin.distance_to(global_transform.origin) < school.neighbor_distance:
							neighbors.push_back(boid)
							if neighbors.size() == school.max_neighbors:
								return neighbors.size()					
	return neighbors.size()
	
func count_neighbors_simple():
	neighbors.clear()
	for i in school.boids.size():
		var boid = school.boids[i]
		if boid != self and global_transform.origin.distance_to(boid.global_transform.origin) < school.neighbor_distance:
			neighbors.push_back(boid)
			if neighbors.size() == school.max_neighbors:
				break
	return neighbors.size()

func _input(event):
	if event is InputEventKey and event.keycode == KEY_P and event.pressed:
		pause = ! pause
		
func set_enabled(behavior, enabled):
	behavior.enabled = enabled
	behavior.set_process(enabled)

static var line_thickness:float = 0.0001

func on_draw_gizmos():

	var len =  10
	DebugDraw3D.draw_arrow(global_transform.origin,  global_transform.origin + transform.basis.z * len , Color(0, 0, 1), line_thickness, line_thickness)
	DebugDraw3D.draw_arrow(global_transform.origin,  global_transform.origin + transform.basis.x * len , Color(1, 0, 0), line_thickness, line_thickness)
	DebugDraw3D.draw_arrow(global_transform.origin,  global_transform.origin + transform.basis.y * len , Color(0, 1, 0), line_thickness, line_thickness)
	DebugDraw3D.draw_arrow(global_transform.origin,  global_transform.origin + force, Color(1, 1, 0), 0.1)
	
	if school and count_neighbors:
		DebugDraw3D.draw_sphere(global_transform.origin, school.neighbor_distance, Color.WEB_PURPLE)
		for neighbor in neighbors:
			DebugDraw3D.draw_sphere(neighbor.global_transform.origin, 3, Color.WEB_PURPLE)
			
func seek_force(target: Vector3):	
	var toTarget = target - global_transform.origin
	toTarget = toTarget.normalized()
	var desired = toTarget * max_speed
	return desired - vel
	
func arrive_force(target:Vector3, slowingDistance:float):
	var toTarget = target - global_transform.origin
	var dist = toTarget.length()
	
	if dist < 2:
		return Vector3.ZERO
	
	var ramped = (dist / slowingDistance) * max_speed
	var limit_length = min(max_speed, ramped)
	var desired = (toTarget * limit_length) / dist 
	return desired - vel

# Called when the node enters the scene tree for the first time.
func _ready():
	# Check for a variable
	if "partition" in get_parent():
		school = get_parent()
	
	for i in get_child_count():
		var child = get_child(i)
		if child.has_method("calculate"):
			behaviors.push_back(child)
			child.set_process(child.enabled) 
	# enable_all(false)
	
func set_enabled_all(enabled):
	for i in behaviors.size():
		behaviors[i].enabled = enabled
		
func update_weights(weights):
	for behavior in weights:
		var b = get_node(behavior)
		if b: 
			b.weight = weights[behavior]

func calculate():
	var force_acc = Vector3.ZERO	
	var behaviors_active = ""
	for i in behaviors.size():
		if behaviors[i].enabled:
			var f = behaviors[i].calculate() * behaviors[i].weight
			if is_nan(f.x) or is_nan(f.y) or is_nan(f.z):
				print(str(behaviors[i]) + " is NAN")
				f = Vector3.ZERO
			behaviors_active += behaviors[i].name + ": " + str(round(f.length())) + " "
			force_acc += f 
			if force_acc.length() > max_force:
				force_acc = force_acc.limit_length(max_force)
				behaviors_active += " Limiting force"
				break
	if draw_gizmos:
		DebugDraw2D.set_text(name, behaviors_active)
	return force_acc


func _process(delta):
	if draw_gizmos:
		on_draw_gizmos()
	if school and count_neighbors:
		if school.partition:
			count_neighbors_partitioned()
		else:
			count_neighbors_simple()
			
func _physics_process(delta):
	# pause = true
	# lerp in the new forces
	new_force = calculate()
	force = lerp(force, new_force, delta)
	_update_combat_collision_cooldowns(delta)
	if ! pause:
		acceleration = force / mass
		vel += acceleration * delta
		speed = vel.length()
		if speed > 0:
			if max_speed == 0:
				print("max_speed is 0")
			vel = vel.limit_length(max_speed)
			
			# Damping
			vel -= vel * delta * damping
			
			set_velocity(vel)
			move_and_slide()
			_resolve_combat_collisions()
			
			# Implement Banking as described:
			# https://www.cs.toronto.edu/~dt/siggraph97-course/cwr87/
			var temp_up = global_transform.basis.y.lerp(Vector3.UP + (acceleration * banking), delta)
			look_at(global_transform.origin - vel.normalized(), temp_up)


func _resolve_combat_collisions() -> void:
	# Resolve close-contact combat once per pair after movement.
	# Only anti-magic vs non anti-magic contacts exchange damage for now.
	if not is_combat_active():
		return
	var collision_count = get_slide_collision_count()
	if collision_count <= 0:
		return

	for i in range(collision_count):
		var collision = get_slide_collision(i)
		if collision == null:
			continue

		var other = collision.get_collider()
		if other == null or not (other is Boid):
			continue
		if other == self:
			continue
		if other.has_method("is_combat_active") and not other.is_combat_active():
			continue

		# Process each pair only once to avoid double damage from both bodies.
		if get_instance_id() > other.get_instance_id():
			continue

		var pair_key = _combat_pair_key(other)
		if _combat_collision_cooldowns.get(pair_key, 0.0) > 0.0:
			continue

		resolve_collision_with(other)
		_combat_collision_cooldowns[pair_key] = combat_collision_cooldown


func resolve_collision_with(other: Boid) -> void:
	# Default Boid implementation does nothing.
	# Lifeform overrides this to apply combat damage.
	pass


func is_combat_active() -> bool:
	# Base boids participate in combat unless a subclass disables it.
	return true


func _update_combat_collision_cooldowns(delta: float) -> void:
	if _combat_collision_cooldowns.is_empty():
		return
	var expired_keys: Array = []
	for key in _combat_collision_cooldowns.keys():
		var remaining = float(_combat_collision_cooldowns[key]) - delta
		if remaining <= 0.0:
			expired_keys.append(key)
		else:
			_combat_collision_cooldowns[key] = remaining
	for key in expired_keys:
		_combat_collision_cooldowns.erase(key)


func _combat_pair_key(other: Boid) -> String:
	var first_id = min(get_instance_id(), other.get_instance_id())
	var second_id = max(get_instance_id(), other.get_instance_id())
	return str(first_id) + ":" + str(second_id)
