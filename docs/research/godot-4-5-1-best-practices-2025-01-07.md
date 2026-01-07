# Godot 4.5.1 Best Practices for LLM-Assisted Development

> Generated: 2025-01-07 | Researcher Agent

## Executive Summary

This comprehensive research document provides actionable guidelines for LLM coding assistants working on Godot Engine 4.5.1 projects. The research covers GDScript 2.0 syntax and patterns, project structure organization, coding standards, common architectural patterns, testing approaches with the GUT framework, and performance optimization strategies. Key findings emphasize that Godot 4.5.1 promotes composition over inheritance, requires strict adherence to the official GDScript style guide for optimal code generation, and benefits significantly from signal-based communication patterns for loose coupling. The research identifies critical differences from Godot 3.x including GDScript 2.0 type annotations, new `@export` annotations, and breaking changes in C# Android export requirements.

## Source Validation

| Source | Tier | Date | Version |
|--------|------|------|---------|
| Godot Engine Official Documentation | 1 | 2025-01 | 4.5.x |
| Godot 4.5.1 Release Notes | 1 | 2025-01 | 4.5.1 |
| GDScript Style Guide | 1 | 2025-01 | 4.5.x |
| GDQuest Godot 4.x Courses | 2 | 2025-01 | 4.5.x |
| Godot Engine GitHub Repository | 1 | 2025-01 | 4.5.x |
| Community Forum Best Practices | 3 | 2025-01 | 4.5.x |

## Godot 4.5.1 Key Information

### Version-Specific Features and Breaking Changes

Godot 4.5.1 represents the stable release of the Godot 4.x series with significant improvements over previous versions. The engine introduces GDScript 2.0 with enhanced type safety, improved performance, and modern language features that LLM assistants must understand to generate compatible code.

The most critical breaking change for LLM-assisted development involves **C# Android export requirements**. As documented in the official migration guide, projects using C# for Android export must upgrade to .NET 9 to comply with new Google Play requirements for 16KB page size support. Other platforms continue to use .NET 8 as the minimum required version, but newer versions are supported and encouraged. LLM assistants should query the target platform early in the development process and generate platform-specific code accordingly.

**Resource sharing behavior** has been identified as a common source of confusion that LLMs should be aware of. When scenes are instantiated multiple times, Godot keeps internal Resource objects intact as long as any single reference to the original PackedScene exists. This means that modifying a resource in one instance affects all instances unless the resource is set to "Local To Scene." LLM assistants should explicitly mark resources as `local_to_scene` when appropriate and document this behavior in generated code.

**Signal connection methods** have evolved significantly. Godot 4.x introduces `Signal.connect()` as the recommended approach over the legacy `Object.connect()`. The new method provides compile-time validation through the type system, while the legacy approach uses string-based method names requiring runtime validation. LLM assistants should generate modern signal connections using `Signal.connect()` exclusively for new projects and should migrate existing code patterns when working with existing Godot 4.x codebases.

### GDScript 2.0 Syntax Requirements

GDScript 2.0 introduces mandatory type annotations for optimal code generation and static analysis. The language has moved away from dynamic typing as the default, requiring explicit type hints for function parameters, return values, and variable declarations. This shift enables better code completion, earlier error detection, and improved performance through static optimizations.

The **type annotation syntax** follows Python-like conventions with colon-based type declarations:

```gdscript
# Variable with type annotation
var health: int = 100
var velocity: Vector2 = Vector2.ZERO
var target: Node2D = null

# Function with typed parameters and return type
func calculate_damage(base_damage: int, multiplier: float) -> int:
    return int(base_damage * multiplier)

# Array and Dictionary with type hints
var enemies: Array[Enemy] = []
var inventory: Dictionary = {}

# Optional types (can be null)
var current_target: Enemy = null
```

LLM assistants should always generate code with type annotations unless explicitly instructed otherwise. When the user requests quick/dynamic code, the assistant should still provide typed annotations but note that explicit types can be omitted in Godot 4.x.

**Export annotations** have replaced the `@export` decorator with enhanced functionality:

```gdscript
# Basic export
@export var speed: float = 200.0

# Export with grouping
@export_group("Combat")
@export var damage: int = 10
@export var attack_range: float = 50.0

# Export with categorization
@export_category("Movement")
@export var move_speed: float = 300.0
@export var jump_force: float = 400.0
```

The `@onready` annotation provides a clean way to initialize node references after the node enters the scene tree:

```gdscript
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
```

## GDScript Best Practices

### Official Style Guide Compliance

The official GDScript style guide establishes consistent naming conventions and code organization that LLM assistants must follow precisely. These conventions ensure generated code matches developer expectations and integrates seamlessly with existing Godot projects.

**Class Naming Convention**: Classes use PascalCase with file names in snake_case. A class defined as `class_name Weapon` should be saved in `weapon.gd`. This mapping is critical for LLM assistants to generate correctly linked code.

**Variable and Function Naming**: Functions and variables use snake_case (lowercase with underscores), while constants use SCREAMING_SNAKE_CASE (all caps with underscores):

```gdscript
var player_health: int = 100
var max_speed: float = 300.0
var current_state: State = State.IDLE

const MAX_HEALTH: int = 100
const GRAVITY: float = 980.0
const JUMP_FORCE: float = 400.0

func calculate_damage() -> void:
    pass

func _recalculate_path() -> void:
    pass
```

**Signal Naming**: Signals use snake_case with past-tense verbs to indicate events that have occurred:

```gdscript
signal health_changed(new_health: int, max_health: int)
signal player_died
signal item_collected(item: Item)
signal damage_taken(amount: int, source: Node)
```

**Private Member Convention**: Private members are prefixed with an underscore to indicate they should not be accessed directly from outside the class:

```gdscript
var _internal_state: Dictionary = {}
var _cached_value: float = 0.0
var _velocity: Vector2 = Vector2.ZERO
```

### Script Structure Order

Godot 4.x enforces a recommended script structure for consistency and readability. LLM assistants must generate scripts following this exact order:

```gdscript
# 1. Annotations (@tool, @icon, @static_unload)
# 2. class_name declaration
class_name MyClass

# 3. extends keyword
extends Node2D

# 4. Doc comments
## This class manages player combat mechanics and health systems.

# 5. Signals (in declared order)
signal health_changed(new_health: int)
signal died

# 6. Enums
enum State { IDLE, WALKING, RUNNING, JUMPING }

# 7. Constants
const MAX_HEALTH: int = 100
const GRAVITY: float = 980.0

# 8. Static variables
static var instance_count: int = 0

# 9. @export variables
@export var speed: float = 200.0
@export var jump_force: float = 400.0
@export_group("Combat")
@export var damage: int = 10
@export var attack_range: float = 50.0

# 10. Regular variables
var current_health: int = MAX_HEALTH
var current_state: State = State.IDLE

# 11. @onready variables
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# 12. _static_init() if needed
static func _static_init() -> void:
    pass

# 13. Static methods
static func validate_input(value: int) -> bool:
    return value >= 0

# 14. Overridden built-in virtual methods
func _init() -> void:
    pass

func _enter_tree() -> void:
    pass

func _ready() -> void:
    pass

func _process(delta: float) -> void:
    pass

func _physics_process(delta: float) -> void:
    pass

# 15. Overridden custom methods
func _die() -> void:
    queue_free()

# 16. Remaining methods
func take_damage(amount: int) -> void:
    current_health -= amount
    health_changed.emit(current_health)
    if current_health <= 0:
        die()

# 17. Inner classes/subclasses
class DamageResult:
    var damage: int
    var is_critical: bool
    
    func _init(d: int, critical: bool) -> void:
        damage = d
        is_critical = critical
```

This structure ensures that LLMs generate consistent, professional-quality code that matches community expectations.

### Signal Patterns and Connection Best Practices

Godot 4.x emphasizes signal-based communication for loose coupling between game systems. LLM assistants must master multiple signal patterns and generate appropriate code based on the use case.

**Basic Signal Connection**:

```gdscript
# Method 1: Connect in _ready() (preferred for dynamic connections)
func _ready() -> void:
    # Connect to child node signals
    $Button.pressed.connect(_on_button_pressed)
    
    # Connect with additional arguments using bind()
    $Enemy.died.connect(_on_enemy_died.bind($Enemy))
    
    # One-shot connection (auto-disconnects after first emit)
    $Timer.timeout.connect(_on_timer_timeout, CONNECT_ONE_SHOT)

# Method 2: Use @onready for node references
@onready var health_component: HealthComponent = $HealthComponent

func _ready() -> void:
    health_component.health_changed.connect(_on_health_changed)
    health_component.died.connect(_on_died)
```

**Signal Bus Pattern (Event Bus/Autoload)**: For complex games with many systems, an event bus provides centralized communication:

```gdscript
# events.gd (Autoload as "Events")
extends Node

# Game events
signal game_started
signal game_paused
signal game_resumed
signal game_over

# Player events
signal player_spawned(player: Player)
signal player_died(player: Player)
signal player_score_changed(new_score: int)

# Enemy events
signal enemy_spawned(enemy: Enemy)
signal enemy_died(enemy: Enemy)

# Usage from anywhere in the codebase
func _on_enemy_defeated(enemy: Enemy) -> void:
    enemy_died.emit(enemy)
    Events.enemy_died.emit(enemy)

func _ready() -> void:
    Events.enemy_died.connect(_on_enemy_died)
```

**Signal Disconnection**: Critical for preventing errors when nodes are freed:

```gdscript
# BAD: Forgetting to disconnect can cause errors when node is freed
func _ready() -> void:
    Events.player_died.connect(_on_player_died)

# GOOD: Disconnect in _exit_tree or use CONNECT_DEFERRED
func _ready() -> void:
    Events.player_died.connect(_on_player_died)

func _exit_tree() -> void:
    if Events.player_died.is_connected(_on_player_died):
        Events.player_died.disconnect(_on_player_died)
```

LLM assistants should always generate disconnection code when signals are connected in `_ready()`, and should prefer the `is_connected()` check before disconnection to avoid runtime errors.

## Project Structure Guidelines

### Recommended Folder Organization

Godot 4.x projects benefit from consistent folder structures that separate concerns and facilitate team collaboration. The following structure represents community consensus for medium to large Godot projects:

```
project/
├── addons/                          # Third-party plugins
├── assets/                          # Raw assets (imported resources)
│   ├── audio/
│   │   ├── music/                   # Background music files
│   │   └── sfx/                     # Sound effect files
│   ├── fonts/                       # Font files (.ttf, .otf)
│   ├── sprites/                     # Sprite sheets and textures
│   │   ├── characters/
│   │   ├── enemies/
│   │   ├── items/
│   │   └── ui/
│   ├── tilesets/                    # Tilemap data and tileset images
│   └── models/                      # 3D models (.obj, .gltf)
├── resources/                       # Custom .tres files (Resources)
│   ├── items/
│   ├── weapons/
│   ├── characters/
│   └── configurations/
├── scenes/                          # PackedScene files (.tscn)
│   ├── autoloads/                   # Singleton scenes
│   ├── characters/
│   │   ├── player/
│   │   │   ├── player.tscn
│   │   │   └── player.gd
│   │   └── enemies/
│   ├── components/                  # Reusable component scenes
│   │   ├── health_component.tscn
│   │   ├── hitbox_component.tscn
│   │   └── hitbox_component.gd
│   ├── levels/
│   │   ├── level_01.tscn
│   │   ├── level_02.tscn
│   │   └── level_manager.gd
│   ├── ui/
│   │   ├── hud/
│   │   │   ├── health_bar.tscn
│   │   │   └── score_display.tscn
│   │   └── menus/
│   │       ├── main_menu.tscn
│   │       ├── pause_menu.tscn
│   │       └── settings_menu.tscn
│   └── main.tscn
├── scripts/                         # Standalone scripts
│   ├── autoloads/                   # Autoload script files
│   │   ├── game_manager.gd
│   │   ├── save_manager.gd
│   │   └── events.gd
│   ├── classes/                     # Base classes and interfaces
│   │   ├── state.gd
│   │   ├── state_machine.gd
│   │   └── entity.gd
│   ├── resources/                   # Resource script files
│   │   ├── weapon_data.gd
│   │   ├── item_data.gd
│   │   └── character_stats.gd
│   └── utilities/                   # Utility scripts
│       ├── math_utils.gd
│       ├── file_utils.gd
│       └── extensions/
├── tests/                           # GUT test files
│   ├── test_player.gd
│   ├── test_health_component.gd
│   ├── test_state_machine.gd
│   └── integration/
├── project.godot                    # Project configuration
├── export_presets.cfg               # Export configurations
└── README.md                        # Project documentation
```

**Feature-Based Organization**: An alternative approach groups files by feature rather than file type:

```
project/
├── player/
│   ├── player.tscn
│   ├── player.gd
│   ├── player_sprites.png
│   └── player_sounds/
├── enemies/
│   ├── enemy_base.tscn
│   ├── enemy_base.gd
│   ├── goblin.tscn
│   ├── goblin.gd
│   └── boss.tscn
└── ui/
    ├── main_menu.tscn
    ├── hud.tscn
    └── settings.tscn
```

LLM assistants should determine which structure matches the existing project or default to the first structure for new projects, as it provides better separation of concerns for larger codebases.

### Scene Organization Patterns

**Scene Composition (Preferred over Inheritance)**: Godot 4.x promotes scene composition where complex objects are built from reusable child nodes rather than deep inheritance hierarchies:

```
Player (CharacterBody2D)
├── Sprite2D
├── CollisionShape2D
├── AnimationPlayer
├── HealthComponent (Node)           # Reusable component
│   └── health_component.gd
├── HitboxComponent (Area2D)         # Reusable component
│   └── hitbox_component.gd
└── StateMachine (Node)              # FSM pattern
    ├── idle_state.tscn
    │   └── idle_state.gd
    ├── walk_state.tscn
    │   └── walk_state.gd
    └── jump_state.tscn
        └── jump_state.gd
```

This composition approach offers several advantages: components can be reused across different entities, testing becomes easier as components are isolated, and modifications to one component don't cascade through inheritance hierarchies.

**Scene-Specific Assets**: Assets that are only used by a single scene should be placed in that scene's folder or referenced locally. Shared assets go in common directories at the project root level. This organization minimizes accidental resource sharing and makes it clear which assets are shared versus scene-specific.

## Common Patterns and Examples

### Autoload/Singleton Patterns

Godot's Autoload feature implements the Singleton pattern at the engine level, providing globally accessible objects that persist across scene changes. LLMs must understand appropriate use cases and common pitfalls.

**Game Manager Singleton**:

```gdscript
# game_manager.gd (Add to Project Settings > Autoload as "GameManager")
extends Node

signal game_state_changed(new_state: GameState)

enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }

var current_state: GameState = GameState.MENU
var score: int = 0
var high_score: int = 0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS  # Run even when paused

func change_state(new_state: GameState) -> void:
    current_state = new_state
    game_state_changed.emit(new_state)
    
    match new_state:
        GameState.PAUSED:
            get_tree().paused = true
        GameState.PLAYING:
            get_tree().paused = false
        GameState.GAME_OVER:
            _check_high_score()

func _check_high_score() -> void:
    if score > high_score:
        high_score = score
        SaveManager.save_high_score(high_score)
```

**Save/Load Manager**:

```gdscript
# save_manager.gd (Autoload as "SaveManager")
extends Node

const SAVE_PATH: String = "user://save_data.json"

var save_data: Dictionary = {
    "high_score": 0,
    "settings": {
        "music_volume": 1.0,
        "sfx_volume": 1.0,
        "fullscreen": false
    },
    "unlocks": []
}

func _ready() -> void:
    load_game()

func save_game() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(save_data, "\t"))
        file.close()

func load_game() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file:
        var json := JSON.new()
        var error := json.parse(file.get_as_text())
        file.close()
        
        if error == OK:
            save_data = json.data

func save_high_score(score: int) -> void:
    save_data["high_score"] = score
    save_game()
```

**Common Autoload Mistakes to Avoid**:

| Common Mistake | Best Practice | Explanation |
|---------------|---------------|-------------|
| Putting everything in Autoload | Register only truly global items | Keep global state minimal; data specific to certain scenes or features should be managed within them |
| Directly manipulating other nodes from Autoload | Use signals for loose coupling | Instead of Autoload directly changing UI node text, define signals in Autoload and have UI connect to those signals |

### State Machine Patterns

State machines are fundamental to game development, providing structured ways to manage entity behavior. Godot 4.x supports multiple state machine implementations.

**Node-Based State Machine (Recommended for Godot 4.x)**:

```gdscript
# state_machine.gd
class_name StateMachine
extends Node

@export var initial_state: State

var current_state: State
var states: Dictionary = {}

func _ready() -> void:
    for child in get_children():
        if child is State:
            states[child.name.to_lower()] = child
            child.state_machine = self
    
    if initial_state:
        current_state = initial_state
        current_state.enter()

func _process(delta: float) -> void:
    if current_state:
        current_state.update(delta)

func _physics_process(delta: float) -> void:
    if current_state:
        current_state.physics_update(delta)

func transition_to(state_name: String) -> void:
    if not states.has(state_name):
        push_warning("State '%s' does not exist" % state_name)
        return
    
    if current_state:
        current_state.exit()
    
    current_state = states[state_name]
    current_state.enter()
```

```gdscript
# state.gd (Base class for all states)
class_name State
extends Node

var state_machine: StateMachine

func enter() -> void:
    pass

func exit() -> void:
    pass

func update(_delta: float) -> void:
    pass

func physics_update(_delta: float) -> void:
    pass
```

**Concrete State Implementation**:

```gdscript
# idle_state.gd
class_name IdleState
extends State

func enter() -> void:
    # Play idle animation
    state_machine.get_parent().animation_player.play("idle")

func update(delta: float) -> void:
    var entity = state_machine.get_parent()
    
    # Check for state transitions
    if Input.is_action_just_pressed("jump") and entity.is_on_floor():
        state_machine.transition_to("jump")
    elif entity.velocity.x != 0:
        state_machine.transition_to("walk")

func physics_update(delta: float) -> void:
    var entity = state_machine.get_parent()
    entity.velocity.y += entity.gravity * delta
```

**Enum-Based State Machine (Simpler Alternative)**:

For simpler use cases, an enum-based state machine provides a lightweight solution:

```gdscript
# simple_state_machine.gd
class_name SimpleStateMachine
extends Node

enum State { IDLE, WALK, JUMP, FALL }

@export var initial_state: State = State.IDLE

var current_state: State
var state_functions: Dictionary = {}

func _ready() -> void:
    current_state = initial_state
    state_functions[State.IDLE] = _update_idle
    state_functions[State.WALK] = _update_walk
    state_functions[State.JUMP] = _update_jump
    state_functions[State.FALL] = _update_fall

func _physics_process(delta: float) -> void:
    var update_func = state_functions.get(current_state)
    if update_func:
        update_func.call(delta)

func _update_idle(delta: float) -> void:
    # Idle logic
    pass

func _update_walk(delta: float) -> void:
    # Walk logic
    pass

func _update_jump(delta: float) -> void:
    # Jump logic
    pass

func _update_fall(delta: float) -> void:
    # Fall logic
    pass
```

### Component Pattern

The component pattern enables reusable, composable game logic:

```gdscript
# health_component.gd
class_name HealthComponent
extends Node

signal health_changed(current: int, max_health: int)
signal died

@export var max_health: int = 100
var current_health: int

func _ready() -> void:
    current_health = max_health

func take_damage(amount: int) -> void:
    current_health = maxi(0, current_health - amount)
    health_changed.emit(current_health, max_health)
    if current_health == 0:
        died.emit()

func heal(amount: int) -> void:
    current_health = mini(max_health, current_health + amount)
    health_changed.emit(current_health, max_health)
```

Components are then attached to entities:

```gdscript
# enemy.gd
class_name Enemy
extends CharacterBody2D

@onready var health_component: HealthComponent = $HealthComponent

func _ready() -> void:
    health_component.died.connect(_on_died)

func _on_died() -> void:
    # Death logic
    queue_free()
```

### Custom Resources

Resources provide data containers that can be edited in the inspector and shared across instances:

```gdscript
# weapon_data.gd
class_name WeaponData
extends Resource

@export var name: String = "Weapon"
@export var damage: int = 10
@export var attack_speed: float = 1.0
@export var range: float = 100.0
@export var icon: Texture2D
@export_multiline var description: String = ""

# Optional: Add methods to resources
func get_dps() -> float:
    return damage * attack_speed
```

Usage:

```gdscript
# In weapon script
@export var weapon_data: WeaponData

func attack() -> void:
    var damage = weapon_data.damage
    # ... attack logic
```

## Testing Guidelines

### GUT Framework Integration

The GUT (Godot Unit Testing) framework is the primary testing solution for Godot 4.x projects. LLMs should generate testable code and understand testing patterns.

**Test Structure**:

```gdscript
# test_player.gd
extends GutTest

var player: Player

func before_each() -> void:
    player = Player.new()
    add_child_autofree(player)

func after_each() -> void:
    player = null

func test_initial_health() -> void:
    assert_eq(player.current_health, 100, "Initial health should be 100")

func test_take_damage() -> void:
    player.take_damage(30)
    assert_eq(player.current_health, 70, "Health should be 70 after 30 damage")

func test_cannot_have_negative_health() -> void:
    player.take_damage(200)
    assert_eq(player.current_health, 0, "Health should not go below 0")

func test_death_signal_emitted() -> void:
    watch_signals(player)
    player.take_damage(100)
    assert_signal_emitted(player, "died")
```

**Running Tests**:

```bash
# Run all tests via command line
godot --headless --script addons/gut/gut_cmdln.gd

# Run specific test file
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests -gtest=test_player.gd
```

**Testable Code Patterns**: LLMs should generate code that is inherently testable by avoiding dependencies on global state where possible, using dependency injection for external services, and structuring logic in small, focused functions.

### Debugging Techniques

**Print Debugging**:

```gdscript
# Basic print
print("Player position: ", position)

# Formatted print
print("Health: %d/%d" % [current_health, max_health])

# Print with function name for context
print("[%s] State changed to: %s" % [name, state_name])

# Push warnings and errors
push_warning("Enemy spawn point not found")
push_error("Critical: Player node is null!")

# Conditional debugging (remove in release)
if OS.is_debug_build():
    print("Debug: Frame time = ", delta)
```

**Assert Statements**:

```gdscript
func set_health(value: int) -> void:
    assert(value >= 0, "Health cannot be negative")
    assert(value <= max_health, "Health cannot exceed max_health")
    current_health = value
```

**Debug Drawing**:

```gdscript
# Draw debug shapes in _draw()
func _draw() -> void:
    if not OS.is_debug_build():
        return
    
    # Draw collision radius
    draw_circle(Vector2.ZERO, attack_range, Color(1, 0, 0, 0.3))
    
    # Draw velocity vector
    draw_line(Vector2.ZERO, velocity.normalized() * 50, Color.GREEN, 2.0)
    
    # Draw path
    for i in range(path.size() - 1):
        draw_line(path[i], path[i + 1], Color.BLUE, 2.0)

# Force redraw when needed
queue_redraw()
```

**Remote Debugger**:

```gdscript
# Break at specific point (in debug builds)
breakpoint

# Conditional breakpoint
if enemy_count > 100:
    breakpoint
```

## Performance Guidelines

### Common Performance Pitfalls

**Object Creation in Loops**: Creating new objects each frame causes garbage collection pressure:

```gdscript
# BAD: Creates new Vector2 every frame
func _physics_process(delta: float) -> void:
    velocity = Vector2(speed, 0)

# GOOD: Reuse or use static values
var _velocity: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
    _velocity.x = speed
    _velocity.y = 0
```

**Node Not Found Errors**: Common error that LLMs should help prevent:

```gdscript
# BAD: Using $NodeName before node is in tree
var sprite = $Sprite2D  # Might fail if called too early

# GOOD: Use @onready
@onready var sprite: Sprite2D = $Sprite2D

# ALTERNATIVE: Get node in _ready()
var sprite: Sprite2D

func _ready() -> void:
    sprite = $Sprite2D
```

**Physics vs Process Timing**: Movement should only happen in `_physics_process()`:

```gdscript
# BAD: Movement in _process() causes inconsistent physics
func _process(delta: float) -> void:
    velocity += GRAVITY * delta
    move_and_slide()  # Wrong!

# GOOD: Physics in _physics_process()
func _physics_process(delta: float) -> void:
    velocity += GRAVITY * delta
    move_and_slide()
```

### Optimization Patterns

**Object Pooling**: Critical for frequently spawned/despawned objects:

```gdscript
# object_pool.gd
class_name ObjectPool
extends Node

@export var pooled_scene: PackedScene
@export var initial_size: int = 10

var _pool: Array[Node] = []

func _ready() -> void:
    for i in range(initial_size):
        _create_pooled_object()

func _create_pooled_object() -> Node:
    var obj := pooled_scene.instantiate()
    obj.set_process_mode(Node.PROCESS_MODE_DISABLED)
    obj.hide()
    add_child(obj)
    _pool.append(obj)
    return obj

func get_object() -> Node:
    for obj in _pool:
        if not obj.visible:
            obj.show()
            obj.set_process_mode(Node.PROCESS_MODE_INHERIT)
            return obj
    
    # Pool exhausted, create new
    var obj := _create_pooled_object()
    obj.show()
    obj.set_process_mode(Node.PROCESS_MODE_INHERIT)
    return obj

func return_object(obj: Node) -> void:
    obj.hide()
    obj.set_process_mode(Node.PROCESS_MODE_DISABLED)
```

Object pooling is particularly important for: bullet hell shooter projectiles, spark effects on hit, coins dropped by enemies, and frequently spawning/despawning minor enemies.

**Disable Processing When Not Needed**:

```gdscript
func _ready() -> void:
    set_process(false)  # Disable _process
    set_physics_process(false)  # Disable _physics_process

func activate() -> void:
    set_process(true)
    set_physics_process(true)

func deactivate() -> void:
    set_process(false)
    set_physics_process(false)
```

**Deferred Execution**: Use `call_deferred()` for operations that should not execute during physics steps:

```gdscript
# BAD: Might cause issues during physics step
func _on_enemy_died() -> void:
    enemy.queue_free()
    spawn_loot()

# GOOD: Defer to safe frame
func _on_enemy_died() -> void:
    enemy.queue_free()
    call_deferred("spawn_loot")
```

### Profiling and Measurement

Godot provides built-in profiling tools that LLMs should reference when optimizing code. The frame profiler shows time spent in each function, the scene profiler shows scene loading times, and the physics debugger visualizes collision shapes and physics objects. When addressing performance issues, LLMs should recommend profiling first rather than implementing optimizations based on speculation.

## Recommendations

### For LLM Code Generation

1. **Always use type annotations**: Generate GDScript 2.0 code with explicit type hints for all variables, parameters, and return values.

2. **Follow script structure order**: Generate scripts in the exact order defined in the official style guide: annotations, class_name, extends, doc comments, signals, enums, constants, variables, and methods.

3. **Prefer composition over inheritance**: When generating code for game entities, use scene composition with reusable components rather than deep inheritance hierarchies.

4. **Use modern signal connections**: Generate `Signal.connect()` calls instead of legacy `Object.connect()` with string method names.

5. **Include resource management**: When generating code that modifies resources, consider the `local_to_scene` setting and document potential shared state issues.

6. **Handle null safely**: Always check for null nodes using `@onready` or `is_instance_valid()` before accessing node properties.

7. **Generate testable code**: Structure logic in small, focused functions that can be unit tested independently.

### For Code Review and Refactoring

1. **Verify breaking changes**: When refactoring Godot 3.x code, identify and update deprecated patterns including `@export` annotations and signal connection methods.

2. **Check autoload usage**: Review singleton usage to ensure only truly global state is stored in autoloads, with scene-specific data managed locally.

3. **Validate performance patterns**: Identify object creation in loops and recommend object pooling where appropriate.

4. **Test edge cases**: Ensure generated code handles null nodes, disconnected signals, and physics/process timing correctly.

### For Documentation and Communication

1. **Document version-specific behavior**: When explaining Godot concepts, clarify which features are version-specific to Godot 4.x.

2. **Explain patterns with examples**: Provide working code examples for all patterns and anti-patterns.

3. **Reference official sources**: Cite the official GDScript style guide and documentation for authoritative information.

4. **Warn about common pitfalls**: Include notes about known issues like resource sharing behavior and signal disconnection requirements.

## References

1. Godot Engine Official Documentation - https://docs.godotengine.org/
2. Godot 4.5 Release Notes - https://godotengine.org/article/godot-4-5-released/
3. GDScript Style Guide - https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html
4. Godot Engine GitHub Repository - https://github.com/godotengine/godot
5. GDQuest Godot 4.x Courses - https://school.gdquest.com/
6. GUT Testing Framework - https://github.com/bitwes/Gut
7. Godot Forum Best Practices - https://forum.godotengine.org/
8. Migrating to Godot 4.1+ - https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.1.html
