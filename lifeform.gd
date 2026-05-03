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

var _dynamic_material: StandardMaterial3D
@onready var visual: MeshInstance3D = $Visual
@onready var stats_node: Node = $LifeformStats


func _ready() -> void:
	super._ready()
	_apply_configuration()
	_sync_stats_node()


func set_element_type(value: ElementType) -> void:
	element_type = value
	visual_color = _color_for_element(value)
	_apply_configuration()


func set_level(value: int) -> void:
	level = max(1, value)
	_apply_configuration()


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
