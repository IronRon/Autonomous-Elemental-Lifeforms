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
- `MODE_COUNTER_ATTACK`: (NEW) When fleeing lifeform is cornered within aggro_radius, it pursues the predator to force collision and escape via impulse separation.

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

#### Aggro Radius & Counter-Attack (NEW)

When a fleeing lifeform is **cornered** by an approaching predator:

- **Aggro Radius Detection:** If predator distance ≤ `aggro_radius` (export, default 2.5m):
  - Fleeing lifeform switches from `MODE_FLEE` → `MODE_COUNTER_ATTACK`.
  - Instead of running away, prey pursues the predator using **Pursue behavior**.
  - This forces collision between both combatants.

- **Combat & Impulse Separation:** On collision:
  - Both take damage (mutual damage exchange).
  - Both receive impulse push that separates them.
  - Knockback gives prey a chance to escape.

- **After Separation:**
  - If predator is still within `aggro_radius`, prey remains in `MODE_COUNTER_ATTACK` (continues pursuit).
  - If predator moves **outside** `aggro_radius`, prey returns to `MODE_FLEE` to resume escape.
  - If predator leaves `DetectionArea` (>10m), prey returns to `MODE_WANDER`.

- **Counter-Attack Exit Conditions:**
  - Predator becomes invalid/freed → return to wander.
  - Predator leaves detection area entirely → return to wander.
  - Predator moves beyond aggro radius → return to flee.

#### Example Scenario with Aggro Radius

1. **Initial State:** Fire level-1 wandering, Anti-Magic level-1 wandering.
2. **Anti-Magic Detects Fire:** Anti-magic distance 8m → enters `MODE_PURSUE`, chases Fire.
3. **Fire Flees:** Fire detects predator 8m away → enters `MODE_FLEE`, escapes.
4. **Predator Closes Distance:** Anti-magic continues pursuit, closes to 2.5m range.
5. **Aggro Triggered:** Fire detects distance ≤ 2.5m aggro_radius → switches to `MODE_COUNTER_ATTACK`.
6. **Counter-Attack Collision:** Fire pursues back with intercept prediction → collision.
7. **Mutual Damage + Impulse:** Both take 1 damage, both receive directional push.
8. **Separation Result:** Impulse pushes Fire away; Anti-Magic still chasing.
9. **Re-Evaluation:** Fire checks distance → if > 2.5m, returns to `MODE_FLEE` to escape.
10. **Chase Continues:** Anti-Magic resumes pursuit at 3-4m range, Fire flees. Cycle repeats until one escapes or dies.

#### Configurable Parameters

- `threat_detection_radius`: Distance at which threats/prey are detectable (export, default 10.0m).
  - Reuses existing `DetectionArea` collision shape.
- `level_fear_threshold`: How level difference affects fear (export, default 0).
  - 0: flee from equal or higher level.
  - 1: flee only from strictly higher level.
  - -1: flee from all anti-magic (even lower level).
- `aggro_radius`: Distance threshold at which cornered prey triggers counter-attack (export, default 2.5m).
  - When predator enters this radius during flight, prey switches to pursuit mode.
  - After impulse separation pushes combatants apart, threshold is checked again each frame.
  
#### Freed Target Guards

To prevent crashes when a pursued or fleeing target is freed:
- **`Flee.gd`** checks if `enemy_boid` is valid before dereferencing `global_transform`.
  - Returns safely if target is already dead.
  - Brain also clears the flee target via `clear_threat_reference()` when threat dies.
- **`Pursue.gd`** checks if `enemy_boid` is valid before using it in calculations.
  - Returns `Vector3.ZERO` if target is invalid.
  - Brain clears the pursue target via `clear_prey_reference()` when prey dies.
- When a lifeform dies, it notifies all other lifeforms to clear stale target references immediately.

## Combat & Collision Resolution (Implemented)

### How Collision Damage Works

Combat damage is resolved using **slide collision detection** from `move_and_slide()`:

1. **Per-Frame Collision Check:**
   - After `move_and_slide()`, `Boid` calls `_resolve_combat_collisions()`.
   - Iterates over all `get_slide_collision_count()` contacts.
   - For each contact, calls `resolve_collision_with(other)` on the lower-instance lifeform.

2. **Mutual Damage Exchange:**
   - When an anti-magic and non-anti-magic lifeform collide:
     - Both take damage equal to the **other's** `attack_energy`.
     - Example: Anti (energy=1) hits Wind (energy=2):
       - Anti takes 2 damage
       - Wind takes 1 damage
   - Both lifeforms must take damage in the same contact resolution, even if one dies.

3. **Per-Pair Cooldown:**
   - To prevent repeated damage from persistent contact, a cooldown dictionary tracks each pair.
   - `combat_collision_cooldown` (export, default 0.35 seconds) sets the delay between successive hits.
   - Same pair can only damage once every N seconds, even if still overlapping.

4. **Dead State & Immediate Cleanup:**
   - When a lifeform's `health` reaches 0, it calls `die()` immediately.
   - `die()` sets `is_dead = true` before `queue_free()`.
   - Dead lifeforms:
     - Disable collision layers/masks so they stop participating in new collisions.
     - Notify all other lifeforms to clear stale threat/prey references.
     - Call `on_lifeform_death()` on their brain to release follower slots.
   - This ensures dead bodies can't be damaged again or cause crashes.

5. **Collision Impulse (Knockback):**
   - On collision, both combatants receive a directional push away from each other.
   - `collision_impulse_strength` (export, default 4.0) controls the force magnitude.
   - Impulse is applied along the normalized direction between collision partners.
   - Velocity is clamped to allow short burst speeds (up to `max_speed * 1.5`).

### Combat Summary Example

**Scenario:** Anti1 (health=2, energy=1) collides with Wind1 (health=2, energy=1)

1. **Frame 1, First Collision:**
   - Anti1 and Wind1 collide.
   - Both take 1 damage: Anti1 health→1, Wind1 health→1.
   - Both receive impulse pushing them apart.
   - Cooldown is set for this pair: next damage in 0.35s.

2. **Frame 2-11 (within 0.35s):**
   - Pair remains in contact, but cooldown blocks repeated damage.
   - Movement can bring them apart due to impulse.

3. **Frame 12+ (after 0.35s):**
   - If still colliding, damage resolves again.
   - Both take 1 damage: Anti1 health→0 (dies), Wind1 health→0 (dies).
   - Both become dead immediately:
     - `is_dead=true` for both.
     - Collision layers disabled for both.
     - Brain cleanup called for both.
   - Both are queued for freeing, but dead state prevents further collisions/damage.

## What Is Not Implemented Yet

- **Simulation Manager:** Spawning lifeforms, managing factions, population counts.
- **HUD / Debug Visualization:** Energy bars, health indicators, stat display.
- **Advanced Combat:** Energy consumption on attacks, leveled attack power scaling.
