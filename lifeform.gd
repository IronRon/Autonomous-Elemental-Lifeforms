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
@onready var visual: MeshInstance3D = $Visual
@onready var stats_node: Node = $LifeformStats


func _ready() -> void:
	super._ready()
	_apply_configuration()
	_update_mesh_for_level()
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


func set_level(value: int) -> void:
	level = max(1, value)
	_apply_configuration()
	_update_mesh_for_level()
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
