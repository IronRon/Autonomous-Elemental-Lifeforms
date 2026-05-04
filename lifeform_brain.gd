# High-level behavior coordinator for each lifeform.
# Chooses between default wander and follower formation logic.
# Also manages evolution: when a leader has 2 followers, merges all 3 into 1 level-2 lifeform.
extends Node

var boid

@export var same_element_only: bool = true
@export var same_level_only: bool = true
@export var formation_offset_x: float = 1.5
@export var formation_offset_z: float = -1.5
@export var lifeform_scene_path: String = "res://lifeform.tscn"
@export var merge_check_interval: float = 10.0
@export var threat_detection_radius: float = 10.0  # Reuses DetectionArea for predator detection
@export var level_fear_threshold: int = 0  # Flee if predator.level >= self.level + threshold

var _merge_check_timer: float = 0.0

var current_mode: String = ""
var current_partner: Boid
var leader_boid: Boid
var follower_slot: int = -1
var current_threat: Boid = null  # The predator we're fleeing from
var current_prey: Boid = null  # The prey we're pursuing

const MODE_WANDER = "wander"
const MODE_LEADER = "leader"
const MODE_FOLLOWER = "follower"
const MODE_SEEK = "seek"
const MODE_PURSUE = "pursue"
const MODE_FLEE = "flee"

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

	# Check for threats (predators) in DetectionArea - prioritize threat avoidance.
	# If we're not currently fleeing or pursuing, and we detect a predator, switch modes.
	if current_mode != MODE_FLEE and current_mode != MODE_PURSUE:
		var predator = _find_nearest_predator()
		if predator != null:
			_set_flee_mode(predator)
			return

	# Check for prey (for anti-magic lifeforms).
	# If we're anti-magic and not already pursuing, find prey in DetectionArea.
	if boid.element_type == boid.ElementType.AntiMagic and current_mode != MODE_PURSUE:
		var prey = _find_nearest_prey()
		if prey != null:
			_set_pursue_mode(prey)
			return

	# If Seek is active but its target was removed (orb picked), return to wandering.
	var seek_check = boid.get_node_or_null("Seek")
	if seek_check and seek_check.enabled:
		var t = seek_check.target
		if t == null or not is_instance_valid(t):
			_set_wander_mode()
			return

	# Resource-seeking behavior: if wandering and below max energy, seek the nearest mana orb.
	# This allows lifeforms to proactively collect resources to maintain attack_energy.
	if current_mode == MODE_WANDER and boid.attack_energy < boid.max_attack_energy:
		var orb = _find_nearest_mana_orb()
		if orb:
			boid.set_enabled_all(false)
			var seek = boid.get_node("Seek")
			seek.target = orb
			seek.enabled = true
			current_mode = MODE_SEEK
			return
	
	# Stable seeking mode: stay in seek until orb is picked or destroyed.
	# Prevents oscillation between seek and wander by holding mode until on_orb_picked() is called.
	if current_mode == MODE_SEEK:
		return
	
	# Pursuit mode: chase the prey until it's out of range or destroyed.
	if current_mode == MODE_PURSUE:
		_pursue_prey_only()
		return
	
	# Flee mode: escape from the predator until it's out of range or destroyed.
	if current_mode == MODE_FLEE:
		_flee_from_threat_only()
		return
	
	# print(boid, current_mode)
	# Sticky follower mode: once following, keep following until leader is invalid.
	if current_mode == MODE_FOLLOWER:
		_follow_leader_only()
		return

	# If we're already a leader, continuously check for merge conditions.
	if current_mode == MODE_LEADER:
		# Run merge checks on a timer to avoid costly every-frame checks and accidental rapid merges.
		_merge_check_timer -= delta
		if _merge_check_timer <= 0.0:
			_check_for_merge_from_leader()
			_merge_check_timer = max(0.001, merge_check_interval)

		# If we already have any followers assigned, remain leader (don't fall back to wander).
		if _has_any_followers():
			return

		# No current followers; still try to detect partners for new leader/follower transitions.
		var partner = _find_same_element_partner()
		if partner == null:
			_set_wander_mode()
			return
		if _is_leader_for(partner):
			_set_leader_mode()
		else:
			_set_follower_mode(partner)
		return

	# Not following nor leader yet: try to find a partner.
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


func on_orb_picked(orb: Node) -> void:
		"""Called by a ManaOrb when picked up by this lifeform.
		Transitions from MODE_SEEK back to wander after energy is gained."""
		_set_wander_mode()


func clear_threat_reference(threat: Node) -> void:
	# Called when a threat is freed so flee mode can release stale targets.
	if current_threat == threat:
		current_threat = null
		var flee = boid.get_node_or_null("Flee")
		if flee:
			flee.enemy_boid = null
		if current_mode == MODE_FLEE:
			_set_wander_mode()


func clear_prey_reference(prey: Node) -> void:
	# Called when a prey is freed so pursuit mode can release stale targets.
	if current_prey == prey:
		current_prey = null
		var pursue = boid.get_node_or_null("Pursue")
		if pursue:
			pursue.enemy_boid = null
		if current_mode == MODE_PURSUE:
			_set_wander_mode()


func on_lifeform_death() -> void:
	# Called when the lifeform this brain controls dies.
	current_partner = null
	leader_boid = null
	current_threat = null
	current_prey = null


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


func _find_nearest_mana_orb():
		"""Find the closest mana orb in the resource detection range.
		Returns the nearest ManaOrb (StaticBody3D) or null if none found."""
		var detection_area = boid.get_node_or_null("ResourceDetection")
		if detection_area == null:
			return null
		
		var best_orb = null
		var best_distance = INF
		# ManaOrbs are StaticBody3D nodes with a PickupArea child; detected via get_overlapping_bodies().
		for body in detection_area.get_overlapping_bodies():
			if body == boid:
				continue
			# Check for ManaOrb by type or by method presence (energy_amount) for compatibility.
			var distance = boid.global_transform.origin.distance_to(body.global_transform.origin)
			if distance < best_distance:
				best_distance = distance
				best_orb = body
			return best_orb


func _find_nearest_predator() -> Boid:
	"""Find the closest anti-magic lifeform in detection range that poses a threat.
	Returns the predator (Boid) or null if none found. Threat determined by:
	- Must be anti-magic element type
	- Must be equal or higher level than self (adjusted by level_fear_threshold)"""
	var detection_area = boid.get_node_or_null("DetectionArea")
	if detection_area == null:
		return null
	
	var best_predator: Boid = null
	var best_distance = INF
	
	for body in detection_area.get_overlapping_bodies():
		if body == boid:
			continue
		if not (body is Boid):
			continue
		
		# Only anti-magic lifeforms are predators.
		if body.element_type != boid.ElementType.AntiMagic:
			continue
		
		# Only consider lifeforms that are strong enough to be a threat.
		# Default threshold 0: flee if predator.level >= self.level
		# Threshold 1: flee only if predator.level > self.level (true equal is ok)
		if body.level < (boid.level + level_fear_threshold):
			continue
		
		var distance = boid.global_transform.origin.distance_to(body.global_transform.origin)
		if distance < best_distance:
			best_distance = distance
			best_predator = body
	
	return best_predator


func _find_nearest_prey() -> Boid:
	"""Find the closest non-anti-magic lifeform in detection range for this anti-magic predator to pursue.
	Returns the prey (Boid) or null if none found. Only valid when called on anti-magic lifeforms."""
	var detection_area = boid.get_node_or_null("DetectionArea")
	if detection_area == null:
		return null
	
	var best_prey: Boid = null
	var best_distance = INF
	
	for body in detection_area.get_overlapping_bodies():
		if body == boid:
			continue
		if not (body is Boid):
			continue
		
		# Skip other anti-magic lifeforms (they are peers, not prey).
		if body.element_type == boid.ElementType.AntiMagic:
			continue
		
		# Skip lifeforms that are already following someone (potentially allied).
		var other_brain = body.get_node_or_null("LifeformBrain")
		if other_brain and other_brain.current_mode == MODE_FOLLOWER:
			continue
		
		var distance = boid.global_transform.origin.distance_to(body.global_transform.origin)
		if distance < best_distance:
			best_distance = distance
			best_prey = body
	
	return best_prey


## Helper: slot management and follower resolution
## These functions manage the two reserved follower slots for a leader. Followers claim
## a slot when they enter follower mode. Leaders consult these slots to determine
## whether they should stay in leader mode and when to attempt merges.


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
	if current_mode == MODE_WANDER and current_partner == null:
		return
	current_mode = MODE_WANDER
	current_partner = null
	current_threat = null
	current_prey = null
	boid.set_enabled_all(false)
	boid.get_node("Wander").enabled = true


func _set_leader_mode() -> void:
	if current_mode == MODE_FOLLOWER:
		return
	if current_mode == MODE_LEADER and current_partner == null:
		return
	current_mode = MODE_LEADER
	current_partner = null
	current_threat = null
	current_prey = null
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
	current_threat = null
	current_prey = null
	leader_boid = partner
	follower_slot = slot
	boid.set_enabled_all(false)
	var offset_pursue = boid.get_node("OffsetPursue")
	offset_pursue.use_custom_offset = true
	offset_pursue.custom_offset_local = _slot_to_offset(slot)
	offset_pursue.leader_boid = partner
	offset_pursue.calculate_offset()
	offset_pursue.enabled = true


func _set_pursue_mode(prey: Boid) -> void:
	"""Enter pursuit mode targeting the given prey lifeform.
	Anti-magic lifeforms use Pursue behavior to chase down non-anti-magic targets."""
	if prey == null:
		return
	
	if current_mode == MODE_PURSUE and current_prey == prey:
		return
	
	current_mode = MODE_PURSUE
	current_partner = null
	current_threat = null
	current_prey = prey
	boid.set_enabled_all(false)
	var pursue = boid.get_node("Pursue")
	pursue.enemy_boid = prey
	pursue.enabled = true


func _set_flee_mode(threat: Boid) -> void:
	"""Enter flee mode to escape from the given predator lifeform.
	Uses Flee behavior to maintain distance from anti-magic threats."""
	if threat == null:
		return
	
	if current_mode == MODE_FLEE and current_threat == threat:
		return
	
	current_mode = MODE_FLEE
	current_partner = null
	current_threat = threat
	current_prey = null
	boid.set_enabled_all(false)
	var flee = boid.get_node("Flee")
	flee.enemy_boid = threat
	flee.enabled = true


func _pursue_prey_only() -> void:
	"""Maintain pursuit mode. Exit if prey is invalid or out of range."""
	var pursue = boid.get_node("Pursue")
	boid.set_enabled_all(false)
	pursue.enabled = true
	
	# If prey is gone or no longer a valid target, return to wander.
	if not is_instance_valid(current_prey):
		_set_wander_mode()
		return
	
	# If prey left detection range, return to wander.
	var detection_area = boid.get_node_or_null("DetectionArea")
	if detection_area:
		var in_range = false
		for body in detection_area.get_overlapping_bodies():
			if body == current_prey:
				in_range = true
				break
		if not in_range:
			_set_wander_mode()
			return
	
	# Still pursuing: update target in case it changed direction.
	pursue.enemy_boid = current_prey


func _flee_from_threat_only() -> void:
	"""Maintain flee mode. Exit if threat is invalid or out of range."""
	var flee = boid.get_node("Flee")
	boid.set_enabled_all(false)
	flee.enabled = true
	
	# If threat is gone or no longer a valid target, return to wander.
	if not is_instance_valid(current_threat):
		_set_wander_mode()
		return
	
	# If threat left detection range, return to wander.
	var detection_area = boid.get_node_or_null("DetectionArea")
	if detection_area:
		var in_range = false
		for body in detection_area.get_overlapping_bodies():
			if body == current_threat:
				in_range = true
				break
		if not in_range:
			_set_wander_mode()
			return
	
	# Still fleeing: update enemy in case they changed direction.
	flee.enemy_boid = current_threat


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
	current_threat = null
	current_prey = null
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

	# Note: followers call _release_slot() when they stop following (or when freed).


func _get_follower_at_slot(slot: int) -> Boid:
	# Retrieve the follower occupying a specific slot for this leader.
	var my_id = boid.get_instance_id()
	if not leader_slots.has(my_id):
		return null
	
	var slots = leader_slots[my_id]
	var slot_follower_id = slots.get("left") if slot == SLOT_LEFT else slots.get("right")
	
	if slot_follower_id == 0:
		return null
	
	# Find the lifeform with this instance ID in the detection area.
	var detection_area = boid.get_node_or_null("DetectionArea")
	if detection_area == null:
		return null
	
	for body in detection_area.get_overlapping_bodies():
		if body.get_instance_id() == slot_follower_id and body is Boid:
			return body
	
	return null


func _has_any_followers() -> bool:
	# Returns true if this lifeform (as a leader) currently has any reserved follower slots.
	# This is used so a leader will remain in leader mode while followers are attached,
	# preventing a premature fallback to wandering when the temporary partner used for
	# leader discovery disappears.
	var my_id = boid.get_instance_id()
	if not leader_slots.has(my_id):
		return false
	var slots = leader_slots[my_id]
	if slots.get("left", 0) != 0:
		return true
	if slots.get("right", 0) != 0:
		return true
	return false


func _check_for_merge_from_leader() -> void:
	# Only the leader checks if it has 2 valid followers, then merges all 3.
	if current_mode != MODE_LEADER:
		return
	
	var left_follower = _get_follower_at_slot(SLOT_LEFT)
	var right_follower = _get_follower_at_slot(SLOT_RIGHT)
	# print("11left: ", left_follower,"right: ", right_follower)
	if left_follower != null and right_follower != null:
		# print("left: ", left_follower,"right: ", right_follower)
		if left_follower.level == 1 and right_follower.level == 1:
			_perform_merge([boid, left_follower, right_follower])


func _perform_merge(group: Array) -> void:
	# Merge 3 level-1 lifeforms into 1 level-2 lifeform.
	# Calculate average position.
	var new_pos = Vector3.ZERO
	for lifeform in group:
		if lifeform != null:
			new_pos += lifeform.global_position
	new_pos /= float(group.size())
	
	# Load and instantiate new level-2 lifeform.
	var scene = load(lifeform_scene_path)
	if scene == null:
		push_error("Failed to load lifeform scene at: ", lifeform_scene_path)
		return
	
	var new_lifeform = scene.instantiate()
	if boid.get_parent() == null:
		return
	
	# Copy element type from the first lifeform and set to level 2.
	var first_lifeform = group[0]
	new_lifeform.element_type = first_lifeform.element_type
	new_lifeform.level = 2
	new_lifeform.size_multiplier = 1.5  # Scale up for level 2.
	new_lifeform.speed_multiplier = 0.8  # Slightly slower for larger lifeform.
	new_lifeform.strength = 1.2  # Stronger merged lifeform.
	
	new_lifeform.global_position = new_pos
	boid.get_parent().add_child(new_lifeform)
	
	# Clean up the 3 originals.
	for lifeform in group:
		if lifeform != null:
			lifeform.queue_free()
