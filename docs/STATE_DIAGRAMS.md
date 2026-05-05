# Behaviour Tree And State Transition Diagrams

This document shows the high-level decision structure used by `lifeform_brain.gd`. The actual implementation is a finite state machine with priority checks, but the first diagram presents it like a behaviour tree because that is easier to explain for the assignment.

## Behaviour Priority Tree

```mermaid
flowchart TD
    A[Physics tick] --> B{Lifeform valid?}
    B -- No --> Z[Stop]
    B -- Yes --> C{Player influence active?}

    C -- Yes --> C1{Attract or repel?}
    C1 -- Attract --> C2[Enable Seek toward pulse point]
    C1 -- Repel --> C3[Enable Flee away from pulse point]
    C2 --> C4{Timer expired or pulse removed?}
    C3 --> C4
    C4 -- No --> Z
    C4 -- Yes --> W[Return to Wander]

    C -- No --> D{Non-AntiMagic and AntiMagic threat nearby?}
    D -- Yes --> F[Enter Flee]
    D -- No --> E{AntiMagic and prey nearby?}

    E -- Yes --> P[Enter Pursue]
    E -- No --> G{Seeking mana target invalid?}

    G -- Yes --> W
    G -- No --> H{Wandering and energy below max?}

    H -- Yes --> I{Mana orb nearby?}
    I -- Yes --> S[Enter Seek mana]
    I -- No --> J{Current mode active?}
    H -- No --> J

    J -- Seek --> S1[Keep seeking until orb picked or removed]
    J -- Pursue --> P1[Maintain prey pursuit]
    J -- CounterAttack --> CA1[Maintain counter-attack]
    J -- Flee --> F1[Maintain flee or switch to counter-attack]
    J -- Follower --> O1[Maintain offset pursue]
    J -- Leader --> L1[Check merge timer and followers]
    J -- None/Wander --> K[Look for same-element partner]

    L1 --> L2{Two valid followers and merge rules met?}
    L2 -- Yes --> EV[Perform evolution merge]
    L2 -- No --> K

    K --> K1{Compatible partner found?}
    K1 -- No --> W
    K1 -- Yes --> K2{Should this lifeform lead?}
    K2 -- Yes --> L[Enter Leader]
    K2 -- No --> O[Enter Follower]
```

## Main State Machine

```mermaid
stateDiagram-v2
    [*] --> WANDER

    WANDER --> SEEK: Mana nearby and energy < max
    SEEK --> WANDER: Orb picked / target removed

    WANDER --> LEADER: Compatible partner found and this lifeform leads
    WANDER --> FOLLOWER: Compatible partner found and other lifeform leads

    FOLLOWER --> WANDER: Leader invalid / incompatible
    LEADER --> WANDER: No followers and no compatible partner
    LEADER --> EVOLVING: Two followers + merge rules pass
    EVOLVING --> WANDER: New evolved lifeform spawned

    WANDER --> FLEE: Normal element detects AntiMagic threat
    FLEE --> COUNTER_ATTACK: Threat within aggro_radius
    COUNTER_ATTACK --> FLEE: Threat outside aggro_radius but still detected
    FLEE --> WANDER: Threat gone / out of detection range
    COUNTER_ATTACK --> WANDER: Threat gone / out of detection range

    WANDER --> PURSUE: AntiMagic detects non-AntiMagic prey
    PURSUE --> WANDER: Prey gone / out of detection range

    WANDER --> PLAYER_ATTRACT: Q attract pulse affects lifeform
    WANDER --> PLAYER_REPEL: E repel pulse affects lifeform
    SEEK --> PLAYER_ATTRACT: Player pulse priority
    SEEK --> PLAYER_REPEL: Player pulse priority
    LEADER --> PLAYER_ATTRACT: Player pulse priority
    LEADER --> PLAYER_REPEL: Player pulse priority
    FOLLOWER --> PLAYER_ATTRACT: Player pulse releases follower slot
    FOLLOWER --> PLAYER_REPEL: Player pulse releases follower slot
    PURSUE --> PLAYER_ATTRACT: Player pulse priority
    PURSUE --> PLAYER_REPEL: Player pulse priority
    FLEE --> PLAYER_ATTRACT: Player pulse priority
    FLEE --> PLAYER_REPEL: Player pulse priority
    COUNTER_ATTACK --> PLAYER_ATTRACT: Player pulse priority
    COUNTER_ATTACK --> PLAYER_REPEL: Player pulse priority
    PLAYER_ATTRACT --> WANDER: Pulse timer expires / pulse removed
    PLAYER_REPEL --> WANDER: Pulse timer expires / pulse removed
```

## Evolution State Flow

```mermaid
flowchart TD
    A[Lifeform in Leader mode] --> B[Merge timer reaches zero]
    B --> C[Get left follower slot]
    C --> D[Get right follower slot]
    D --> E{Both followers valid?}
    E -- No --> R[Reset merge timer]
    E -- Yes --> F[Build group of leader + 2 followers]

    F --> G{Same element and below max level?}
    G -- No --> R
    G -- Yes --> H{Leader level 1 and all group level 1?}

    H -- Yes --> L2[Target level = 2]
    H -- No --> I{Leader level 2 and mixed level 3 merge allowed?}

    I -- Yes --> J{Followers level 1 or 2?}
    J -- Yes --> L3[Target level = 3]
    J -- No --> R
    I -- No --> R

    L2 --> M[Average group position]
    L3 --> M
    M --> N[Instantiate lifeform.tscn]
    N --> O[Copy element and set target level]
    O --> P[Apply evolution defaults]
    P --> Q[Add new lifeform to scene]
    Q --> S[Record evolution and play sound]
    S --> T[Queue original group for freeing]
```

## Combat State Flow

```mermaid
sequenceDiagram
    participant B as Boid movement
    participant L as Lifeform A
    participant O as Lifeform B
    participant M as SimulationManager

    B->>B: move_and_slide()
    B->>B: get_slide_collision_count()
    B->>L: resolve_collision_with(other)
    L->>L: Check AntiMagic vs non-AntiMagic
    L->>L: Check per-pair cooldown
    L->>L: Play collision sound
    L->>L: Spawn collision burst
    L->>O: Ask other to spawn collision burst
    L->>L: apply_damage(other.attack_energy)
    L->>O: apply_damage(self.attack_energy)
    L->>L: Apply knockback impulse
    L->>O: Apply knockback impulse
    alt Health reaches zero
        L->>L: die()
        L->>M: record_lifeform_death()
        L->>L: Play death sound and burst
        L->>L: queue_free()
    end
```

## Mana Seeking Flow

```mermaid
flowchart TD
    A[Lifeform wandering] --> B{attack_energy < max_attack_energy?}
    B -- No --> W[Keep wandering]
    B -- Yes --> C[Scan ResourceDetection]
    C --> D{Nearest ManaOrb found?}
    D -- No --> W
    D -- Yes --> E[Enable Seek toward orb]
    E --> F[MODE_SEEK]
    F --> G{Orb still valid?}
    G -- No --> W
    G -- Yes --> H{PickupArea body_entered?}
    H -- No --> F
    H -- Yes --> I[ManaOrb calls brain.on_orb_picked]
    I --> J[Lifeform add_attack_energy]
    J --> K[Orb flash, sound, fade, queue_free]
    K --> W
```

## Notes For Explaining The System

- The code is not a formal behaviour tree implementation. It is a priority-driven finite state machine.
- The behaviour-tree view is still useful because the brain checks high-priority needs first, then falls through to lower-priority social/evolution behavior.
- `Constrain` and `Avoidance` are not separate states. They are support behaviors kept active inside every state.
- Player pulses intentionally override normal autonomy for a short time, then release the lifeforms back to normal decision-making.
