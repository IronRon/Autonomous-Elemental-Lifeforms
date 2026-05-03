# Lightweight stats container for a lifeform.
# Useful as a single data node for copy/apply workflows.
extends Node

enum ElementType { Fire, Wind, Water, Earth, AntiMagic }

@export var element_type: ElementType = ElementType.Fire
@export var level: int = 1
@export var visual_color: Color = Color(1, 0.3019608, 1, 1)
@export var size_multiplier: float = 1.0
@export var strength: float = 1.0
@export var speed_multiplier: float = 1.0


func copy_from_lifeform(lifeform: Node) -> void:
	# Pull current values from the root lifeform script.
	if lifeform == null:
		return

	if "element_type" in lifeform:
		element_type = lifeform.element_type
	if "level" in lifeform:
		level = lifeform.level
	if "visual_color" in lifeform:
		visual_color = lifeform.visual_color
	if "size_multiplier" in lifeform:
		size_multiplier = lifeform.size_multiplier
	if "strength" in lifeform:
		strength = lifeform.strength
	if "speed_multiplier" in lifeform:
		speed_multiplier = lifeform.speed_multiplier


func apply_to_lifeform(lifeform: Node) -> void:
	# Push this stats node values back to the root lifeform script.
	if lifeform == null:
		return

	if "element_type" in lifeform:
		lifeform.element_type = element_type
	if "level" in lifeform:
		lifeform.level = level
	if "visual_color" in lifeform:
		lifeform.visual_color = visual_color
	if "size_multiplier" in lifeform:
		lifeform.size_multiplier = size_multiplier
	if "strength" in lifeform:
		lifeform.strength = strength
	if "speed_multiplier" in lifeform:
		lifeform.speed_multiplier = speed_multiplier
