# Lifeform root controller.
# Applies exported gameplay stats to boid movement and visual presentation.
@tool
extends Boid

enum ElementType { Fire, Wind, Water, Earth, AntiMagic }

@export var element_type: ElementType = ElementType.Fire:
	set = set_element_type
@export var level: int = 1:
	set = set_level
@export var visual_color: Color = Color(1, 0.3019608, 1, 1):
	set = set_visual_color
@export var size_multiplier: float = 1.0:
	set = set_size_multiplier
@export var strength: float = 1.0:
	set = set_strength
@export var speed_multiplier: float = 1.0:
	set = set_speed_multiplier

@export var base_max_speed: float = 3.0
@export var base_mass: float = 1.0
@export var trail_enabled: bool = true:
	set = set_trail_enabled

# Combat / resource stats
@export var attack_energy: int = 1
@export var max_attack_energy: int = 3
@export var health: int = 2
@export var collision_impulse_strength: float = 4.0
var is_dead: bool = false

# Detection radii (meters)
@export var social_detection_radius: float = 20.0
@export var resource_detection_radius: float = 20.0


var _dynamic_material: StandardMaterial3D
var _face_material: StandardMaterial3D
var _accessory_material: StandardMaterial3D
var _trail_material_is_unique: bool = false
var _death_burst_material_is_unique: bool = false
var _collision_burst_material_is_unique: bool = false
@onready var visual: MeshInstance3D = $Visual
@onready var stats_node: Node = $LifeformStats
@onready var trail_particles: GPUParticles3D = $TrailParticles
@onready var death_burst_particles: GPUParticles3D = $DeathBurstParticles
@onready var collision_burst_particles: GPUParticles3D = $CollisionBurstParticles
@onready var death_sound: AudioStreamPlayer3D = $DeathSound
@onready var collision_sound: AudioStreamPlayer3D = $CollisionSound
@onready var left_eye: MeshInstance3D = $Visual/LeftEye
@onready var right_eye: MeshInstance3D = $Visual/RightEye
@onready var mouth: MeshInstance3D = $Visual/Mouth
@onready var fire_crest: MeshInstance3D = $Visual/FireCrest
@onready var wind_wing_left: MeshInstance3D = $Visual/WindWingLeft
@onready var wind_wing_right: MeshInstance3D = $Visual/WindWingRight
@onready var water_drop: MeshInstance3D = $Visual/WaterDrop
@onready var earth_pebble_left: MeshInstance3D = $Visual/EarthPebbleLeft
@onready var earth_pebble_right: MeshInstance3D = $Visual/EarthPebbleRight
@onready var anti_horn_left: MeshInstance3D = $Visual/AntiHornLeft
@onready var anti_horn_right: MeshInstance3D = $Visual/AntiHornRight


func _ready() -> void:
	super._ready()
	_apply_configuration()
	_update_mesh_for_level()
	_update_face()
	_update_accessories()
	_update_trail()
	_update_death_burst()
	_update_collision_burst()
	_sync_stats_node()

	# Apply configured detection radii to area collision shapes.
	# DetectionArea is used for social/partner detection (forming groups).
	var det = get_node_or_null("DetectionArea/CollisionShape3D")
	if det and det.shape and det.shape.has_method("set"):
		det.shape.radius = social_detection_radius

	# ResourceDetection is used for finding mana orbs to seek and consume for energy.
	var res = get_node_or_null("ResourceDetection/CollisionShape3D")
	if res and res.shape and res.shape.has_method("set"):
		res.shape.radius = resource_detection_radius
	_update_attack_stats()


func set_element_type(value: ElementType) -> void:
	element_type = value
	visual_color = _color_for_element(value)
	_apply_configuration()
	_update_face()
	_update_accessories()
	_update_trail()
	_update_death_burst()
	_update_collision_burst()


func set_level(value: int) -> void:
	level = max(1, value)
	_apply_configuration()
	_update_mesh_for_level()
	_update_face()
	_update_accessories()
	_update_trail()
	_update_death_burst()
	_update_collision_burst()
	_update_attack_stats()


func _update_attack_stats() -> void:
	# Set defaults for health and max attack energy based on level.
	# Level progression increases durability and energy capacity.
	match level:
		1:
			max_attack_energy = 3
			health = health #2
			# Ensure level-1 lifeforms always have at least 1 energy to enable seeking behavior.
			attack_energy = max(attack_energy, 1)
		2:
			max_attack_energy = 5
			health = 4
			attack_energy = min(attack_energy, max_attack_energy)
		_:
			max_attack_energy = 8
			health = 6
			attack_energy = min(attack_energy, max_attack_energy)


func add_attack_energy(amount: int) -> void:
	# Gain attack energy from resource pickup (mana orbs).
	# Clamped to [0, max_attack_energy].
	attack_energy = clamp(attack_energy + amount, 0, max_attack_energy)


func apply_damage(amount: int) -> bool:
	# Returns true if this lifeform died from the hit.
	print(self, " Start health: ", health, " amount: ", amount)
	if amount <= 0 or is_dead:
		return false
	health = max(0, health - amount)
	print(self, " health: ", health, " amount: ", amount)
	if health <= 0:
		print(self, "Ye we dead", " health: ", health)
		die()
		return true
	return false


func resolve_collision_with(other: Boid) -> void:
	# Resolve combat once per colliding pair.
	# Only anti-magic vs non anti-magic contacts exchange damage in this step.
	if is_dead:
		return
	if other == null or not is_instance_valid(other) or other == self:
		return
	if not (other is Boid):
		return
	if other.has_method("is_combat_active") and not other.is_combat_active():
		return
	if get_instance_id() > other.get_instance_id():
		return
	if element_type == other.element_type:
		return
	if element_type != ElementType.AntiMagic and other.element_type != ElementType.AntiMagic:
		return

	var collision_point = (global_position + other.global_position) * 0.5
	_play_collision_sound(collision_point)
	_play_collision_burst(collision_point)
	if other.has_method("_play_collision_burst"):
		other._play_collision_burst(collision_point)

	var was_dead_before = is_dead
	if other.has_method("apply_damage"):
		apply_damage(int(other.attack_energy))
	if other.has_method("apply_damage") and not was_dead_before:
		other.apply_damage(int(attack_energy))
	_apply_collision_impulse(other)
	if other.has_method("_apply_collision_impulse"):
		other._apply_collision_impulse(self)


func die() -> void:
	# Clear references before removing this lifeform from the scene.
	if is_dead:
		return
	is_dead = true
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	set_collision_layer_value(2, false)
	set_collision_mask_value(2, false)
	var all_lifeforms = get_tree().get_nodes_in_group("lifeforms")
	print(all_lifeforms)
	for lifeform in all_lifeforms:
		if lifeform == null or lifeform == self or not lifeform.has_node("LifeformBrain"):
			continue
		var brain = lifeform.get_node("LifeformBrain")
		if brain and brain.has_method("clear_threat_reference"):
			brain.clear_threat_reference(self)
		if brain and brain.has_method("clear_prey_reference"):
			brain.clear_prey_reference(self)
	var brain = get_node_or_null("LifeformBrain")
	if brain and brain.has_method("on_lifeform_death"):
		brain.on_lifeform_death()
	_play_death_sound()
	_play_death_burst()
	queue_free()


func is_combat_active() -> bool:
	return not is_dead


func _apply_collision_impulse(other: Boid) -> void:
	# Push colliding lifeforms apart so combat has visible physical feedback.
	if other == null or not is_instance_valid(other):
		return
	var offset = other.global_transform.origin - global_transform.origin
	if offset == Vector3.ZERO:
		offset = -global_transform.basis.z
	var impulse = offset.normalized() * collision_impulse_strength
	vel -= impulse
	vel = vel.limit_length(max_speed * 1.5)



func set_visual_color(value: Color) -> void:
	visual_color = value
	_apply_configuration()


func set_size_multiplier(value: float) -> void:
	size_multiplier = max(0.1, value)
	_apply_configuration()


func set_strength(value: float) -> void:
	strength = max(0.1, value)
	_apply_configuration()


func set_speed_multiplier(value: float) -> void:
	speed_multiplier = max(0.1, value)
	_apply_configuration()


func set_trail_enabled(value: bool) -> void:
	trail_enabled = value
	_update_trail()


func _apply_configuration() -> void:
	# Stat modifiers directly shape motion and physical scale.
	max_speed = base_max_speed * speed_multiplier
	mass = base_mass / strength
	scale = Vector3.ONE * size_multiplier

	if not is_inside_tree():
		return

	if visual == null:
		visual = get_node_or_null("Visual")
	if visual:
		# Each lifeform gets its own material override so per-instance tinting works.
		if _dynamic_material == null:
			_dynamic_material = StandardMaterial3D.new()
			_dynamic_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
			_dynamic_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		visual.material_override = _dynamic_material
		_dynamic_material.albedo_color = visual_color

	_update_face()
	_update_accessories()
	_update_trail()
	_update_death_burst()
	_update_collision_burst()
	_sync_stats_node()


func _sync_stats_node() -> void:
	if stats_node == null:
		stats_node = get_node_or_null("LifeformStats")
	if stats_node and stats_node.has_method("copy_from_lifeform"):
		stats_node.copy_from_lifeform(self)


func _color_for_element(value: ElementType) -> Color:
	# Default palette used whenever element type changes in editor/runtime.
	match value:
		ElementType.Fire:
			return Color(1, 0, 0)
		ElementType.Wind:
			return Color(0, 1, 0)
		ElementType.Water:
			return Color(0, 0, 1)
		ElementType.Earth:
			return Color(0.55, 0.27, 0.07)
		ElementType.AntiMagic:
			return Color(0, 0, 0)
		_:
			return Color(1, 0.3019608, 1, 1)


func _update_mesh_for_level() -> void:
	# Swap mesh based on level: sphere for level 1, cube for level 2, capsule for level 3+.
	if visual == null:
		return
	
	match level:
		1:
			visual.mesh = SphereMesh.new()
		2:
			visual.mesh = BoxMesh.new()
		_:
			var capsule = CapsuleMesh.new()
			capsule.radius = 0.65
			capsule.height = 1.8
			visual.mesh = capsule
	# Material override persists across mesh swap, preserving albedo color.


func _update_face() -> void:
	if not is_inside_tree():
		return
	if left_eye == null:
		left_eye = get_node_or_null("Visual/LeftEye")
	if right_eye == null:
		right_eye = get_node_or_null("Visual/RightEye")
	if mouth == null:
		mouth = get_node_or_null("Visual/Mouth")
	if left_eye == null or right_eye == null or mouth == null:
		return

	var show_face = level == 1
	left_eye.visible = show_face
	right_eye.visible = show_face
	mouth.visible = show_face
	if not show_face:
		return

	_apply_face_material(_face_color_for_element())

	match element_type:
		ElementType.Fire:
			_apply_face_layout(
				Vector3(-0.14, 0.24, 0.49),
				Vector3(0.14, 0.24, 0.49),
				Vector3(0.0, -0.08, 0.50),
				Vector3(1.35, 0.6, 0.9),
				Vector3(1.35, 0.6, 0.9),
				Vector3(1.25, 0.75, 1.0),
				deg_to_rad(-12.0),
				deg_to_rad(12.0),
				deg_to_rad(92.0)
			)
		ElementType.Wind:
			_apply_face_layout(
				Vector3(-0.18, 0.24, 0.49),
				Vector3(0.18, 0.24, 0.49),
				Vector3(0.0, -0.06, 0.50),
				Vector3(1.15, 1.2, 1.0),
				Vector3(1.15, 1.2, 1.0),
				Vector3(1.55, 0.85, 1.0),
				deg_to_rad(8.0),
				deg_to_rad(-8.0),
				deg_to_rad(100.0)
			)
		ElementType.Water:
			_apply_face_layout(
				Vector3(-0.14, 0.17, 0.49),
				Vector3(0.14, 0.17, 0.49),
				Vector3(0.0, -0.12, 0.50),
				Vector3(1.0, 0.8, 1.0),
				Vector3(1.0, 0.8, 1.0),
				Vector3(1.35, 0.7, 1.0),
				deg_to_rad(0.0),
				deg_to_rad(0.0),
				deg_to_rad(82.0)
			)
		ElementType.Earth:
			_apply_face_layout(
				Vector3(-0.12, 0.13, 0.49),
				Vector3(0.12, 0.13, 0.49),
				Vector3(0.0, -0.13, 0.50),
				Vector3(1.2, 0.75, 1.0),
				Vector3(1.2, 0.75, 1.0),
				Vector3(1.65, 0.65, 1.0),
				deg_to_rad(0.0),
				deg_to_rad(0.0),
				deg_to_rad(90.0)
			)
		ElementType.AntiMagic:
			_apply_face_layout(
				Vector3(-0.13, 0.23, 0.49),
				Vector3(0.13, 0.23, 0.49),
				Vector3(0.0, -0.09, 0.50),
				Vector3(1.45, 0.55, 1.0),
				Vector3(1.45, 0.55, 1.0),
				Vector3(1.15, 0.7, 1.0),
				deg_to_rad(18.0),
				deg_to_rad(-18.0),
				deg_to_rad(70.0)
			)


func _apply_face_layout(
	left_pos: Vector3,
	right_pos: Vector3,
	mouth_pos: Vector3,
	left_scale: Vector3,
	right_scale: Vector3,
	mouth_scale: Vector3,
	left_roll: float,
	right_roll: float,
	mouth_roll: float
) -> void:
	left_eye.position = left_pos
	right_eye.position = right_pos
	mouth.position = mouth_pos
	left_eye.rotation = Vector3(0.0, 0.0, left_roll)
	right_eye.rotation = Vector3(0.0, 0.0, right_roll)
	mouth.rotation = Vector3(0.0, 0.0, mouth_roll)
	left_eye.scale = left_scale
	right_eye.scale = right_scale
	mouth.scale = mouth_scale


func _apply_face_material(color: Color) -> void:
	if _face_material == null:
		_face_material = StandardMaterial3D.new()
		_face_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	left_eye.material_override = _face_material
	right_eye.material_override = _face_material
	mouth.material_override = _face_material
	_face_material.albedo_color = color
	_face_material.emission_enabled = element_type == ElementType.AntiMagic
	_face_material.emission = color
	_face_material.emission_energy_multiplier = 0.8


func _face_color_for_element() -> Color:
	if element_type == ElementType.AntiMagic:
		return Color(0.75, 0.0, 1.0)
	return Color.BLACK


func _update_accessories() -> void:
	if not is_inside_tree():
		return
	_cache_accessory_nodes()
	var accessories = _get_accessory_nodes()
	for accessory in accessories:
		if accessory:
			accessory.visible = false
	if level != 1:
		return

	_apply_accessory_material(_accessory_color_for_element())

	match element_type:
		ElementType.Fire:
			_show_accessory(
				fire_crest,
				Vector3(0.0, 0.58, 0.02),
				Vector3(deg_to_rad(-12.0), 0.0, 0.0),
				Vector3(1.0, 1.25, 0.9)
			)
		ElementType.Wind:
			_show_accessory(
				wind_wing_left,
				Vector3(-0.46, 0.02, 0.02),
				Vector3(0.0, 0.0, deg_to_rad(35.0)),
				Vector3(1.0, 1.0, 1.0)
			)
			_show_accessory(
				wind_wing_right,
				Vector3(0.46, 0.02, 0.02),
				Vector3(0.0, 0.0, deg_to_rad(-35.0)),
				Vector3(1.0, 1.0, 1.0)
			)
		ElementType.Water:
			_show_accessory(
				water_drop,
				Vector3(0.0, 0.55, 0.04),
				Vector3.ZERO,
				Vector3(0.85, 1.35, 0.85)
			)
		ElementType.Earth:
			_show_accessory(
				earth_pebble_left,
				Vector3(-0.22, 0.48, 0.02),
				Vector3(deg_to_rad(15.0), deg_to_rad(0.0), deg_to_rad(18.0)),
				Vector3(1.0, 0.8, 0.9)
			)
			_show_accessory(
				earth_pebble_right,
				Vector3(0.22, 0.48, 0.02),
				Vector3(deg_to_rad(-10.0), deg_to_rad(0.0), deg_to_rad(-15.0)),
				Vector3(0.85, 0.95, 0.9)
			)
		ElementType.AntiMagic:
			_show_accessory(
				anti_horn_left,
				Vector3(-0.23, 0.47, 0.04),
				Vector3(deg_to_rad(-20.0), 0.0, deg_to_rad(22.0)),
				Vector3(1.0, 1.1, 1.0)
			)
			_show_accessory(
				anti_horn_right,
				Vector3(0.23, 0.47, 0.04),
				Vector3(deg_to_rad(-20.0), 0.0, deg_to_rad(-22.0)),
				Vector3(1.0, 1.1, 1.0)
			)


func _cache_accessory_nodes() -> void:
	if fire_crest == null:
		fire_crest = get_node_or_null("Visual/FireCrest")
	if wind_wing_left == null:
		wind_wing_left = get_node_or_null("Visual/WindWingLeft")
	if wind_wing_right == null:
		wind_wing_right = get_node_or_null("Visual/WindWingRight")
	if water_drop == null:
		water_drop = get_node_or_null("Visual/WaterDrop")
	if earth_pebble_left == null:
		earth_pebble_left = get_node_or_null("Visual/EarthPebbleLeft")
	if earth_pebble_right == null:
		earth_pebble_right = get_node_or_null("Visual/EarthPebbleRight")
	if anti_horn_left == null:
		anti_horn_left = get_node_or_null("Visual/AntiHornLeft")
	if anti_horn_right == null:
		anti_horn_right = get_node_or_null("Visual/AntiHornRight")


func _get_accessory_nodes() -> Array:
	return [
		fire_crest,
		wind_wing_left,
		wind_wing_right,
		water_drop,
		earth_pebble_left,
		earth_pebble_right,
		anti_horn_left,
		anti_horn_right
	]


func _show_accessory(accessory: MeshInstance3D, pos: Vector3, rot: Vector3, accessory_scale: Vector3) -> void:
	if accessory == null:
		return
	accessory.visible = true
	accessory.position = pos
	accessory.rotation = rot
	accessory.scale = accessory_scale
	accessory.material_override = _accessory_material


func _apply_accessory_material(color: Color) -> void:
	if _accessory_material == null:
		_accessory_material = StandardMaterial3D.new()
		_accessory_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	_accessory_material.albedo_color = color
	_accessory_material.emission_enabled = element_type == ElementType.Fire or element_type == ElementType.AntiMagic
	_accessory_material.emission = color
	_accessory_material.emission_energy_multiplier = 0.45


func _accessory_color_for_element() -> Color:
	match element_type:
		ElementType.Fire:
			return Color(1.0, 0.35, 0.02)
		ElementType.Wind:
			return Color(0.65, 1.0, 0.55)
		ElementType.Water:
			return Color(0.2, 0.7, 1.0)
		ElementType.Earth:
			return Color(0.35, 0.22, 0.12)
		ElementType.AntiMagic:
			return Color(0.35, 0.0, 0.5)
		_:
			return visual_color


func _update_trail() -> void:
	if not is_inside_tree():
		return
	if trail_particles == null:
		trail_particles = get_node_or_null("TrailParticles")
	if trail_particles == null:
		return

	if not _trail_material_is_unique and trail_particles.process_material:
		trail_particles.process_material = trail_particles.process_material.duplicate()
		_trail_material_is_unique = true

	trail_particles.emitting = trail_enabled
	var material = trail_particles.process_material
	if material is ParticleProcessMaterial:
		material.color = _trail_color_for_element()


func _trail_color_for_element() -> Color:
	var color = visual_color
	color.a = 0.45
	match element_type:
		ElementType.Fire:
			return Color(1.0, 0.35, 0.05, 0.8)
		ElementType.Wind:
			return Color(0.55, 1.0, 0.45, 0.7)
		ElementType.Water:
			return Color(0.25, 0.65, 1.0, 0.75)
		ElementType.Earth:
			return Color(0.45, 0.28, 0.12, 0.7)
		ElementType.AntiMagic:
			return Color(0.6, 0.0, 0.9, 0.8)
		_:
			return color


func _update_death_burst() -> void:
	if not is_inside_tree():
		return
	if death_burst_particles == null:
		death_burst_particles = get_node_or_null("DeathBurstParticles")
	if death_burst_particles == null:
		return

	if not _death_burst_material_is_unique and death_burst_particles.process_material:
		death_burst_particles.process_material = death_burst_particles.process_material.duplicate()
		_death_burst_material_is_unique = true

	var material = death_burst_particles.process_material
	if material is ParticleProcessMaterial:
		material.color = _death_burst_color_for_element()


func _update_collision_burst() -> void:
	if not is_inside_tree():
		return
	if collision_burst_particles == null:
		collision_burst_particles = get_node_or_null("CollisionBurstParticles")
	if collision_burst_particles == null:
		return

	if not _collision_burst_material_is_unique and collision_burst_particles.process_material:
		collision_burst_particles.process_material = collision_burst_particles.process_material.duplicate()
		_collision_burst_material_is_unique = true

	var material = collision_burst_particles.process_material
	if material is ParticleProcessMaterial:
		material.color = _collision_burst_color_for_element()


func _play_death_burst() -> void:
	if death_burst_particles == null:
		death_burst_particles = get_node_or_null("DeathBurstParticles")
	if death_burst_particles == null:
		return

	var burst = death_burst_particles
	death_burst_particles = null
	burst.emitting = false
	burst.reparent(_get_effect_parent(), true)
	burst.global_position = global_position
	burst.restart()
	burst.emitting = true

	var free_timer = get_tree().create_timer(burst.lifetime + 0.25)
	free_timer.timeout.connect(Callable(burst, "queue_free"))


func _play_death_sound() -> void:
	if death_sound == null:
		death_sound = get_node_or_null("DeathSound")
	if death_sound == null or death_sound.stream == null:
		return

	var sound = death_sound
	death_sound = null
	sound.reparent(_get_effect_parent(), true)
	sound.global_position = global_position
	sound.play()

	var free_timer = get_tree().create_timer(sound.stream.get_length() + 0.25)
	free_timer.timeout.connect(Callable(sound, "queue_free"))


func _play_collision_burst(collision_point: Vector3) -> void:
	if collision_burst_particles == null:
		collision_burst_particles = get_node_or_null("CollisionBurstParticles")
	if collision_burst_particles == null:
		return

	var burst = collision_burst_particles.duplicate() as GPUParticles3D
	if burst == null:
		return

	var material = burst.process_material
	if material:
		burst.process_material = material.duplicate()
		material = burst.process_material
	if material is ParticleProcessMaterial:
		material.color = _collision_burst_color_for_element()

	burst.emitting = false
	_get_effect_parent().add_child(burst)
	burst.global_position = collision_point
	burst.restart()
	burst.emitting = true

	var free_timer = get_tree().create_timer(burst.lifetime + 0.25)
	free_timer.timeout.connect(Callable(burst, "queue_free"))


func _play_collision_sound(collision_point: Vector3) -> void:
	if collision_sound == null:
		collision_sound = get_node_or_null("CollisionSound")
	if collision_sound == null or collision_sound.stream == null:
		return

	var sound = collision_sound.duplicate() as AudioStreamPlayer3D
	if sound == null:
		return

	_get_effect_parent().add_child(sound)
	sound.global_position = collision_point
	sound.play()

	var free_timer = get_tree().create_timer(sound.stream.get_length() + 0.25)
	free_timer.timeout.connect(Callable(sound, "queue_free"))


func _get_effect_parent() -> Node:
	var current_scene = get_tree().current_scene
	if current_scene:
		return current_scene
	if get_parent():
		return get_parent()
	return self


func _death_burst_color_for_element() -> Color:
	match element_type:
		ElementType.Fire:
			return Color(1.0, 0.25, 0.02, 0.95)
		ElementType.Wind:
			return Color(0.55, 1.0, 0.45, 0.85)
		ElementType.Water:
			return Color(0.25, 0.65, 1.0, 0.9)
		ElementType.Earth:
			return Color(0.5, 0.3, 0.12, 0.85)
		ElementType.AntiMagic:
			return Color(0.75, 0.0, 1.0, 0.95)
		_:
			return visual_color


func _collision_burst_color_for_element() -> Color:
	match element_type:
		ElementType.Fire:
			return Color(1.0, 0.35, 0.05, 0.85)
		ElementType.Wind:
			return Color(0.55, 1.0, 0.45, 0.75)
		ElementType.Water:
			return Color(0.25, 0.65, 1.0, 0.8)
		ElementType.Earth:
			return Color(0.55, 0.32, 0.12, 0.8)
		ElementType.AntiMagic:
			return Color(0.75, 0.0, 1.0, 0.9)
		_:
			return visual_color
