# Combat, Effects, And Audio

## Purpose

This subsystem makes interactions visible and audible. Combat is resolved on physical slide collisions, then particles, sounds, damage, death cleanup, and manager counters are triggered.

Main files:

- `lifeform.gd`
- `lifeform.tscn`
- `lifeform_brain.gd`
- `behaviors/boid.gd`
- `background_music.gd`
- `world.tscn`

## Combat Rules

Combat only happens between:

- AntiMagic lifeforms
- non-AntiMagic lifeforms

No combat damage happens for:

- same element collisions
- normal element vs normal element collisions
- AntiMagic vs AntiMagic collisions

Damage is mutual:

- each lifeform takes damage equal to the other lifeform's `attack_energy`

## Collision Resolution Flow

1. `Boid._physics_process()` calls `move_and_slide()`.
2. `Boid._resolve_combat_collisions()` checks slide collisions.
3. It filters to other `Boid` instances.
4. It uses a per-pair cooldown to avoid repeated frame-by-frame damage.
5. It calls `resolve_collision_with(other)`.
6. `lifeform.gd` overrides `resolve_collision_with()` and handles the actual combat response.

## Major Combat Functions

### `resolve_collision_with(other)`

Checks combat eligibility, plays collision feedback, applies damage, and applies knockback.

Important details:

- only the lower instance ID resolves the pair, avoiding double damage
- collision point is the midpoint between the two lifeforms
- one collision sound is played
- both lifeforms can create collision bursts
- both lifeforms receive impulse separation

### `apply_damage(amount)`

Reduces health and calls `die()` if health reaches zero.

### `die()`

Handles death cleanup:

- sets `is_dead`
- disables collision layers/masks
- tells other brains to clear stale threat/prey references
- notifies its own brain with `on_lifeform_death()`
- notifies simulation manager with `record_lifeform_death`
- plays death sound
- plays death burst
- queues the lifeform for freeing

### `_apply_collision_impulse(other)`

Applies visible knockback after collision. This helps separate colliding lifeforms and makes combat easier to read.

## Particle Effects

Particle nodes live in `lifeform.tscn`.

### `TrailParticles`

- continuous `GPUParticles3D`
- follows each lifeform
- element-colored
- controlled by `trail_enabled`
- material is duplicated per instance so colors do not leak between lifeforms

### `DeathBurstParticles`

- one-shot `GPUParticles3D`
- triggered by `die()`
- reparented to the current scene before the lifeform is freed
- freed after lifetime plus a small buffer

### `CollisionBurstParticles`

- one-shot burst template
- duplicated when combat collision happens
- placed at collision midpoint
- each combatant can spawn its own colored burst

## Important Particle Functions

- `_update_trail()`
- `_update_death_burst()`
- `_update_collision_burst()`
- `_play_death_burst()`
- `_play_collision_burst(collision_point)`

## Particle Color Functions

- `_trail_color_for_element()`
- `_death_burst_color_for_element()`
- `_collision_burst_color_for_element()`

These keep effect colors readable by element.

## Audio

### Mana Pickup

Handled by `mana_orb.gd` using the `PickupSound` node in `mana_orb.tscn`.

### Death Sound

Handled by:

- `DeathSound` node in `lifeform.tscn`
- `_play_death_sound()` in `lifeform.gd`

The sound node is reparented before the lifeform is freed so the sound can finish playing.

### Collision Sound

Handled by:

- `CollisionSound` node in `lifeform.tscn`
- `_play_collision_sound(collision_point)` in `lifeform.gd`

The sound node is duplicated so overlapping combat sounds can play independently.

### Evolution Sound

Handled by:

- `evolution_sound` export in `lifeform_brain.gd`
- `_play_evolution_sound(sound_position)`

It creates a temporary `AudioStreamPlayer3D` at the merge position.

### Background Music

Handled by:

- `BackgroundMusic` node in `world.tscn`
- `background_music.gd`

Current world volume is quiet so effects remain clear.

## Important Values

Combat:

- `attack_energy`
- `health`
- `collision_impulse_strength`
- `combat_collision_cooldown`

Sound:

- `DeathSound.volume_db`
- `CollisionSound.volume_db`
- `evolution_sound_volume_db`
- `BackgroundMusic.volume_db`

Particles:

- particle `amount`
- `lifetime`
- `explosiveness`
- draw mesh size
- `ParticleProcessMaterial.color`

## Tuning Notes

- Increase `collision_impulse_strength` for stronger visible knockback.
- Lower `combat_collision_cooldown` for faster damage, but this can make deaths happen too quickly.
- Increase collision burst amount/size for more readable combat impacts.
- Keep background music low so pickup/evolution/death sounds are still noticeable.
