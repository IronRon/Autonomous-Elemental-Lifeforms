# Autonomous Elemental Lifeforms

## Project Proposal

### Project Title
**Aether Swarm: Autonomous Elemental Lifeforms**

---

## Overview
This project is a 3D artificial life simulation built in Godot where small magical elemental lifeforms autonomously move, interact, evolve, and compete for survival.

The world contains multiple elemental species such as **Fire**, **Wind**, **Water**, **Earth**, and **Anti-Magic**. Each lifeform begins as a small floating sphere-like creature with its own colour, face, movement, and behaviour. These lifeforms are not directly controlled by the player. Instead, they make decisions on their own using autonomous behaviours such as wandering, seeking allies, fleeing stronger enemies, pursuing weaker targets, and merging with their own kind to evolve into stronger forms.

The aim of the project is to create the illusion that these small magical entities are truly “alive” by giving them autonomous movement, survival instincts, readable reactions, distinct visual identity, and emergent group behaviour.

---

## Core Idea
Each elemental lifeform acts as a tiny magical organism.

They will:

- wander when idle
- detect nearby lifeforms
- seek others of the same element
- merge with matching allies to evolve into stronger forms
- avoid or flee stronger enemies
- pursue weaker targets when aggressive
- react differently depending on their element and evolution level
- compete until one element dominates the simulation

This creates a magical ecosystem where simple rules combine to produce more complex and lifelike behaviour.

---

## Player Interaction
Player interaction will be intentionally simple so that the main focus remains on the autonomous simulation.

The player will:

- choose an element to support at the beginning of the simulation
- observe the battle for survival between all elemental species
- place a limited number of **neutral mana orbs** during the simulation
- use these mana orbs strategically to help their chosen element evolve and survive

Any nearby lifeform may consume a neutral mana orb, so the player must place them carefully at the right time and location.

This keeps the simulation mostly autonomous while still giving the player a small but meaningful influence on the outcome.

---

## Artificial Life and Believability
The project is based on the idea that life-like behaviour can emerge from a set of simple rules.

The elemental lifeforms should feel alive because they will appear to:

- search for allies
- fear stronger threats
- protect their own kind through grouping
- become more confident when evolved
- compete for survival
- move with purpose rather than randomness

Although they are simple magical beings, their behaviour should make the user feel that they have instincts, goals, and a form of agency.

---

## Planned Features

### 1. Multiple Elemental Species
The simulation will contain different elemental lifeforms, each with their own identity and style.

Planned elements:

- Fire
- Wind
- Water
- Earth
- Anti-Magic

Each element will have:

- its own colour
- different movement feel
- different personality/temperament
- its own evolution chain

---

### 2. Steering Behaviours
The lifeforms will use steering behaviours to move autonomously in the world.

Planned behaviours include:

- **Wander** – default movement when nothing important is nearby
- **Seek** – move toward same-element allies or targets
- **Arrive** – slow down naturally near a target
- **Flee** – escape from stronger enemies
- **Pursue** – chase weaker enemies or prey
- **Offset Pursue / Follow** – smaller same-type lifeforms follow stronger evolved allies
- **Avoidance** – avoid non-matching elements or obstacles

These behaviours will make movement more natural and life-like.

---

### 3. Evolution System
Lifeforms of the same element will merge when they collide under the correct conditions.

This is inspired by a progression system similar to **2048**, where two matching lifeforms combine to form a stronger evolution stage.

Example Fire evolution:

- Spark
- Flame
- Salamander
- Drake
- Dragon

Other elements will have their own themed evolutions.

This gives the simulation:

- visible growth
- changing power levels
- more readable progression
- stronger emotional attachment to surviving factions

---

### 4. Predator / Survival System
The project will include competitive survival mechanics.

Rules may include:

- stronger entities can defeat weaker enemies
- weaker entities will flee stronger threats
- Anti-Magic lifeforms actively hunt normal elemental lifeforms
- Anti-Magic can also merge and evolve like other species
- final evolved forms may become dominant hunters or independent wanderers

This should create emergent survival scenarios rather than a fixed scripted outcome.

---

### 5. Visual Identity and Personality
Although the creatures are simple in shape, they will still have personality.

Planned visual/personality features:

- expressive faces
- glowing elemental colours
- different facial expressions or eye styles
- different movement styles per element
- particles/trails to emphasize magical identity
- growth in size and visual power as they evolve

Possible elemental personalities:

- **Fire** – aggressive, energetic, bold
- **Wind** – fast, playful, erratic
- **Water** – cautious, fluid, social
- **Earth** – slow, defensive, strong
- **Anti-Magic** – hostile, predatory, corrupting

This will help distinguish the lifeforms beyond colour alone.

---

## Technical Approach

### Engine
- **Godot**

### Base Project
This project will use the following repository as a starting point for behaviour systems and project setup:

- [skooter500/hands - behaviors branch](https://github.com/skooter500/hands/tree/behaviors)

This starter project will be extended and heavily modified to create an original autonomous life simulation.

---

## Planned Architecture
The final system will be split into multiple scripts/classes rather than placing all behaviour in one large file.

Possible script structure:

- `Lifeform.gd`  
  Main controller for an elemental creature

- `LifeformStats.gd`  
  Stores element type, level, size, strength, speed, and state values

- `LifeformBrain.gd`  
  Handles decision-making and state changes

- `SteeringController.gd`  
  Handles wander, seek, flee, pursue, and group following

- `EvolutionSystem.gd`  
  Handles merging, upgrading, and evolution logic

- `CombatResolver.gd`  
  Handles collision outcomes and predator/prey rules

- `SimulationManager.gd`  
  Spawns lifeforms, tracks counts, manages win conditions, and player support features

- `ManaOrb.gd`  
  Neutral interactable resource that can be consumed by lifeforms

This structure should help keep the project modular and easier to expand.

---

## Planned AI Logic
Each lifeform will make decisions based on what it detects nearby.

Example decision flow:

1. If a stronger enemy is nearby, flee
2. If a weaker enemy is nearby and attack conditions are met, pursue
3. If a same-element ally is nearby and merge conditions are met, seek and combine
4. If a stronger same-element ally is nearby, follow/support it
5. If nothing relevant is nearby, wander

This will allow the simulation to produce emergent behaviour from simple decision rules.

---

## Why This Fits the Assignment
This project matches the assignment brief because it creates autonomous artificial lifeforms that appear to have goals and instincts of their own.

It includes:

- autonomous behaviour
- interaction with surroundings
- group behaviour
- survival instincts
- emergent outcomes
- steering behaviours
- evolving forms
- visual identity and personality

Rather than one large character, this project explores the idea of **life through a magical ecosystem of many small autonomous beings**.

The goal is to make the player believe that these elemental creatures are alive in some way through their motion, reactions, alliances, conflicts, and survival.

---

## Scope
The project is designed to be achievable while still showing strong complexity.

### Minimum Viable Product
- multiple elemental lifeform types
- wandering and seeking behaviours
- same-element merging/evolution
- enemy fleeing/pursuit
- anti-magic predator behaviour
- simulation end state / winning element
- simple player support mechanic through neutral mana orbs


## References
- [skooter500/hands - behaviors branch](https://github.com/skooter500/hands/tree/behaviors)

---

## Author
**Ronak Pathak**

Autonomous Agents Assignment 2026
