# Brain, Behaviors, And Evolution

## Purpose

`lifeform_brain.gd` is the high-level decision system for each lifeform. It decides which steering behavior should be active, manages leader/follower group formation, handles evolution merges, and controls predator/prey logic.

Main script:

- `lifeform_brain.gd`

Core behavior scripts:

- `behaviors/boid.gd`
- `behaviors/steering_behavior.gd`
- `behaviors/wander.gd`
- `behaviors/seek.gd`
- `behaviors/Flee.gd`
- `behaviors/pursue.gd`
- `behaviors/offset_pursue.gd`
- `behaviors/constrain.gd`
- `behaviors/avoidance.gd`
- `behaviors/arrive.gd`

## Behavior Modes

`lifeform_brain.gd` uses string constants for modes:

- `MODE_WANDER`: default movement.
- `MODE_LEADER`: leads a group and checks merge opportunities.
- `MODE_FOLLOWER`: follows a leader using offset pursue.
- `MODE_SEEK`: seeks mana orbs.
- `MODE_PURSUE`: AntiMagic pursues non-AntiMagic prey.
- `MODE_FLEE`: non-AntiMagic flees AntiMagic predators.
- `MODE_COUNTER_ATTACK`: fleeing lifeform turns toward a predator when close enough.
- `MODE_PLAYER_ATTRACT`: temporary player pulse makes lifeforms seek a point.
- `MODE_PLAYER_REPEL`: temporary player pulse makes lifeforms flee a point.

## Important Exported Values

- `same_element_only`: compatible partners must share element.
- `same_level_only`: compatible partners usually need same level.
- `allow_mixed_level_3_merge`: allows level 2 + level 1/2 groups to merge into level 3.
- `max_evolution_level`: current cap, default 3.
- `formation_offset_x`: sideways follower offset.
- `formation_offset_z`: backward follower offset.
- `lifeform_scene_path`: scene path used when spawning evolved lifeforms.
- `merge_check_interval`: seconds between merge checks while leader.
- `threat_detection_radius`: documented predator/prey radius. Detection currently uses `DetectionArea`.
- `level_fear_threshold`: controls when normal elements fear AntiMagic.
- `aggro_radius`: distance at which fleeing lifeforms counter-attack.
- `evolution_sound`: sound played at merge position.
- `evolution_sound_volume_db`: volume for evolution sound.

## Main Decision Flow

`_physics_process(delta)` runs the mode selection.

Priority order:

1. Invalid/forced cleanup checks.
2. Active player attract/repel influence.
3. Threat detection for non-AntiMagic.
4. Prey detection for AntiMagic.
5. Mana seek target validity.
6. Mana seeking when wandering and below max energy.
7. Active pursue/counter/flee continuation.
8. Active follower continuation.
9. Active leader merge checks.
10. Partner search for new formation.

This priority order means combat and temporary player influence can interrupt normal grouping.

## Always-On Behaviors

`_enable_always_on_behaviors()` enables:

- `Constrain`
- `Avoidance`

The brain calls `boid.set_enabled_all(false)` when changing modes, then re-enables these support behaviors. This makes the lifeforms obey arena boundaries and obstacle avoidance in every state.

## Formation Logic

Same-element lifeforms can form a leader/follower group.

Important functions:

- `_find_same_element_partner()`: searches nearby bodies in `DetectionArea`.
- `_is_compatible(other)`: validates element and level compatibility.
- `_is_leader_for(partner)`: chooses leader by level first, then instance ID.
- `_claim_slot(leader)`: reserves left or right follower slot.
- `_release_slot()`: frees a follower slot.
- `_follow_leader_only()`: keeps follower attached to leader until invalid.

Followers use `OffsetPursue` with one of two custom offsets:

- Left slot: `Vector3(-formation_offset_x, 0, formation_offset_z)`
- Right slot: `Vector3(formation_offset_x, 0, formation_offset_z)`

## Evolution Logic

Evolution is leader-driven. Only a leader checks whether it has two valid followers.

Important functions:

- `_check_for_merge_from_leader()`
- `_get_merge_target_level(group)`
- `_is_valid_merge_group(group)`
- `_perform_merge(group, target_level)`
- `_apply_evolution_defaults(new_lifeform, target_level)`
- `_play_evolution_sound(sound_position)`

Level 2 merge:

- group size must be 3
- same element
- leader is level 1
- all group members are level 1
- result is one level 2 lifeform

Level 3 merge:

- group size must be 3
- same element
- leader is level 2
- followers can be level 1 or level 2 when mixed merge is enabled
- result is one level 3 lifeform

Merge result:

1. Average position is calculated.
2. `lifeform.tscn` is loaded from `lifeform_scene_path`.
3. New lifeform copies element and target level.
4. Level defaults are applied.
5. New lifeform is added to the same parent.
6. Simulation manager records the evolution.
7. Evolution sound plays.
8. Original three lifeforms are freed.

## Predator / Prey Logic

AntiMagic:

- searches for nearest non-AntiMagic prey using `_find_nearest_prey()`
- skips other AntiMagic
- skips active followers
- enters `MODE_PURSUE`

Normal elements:

- search for AntiMagic predators using `_find_nearest_predator()`
- only fear predators meeting `level_fear_threshold`
- enter `MODE_FLEE`
- if predator enters `aggro_radius`, switch to `MODE_COUNTER_ATTACK`

## Player Influence Logic

Player pulses call:

- `apply_player_influence(target, mode, duration)`

This stores a temporary target and timer. While active:

- attract mode enables `Seek` toward the pulse point
- repel mode enables `Flee` away from the pulse point

When the timer ends or the pulse node is freed, the lifeform returns to wander.

## Steering Behaviors Summary

### `Boid`

Combines active steering forces, clamps force, updates velocity, moves with `move_and_slide()`, and resolves slide collisions.

Important values:

- `mass`
- `max_speed`
- `max_force`
- `banking`
- `damping`
- `combat_collision_cooldown`

### `Wander`

Generates default roaming behavior.

### `Seek`

Moves toward a target node or world target.

### `Flee`

Moves away from an enemy node within `flee_range`.

### `Pursue`

Predicts target future position using target velocity and distance, then seeks the projected point.

### `OffsetPursue`

Follows a projected offset around a leader and uses `arrive_force()` for smoother formation movement.

### `Constrain`

Applies force back toward the center when outside `radius`.

### `Avoidance`

Uses raycast feelers against `boid.collision_mask` to produce obstacle avoidance force.

## Tuning Notes

- Lower `merge_check_interval` for faster visible evolution.
- Increase `social_detection_radius` on lifeforms to make grouping easier.
- Decrease `formation_offset_x/z` to make followers stay close enough for obvious merge formations.
- Increase AntiMagic speed for more combat.
- Increase `aggro_radius` to make normal elements counter-attack sooner and collide more often.
- Avoid making `Avoidance.weight` too high or lifeforms may refuse to approach cluttered areas.
