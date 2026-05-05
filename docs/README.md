# System Documentation Index

These documents explain the current autonomous lifeform simulation system by subsystem. They are intended to help with development, assignment explanation, and demo preparation.

## Recommended Reading Order

1. [Architecture Overview](ARCHITECTURE_OVERVIEW.md)
2. [Lifeform Visuals And Stats](LIFEFORM_VISUALS_AND_STATS.md)
3. [Brain, Behaviors, And Evolution](BRAIN_BEHAVIOR_EVOLUTION.md)
4. [Behaviour Tree And State Transition Diagrams](STATE_DIAGRAMS.md)
5. [Combat, Effects, And Audio](COMBAT_EFFECTS_AUDIO.md)
6. [Mana Orbs And Player Interaction](MANA_AND_PLAYER_INTERACTION.md)
7. [Simulation Manager And Spawning](SIMULATION_MANAGER_AND_SPAWNING.md)
8. [World, Environment, UI, And Camera](WORLD_ENVIRONMENT_UI_CAMERA.md)

## Main Project Files

- `world.tscn`: main scene.
- `lifeform.tscn`: reusable lifeform scene.
- `lifeform.gd`: visual/stat/combat controller for one lifeform.
- `lifeform_brain.gd`: high-level AI state machine and evolution logic.
- `simulation_manager.gd`: simulation setup, spawning, counters, player input.
- `mana_orb.tscn` / `mana_orb.gd`: resource pickup object.
- `simulation_stats_ui.gd`: live stats overlay.
- `camera_free_fly.gd`: observer camera controls.

## Notes

- The `behaviors/` folder contains many inherited/example scripts from the starting project. The main simulation currently uses only a subset: `boid.gd`, `steering_behavior.gd`, `wander.gd`, `seek.gd`, `Flee.gd`, `pursue.gd`, `offset_pursue.gd`, `constrain.gd`, `avoidance.gd`, and `arrive.gd`.
- `CURRENT_FUNCTIONALITY.md` is the quick feature snapshot. The files in this folder are more detailed subsystem explanations.
