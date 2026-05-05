# Current Functionality Snapshot

This document summarizes what is currently implemented for the autonomous lifeform simulation prototype.

## Project Overview
- The project is a 3D Godot autonomous agents simulation.
- Elemental lifeforms use boid-style steering to wander, seek resources, form groups, evolve, flee, pursue, collide, and die.
- The main demo scene is `world.tscn`.
- The current simulation includes:
  - procedural lifeform visuals for levels 1, 2, and 3
  - mana orb resources
  - environment collision, avoidance, and arena constraint
  - safe random spawning
  - mana relocation
  - combat effects
  - sound effects and background music
  - a stats UI
  - simple player mana-orb spawning

## Main Scene Node Structure (`lifeform.tscn`)
- `Lifeform` (`CharacterBody3D`) with script `lifeform.gd`
- `CollisionShape3D`
- `Visual` (`MeshInstance3D`)
  - Main body mesh, changed procedurally by level:
    - Level 1: sphere
    - Level 2: box
    - Level 3+: capsule
  - `EvolutionVisualRoot`
    - Empty runtime root kept for future evolved visual experiments.
    - Current code clears any children and uses procedural meshes instead of imported model scenes.
  - Face meshes:
    - `LeftEye`
    - `RightEye`
    - `Mouth`
  - Element accessory meshes:
    - `FireCrest`
    - `WindWingLeft`
    - `WindWingRight`
    - `WaterDrop`
    - `EarthPebbleLeft`
    - `EarthPebbleRight`
    - `AntiHornLeft`
    - `AntiHornRight`
- `DetectionArea` (`Area3D`) for social/combat detection
- `ResourceDetection` (`Area3D`) for mana orb detection
- `LifeformBrain` (`Node`) with script `lifeform_brain.gd`
- Steering behavior nodes:
  - `Constrain`
  - `Avoidance`
  - `Wander`
  - `Seek`
  - `Arrive`
  - `Flee`
  - `Pursue`
  - `OffsetPursue`
- `LifeformStats` (`Node`) with script `lifeform_stats.gd`
- `TrailParticles` (`GPUParticles3D`)
- `DeathBurstParticles` (`GPUParticles3D`)
- `CollisionBurstParticles` (`GPUParticles3D`)
- `DeathSound` (`AudioStreamPlayer3D`)
- `CollisionSound` (`AudioStreamPlayer3D`)

## World / Environment (`world.tscn`)
- Main world scene instances a separate `environment.tscn` scene.
- Current environment uses KayKit-style low-poly assets and user-added floating rocks.
- Environment collision is expected on layer 2 so lifeforms can avoid obstacles and spawn checks can reject blocked positions.
- `WorldEnvironment` has glow enabled so mana orbs and emissive effects read better.
- `ObserverCamera` uses `camera_free_fly.gd` for free-fly inspection.
- `BackgroundMusic` plays quiet looping background audio through `background_music.gd`.
- `SimulationStatsUI` displays live simulation statistics.

## Collision Layer / Mask Conventions
- Layer 1: lifeforms.
- Layer 2: environment / obstacle collision.
- Layer 3: mana orbs.
- Lifeform root collision mask includes environment obstacles for physical movement and avoidance.
- `ResourceDetection` uses the mana-orb layer so lifeforms detect orbs separately from other lifeforms.
- `ManaOrb` root uses the mana-orb collision layer.
- Environment meshes must have physics bodies/collision shapes. Avoidance reacts to collision, not visual mesh surfaces by themselves.

## `lifeform.gd` Root Controller
- Extends `Boid`.
- Exposes editable identity and stat properties:
  - `element_type`
  - `level`
  - `visual_color`
  - `size_multiplier`
  - `strength`
  - `speed_multiplier`
  - `base_max_speed`
  - `base_mass`
  - `trail_enabled`
- Applies stat effects to movement/body:
  - `max_speed = base_max_speed * speed_multiplier`
  - `mass = base_mass / strength`
  - `scale = Vector3.ONE * size_multiplier`
- Auto-maps element to color:
  - Fire: red
  - Wind: green
  - Water: blue
  - Earth: brown
  - AntiMagic: black/purple accents
- Updates level-based mesh:
  - Level 1: `SphereMesh`
  - Level 2: `BoxMesh`
  - Level 3+: `CapsuleMesh`
- Updates face placement, accessory placement, trail color, death burst color, and collision burst color when element or level changes.
- Syncs values into the `LifeformStats` node.
- Tracks combat stats:
  - `attack_energy`
  - `max_attack_energy`
  - `health`
  - `collision_impulse_strength`
- Notifies the simulation manager when a lifeform dies.

## Lifeform Visual Design
- Level 1 lifeforms are elemental orb characters.
- Level 2 lifeforms become larger box-shaped evolved forms.
- Level 3 lifeforms become larger capsule-shaped evolved forms.
- Faces and accessories remain visible on all levels and are repositioned/scaled for the active body shape.
- Face layouts are element-specific:
  - Fire: sharper aggressive eyes and mouth.
  - Wind: wider, lighter expression.
  - Water: softer/lower expression.
  - Earth: lower, heavier, grounded expression.
  - AntiMagic: sharp purple-emissive face details.
- Each element has a small accessory:
  - Fire: flame-like crest using a tapered cylinder mesh.
  - Wind: two wing shapes.
  - Water: droplet shape.
  - Earth: two pebble/rock shapes.
  - AntiMagic: two horn shapes using tapered cylinder meshes.

## Particle Effects
- Particle effects are scene-node based in `lifeform.tscn`.
- `TrailParticles`:
  - Lightweight continuous trail attached to each lifeform.
  - Color is updated from the lifeform element.
  - Process material is duplicated per instance so each element can have its own color.
- `DeathBurstParticles`:
  - One-shot burst when a lifeform dies.
  - Reparented to the current scene before the lifeform is freed, allowing the burst to finish.
  - Color is updated from the lifeform element.
- `CollisionBurstParticles`:
  - Small one-shot burst used for combat collisions.
  - Duplicated from a template node per collision.
  - Plays at the midpoint between two colliding lifeforms.
  - Each combatant creates its own colored burst, giving two overlapping elemental bursts.
- Particle draw meshes use materials with `vertex_color_use_as_albedo = true` so `ParticleProcessMaterial.color` shows instead of rendering white.

## Sound Effects
- Mana pickup:
  - `mana_orb.tscn` has `PickupSound` (`AudioStreamPlayer3D`).
  - The sound plays during the pickup flash before the orb frees itself.
- Lifeform death:
  - `lifeform.tscn` has `DeathSound` (`AudioStreamPlayer3D`).
  - The sound is reparented to the current scene so it continues after the dead lifeform is freed.
- Combat collision:
  - `lifeform.tscn` has `CollisionSound` (`AudioStreamPlayer3D`).
  - A duplicate sound player is spawned at the collision midpoint for each combat hit.
- Evolution:
  - `lifeform_brain.gd` exports `evolution_sound`.
  - On merge, it creates a temporary `AudioStreamPlayer3D` at the merge position.
- Background music:
  - `world.tscn` has a quiet `BackgroundMusic` `AudioStreamPlayer`.

## `lifeform_brain.gd` Behavior Selection
- Default mode is `wander`.
- `Constrain` and `Avoidance` are always-on support steering.
  - The brain re-enables them after every behavior reset.
  - Wander, seek, pursue, flee, counter-attack, leader, and follower modes all keep arena and obstacle steering active.
- Finds compatible nearby lifeforms using `DetectionArea`.
- Compatibility is based on:
  - same element
  - level rules for current merge target
- Chooses leader/follower role deterministically using instance IDs.
- Follower behavior:
  - Uses `OffsetPursue`.
  - Claims one of two slots around the leader.
  - Slot offsets are controlled by `formation_offset_x` and `formation_offset_z`.
- If the leader becomes invalid, followers release their slot and return to wander.

## Evolution / Merge
- Evolution is leader-driven.
- A leader checks merge conditions on `merge_check_interval` rather than every frame.
- Level 2 evolution:
  - A level 1 leader with two level 1 same-element followers merges into one level 2 lifeform.
- Level 3 evolution:
  - A level 2 leader with two same-element followers can merge into one level 3 lifeform.
  - Followers can be a mix of level 1 and level 2 when `allow_mixed_level_3_merge` is enabled.
- `max_evolution_level` currently limits evolution to level 3.
- When a merge occurs:
  - new lifeform spawns at the average group position
  - new lifeform copies the element type
  - level-specific defaults are applied
  - evolution sound plays
  - simulation manager records an evolution
  - original lifeforms are freed
- Current evolution defaults:
  - Level 2: `size_multiplier = 1.5`, `speed_multiplier = 0.8`, `strength = 1.2`
  - Level 3: `size_multiplier = 2.2`, `speed_multiplier = 0.65`, `strength = 1.6`, `attack_energy = 3`, `health = 6`

## Mana Orb System
- `ManaOrb` is a `StaticBody3D` with script `mana_orb.gd`.
- It has `energy_amount` export, default `1`.
- Mana orbs are in the `mana_orbs` group.
- Child nodes:
  - `PickupArea`
  - `GlowLight`
  - main mesh
  - `OutlineMesh`
  - `PickupSound`
- Idle animation:
  - smooth scale pulse
  - pulsing light energy
  - pulsing emission energy
- Pickup flow:
  1. Pickup area detects a lifeform.
  2. The orb notifies the lifeform brain with `on_orb_picked(self)`.
  3. The lifeform gains attack energy.
  4. Pickup collision is disabled.
  5. Orb flashes, expands, reveals/fades outline, and fades its material.
  6. Pickup sound plays.
  7. Orb frees itself after the sound has time to finish.
- Lifeforms seek mana orbs when wandering and below max attack energy.

## Simulation Manager
- `SimulationManager` is a world-level node in `world.tscn`.
- Runtime setup is deferred with `call_deferred("_start_simulation")` so children can be added safely after scene setup.
- Configurable exports include:
  - `lifeform_scene`
  - `mana_orb_scene`
  - `spawn_parent_path`
  - `use_evolution_test_spawn`
  - `clear_existing_lifeforms`
  - `clear_existing_mana_orbs`
  - `lifeforms_per_element`
  - `mana_orb_count`
  - `spawn_radius`
  - `spawn_height`
  - `mana_orb_spawn_height`
  - `relocate_mana_orbs`
  - `mana_orb_relocation_interval`
  - `lifeform_clearance_radius`
  - `mana_orb_clearance_radius`
  - `spawn_blocking_collision_mask`
  - `max_spawn_attempts`
  - `random_seed`
  - `player_mana_spawn_enabled`
  - `player_mana_spawn_distance`
  - `player_mana_spawn_clearance_radius`
- Current startup defaults:
  - clears existing lifeforms
  - clears existing mana orbs
  - spawns `lifeforms_per_element` lifeforms for each element, currently 9 per element
  - spawns `mana_orb_count` mana orbs, currently 15
  - places lifeforms and mana orbs randomly within `spawn_radius`
- AntiMagic lifeforms spawned by the manager receive boosted defaults:
  - `base_max_speed = 5.0`
  - `health = 5.0`
- If `random_seed` is 0, spawn placement is randomized each run.
- If `random_seed` is non-zero, spawn placement is repeatable.
- Tracks totals:
  - `total_deaths`
  - `total_evolutions`

## Safe Spawning / Mana Orb Relocation
- Lifeforms and mana orbs use physics overlap checks before accepting random positions.
- Spawn checks use a `SphereShape3D` against `spawn_blocking_collision_mask`, default layer 2.
- Lifeform safe placement uses `lifeform_clearance_radius`.
- Mana orb safe placement uses `mana_orb_clearance_radius`.
- Each placement tries up to `max_spawn_attempts` candidates before falling back to a random position.
- Mana orbs can teleport to new random safe positions every `mana_orb_relocation_interval` seconds.
  - Default interval: 30 seconds.
  - This helps recover orbs that spawned near scenery or became unreachable.

## Player Interaction
- The simulation manager supports simple player-controlled mana spawning.
- Press `M` to spawn a mana orb in front of the active camera.
- Left click to spawn a mana orb along the camera/cursor ray.
- Player-spawned mana uses the same safe-position check as normal spawning and tries nearby offsets if the preferred point is blocked.

## Stats UI
- `SimulationStatsUI` is a `CanvasLayer` in `world.tscn`.
- Script: `simulation_stats_ui.gd`.
- Updates every `update_interval` seconds, currently default `0.5`.
- Displays:
  - total live lifeforms
  - current mana orbs
  - total deaths
  - total evolutions
  - per-element counts for level 1, level 2, and level 3

## Energy & Combat Stats
- Each lifeform has:
  - `attack_energy`
  - `max_attack_energy`
  - `health`
- Defaults scale by level:
  - Level 1: `max_attack_energy = 3`, health starts from configured value
  - Level 2: `max_attack_energy = 5`, `health = 4`
  - Level 3+: `max_attack_energy = 8`, `health = 6`
- `add_attack_energy(amount)` clamps energy between 0 and max.
- Combat damage is based on the other lifeform's `attack_energy`.

## Detection Radii
- `DetectionArea` is used for social/partner detection and combat threat/prey detection.
- `ResourceDetection` is used for mana orb detection.
- Current exported defaults:
  - `social_detection_radius = 16.0`
  - `resource_detection_radius = 10.0`
- Radii are applied to their collision shapes in `_ready()`.

## Arena Constraint / Obstacle Avoidance
- `Constrain` keeps lifeforms inside a circular radius.
  - Current scene target value is around 100 meters.
  - If no `center_path` is assigned, the center is world origin.
- `Avoidance` uses raycast feelers against the boid's collision mask.
- Obstacles must have collision shapes on a layer the lifeform can query.
- The brain keeps `Constrain` and `Avoidance` enabled in every behavior mode.

## Behavior Modes
- `MODE_WANDER`: default roaming mode.
- `MODE_LEADER`: leader of a two-follower formation; checks merge opportunities.
- `MODE_FOLLOWER`: follows a leader at an assigned offset.
- `MODE_SEEK`: seeks the nearest mana orb until pickup or target removal.
- `MODE_PURSUE`: AntiMagic chases non-AntiMagic prey.
- `MODE_FLEE`: non-AntiMagic escapes AntiMagic predators.
- `MODE_COUNTER_ATTACK`: non-AntiMagic pursues a predator when it gets close enough to force a collision.

## Pursuit / Flee / Counter-Attack
- AntiMagic lifeforms pursue only non-AntiMagic lifeforms.
- AntiMagic lifeforms do not flee or counter-attack.
- Non-AntiMagic lifeforms flee AntiMagic predators that meet the level fear threshold.
- Followers are skipped by AntiMagic prey selection to avoid breaking active formations.
- If a fleeing lifeform is within `aggro_radius`, it switches to counter-attack mode and pursues the predator to force combat contact.
- Target references are cleared when targets die so freed nodes are not dereferenced.
- Pursue behavior uses close-range direct seeking to reduce endless orbiting and make collisions more likely.

## Combat & Collision Resolution
- Combat is resolved through slide collisions after `move_and_slide()`.
- Only AntiMagic vs non-AntiMagic contacts exchange combat damage.
- Same-element collisions and normal-element vs normal-element collisions do not deal combat damage.
- Damage is mutual:
  - each lifeform takes damage equal to the other lifeform's `attack_energy`
- Per-pair cooldown prevents repeated damage every frame while bodies remain touching.
- Collision impulse pushes both combatants apart.
- When a lifeform dies:
  - `is_dead` is set
  - collision layers/masks are disabled
  - other brains clear stale threat/prey references
  - follower slots are released
  - death sound and death burst play
  - simulation manager records the death
  - the lifeform is queued for freeing

## World Camera
- `camera_free_fly.gd` provides observer-camera movement.
- Controls:
  - Move: `W A S D`
  - Vertical: `Space` up, `Shift` down
  - Sprint: `Ctrl`
  - Mouse look when captured
  - `Esc`: release mouse
  - `Tab`: capture mouse

## What Is Not Implemented Yet
- Explicit win condition or simulation end state.
- Health/energy bars above individual lifeforms.
- Advanced combat tuning such as energy consumption per attack or richer level-based attack scaling.
- Advanced pathfinding or obstacle-aware target selection beyond steering avoidance and spawn checks.
- Authored/imported custom level-2 and level-3 creature models.
- More polished assignment deliverables such as final demo video, screenshots, and README submission notes.
