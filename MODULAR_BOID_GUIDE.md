# Modular Boid System Guide (Godot)

This document explains how the modular boid system in this project works, and lists all files you should copy to reuse it in your own project.

This guide is for the modular system built around `boid.gd` + behavior nodes.
It intentionally excludes `big_boid.gd`.

## 1) How the modular boid system works

### Core design
- `Boid` is a `CharacterBody3D` controller script.
- Each steering behavior is a child node script extending `SteeringBehavior`.
- On startup, the boid scans child nodes and registers anything with a `calculate()` method as a behavior.

### Force pipeline
In each physics frame:
1. Every enabled behavior returns a steering vector from `calculate()`.
2. The boid multiplies each behavior output by that behavior's `weight`.
3. It accumulates them in order (scene child order).
4. If accumulated force exceeds `max_force`, it truncates to `max_force` and stops early.
5. It smooths force with `lerp(force, new_force, delta)`.
6. Integrates acceleration/velocity, clamps to `max_speed`, applies damping, then `move_and_slide()`.

This is a weighted, truncated, prioritized running sum.
Priority comes from child node order.

### Shared boid helpers
Behaviors call boid helpers (instead of duplicating math):
- `seek_force(target)`
- `arrive_force(target, slowing_distance)`

### Flocking
- `Separation`, `Cohesion`, and `Alignment` read `boid.neighbors`.
- Those behaviors enable neighbor counting via `boid.count_neighbors = true`.
- Neighbor lookup can be simple or partitioned (if boid has a school parent with partition data).

### State machine layer (optional but useful)
- A `StateMachine` node can run alongside steering behaviors.
- States call `boid.set_enabled_all(false)` then enable only needed behaviors for that state.
- States switch via `change_state(NewState.new())`.
- This gives mode-based control (attack/retreat/launch/defend/etc) while still using the same steering modules.

## 2) Files to copy for a modular boid project

## Minimum core (required)
- `behaviors/boid.gd`
- `behaviors/steering_behavior.gd`

## Core steering behaviors (common)
- `behaviors/seek.gd`
- `behaviors/arrive.gd`
- `behaviors/Flee.gd`
- `behaviors/pursue.gd`
- `behaviors/offset_pursue.gd`
- `behaviors/wander.gd`
- `behaviors/avoidance.gd`
- `behaviors/constrain.gd`
- `behaviors/follow_path.gd`

## Flocking behaviors
- `behaviors/separation.gd`
- `behaviors/cohesion.gd`
- `behaviors/alignment.gd`

## Utility dependency used by wander
- `behaviors/utils.gd`

## Optional steering modules used in some scenes
- `behaviors/noise_wander.gd`
- `behaviors/player_steering.gd`

## State machine (recommended)
- `behaviors/state.gd`
- `behaviors/state_machine.gd`

## Example state scripts (copy if you want this same state flow)
- `behaviors/AttackState.gd`
- `behaviors/DefendState.gd`
- `behaviors/DockedState.gd`
- `behaviors/LaunchState.gd`
- `behaviors/ready_to_launch.gd`
- `behaviors/RetreatState.gd`
- `behaviors/return_to_base_state.gd`
- `behaviors/fire_at_target_global_state.gd`

## Example scene wiring (reference)
- `behaviors/StateMachineBots.tscn`

## 3) Notes when reusing in a new project

- Behavior execution priority is node order under the boid node.
- Start with low weights and tune gradually.
- Keep `max_force` and `max_speed` balanced with behavior weights.
- Many scripts draw debug gizmos through DebugDraw; if you do not use DebugDraw, remove/comment those draw calls.
- State scripts in this project assume specific node names (`Seek`, `Wander`, `Avoidance`, `StateMachine`, etc). Keep names consistent or update scripts.

## 4) Suggested minimal starter setup

Create a boid scene with:
- `CharacterBody3D` + `boid.gd`
- child behavior nodes for: `Seek`, `Wander`, `Avoidance`, and optionally flocking nodes
- optional `StateMachine` + one initial state

Then tune:
- boid: `max_speed`, `max_force`, `mass`, `damping`
- each behavior: `enabled`, `weight`, behavior-specific params
