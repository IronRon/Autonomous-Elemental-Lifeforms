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
- `MODE_PURSUE`: anti-magic lifeforms chase non-anti-magic prey within DetectionArea using Pursue behavior.
- `MODE_FLEE`: non-anti-magic lifeforms escape from anti-magic predators using Flee behavior.

### Pursuit & Flee System (Fully Implemented)

#### How It Works

**Detection & Priority:**
- Threat/prey detection runs at the START of every frame, BEFORE partner detection, so combat takes priority.
- Each lifeform scans its `DetectionArea` (10m radius) for threats or prey.

**For Non-Anti-Magic Lifeforms (Flee Behavior):**
1. Scans `DetectionArea` for anti-magic predators.
2. Only considers predators at equal or higher level (configurable via `level_fear_threshold`).
   - Default: flee from predators at `level >= self.level`
   - Threshold +1: flee only if `level > self.level` (accept equals)
3. When threat detected → enters `MODE_FLEE` and enables Flee behavior.
4. Flee behavior: uses `Flee` steering to move away from predator, predicting its future position.

**For Anti-Magic Lifeforms (Pursue Behavior):**
1. Scans `DetectionArea` for non-anti-magic lifeforms.
2. Skips followers to avoid interrupting ally formations.
3. When prey detected → enters `MODE_PURSUE` and enables Pursue behavior.
4. Pursue behavior: uses `Pursue` steering (intercept prediction) to chase prey.
   - Calculates prey's estimated position based on velocity and distance.
   - Chases predicted intercept point rather than current position.

**How Pursuit/Flee Continue Each Frame:**
- `_pursue_prey_only()`: Maintains pursuit by:
  - Checking if prey still exists and is valid.
  - Checking if prey is still in `DetectionArea` (10m radius).
  - Continuously updating pursue behavior's target each frame to track movement.
  - Returns to `MODE_WANDER` immediately if prey disappears or leaves range.
  
- `_flee_from_threat_only()`: Maintains flee by:
  - Checking if threat still exists and is valid.
  - Checking if threat is still in `DetectionArea` (10m radius).
  - Continuously updating flee behavior's enemy reference each frame.
  - Returns to `MODE_WANDER` immediately if threat disappears or leaves range.

#### When Pursuit/Flee Stop

Pursuit or flee **exit immediately** if ANY of these conditions become true:

1. **Target is Destroyed:**
   - Prey is freed/invalid (checked via `is_instance_valid(current_prey)`).
   - Predator is freed/invalid (checked via `is_instance_valid(current_threat)`).
   - → Return to `MODE_WANDER` and resume normal behavior.

2. **Target Leaves Detection Range:**
   - Prey moves outside the 10m `DetectionArea` radius.
   - Predator moves outside the 10m `DetectionArea` radius.
   - Detection loop checks all bodies in area; if target not found → return to wander.

3. **Lifeform is Freed:**
   - When a lifeform dies or is removed, cleanup via `_exit_tree()` releases follower slots.
   - The hunter/prey relationship ends naturally.

4. **Mode Switching (Future Combat Phase):**
   - When aggro radius is implemented, prey may counter-attack if predator gets too close.
   - When health reaches 0, lifeform queue_free()s (not yet implemented).

#### Example Scenario

1. **Initial State:** Fire level-1 wandering, Anti-Magic level-1 wandering.
2. **Anti-Magic Spawns Anti-Magic:** Anti-magic detects fire in `DetectionArea` → `MODE_PURSUE` starts.
3. **Pursuit Active:** Fire flees, anti-magic chases with Pursue behavior (intercept calculation).
4. **Prey Escapes:** Fire flees 12m away, outside 10m radius → anti-magic exits pursue, returns to wander.
5. **Predator Turns Back:** Anti-magic loses interest, wanders again. Fire resumes normal behavior (formation/seeking).

#### Configurable Parameters

- `threat_detection_radius`: Distance at which threats/prey are detectable (export, default 10.0m).
  - Reuses existing `DetectionArea` collision shape.
- `level_fear_threshold`: How level difference affects fear (export, default 0).
  - 0: flee from equal or higher level.
  - 1: flee only from strictly higher level.
  - -1: flee from all anti-magic (even lower level).
  
#### Known Limitations (Pending Future Work)

- **No Collision Damage Yet:** Pursuit/flee don't cause damage on collision; health stays unchanged.
- **No Aggro Radius:** Prey can flee indefinitely; no "too close" counter-attack mechanic.
- **No Attack Cooldown:** Anti-magic don't consume energy to attack (energy system is placeholder).
- **No Death Mechanics:** Lifeforms don't die when health depletes; they persist until manually removed.
- **No Combat Resolution:** No knockback, bounce, or energy drain on contact.

## What Is Not Implemented Yet
- Combat resolution / predator-prey outcomes (using energy vs health)
- Aggro radius and flee→pursue counter-attack transition (when predator too close)
- Collision-based damage application and knockback physics
- Health depletion and death (queue_free when health <= 0)
- Simulation manager for spawning and faction counts
- HUD / debug visualization of energy and stats
