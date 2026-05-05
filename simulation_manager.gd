extends Node

@export var lifeform_scene: PackedScene = preload("res://lifeform.tscn")
@export var mana_orb_scene: PackedScene = preload("res://mana_orb.tscn")
@export var spawn_parent_path: NodePath = ".."
@export var use_evolution_test_spawn: bool = false
@export var clear_existing_lifeforms: bool = true
@export var clear_existing_mana_orbs: bool = true
@export var lifeforms_per_element: int = 9
@export var mana_orb_count: int = 15
@export var spawn_radius: float = 30.0
@export var spawn_height: float = 7.0
@export var evolution_test_center: Vector3 = Vector3.ZERO
@export var evolution_test_merge_check_interval: float = 10.0
@export var mana_orb_spawn_height: float = 20.0
@export var relocate_mana_orbs: bool = true
@export var mana_orb_relocation_interval: float = 30.0
@export var lifeform_clearance_radius: float = 3.0
@export var mana_orb_clearance_radius: float = 2.0
@export var spawn_blocking_collision_mask: int = 2
@export var max_spawn_attempts: int = 40
@export var random_seed: int = 0
@export var player_mana_spawn_enabled: bool = true
@export var player_mana_spawn_distance: float = 15.0
@export var player_mana_spawn_clearance_radius: float = 2.0

var _rng := RandomNumberGenerator.new()
var _mana_orb_relocation_timer: Timer
var total_deaths: int = 0
var total_evolutions: int = 0
var _player_spawned_mana_count: int = 0


func _ready() -> void:
	add_to_group("simulation_manager")
	if random_seed == 0:
		_rng.randomize()
	else:
		_rng.seed = random_seed

	call_deferred("_start_simulation")


func _unhandled_input(event: InputEvent) -> void:
	if not player_mana_spawn_enabled:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		_spawn_player_mana_orb_in_front_of_camera()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_spawn_player_mana_orb_from_cursor(event.position)
		get_viewport().set_input_as_handled()


func _start_simulation() -> void:
	total_deaths = 0
	total_evolutions = 0
	var spawn_parent = get_node_or_null(spawn_parent_path)
	if spawn_parent == null:
		spawn_parent = get_parent()

	if clear_existing_lifeforms:
		_clear_existing_lifeforms()
	if clear_existing_mana_orbs:
		_clear_existing_mana_orbs()

	if use_evolution_test_spawn:
		_spawn_evolution_test(spawn_parent)
	else:
		_spawn_initial_lifeforms(spawn_parent)
		_spawn_initial_mana_orbs(spawn_parent)
	_setup_mana_orb_relocation_timer()


func _clear_existing_lifeforms() -> void:
	for lifeform in get_tree().get_nodes_in_group("lifeforms"):
		if lifeform != null and is_instance_valid(lifeform):
			lifeform.queue_free()


func _clear_existing_mana_orbs() -> void:
	for orb in get_tree().get_nodes_in_group("mana_orbs"):
		if orb != null and is_instance_valid(orb):
			orb.queue_free()


func _spawn_initial_lifeforms(spawn_parent: Node) -> void:
	if lifeform_scene == null:
		push_error("SimulationManager needs a lifeform scene.")
		return

	for element_type in range(5):
		for index in range(lifeforms_per_element):
			_spawn_lifeform(spawn_parent, element_type, index)


func _spawn_initial_mana_orbs(spawn_parent: Node) -> void:
	if mana_orb_scene == null:
		push_error("SimulationManager needs a mana orb scene.")
		return

	for index in range(mana_orb_count):
		_spawn_mana_orb(spawn_parent, index)


func _spawn_evolution_test(spawn_parent: Node) -> void:
	if lifeform_scene == null:
		push_error("SimulationManager needs a lifeform scene.")
		return

	var y = spawn_height
	var center = evolution_test_center

	# Cluster A: three level-1 Fire lifeforms should merge into a level-2 form.
	_spawn_lifeform_at(spawn_parent, 0, 1, center + Vector3(-7.0, y, 0.0), "FireL1MergeA")
	_spawn_lifeform_at(spawn_parent, 0, 1, center + Vector3(-4.5, y, 1.5), "FireL1MergeB")
	_spawn_lifeform_at(spawn_parent, 0, 1, center + Vector3(-4.5, y, -1.5), "FireL1MergeC")

	# Cluster B: one level-2 Fire leader plus two level-1 followers should merge into level 3.
	_spawn_lifeform_at(spawn_parent, 0, 2, center + Vector3(7.0, y, 0.0), "FireL2Leader")
	_spawn_lifeform_at(spawn_parent, 0, 1, center + Vector3(9.5, y, 1.5), "FireL1FollowerA")
	_spawn_lifeform_at(spawn_parent, 0, 1, center + Vector3(9.5, y, -1.5), "FireL1FollowerB")


func _spawn_lifeform(spawn_parent: Node, element_type: int, index: int) -> void:
	var lifeform = lifeform_scene.instantiate()
	if lifeform == null:
		return

	lifeform.name = _element_name(element_type) + "Lifeform" + str(index + 1)
	lifeform.add_to_group("lifeforms")
	lifeform.element_type = element_type
	lifeform.position = _random_safe_lifeform_position()

	if element_type == 4:
		lifeform.base_max_speed = 5.0
		lifeform.health = 5.0

	spawn_parent.add_child(lifeform)


func _spawn_lifeform_at(spawn_parent: Node, element_type: int, level: int, position: Vector3, node_name: String) -> void:
	var lifeform = lifeform_scene.instantiate()
	if lifeform == null:
		return

	lifeform.name = node_name
	lifeform.add_to_group("lifeforms")
	lifeform.element_type = element_type
	lifeform.level = level
	lifeform.position = position
	_configure_evolution_test_brain(lifeform)

	if element_type == 4:
		lifeform.base_max_speed = 5.0
		lifeform.health = 5.0

	spawn_parent.add_child(lifeform)


func _configure_evolution_test_brain(lifeform: Node) -> void:
	var brain = lifeform.get_node_or_null("LifeformBrain")
	if brain == null:
		return
	brain.merge_check_interval = evolution_test_merge_check_interval


func _spawn_mana_orb(spawn_parent: Node, index: int) -> void:
	var mana_orb = mana_orb_scene.instantiate()
	if mana_orb == null:
		return

	mana_orb.name = "ManaOrb" + str(index + 1)
	mana_orb.add_to_group("mana_orbs")
	mana_orb.position = _random_safe_mana_orb_position()
	spawn_parent.add_child(mana_orb)


func _spawn_player_mana_orb_in_front_of_camera() -> void:
	var camera = get_viewport().get_camera_3d()
	if camera == null:
		return
	var spawn_position = camera.global_position - camera.global_transform.basis.z * player_mana_spawn_distance
	_spawn_player_mana_orb_at(_safe_player_mana_position(spawn_position))


func _spawn_player_mana_orb_from_cursor(cursor_position: Vector2) -> void:
	var camera = get_viewport().get_camera_3d()
	if camera == null:
		return
	var origin = camera.project_ray_origin(cursor_position)
	var direction = camera.project_ray_normal(cursor_position)
	var spawn_position = origin + direction * player_mana_spawn_distance
	_spawn_player_mana_orb_at(_safe_player_mana_position(spawn_position))


func _spawn_player_mana_orb_at(spawn_position: Vector3) -> void:
	if mana_orb_scene == null:
		return
	var spawn_parent = get_node_or_null(spawn_parent_path)
	if spawn_parent == null:
		spawn_parent = get_parent()
	if spawn_parent == null:
		return

	var mana_orb = mana_orb_scene.instantiate()
	if mana_orb == null:
		return

	_player_spawned_mana_count += 1
	mana_orb.name = "PlayerManaOrb" + str(_player_spawned_mana_count)
	mana_orb.add_to_group("mana_orbs")
	mana_orb.global_position = spawn_position
	spawn_parent.add_child(mana_orb)


func _safe_player_mana_position(preferred_position: Vector3) -> Vector3:
	if not _is_spawn_position_blocked(preferred_position, player_mana_spawn_clearance_radius):
		return preferred_position

	for attempt in range(max_spawn_attempts):
		var offset = Vector3(
			_rng.randf_range(-player_mana_spawn_clearance_radius, player_mana_spawn_clearance_radius),
			_rng.randf_range(-player_mana_spawn_clearance_radius, player_mana_spawn_clearance_radius),
			_rng.randf_range(-player_mana_spawn_clearance_radius, player_mana_spawn_clearance_radius)
		) * 2.0
		var candidate = preferred_position + offset
		if not _is_spawn_position_blocked(candidate, player_mana_spawn_clearance_radius):
			return candidate

	return preferred_position


func _random_spawn_position(height: float = spawn_height) -> Vector3:
	var angle = _rng.randf_range(0.0, TAU)
	var distance = sqrt(_rng.randf()) * spawn_radius
	return Vector3(cos(angle) * distance, height, sin(angle) * distance)


func _random_safe_mana_orb_position() -> Vector3:
	var fallback_position = _random_spawn_position(mana_orb_spawn_height)
	for attempt in range(max_spawn_attempts):
		var candidate = _random_spawn_position(mana_orb_spawn_height)
		if not _is_spawn_position_blocked(candidate, mana_orb_clearance_radius):
			return candidate
	return fallback_position


func _random_safe_lifeform_position() -> Vector3:
	var fallback_position = _random_spawn_position(spawn_height)
	for attempt in range(max_spawn_attempts):
		var candidate = _random_spawn_position(spawn_height)
		if not _is_spawn_position_blocked(candidate, lifeform_clearance_radius):
			return candidate
	return fallback_position


func _is_spawn_position_blocked(position: Vector3, clearance_radius: float) -> bool:
	var shape = SphereShape3D.new()
	shape.radius = clearance_radius

	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), position)
	query.collision_mask = spawn_blocking_collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var hits = get_viewport().world_3d.direct_space_state.intersect_shape(query, 1)
	return not hits.is_empty()


func _setup_mana_orb_relocation_timer() -> void:
	if not relocate_mana_orbs or mana_orb_relocation_interval <= 0.0:
		return

	_mana_orb_relocation_timer = Timer.new()
	_mana_orb_relocation_timer.wait_time = mana_orb_relocation_interval
	_mana_orb_relocation_timer.timeout.connect(_relocate_mana_orbs)
	add_child(_mana_orb_relocation_timer)
	_mana_orb_relocation_timer.start()


func _relocate_mana_orbs() -> void:
	for orb in get_tree().get_nodes_in_group("mana_orbs"):
		if orb != null and is_instance_valid(orb) and orb is Node3D:
			orb.global_position = _random_safe_mana_orb_position()


func _element_name(element_type: int) -> String:
	match element_type:
		0:
			return "Fire"
		1:
			return "Wind"
		2:
			return "Water"
		3:
			return "Earth"
		4:
			return "AntiMagic"
		_:
			return "Unknown"


func record_lifeform_death() -> void:
	total_deaths += 1


func record_evolution() -> void:
	total_evolutions += 1
