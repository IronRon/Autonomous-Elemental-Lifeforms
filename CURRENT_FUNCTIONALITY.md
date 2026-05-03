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

## What Is Not Implemented Yet
- Evolution merge rule (e.g. 3 same element + level -> level up)
- Combat resolution / predator-prey outcomes
- Simulation manager for spawning and faction counts
- Mana orb support mechanic
