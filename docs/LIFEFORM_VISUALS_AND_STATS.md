# Lifeform Visuals And Stats

## Purpose

`lifeform.gd` is the root controller for one elemental creature. It owns the lifeform's public identity, stats, procedural visual state, particles, combat response, and local sound effects.

Scene:

- `lifeform.tscn`

Script:

- `lifeform.gd`

Base class:

- `Boid` from `behaviors/boid.gd`

## Important Exported Values

- `element_type`: current element enum: Fire, Wind, Water, Earth, AntiMagic.
- `level`: evolution level, clamped to at least 1.
- `visual_color`: current body color.
- `size_multiplier`: scales the whole lifeform.
- `strength`: affects mass through `mass = base_mass / strength`.
- `speed_multiplier`: affects movement through `max_speed = base_max_speed * speed_multiplier`.
- `base_max_speed`: base movement speed before multipliers.
- `base_mass`: base mass before strength modifier.
- `trail_enabled`: toggles the continuous trail.
- `attack_energy`: current combat/resource energy.
- `max_attack_energy`: energy cap.
- `health`: current hit points.
- `collision_impulse_strength`: knockback strength after combat contact.
- `social_detection_radius`: radius for social/combat detection.
- `resource_detection_radius`: radius for mana orb detection.

## Visual Structure

`Visual` is the main `MeshInstance3D` body. The active mesh changes by level:

- Level 1: `SphereMesh`
- Level 2: `BoxMesh`
- Level 3+: `CapsuleMesh`

The face and accessories are child meshes of `Visual`, so they inherit body movement and scaling.

Face nodes:

- `LeftEye`
- `RightEye`
- `Mouth`
- `LeftBrow`
- `RightBrow`
- `LeftEyeShine`
- `RightEyeShine`
- `MouthLeftCorner`
- `MouthRightCorner`

Accessory nodes:

- `FireCrest`
- `WindWingLeft`
- `WindWingRight`
- `WaterDrop`
- `EarthPebbleLeft`
- `EarthPebbleRight`
- `AntiHornLeft`
- `AntiHornRight`

## Major Functions

### `_ready()`

Initializes the lifeform by applying configuration, setting the level mesh, updating face/accessories/effects, syncing the stats node, applying detection radii, and setting attack stats.

### `set_element_type(value)`

Changes the element, updates the body color, and refreshes visual/effect colors.

### `set_level(value)`

Clamps the level to at least 1 and refreshes body mesh, face placement, accessories, effects, and attack stat defaults.

### `_apply_configuration()`

Applies size, speed, mass, and dynamic material color. This is the central visual/stat refresh function.

### `_update_mesh_for_level()`

Swaps the main body mesh based on `level`. It also clears `Visual/EvolutionVisualRoot` so abandoned/imported evolution children are not left active.

### `_update_face()`

Updates all face meshes. This now includes eyes, mouth, brows, eye highlights, and mouth corners. Each element has a different layout.

### `_apply_face_layout(...)`

Positions and scales the main eyes and mouth.

### `_apply_face_detail_layout(...)`

Positions and scales brows, eye shines, and mouth-corner details.

### `_adjust_face_position(base_pos)` and `_adjust_face_scale(base_scale)`

Adapt face placement and size for level 2 box bodies and level 3 capsule bodies.

### `_update_accessories()`

Hides all accessories, then shows only the accessory for the current element. Accessory position and scale also adapt to level.

### `_sync_stats_node()`

Copies current lifeform values into `LifeformStats` for inspection/storage.

## Element Visual Identity

- Fire: red body, aggressive angled face, flame crest.
- Wind: green body, wider/open expression, side wings.
- Water: blue body, softer lower expression, top droplet.
- Earth: brown body, heavier grounded face, pebble accessories.
- AntiMagic: black body, purple emissive face, horns.

## Stats And Scaling

Movement:

- `max_speed = base_max_speed * speed_multiplier`
- `mass = base_mass / strength`
- `scale = Vector3.ONE * size_multiplier`

Attack defaults:

- Level 1: `max_attack_energy = 3`
- Level 2: `max_attack_energy = 5`, `health = 4`
- Level 3+: `max_attack_energy = 8`, `health = 6`

## Practical Tuning Notes

- Increase `base_max_speed` or `speed_multiplier` for faster-looking simulation movement.
- Increase `size_multiplier` for evolved forms if level changes are hard to see.
- Increase `social_detection_radius` to make grouping/evolution happen more often.
- Increase `resource_detection_radius` to make mana seeking more obvious.
- Keep face meshes small and close to the front surface. If they clip into level 2/3 bodies, adjust `_adjust_face_position()`.
