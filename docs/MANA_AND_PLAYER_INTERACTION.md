# Mana Orbs And Player Interaction

## Purpose

Mana orbs are neutral resources that lifeforms can seek and collect to gain attack energy. The player can influence the simulation by spawning mana orbs and by creating temporary attract/repel pulses.

Main files:

- `mana_orb.tscn`
- `mana_orb.gd`
- `simulation_manager.gd`
- `lifeform_brain.gd`

## Mana Orb Scene

`mana_orb.tscn` root:

- `ManaOrb` (`StaticBody3D`)

Important children:

- `PickupArea`: detects lifeforms entering pickup range.
- `CollisionShape3D`: physics body shape.
- `MeshInstance3D`: visible orb mesh.
- `OutlineMesh`: pickup flash/outline.
- `GlowLight`: pulsing glow.
- `PickupSound`: pickup audio.

Mana orbs belong to:

- `mana_orbs` group

## Important Mana Orb Values

- `energy_amount`: energy granted to a lifeform, default 1.
- `pulse_speed`: visual pulse speed.
- `pulse_scale_amount`: how much the orb grows/shrinks while idle.
- `glow_energy`: base emission strength.
- `pickup_flash_time`: flash/expand duration before fade.

## Mana Orb Flow

1. Orb idles with scale, light, and emission pulsing.
2. A lifeform enters `PickupArea`.
3. `_on_body_entered(body)` checks for `add_attack_energy`.
4. Orb marks itself picked up so it cannot trigger twice.
5. Orb notifies the lifeform brain with `on_orb_picked(self)`.
6. Lifeform gains energy with `body.add_attack_energy(energy_amount)`.
7. Orb disables pickup/collision.
8. Orb plays flash, outline, fade, and pickup sound.
9. Orb frees itself after the sound has time to finish.

## Major Mana Orb Functions

### `_ready()`

Stores base scale, prepares materials, and connects pickup area signal.

### `_process(delta)`

Runs idle pulse animation while the orb has not been picked up.

### `_on_body_entered(body)`

Handles lifeform pickup detection and starts the pickup sequence.

### `_setup_visuals()`

Duplicates/setup materials, glow, and outline values.

### `_play_pickup_flash()`

Disables pickup, plays sound, animates scale/material fade, then frees the orb.

## Lifeform Mana Seeking

`lifeform_brain.gd` controls mana seeking.

Important functions:

- `_find_nearest_mana_orb()`
- `on_orb_picked(orb)`

Lifeforms seek mana when:

- current mode is `MODE_WANDER`
- `attack_energy < max_attack_energy`
- a valid `ManaOrb` is inside `ResourceDetection`

When seeking:

- brain disables other behaviors
- re-enables `Constrain` and `Avoidance`
- enables `Seek` toward the orb
- stays in `MODE_SEEK` until the orb is picked or removed

## Player Mana Spawning

Handled in `simulation_manager.gd`.

Controls:

- `M`: spawn mana orb in front of the active camera.
- Left click: spawn mana orb along the camera/cursor ray.

Important values:

- `player_mana_spawn_enabled`
- `player_mana_spawn_distance`
- `player_mana_spawn_clearance_radius`

Important functions:

- `_spawn_player_mana_orb_in_front_of_camera()`
- `_spawn_player_mana_orb_from_cursor(cursor_position)`
- `_spawn_player_mana_orb_at(spawn_position)`
- `_safe_player_mana_position(preferred_position)`

Player-spawned mana uses a safe position check. If the preferred position overlaps environment collision, the manager tries nearby offsets.

## Player Attract / Repel Pulses

Handled in:

- `simulation_manager.gd`
- `lifeform_brain.gd`

Controls:

- `Q`: attract pulse.
- `E`: repel pulse.

Current defaults:

- `player_pulse_distance = 15.0`
- `attract_pulse_radius = 18.0`
- `attract_pulse_duration = 4.0`
- `repel_pulse_radius = 18.0`
- `repel_pulse_duration = 2.0`

## Pulse Flow

1. Player presses `Q` or `E`.
2. Simulation manager calculates a point along the active camera cursor ray.
3. It creates a temporary visible pulse node.
4. It scans all `lifeforms`.
5. Any lifeform within radius gets `apply_player_influence(...)` called on its brain.
6. Brain enters:
   - `MODE_PLAYER_ATTRACT` using `Seek`
   - or `MODE_PLAYER_REPEL` using `Flee`
7. After the duration expires, the brain returns to wander.

## Major Pulse Functions

In `simulation_manager.gd`:

- `_spawn_player_pulse_from_cursor(mode)`
- `_spawn_player_pulse_at(pulse_position, mode)`
- `_create_player_pulse_point(pulse_position, radius, duration, color, mode)`
- `_apply_player_pulse_to_lifeforms(pulse_point, mode, radius, duration)`

In `lifeform_brain.gd`:

- `apply_player_influence(target, mode, duration)`
- `_update_player_influence(delta)`
- `_apply_player_influence_behavior()`

## Tuning Notes

- Increase attract radius for a more dramatic demo.
- Keep repel duration shorter than attract so it feels like a shockwave.
- Increase `player_pulse_distance` if pulses spawn too close to the camera.
- Use mana spawning to encourage evolution in a specific region.
