# Architecture Overview

## Purpose

The project is a 3D autonomous agents simulation in Godot. Multiple elemental lifeforms spawn into a world, move using steering behaviors, seek mana resources, form same-element groups, evolve, flee or pursue enemies, collide, die, and produce visible/audio feedback.

The design is split into reusable scenes and scripts so each part has one main responsibility:

- `lifeform.tscn`: one autonomous creature.
- `lifeform.gd`: creature presentation, stats, combat response, effects, sounds.
- `lifeform_brain.gd`: creature decision-making and evolution.
- `behaviors/*.gd`: reusable steering force modules.
- `mana_orb.tscn` / `mana_orb.gd`: resource pickup.
- `simulation_manager.gd`: world-level spawning, counters, input.
- `world.tscn`: assembled demo scene.

## Runtime Flow

1. `world.tscn` loads the environment, camera, stats UI, background music, and `SimulationManager`.
2. `SimulationManager._ready()` adds the manager to the `simulation_manager` group and defers startup with `call_deferred("_start_simulation")`.
3. `_start_simulation()` clears old lifeforms/orbs if enabled, then spawns the initial population and mana orbs.
4. Each spawned lifeform enters the `lifeforms` group and runs:
   - `lifeform.gd` for stats, visuals, particles, audio, combat.
   - `lifeform_brain.gd` for behavior state choice.
   - `Boid._physics_process()` for steering force integration and movement.
5. Mana orbs are placed in the `mana_orbs` group and can be consumed by lifeforms.
6. The stats UI polls the scene and manager counters to display live totals.

## Main Groups

- `lifeforms`: all active lifeforms.
- `mana_orbs`: all active mana orbs.
- `simulation_manager`: the active simulation manager.

Groups are important because several systems communicate through them:

- Lifeform death cleanup scans `lifeforms` to clear stale targets.
- Stats UI scans `lifeforms` and `mana_orbs`.
- Simulation manager clears/spawns nodes through the groups.
- Lifeforms notify the manager through `simulation_manager`.

## Collision Layer Intent

- Layer 1: lifeforms.
- Layer 2: environment and obstacles.
- Layer 3: mana orbs.

The main rule is that visible scenery must also have physics collision on the environment layer if it should affect avoidance or safe spawning.

## Major Design Decisions

- The simulation uses steering behaviors rather than navigation paths. This makes motion reactive and emergent.
- `Constrain` and `Avoidance` are always-on support behaviors, so every AI mode still respects the arena and obstacles.
- Evolution is handled by the brain because it depends on group/formation state.
- Effects and sounds are mostly node-based in scenes, with scripts only controlling playback/color/reparenting.
- Level 2 and 3 visuals are procedural meshes rather than imported models, keeping the project lightweight and stable.

## Extension Points

Useful future additions:

- Dominant element or win condition in `simulation_manager.gd`.
- Health/energy bars above lifeforms.
- More authored evolution visuals under `Visual/EvolutionVisualRoot`.
- More state-based face changes in `lifeform.gd`.
- More environment landmarks in `environment.tscn`.
