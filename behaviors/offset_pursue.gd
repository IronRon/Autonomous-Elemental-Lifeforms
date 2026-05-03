class_name OffsetPursue extends SteeringBehavior

@export var leader_boid:Boid
@export var use_custom_offset: bool = false
@export var custom_offset_local: Vector3 = Vector3(1.5, 0.0, 0.0)
var leader_offset:Vector3
var target:Vector3
var world_target:Vector3
var projected:Vector3

func on_draw_gizmos():
	# DebugDraw.draw_sphere(world_target, 1, Color.GREEN)
	# DebugDraw.draw_sphere(projected, 1, Color.GREEN)
	if leader_boid:
		DebugDraw3D.draw_arrow(world_target, projected, Color.BLUE_VIOLET, 0.1)	


func calculate_offset():
	if leader_boid == null:
		return
	if use_custom_offset:
		leader_offset = custom_offset_local
		return
	leader_offset = boid.global_transform.origin - leader_boid.global_transform.origin
	leader_offset = (leader_offset) * leader_boid.global_transform.basis	

func _ready():
	boid = get_parent()		
	if leader_boid:
		call_deferred("calculate_offset")		

func calculate():		
	if leader_boid == null:
		return Vector3.ZERO
	world_target = leader_boid.global_transform * (leader_offset)
	var dist = boid.global_transform.origin.distance_to(world_target)
	var time = dist / boid.max_speed
	projected = world_target + leader_boid.velocity * time
	

	return boid.arrive_force(projected, 30)
