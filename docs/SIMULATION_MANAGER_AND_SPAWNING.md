# Simulation Manager And Spawning

## Purpose

`simulation_manager.gd` is the world-level coordinator. It starts the simulation, clears old nodes, spawns lifeforms and mana orbs, relocates mana, handles player input, and tracks global counters.

Main file:

- `simulation_manager.gd`

Scene:

- `world.tscn` has a `SimulationManager` node.

## Startup Flow

### `_ready()`

- Adds the manager to the `simulation_manager` group.
- Sets up random number generation.
- Defers `_start_simulation()` so children can be added after the scene finishes setup.

### `_start_simulation()`

- Resets `total_deaths`.
- Resets `total_evolutions`.
- Resolves `spawn_parent_path`.
- Clears existing lifeforms/orbs if enabled.
- Either spawns test evolution clusters or normal population.
- Starts the mana relocation timer if enabled.

## Important Exported Values

Scene references:

- `lifeform_scene`
- `mana_orb_scene`
- `spawn_parent_path`

Startup options:

- `use_evolution_test_spawn`
- `clear_existing_lifeforms`
- `clear_existing_mana_orbs`
- `random_seed`

Population:

- `lifeforms_per_element`
- `mana_orb_count`

Spawn space:

- `spawn_radius`
- `spawn_height`
- `mana_orb_spawn_height`
- `lifeform_clearance_radius`
- `mana_orb_clearance_radius`
- `spawn_blocking_collision_mask`
- `max_spawn_attempts`

Mana relocation:

- `relocate_mana_orbs`
- `mana_orb_relocation_interval`

Player interaction:

- `player_mana_spawn_enabled`
- `player_mana_spawn_distance`
- `player_mana_spawn_clearance_radius`
- `player_pulses_enabled`
- `player_pulse_distance`
- `attract_pulse_radius`
- `attract_pulse_duration`
- `repel_pulse_radius`
- `repel_pulse_duration`

## Normal Spawning

### `_spawn_initial_lifeforms(spawn_parent)`

Loops through all five element types and spawns `lifeforms_per_element` of each.

### `_spawn_lifeform(spawn_parent, element_type, index)`

Instantiates `lifeform_scene`, names it, adds it to `lifeforms`, sets `element_type`, places it at a random safe position, applies AntiMagic defaults, and adds it to the scene.

AntiMagic spawn defaults:

- `base_max_speed = 5.0`
- `health = 5.0`

### `_spawn_initial_mana_orbs(spawn_parent)`

Spawns `mana_orb_count` mana orbs.

### `_spawn_mana_orb(spawn_parent, index)`

Instantiates `mana_orb_scene`, names it, adds it to `mana_orbs`, places it safely, and adds it to the scene.

## Evolution Test Spawn

If `use_evolution_test_spawn` is enabled, `_spawn_evolution_test(spawn_parent)` creates:

- Cluster A: three level 1 Fire lifeforms for level 2 merge.
- Cluster B: one level 2 Fire leader plus two level 1 Fire followers for level 3 merge.

`_configure_evolution_test_brain(lifeform)` sets the brain's merge interval to `evolution_test_merge_check_interval`.

This is useful for demonstrating evolution quickly.

## Safe Spawning

Safe spawning prevents lifeforms and mana orbs from starting inside environment collision.

Important functions:

- `_random_spawn_position(height)`
- `_random_safe_lifeform_position()`
- `_random_safe_mana_orb_position()`
- `_is_spawn_position_blocked(position, clearance_radius)`

`_is_spawn_position_blocked()` creates a temporary `SphereShape3D` query and checks it against `spawn_blocking_collision_mask`.

Current intended mask:

- layer 2 environment collision

If no safe position is found after `max_spawn_attempts`, the function returns a random fallback position.

## Mana Relocation

Mana orbs can relocate every `mana_orb_relocation_interval` seconds.

Important functions:

- `_setup_mana_orb_relocation_timer()`
- `_relocate_mana_orbs()`

This helps avoid cases where orbs become stuck or unreachable near scenery.

## Player Input

`_unhandled_input(event)` handles:

- `M`: spawn mana in front of the camera.
- Left click: spawn mana along cursor ray.
- `Q`: attract pulse.
- `E`: repel pulse.

This gives player interaction while keeping lifeforms mostly autonomous.

## Global Counters

The manager tracks:

- `total_deaths`
- `total_evolutions`

Functions:

- `record_lifeform_death()`
- `record_evolution()`

Lifeforms and brains call these through the `simulation_manager` group.

## Tuning Notes

- Increase `lifeforms_per_element` for more chaotic simulation.
- Increase `mana_orb_count` for more resource seeking.
- Lower `spawn_radius` for faster interactions.
- Increase `spawn_height` if lifeforms start too close to terrain.
- Increase clearance radii if spawns overlap scenery.
- Use a non-zero `random_seed` for a repeatable demo.
