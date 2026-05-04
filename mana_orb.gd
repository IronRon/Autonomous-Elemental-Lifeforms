# Mana orb resource pickup.
# A StaticBody3D with a child PickupArea (Area3D) that grants energy to colliding lifeforms.
# When picked up, notifies the lifeform's brain to exit seek mode and frees itself.
class_name ManaOrb
extends StaticBody3D

@export var energy_amount: int = 1

func _ready():
	# Use a small child Area3D as the pickup trigger so the orb remains a physics body
	# (detectable by Area.get_overlapping_bodies()).
	var pickup = get_node_or_null("PickupArea")
	if pickup:
		pickup.body_entered.connect(Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body == null:
		return
	if body.has_method("add_attack_energy"):
		# Notify the lifeform's brain so it can cancel Seek immediately.
		var brain = null
		if body.has_node("LifeformBrain"):
			brain = body.get_node("LifeformBrain")
		if brain and brain.has_method("on_orb_picked"):
			brain.on_orb_picked(self)
		body.add_attack_energy(energy_amount)
		queue_free()
