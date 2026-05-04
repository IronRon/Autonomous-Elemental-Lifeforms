# Current Functionality Snapshot

This document summarizes what is currently implemented for the lifeform prototype.

## Lifeform Overview
- A lifeform is a `CharacterBody3D` using `Boid`-based steering movement.
- It has configurable stats and element identity.
- It can wander by default and form a leader/follower pair with another compatible lifeform.

## Main Scene Node Structure (`lifeform.tscn`)
- `Lifeform` (`CharacterBody3D`) with script `lifeform.gd`
- `CollisionShape3D`
- `Visual` (`MeshInstance3D`)
- `DetectionArea` (`Area3D`) + child collision shape
- `LifeformBrain` (`Node`) with script `lifeform_brain.gd`
- Steering behavior nodes:
  - `Wander`
  - `Seek`
  - `Arrive`
  - `Flee`
  - `Pursue`
  - `OffsetPursue`
  - plus optional behavior nodes already present
- `LifeformStats` (`Node`) with script `lifeform_stats.gd`

## `lifeform.gd` (Root Controller)
- Extends `Boid` and exposes main editable properties:
  - `element_type`, `level`, `visual_color`
  - `size_multiplier`, `strength`, `speed_multiplier`
  - `base_max_speed`, `base_mass`
- Applies stat effects to movement/body:
  - `max_speed = base_max_speed * speed_multiplier`
  - `mass = base_mass / strength`
  - `scale = Vector3.ONE * size_multiplier`
- Assigns a unique material to `Visual` and updates color.
- Auto-maps element to color:
  - Fire -> red
  - Wind -> green
  - Water -> blue
  - Earth -> brown
  - AntiMagic -> black
- Syncs values into `LifeformStats` node.

## `lifeform_stats.gd` (Stats Data Node)
- Holds exported data copy of identity and gameplay stats.
- Can copy from a lifeform root (`copy_from_lifeform`).
- Can apply back to a lifeform root (`apply_to_lifeform`).

## `lifeform_brain.gd` (Behavior Selection)
- Default mode is `wander`.
- Finds compatible nearby lifeforms using `DetectionArea`:
  - same element (configurable)
  - same level (configurable)
- Chooses leader/follower role deterministically (instance ID).
- Follower behavior:
  - Uses `OffsetPursue` only.
  - Claims one of two follower slots around leader:
    - left diagonal
    - right diagonal
  - Uses configurable formation distances (`formation_offset_x`, `formation_offset_z`).
- If leader is removed/invalid, follower drops formation and returns to default wander.

### Evolution / Merge (Implemented)
- Leader-driven merge: when a `leader` has two occupied follower slots and all three
  are level 1 and the same element, the leader spawns a single level-2 lifeform and
  removes the three originals.
- Merge is checked on a configurable interval (`merge_check_interval`, default 5s)
  to avoid per-frame checks.
- Visual differentiation: level-1 uses a `SphereMesh`; level-2 uses a `BoxMesh`.
- Spawned level-2 defaults: `size_multiplier = 1.5`, `speed_multiplier = 0.8`,
  `strength = 1.2`. These are configurable per instance after merge.

## `OffsetPursue` Role in Formation
- Follower tracks a local offset around leader and arrives toward predicted target position.
- Custom offset mode is enabled by brain for formation slots.
- Typical offsets are in meter-like world units (e.g. 1.0 to 2.0).

## World Camera (`camera_free_fly.gd`)
- Simple observer camera for 3D inspection.
- Controls:
  - Move: `W A S D`
  - Vertical: `E` up, `Q` down
  - Sprint: `Shift`
  - Mouse look when captured
  - `Esc`: release mouse
  - `Tab`: capture mouse

## Mana Orb System (Implemented)
- `ManaOrb` is a `StaticBody3D` with an `energy_amount` export (default: 1).
- Root node: `StaticBody3D` with attached script `mana_orb.gd`.
- Child node: `PickupArea` (Area3D) with collision shape for detecting lifeforms.
- When a lifeform body enters the PickupArea:
  1. Mana orb notifies the lifeform's brain via `on_orb_picked(self)`
  2. Lifeform gains energy via `add_attack_energy(energy_amount)`
  3. Mana orb frees itself
- Lifeforms detect orbs using a separate `ResourceDetection` area with configurable `resource_detection_radius`.
- Seeking orbs: lifeforms in `MODE_WANDER` with `attack_energy < max_attack_energy` will seek the nearest orb.
  - Enters `MODE_SEEK` and disables other behaviors.
  - Stays in `MODE_SEEK` until orb is picked or freed.
  - Returns to `MODE_WANDER` after pickup.

## Energy & Combat Stats (Implemented)
- Each lifeform has `attack_energy` (current), `max_attack_energy` (capacity), and `health` (hit points).
- Defaults scale by level:
  - Level 1: `max_attack_energy = 3`, `health = 2`
  - Level 2: `max_attack_energy = 5`, `health = 4`
  - Level 3+: `max_attack_energy = 8`, `health = 6`
- Method `add_attack_energy(amount)` clamps to [0, max].
- Method `_update_attack_stats()` applies defaults based on level.

## Detection Radii (Implemented)
- Two separate detection areas per lifeform:
  - `DetectionArea` (social/partner detection) with export `social_detection_radius` (default: 10.0)
  - `ResourceDetection` (resource/orb detection) with export `resource_detection_radius` (default: 20.0)
- Radii are applied to collision shapes in `_ready()`.

## Behavior Modes (STATE MACHINE)
- `MODE_WANDER`: default; wanders using Wander steering behavior.
- `MODE_LEADER`: leads formation of up to 2 followers; checks for merge opportunities.
- `MODE_FOLLOWER`: follows leader at assigned offset slot (left or right).
- `MODE_SEEK`: seeks nearest mana orb; stable mode until pickup via `on_orb_picked()`.

## What Is Not Implemented Yet
- Combat resolution / predator-prey outcomes (using energy vs health)
- Simulation manager for spawning and faction counts
- Attack and take_damage mechanics
- HUD / debug visualization of energy and stats
