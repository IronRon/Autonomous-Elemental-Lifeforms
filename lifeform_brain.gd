# High-level behavior coordinator for each lifeform.
# Chooses between default wander and follower formation logic.
extends Node

var boid

@export var same_element_only: bool = true
@export var same_level_only: bool = true
@export var formation_offset_x: float = 1.5
@export var formation_offset_z: float = -1.5

var current_mode: String = ""
var current_partner: Boid
var leader_boid: Boid
var follower_slot: int = -1

const MODE_WANDER = "wander"
const MODE_LEADER = "leader"
const MODE_FOLLOWER = "follower"

const SLOT_LEFT = 0
const SLOT_RIGHT = 1

# Shared slot table so each leader can reserve only two followers.
static var leader_slots: Dictionary = {}

func _ready():
	boid = get_parent() # CharacterBody3D with boid.gd
	set_physics_process(true)
	_set_wander_mode()


func _physics_process(delta):
	if boid == null:
		return

	# Sticky follower mode: once following, keep following until leader is invalid.
	if current_mode == MODE_FOLLOWER:
		_follow_leader_only()
		return

	var partner = _find_same_element_partner()
	if partner == null:
		_set_wander_mode()
		return

	if _is_leader_for(partner):
		_set_leader_mode()
	else:
		_set_follower_mode(partner)


func _exit_tree() -> void:
	_release_slot()

func see_enemy(enemy):
	boid.set_enabled_all(false)
	boid.get_node("Flee").enabled = true
	boid.get_node("Flee").enemy_boid = enemy

func see_ally_to_merge(ally):
	boid.set_enabled_all(false)
	boid.get_node("Seek").enabled = true
	boid.get_node("Seek").target = ally


func _find_same_element_partner():
	# Pick the nearest compatible non-follower in detection range.
	var detection_area = boid.get_node_or_null("DetectionArea")
	if detection_area == null:
		return null

	var best_partner: Boid = null
	var best_distance = INF
	for body in detection_area.get_overlapping_bodies():
		if body == boid:
			continue
		if not (body is Boid):
			continue
		if not _is_compatible(body):
			continue

		var other_brain = body.get_node_or_null("LifeformBrain")
		if other_brain and other_brain.current_mode == MODE_FOLLOWER:
			continue
		if same_element_only and body.element_type != boid.element_type:
			continue
		if same_level_only and body.level != boid.level:
			continue

		var distance = boid.global_transform.origin.distance_to(body.global_transform.origin)
		if distance < best_distance:
			best_distance = distance
			best_partner = body

	return best_partner


func _is_leader_for(partner: Boid) -> bool:
	return boid.get_instance_id() < partner.get_instance_id()


func _is_compatible(other: Boid) -> bool:
	if other == null:
		return false
	if same_element_only and other.element_type != boid.element_type:
		return false
	if same_level_only and other.level != boid.level:
		return false
	return true


func _set_wander_mode() -> void:
	if current_mode == MODE_FOLLOWER:
		return
	if current_mode == "wander" and current_partner == null:
		return
	current_mode = MODE_WANDER
	current_partner = null
	boid.set_enabled_all(false)
	boid.get_node("Wander").enabled = true


func _set_leader_mode() -> void:
	if current_mode == MODE_FOLLOWER:
		return
	if current_mode == MODE_LEADER and current_partner == null:
		return
	current_mode = MODE_LEADER
	current_partner = null
	boid.set_enabled_all(false)
	boid.get_node("Wander").enabled = true


func _set_follower_mode(partner: Boid) -> void:
	if partner == null:
		return

	var slot = _claim_slot(partner)
	if slot == -1:
		return

	if current_mode == MODE_FOLLOWER and current_partner == partner and follower_slot == slot:
		return

	_release_slot()
	current_mode = MODE_FOLLOWER
	current_partner = partner
	leader_boid = partner
	follower_slot = slot
	boid.set_enabled_all(false)
	var offset_pursue = boid.get_node("OffsetPursue")
	offset_pursue.use_custom_offset = true
	offset_pursue.custom_offset_local = _slot_to_offset(slot)
	offset_pursue.leader_boid = partner
	offset_pursue.calculate_offset()
	offset_pursue.enabled = true


func _follow_leader_only() -> void:
	var offset_pursue = boid.get_node("OffsetPursue")
	boid.set_enabled_all(false)
	offset_pursue.enabled = true

	if is_instance_valid(leader_boid) and _is_compatible(leader_boid):
		offset_pursue.use_custom_offset = true
		offset_pursue.custom_offset_local = _slot_to_offset(follower_slot)
		offset_pursue.leader_boid = leader_boid
		offset_pursue.calculate_offset()
		return

	# Leader is gone (or no longer compatible): return to default wandering behavior.
	offset_pursue.leader_boid = null
	offset_pursue.enabled = false
	_release_slot()
	current_mode = MODE_WANDER
	current_partner = null
	_set_wander_mode()


func _slot_to_offset(slot: int) -> Vector3:
	# Two formation anchors behind the leader: left and right diagonal.
	if slot == SLOT_RIGHT:
		return Vector3(formation_offset_x, 0.0, formation_offset_z)
	return Vector3(-formation_offset_x, 0.0, formation_offset_z)


func _claim_slot(leader: Boid) -> int:
	if leader == null:
		return -1
	var leader_id = leader.get_instance_id()
	if not leader_slots.has(leader_id):
		leader_slots[leader_id] = {"left": 0, "right": 0}

	var slots = leader_slots[leader_id]
	var my_id = boid.get_instance_id()

	if slots.left == my_id:
		return SLOT_LEFT
	if slots.right == my_id:
		return SLOT_RIGHT

	if slots.left == 0:
		slots.left = my_id
		leader_slots[leader_id] = slots
		return SLOT_LEFT
	if slots.right == 0:
		slots.right = my_id
		leader_slots[leader_id] = slots
		return SLOT_RIGHT

	return -1


func _release_slot() -> void:
	if leader_boid == null:
		return
	var leader_id = leader_boid.get_instance_id()
	if not leader_slots.has(leader_id):
		leader_boid = null
		follower_slot = -1
		return

	var slots = leader_slots[leader_id]
	var my_id = boid.get_instance_id()
	if slots.left == my_id:
		slots.left = 0
	if slots.right == my_id:
		slots.right = 0

	leader_slots[leader_id] = slots
	leader_boid = null
	follower_slot = -1
