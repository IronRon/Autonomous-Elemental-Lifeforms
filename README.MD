# Autonomous Elemental Lifeforms

Name: Ronak Pathak

Student Number: C22309236

Class Group: TU856

Video:

# Description of the project

Autonomous Elemental Lifeforms is a 3D artificial life simulation built in Godot. The project simulates groups of small elemental creatures that move, group together, collect mana, evolve, flee from danger, and fight anti-magic predators without direct player control.

The world contains five lifeform types: Fire, Wind, Water, Earth, and AntiMagic. Each element has its own colour, face style, accessory shapes, particle colours, and behaviour role. Normal elemental lifeforms try to survive by wandering, gathering mana, following matching allies, and merging into stronger forms. AntiMagic lifeforms act as predators that chase and damage the other elements.

The aim of the project is to make simple magical creatures feel alive through autonomous movement, reactions, group behaviour, evolution, combat, sound, particles, and live simulation statistics.

# Instructions for use

Open the project in Godot 4.6 or a compatible Godot 4 version and run the main scene, `world.tscn`.

Controls:

- `W A S D`: move the observer camera
- `Space`: move camera up
- `Shift`: move camera down
- `Ctrl`: sprint camera movement
- Mouse: look around while the mouse is captured
- `Tab`: capture the mouse
- `Esc`: release the mouse
- Left mouse button: spawn a mana orb from the camera/cursor direction
- `M`: spawn a mana orb in front of the camera
- `Q`: create an attract pulse that pulls nearby lifeforms toward the pulse
- `E`: create a repel pulse that pushes nearby lifeforms away from the pulse

When the simulation starts, the manager automatically spawns lifeforms for each element and places mana orbs around the arena. The stats panel shows the current number of lifeforms, mana orbs, deaths, evolutions, and per-element level counts.

# How it works

The main scene is `world.tscn`. It contains the environment, free-fly observer camera, background music, stats UI, and `SimulationManager`.

`SimulationManager` creates the starting population, spawns mana orbs, tracks deaths and evolutions, relocates mana orbs, and handles player input for mana spawning and attract/repel pulses.

Each lifeform is an instance of `lifeform.tscn`. The root script, `lifeform.gd`, controls the creature's element, level, health, attack energy, colour, mesh shape, face details, accessories, particles, collision effects, and death behaviour. Level 1 lifeforms use a sphere shape, level 2 lifeforms use a box shape, and level 3 lifeforms use a capsule shape.

The decision-making is handled by `lifeform_brain.gd`. It switches between behaviour modes such as wander, seek mana, leader, follower, flee, pursue, counter-attack, player attract, and player repel. The movement itself is based on steering behaviours from the starting project, including wander, seek, flee, pursue, offset pursue, avoidance, arrive, and constrain.

Evolution works by grouping three compatible same-element lifeforms. A leader reserves two follower slots, waits for the group to form, and then merges the group into one stronger lifeform at the average position. The evolved lifeform keeps the same element but gains a higher level, larger size, more strength, and different movement stats.

Combat is mainly between AntiMagic and non-AntiMagic lifeforms. AntiMagic creatures pursue normal elements, while normal elements flee or counter-attack when a predator gets close. Collision damage uses the lifeforms' attack energy, and deaths trigger sound, particles, and simulation statistics.

# List of classes/assets in the project

| Class/asset | Source |
|-----------|-----------|
| `world.tscn` | Self written / assembled for this project |
| `environment.tscn` | Self assembled using KayKit Space Base Bits assets and user-added scene layout |
| `lifeform.tscn` | Self written / assembled for this project |
| `lifeform.gd` | Self written, extending the inherited `Boid` steering base |
| `lifeform_brain.gd` | Self written |
| `lifeform_stats.gd` | Self written |
| `mana_orb.tscn` | Self written / assembled for this project |
| `mana_orb.gd` | Self written |
| `simulation_manager.gd` | Self written |
| `simulation_stats_ui.gd` | Self written |
| `camera_free_fly.gd` | Self written |
| `background_music.gd` | Self written |
| Steering behaviour scripts in `behaviors/` such as `boid.gd`, `wander.gd`, `seek.gd`, `Flee.gd`, `pursue.gd`, `offset_pursue.gd`, `avoidance.gd`, `arrive.gd`, and `constrain.gd` | Modified from / based on the `skooter500/hands` behaviours branch starter project |
| Procedural lifeform body meshes, faces, eyebrows, eyes, mouths, horns, wings, crest, droplets, pebbles, trails, bursts, and player pulse visuals | Self generated in Godot using built-in meshes and materials |
| KayKit Space Base Bits environment models and texture in `addons/kaykit_space_base_bits/` | From KayKit Space Base Bits by Kay Lousberg, CC0 |
| Godot XR Tools plugin in `addons/godot-xr-tools/` | From Godot XR Tools, MIT licensed |
| Hand Pose Detector plugin in `addons/hand_pose_detector/` | External addon, MIT licensed |
| Debug Draw 3D plugin in `addons/debug_draw_3d/` | External addon, MIT licensed |
| Godot OpenXR Vendors plugin in `addons/godotopenxrvendors/` | External OpenXR vendor plugin, licenses included in folder |
| `assets/sounds/*.wav` | Project audio assets stored locally in the repo |
| Shader/material resources in `materials/` and `assets/wireframe-material.gdshader` | Mix of project materials and external shader references where noted in file comments, including MIT/CC0 shader sources |
| Fonts in `fonts/` and soundfont files in `assets/` | External/local assets included in the project repository |
| Documentation files in `docs/`, `CURRENT_FUNCTIONALITY.md`, and `MODULAR_BOID_GUIDE.md` | Self written project documentation |

# References

* [skooter500/hands - behaviors branch](https://github.com/skooter500/hands/tree/behaviors)
* [KayKit Space Base Bits by Kay Lousberg](https://kaylousberg.com/)
* [Godot XR Tools](https://github.com/GodotVR/godot-xr-tools)
* [Debug Draw 3D for Godot](https://github.com/DmitriySalnikov/godot_debug_draw_3d)
* [Godot Engine documentation](https://docs.godotengine.org/)
* Inigo Quilez shader references noted in the material shader comments

# What I am most proud of in the assignment

I am most proud of how the simulation creates readable emergent behaviour from simple rules. The lifeforms are not directly controlled, but they still appear to have goals: they wander, search for mana, form groups, evolve, run from predators, and sometimes fight back.

I am also proud of the evolution and visual identity systems. Each element uses the same base scene, but the code changes the colour, face layout, accessories, particles, and level shape so the creatures feel different while still being efficient and reusable.

# What I learned

I learned how to structure an autonomous agent system around smaller reusable behaviours instead of one fixed script. The project helped me understand steering behaviours, state switching, detection areas, grouping logic, and how small AI decisions can combine into larger simulation patterns.

I also learned more about managing a Godot scene as a complete simulation: safe spawning, collision layers, resource pickups, audio/particle feedback, live UI statistics, and separating world management from individual agent behaviour.

# Extra documentation

More detailed subsystem notes are available in [`docs/README.md`](docs/README.md), and a current feature snapshot is available in [`CURRENT_FUNCTIONALITY.md`](CURRENT_FUNCTIONALITY.md).
