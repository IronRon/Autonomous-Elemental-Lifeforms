# Autonomous Elemental Lifeforms

Name: Ronak Pathak

Student Number: C22309236

Class Group: TU856

Video: [![Video](https://www.youtube.com/watch?v=Kn3jiWXXXIk)](https://www.youtube.com/watch?v=Kn3jiWXXXIk)

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

# How the project matches the assignment brief

The brief asks for an autonomous artificial lifeform with identity, personality, interaction with its surroundings, interaction with the player, and behaviour that helps convince the viewer it is alive. This project addresses that by treating the world as a small magical ecosystem rather than a single scripted character.

The lifeforms have their own goals and needs. They search for mana when low on attack energy, wander when idle, detect nearby allies and predators, flee from stronger AntiMagic lifeforms, pursue enemies, form groups, and evolve when enough compatible lifeforms gather. These behaviours happen automatically through each lifeform's brain rather than through direct player control.

The creatures also have identity and personality through elemental types. Fire, Wind, Water, Earth, and AntiMagic lifeforms have different colours, face layouts, accessories, particles, and roles in the simulation. AntiMagic is more predatory, while the other elements behave more like social creatures trying to survive and evolve.

The player can affect the ecosystem without taking full control of it. Spawning mana orbs, attract pulses, and repel pulses gives the player influence, but the lifeforms still decide how to react using their normal steering behaviours.

# Autonomous agents techniques used

The project uses several autonomous agent techniques from the assignment brief:

- Steering behaviours: wander, seek, flee, pursue, arrive, offset pursue, obstacle avoidance, and arena constraint.
- Boid-style movement: each lifeform inherits from the Boid controller and combines steering forces to move naturally.
- Finite State Machine style brain: `lifeform_brain.gd` switches between named behaviour modes such as wander, seek, leader, follower, flee, pursue, counter-attack, attract, and repel.
- Emergent group behaviour: compatible lifeforms form leader/follower groups and merge into evolved forms.
- Resource-driven behaviour: mana orbs create a need/reward system where lifeforms seek resources to improve attack energy.
- Predator/prey behaviour: AntiMagic lifeforms hunt other elements, while normal elements react by fleeing or counter-attacking.

# Visuals, sound, and believability

The assignment rewards visual and sound polish as part of making the lifeform feel alive. This project uses simple but readable procedural visuals instead of relying on one imported character model.

Each lifeform has a coloured body, face, eyebrows, eye shine, mouth details, element-specific accessories, trails, death bursts, and collision bursts. The level system changes the body shape from sphere to box to capsule, making evolution visible during the simulation.

Sound is used for feedback and atmosphere. Mana pickup, evolution, combat collision, death, and background music all have audio feedback. Mana orbs also pulse and glow so resources feel active rather than static.

# Interactivity

The player does not control a single creature directly, because the main focus is autonomous behaviour. Instead, the player influences the world:

- Mana orbs can be spawned to feed nearby lifeforms.
- Attract pulses temporarily pull nearby lifeforms toward a point.
- Repel pulses temporarily push nearby lifeforms away.
- The observer camera lets the player inspect the simulation from different angles.

This keeps the lifeforms independent while still giving the player a meaningful way to affect the outcome.

# Use of SOLID principles

The code is split into focused scripts and scenes so each major responsibility is separated.

- Single Responsibility Principle: `lifeform.gd` manages one lifeform's stats, visuals, combat feedback, and death handling; `lifeform_brain.gd` handles behaviour decisions; `simulation_manager.gd` handles spawning and global simulation state; `mana_orb.gd` handles resource pickup; `simulation_stats_ui.gd` handles display.
- Open/Closed Principle: new behaviour modes or element types can be added by extending the existing brain/state structure and element visual mappings without rewriting the whole simulation.
- Liskov Substitution Principle: lifeforms extend the existing `Boid` type and continue to work with the inherited steering behaviour system.
- Interface Segregation Principle: scripts communicate through small methods such as `add_attack_energy`, `on_orb_picked`, `record_evolution`, and `apply_player_influence` rather than one large shared manager interface.
- Dependency Inversion Principle: scenes are connected through exported `PackedScene`, `NodePath`, groups, and Godot nodes rather than hard-coding every object instance. For example, `SimulationManager` exports the lifeform and mana orb scenes, and lifeforms notify the manager through the `simulation_manager` group.

The project is not perfectly SOLID, because `lifeform.gd` still has several responsibilities around visuals, stats, combat, and effects. However, the overall structure separates the main systems enough that the project can be extended without having to rewrite everything in one script.

# Complexity and system design

The project contains several interacting systems rather than a single animated object. The main systems are lifeform visuals/stats, autonomous brain states, steering behaviours, evolution, resource seeking, combat, player influence, safe spawning, mana relocation, audio/particles, UI statistics, and camera controls.

The most complex part is the behaviour selection and evolution logic. Lifeforms must choose between competing needs such as seeking mana, fleeing predators, pursuing prey, following a leader, leading a group, merging, and reacting to player pulses. The result is not a fixed animation sequence; different runs can produce different outcomes depending on spawn positions, mana placement, and collisions.

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
| Debug Draw 3D plugin in `addons/debug_draw_3d/` | External addon, MIT licensed |
| Godot OpenXR Vendors plugin in `addons/godotopenxrvendors/` | External OpenXR vendor plugin, licenses included in folder |
| `assets/sounds/*.wav` | Sound effects and background audio from [Mixkit](https://mixkit.co/) |
| Shader/material resources in `materials/` and `assets/wireframe-material.gdshader` | Mix of project materials and external shader references where noted in file comments, including MIT/CC0 shader sources |
| Fonts in `fonts/` and soundfont files in `assets/` | External/local assets included in the project repository |
| Documentation files in `docs/`, `CURRENT_FUNCTIONALITY.md`, and `MODULAR_BOID_GUIDE.md` | Self written project documentation |

# References

* [skooter500/hands - behaviors branch](https://github.com/skooter500/hands/tree/behaviors)
* [KayKit Space Base Bits by Kay Lousberg](https://kaylousberg.com/)
* [Debug Draw 3D for Godot](https://github.com/DmitriySalnikov/godot_debug_draw_3d)
* [Mixkit sound effects and music](https://mixkit.co/)
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
