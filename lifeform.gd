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

@export var base_max_speed: float = 1.0
@export var base_mass: float = 1.0

# Combat / resource stats
@export var attack_energy: int = 1
@export var max_attack_energy: int = 3
@export var health: int = 2

# Detection radii (meters)
@export var social_detection_radius: float = 10.0
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
			health = 2
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
	# Swap mesh based on level: sphere for level 1, cube for level 2+.
	if visual == null:
		return
	
	if level >= 2:
		visual.mesh = BoxMesh.new()
	else:
		visual.mesh = SphereMesh.new()
	# Material override persists across mesh swap, preserving albedo color.
