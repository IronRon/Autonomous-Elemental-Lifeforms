# Mana orb resource pickup.
# A StaticBody3D with a child PickupArea (Area3D) that grants energy to colliding lifeforms.
# When picked up, notifies the lifeform's brain to exit seek mode and plays a short
# pickup flash before freeing itself.
class_name ManaOrb
extends StaticBody3D

@export var energy_amount: int = 1
@export var pulse_speed: float = 3.0
@export var pulse_scale_amount: float = 0.12
@export var glow_energy: float = 1.6
@export var pickup_flash_time: float = 0.22

var _base_scale: Vector3
var _base_light_energy: float = 1.0
var _orb_material: StandardMaterial3D
var _outline_material: StandardMaterial3D
var _is_picked_up: bool = false

@onready var orb_mesh: MeshInstance3D = get_node_or_null("MeshInstance3D")
@onready var outline_mesh: MeshInstance3D = get_node_or_null("OutlineMesh")
@onready var glow_light: OmniLight3D = get_node_or_null("GlowLight")
@onready var pickup_area: Area3D = get_node_or_null("PickupArea")
@onready var body_collision_shape: CollisionShape3D = get_node_or_null("CollisionShape3D")

func _ready():
	_base_scale = scale
	_setup_visuals()

	# Use a small child Area3D as the pickup trigger so the orb remains a physics body
	# (detectable by Area.get_overlapping_bodies()).
	if pickup_area:
		pickup_area.body_entered.connect(Callable(self, "_on_body_entered"))


func _process(_delta: float) -> void:
	if _is_picked_up:
		return

	var pulse = (sin(Time.get_ticks_msec() * 0.001 * pulse_speed) + 1.0) * 0.5
	var pulse_scale = 1.0 + pulse * pulse_scale_amount
	scale = _base_scale * pulse_scale

	if glow_light:
		glow_light.light_energy = _base_light_energy * (0.75 + pulse * 0.5)

	if _orb_material:
		_orb_material.emission_energy_multiplier = glow_energy * (0.75 + pulse * 0.4)


func _on_body_entered(body: Node) -> void:
	if _is_picked_up:
		return
	if body == null:
		return
	if body.has_method("add_attack_energy"):
		_is_picked_up = true

		# Notify the lifeform's brain so it can cancel Seek immediately.
		var brain = null
		if body.has_node("LifeformBrain"):
			brain = body.get_node("LifeformBrain")
		if brain and brain.has_method("on_orb_picked"):
			brain.on_orb_picked(self)
		body.add_attack_energy(energy_amount)
		_play_pickup_flash()


func _setup_visuals() -> void:
	if orb_mesh:
		_orb_material = _get_unique_material(orb_mesh)
		if _orb_material:
			_orb_material.albedo_color = Color(0.25, 0.8, 1.0, 1.0)
			_orb_material.emission_enabled = true
			_orb_material.emission = Color(0.25, 0.8, 1.0, 1.0)
			_orb_material.emission_energy_multiplier = glow_energy
			_orb_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	if outline_mesh:
		_outline_material = _get_unique_material(outline_mesh)
		outline_mesh.visible = false
		if _outline_material:
			_outline_material.albedo_color = Color(0.75, 0.95, 1.0, 0.0)
			_outline_material.emission_enabled = true
			_outline_material.emission = Color(0.75, 0.95, 1.0, 1.0)
			_outline_material.emission_energy_multiplier = glow_energy * 1.4
			_outline_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	if glow_light:
		_base_light_energy = glow_light.light_energy


func _get_unique_material(mesh_instance: MeshInstance3D) -> StandardMaterial3D:
	var material = mesh_instance.material_override
	if material == null and mesh_instance.mesh:
		material = mesh_instance.mesh.surface_get_material(0)
	if material is StandardMaterial3D:
		var unique_material = material.duplicate() as StandardMaterial3D
		mesh_instance.material_override = unique_material
		return unique_material
	return null


func _play_pickup_flash() -> void:
	remove_from_group("mana_orbs")
	if pickup_area:
		pickup_area.set_deferred("monitoring", false)
		pickup_area.set_deferred("monitorable", false)
	if body_collision_shape:
		body_collision_shape.set_deferred("disabled", true)

	if outline_mesh:
		outline_mesh.visible = true
	if _outline_material:
		_outline_material.albedo_color = Color(0.75, 0.95, 1.0, 0.75)
	if _orb_material:
		_orb_material.emission_energy_multiplier = glow_energy * 3.0
	if glow_light:
		glow_light.light_energy = _base_light_energy * 3.0

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", _base_scale * 1.8, pickup_flash_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if _outline_material:
		tween.tween_property(_outline_material, "albedo_color", Color(0.75, 0.95, 1.0, 0.0), pickup_flash_time)
	if _orb_material:
		tween.tween_property(_orb_material, "albedo_color", Color(0.25, 0.8, 1.0, 0.0), pickup_flash_time)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
