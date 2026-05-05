# World, Environment, UI, And Camera

## Purpose

This subsystem covers the assembled demo scene, environment collision expectations, live stats overlay, camera controls, and background music.

Main files:

- `world.tscn`
- `environment.tscn`
- `simulation_stats_ui.gd`
- `camera_free_fly.gd`
- `background_music.gd`

## `world.tscn`

The main scene contains:

- `DirectionalLight3D`
- `WorldEnvironment`
- `BackgroundMusic`
- `Environment`
- `SimulationManager`
- `SimulationStatsUI`
- `ObserverCamera`

It may also contain manually placed lifeforms or mana orbs, but the simulation manager currently clears existing grouped nodes on startup by default.

## Environment

`environment.tscn` is the current world/arena environment. It uses low-poly assets and user-added floating rocks/obstacles.

Environment requirements:

- Anything lifeforms should avoid must have physics collision.
- Obstacle collision should be on layer 2.
- Safe spawn checks use layer 2 through `spawn_blocking_collision_mask`.
- Visual meshes alone do not affect avoidance.

## Arena / Obstacle Relationship

The simulation has two separate systems:

- `Constrain`: keeps lifeforms inside a radius.
- `Avoidance`: steers lifeforms away from raycast-detected collision.

This means the world should ideally have:

- a readable arena boundary that matches the constrain radius
- a few obstacles in the air with collision shapes
- enough open space for lifeforms to actually move and collide

## World Environment And Glow

`WorldEnvironment` has glow enabled. This helps:

- mana orb emission
- AntiMagic purple face emission
- pulse visuals
- particle effects

If emissive effects look too weak, tune the material emission values first, then world glow settings.

## Stats UI

Scene node:

- `SimulationStatsUI` (`CanvasLayer`)

Script:

- `simulation_stats_ui.gd`

Visual structure:

- `StatsPanel`
- `MarginContainer`
- `StatsLabel`

## Stats UI Flow

`simulation_stats_ui.gd` updates every `update_interval` seconds.

It displays:

- total live lifeforms
- current mana orbs
- total deaths
- total evolutions
- Fire/Wind/Water/Earth/Anti counts by level 1, level 2, level 3

Important functions:

- `_ready()`
- `_process(delta)`
- `_update_stats()`
- `_get_simulation_manager()`
- `_element_name(element_type)`

It reads:

- `lifeforms` group
- `mana_orbs` group
- `SimulationManager.total_deaths`
- `SimulationManager.total_evolutions`

## Camera

Scene node:

- `ObserverCamera`

Script:

- `camera_free_fly.gd`

Exported values:

- `move_speed`
- `sprint_multiplier`
- `look_sensitivity`
- `capture_mouse_on_start`

Controls:

- `W A S D`: move horizontally relative to camera.
- `Space`: move up.
- `Shift`: move down.
- `Ctrl`: sprint.
- Mouse movement: look around while captured.
- `Esc`: release mouse.
- `Tab`: capture mouse.

The camera is intentionally separate from simulation nodes, so it can continue being used for observation/debugging even if a future simulation pause feature freezes lifeforms.

## Background Music

Scene node:

- `BackgroundMusic`

Script:

- `background_music.gd`

The world currently uses a quiet volume so combat, pickup, death, and evolution sounds remain audible.

## Visual Improvement Ideas

Good environment additions for the assignment/demo:

- visible arena ring matching the constrain radius
- elemental landmark clusters
- central mana fountain/crystal
- floating rocks/pillars with layer 2 collision
- colored lights near each elemental area
- clearer boundary posts or low walls

These additions improve readability without changing the AI logic.
