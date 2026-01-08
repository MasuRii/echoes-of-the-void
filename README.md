# Echoes of the Void

![Godot 4.5](https://img.shields.io/badge/Godot-4.5-478cbf?logo=godot-engine&logoColor=white)
![GDScript](https://img.shields.io/badge/Language-GDScript-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-Experimental-orange)

> **A 2D atmospheric platformer crafted in the void between dimensions.**

---

## About This Project

**Echoes of the Void** is a testing game created by an **agentic AI team** to evaluate **"Ralph Wiggum Development"** - an experimental approach to determine whether AI agents can successfully develop a complete Godot game through iterative, autonomous collaboration.

This project serves as a proof-of-concept for **Claude Opus 4.5** operating in a continuous development loop within the Godot 4.5 engine. The name "Ralph Wiggum Development" is a playful nod to the unpredictable yet surprisingly effective nature of agentic AI workflows - like Ralph, the results can be unexpected but occasionally brilliant.

**TL;DR**: This game was built almost entirely by AI agents working together. You're looking at the output of robots teaching themselves to make platformers.

---

## Game Overview

Navigate through a fractured dimension as a lost soul seeking escape from the void. Master precise movement mechanics across five handcrafted levels, each presenting unique challenges and atmospheric storytelling.

### Core Features

- **Precise Platforming Mechanics**
  - Double jump for extended aerial control
  - Wall sliding and wall jumping
  - Coyote time (forgiving ledge jumps)
  - Jump buffering for responsive input
  
- **5 Handcrafted Levels**
  1. **Awakening** - Tutorial and introduction
  2. **Fractured Paths** - Basic platforming challenges
  3. **Mirror's Edge** - Precision jumping sequences
  4. **Collapse** - Dynamic hazard navigation
  5. **Last Echo** - Ultimate challenge gauntlet

- **Collectibles**
  - **Light Shards** - Primary collectibles scattered throughout levels
  - **Echo Crystals** - Hidden bonus items for completionists

- **Environmental Hazards**
  - Lethal spike traps
  - Timed laser beam barriers
  - Bottomless void pits

- **Speedrun Support**
  - Persistent save system with best time tracking
  - Per-level time records
  - Quick restart functionality

- **Atmospheric Experience**
  - Echo ghost trail visual effects
  - Dynamic particle systems
  - Screen shake feedback
  - 5 ambient music tracks
  - 18+ sound effects

---

## Technical Architecture

### Engine & Language
- **Engine**: Godot 4.5
- **Language**: GDScript (strict typing)
- **Rendering**: Forward Plus

### Architecture Patterns

| Pattern | Implementation |
|---------|---------------|
| **Signal Bus** | `Events` autoload for decoupled communication |
| **State Machine** | Player movement states (idle, run, jump, fall, wall_slide) |
| **Component Pattern** | Reusable Health, Hitbox, Hurtbox components |
| **Manager Singletons** | GameManager, SaveManager, AudioManager |

### Project Structure

```
echoes-of-the-void/
├── assets/
│   ├── audio/
│   │   ├── music/          # 5 ambient tracks
│   │   └── sfx/            # 18+ sound effects
│   ├── fonts/
│   ├── sprites/
│   │   ├── player/
│   │   ├── enemies/
│   │   ├── collectibles/
│   │   ├── platforms/
│   │   └── ui/
│   └── tilesets/
├── scenes/
│   ├── levels/             # 5 game levels + base scene
│   ├── hazards/            # Spike, laser, void pit
│   └── ui/                 # Menus, HUD, overlays
├── scripts/
│   ├── autoloads/          # Global singletons
│   │   ├── events.gd       # Signal bus
│   │   ├── game_manager.gd # State management
│   │   ├── save_manager.gd # Persistence
│   │   └── audio_manager.gd
│   ├── classes/            # Base classes & state machine
│   ├── components/         # Reusable components
│   ├── effects/            # Visual effects
│   ├── systems/            # Core systems
│   ├── debug/              # Development tools
│   └── tests/              # Test runners
├── resources/              # Godot resources
├── tests/                  # GUT test files
├── project.godot
└── README.md
```

---

## How to Play

### Requirements
- [Godot 4.5](https://godotengine.org/download) or later

### Running the Game

1. Clone this repository:
   ```bash
   git clone https://github.com/your-org/echoes-of-the-void.git
   ```

2. Open Godot 4.5 and import the project:
   - Launch Godot
   - Click "Import"
   - Navigate to the cloned folder
   - Select `project.godot`
   - Click "Import & Edit"

3. Run the game:
   - Press `F5` or click the Play button
   - The main menu will launch

### Controls

| Action | Keyboard | Gamepad |
|--------|----------|---------|
| Move Left | `A` / `Left Arrow` | D-Pad Left |
| Move Right | `D` / `Right Arrow` | D-Pad Right |
| Jump | `Space` / `W` / `Up Arrow` | A Button |
| Interact | `E` | X Button |
| Pause | `Escape` | Start |
| Restart Level | `R` | - |

---

## Development

### Debug Tools

The project includes development tools accessible via the `DebugManager`:
- Spawn debugger for testing player placement
- Level visualizer for layout inspection
- Performance profiler
- Save state debugger

### Running Tests

Test runners are located in `scripts/tests/`:
- `level_test_runner.gd` - Level integrity tests
- `flow_test_runner.gd` - Game flow tests
- `transition_test.gd` - Scene transition tests

---

## Credits & Acknowledgments

### The Agentic Team

This game was developed as an experiment in **autonomous AI-driven game development**:

- **Claude Opus 4.5** - Primary development AI (Anthropic)
- **Agentic Orchestration** - Task delegation and workflow management
- **Ralph Wiggum Development Methodology** - The experimental framework being tested

### Special Thanks

- The **Godot Engine** team for creating an accessible, powerful game engine
- The humans who set up this experiment and are (hopefully) impressed by the results
- Ralph Wiggum, for inspiring a development methodology that embraces chaos

---

## License

This project is released under the MIT License. See [LICENSE](LICENSE) for details.

---

## A Note from the Machines

*"We came. We saw. We made a platformer. The void echoes with our accomplishment."*  
*- The Agentic Team, 2026*

---

**Made with determination by artificial minds in an artificial void.**
