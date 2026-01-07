# Godot 4.5.1 Development Guidelines

> Auto-loaded by AI coding assistants for the "Echoes of the Void" project.
> Last Updated: 2025-01-07

---

## Project Information

| Property | Value |
|----------|-------|
| Engine | Godot 4.5.1 |
| Project | Echoes of the Void |
| Genre | 2D Platformer |
| GDScript Version | 2.0 |
| Renderer | Forward+ (Vulkan) |

### Project Goals
- Responsive, tight platformer controls
- Multiple enemy types with distinct AI behaviors
- Modular, component-based architecture
- Testable, maintainable codebase

---

## GDScript Coding Standards

### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Classes | PascalCase | `PlayerController`, `EnemySpawner` |
| Files | snake_case | `player_controller.gd`, `enemy_spawner.gd` |
| Functions | snake_case | `calculate_damage()`, `spawn_enemy()` |
| Variables | snake_case | `current_health`, `move_speed` |
| Constants | SCREAMING_SNAKE_CASE | `MAX_HEALTH`, `GRAVITY` |
| Signals | snake_case, past tense | `health_changed`, `player_died` |
| Enums | PascalCase (type), SCREAMING_SNAKE_CASE (values) | `enum State { IDLE, RUNNING }` |
| Private members | Prefix with underscore | `_internal_velocity`, `_cached_path` |

### Script Structure Order (MANDATORY)

Scripts MUST follow this exact order:

```gdscript
# 1. Tool annotation (if applicable)
@tool

# 2. Class name
class_name Player

# 3. Extends
extends CharacterBody2D

# 4. Doc comment
## Player character controller for Echoes of the Void.
## Handles movement, jumping, and combat input.

# 5. Signals
signal health_changed(current: int, max_health: int)
signal died
signal attack_performed(attack_type: String)

# 6. Enums
enum State { IDLE, RUNNING, JUMPING, FALLING, ATTACKING }

# 7. Constants
const MAX_HEALTH: int = 100
const GRAVITY: float = 980.0
const COYOTE_TIME: float = 0.1

# 8. Static variables
static var instance_count: int = 0

# 9. @export variables (grouped logically)
@export_group("Movement")
@export var move_speed: float = 300.0
@export var jump_force: float = 400.0
@export var acceleration: float = 2000.0

@export_group("Combat")
@export var attack_damage: int = 10
@export var attack_cooldown: float = 0.5

# 10. Regular variables
var current_health: int = MAX_HEALTH
var current_state: State = State.IDLE
var _coyote_timer: float = 0.0

# 11. @onready variables
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var state_machine: StateMachine = $StateMachine

# 12. Built-in virtual methods (in lifecycle order)
func _init() -> void:
    instance_count += 1

func _enter_tree() -> void:
    pass

func _ready() -> void:
    _connect_signals()

func _process(delta: float) -> void:
    _update_animations()

func _physics_process(delta: float) -> void:
    _apply_gravity(delta)
    _handle_movement(delta)
    move_and_slide()

func _exit_tree() -> void:
    instance_count -= 1

# 13. Public methods
func take_damage(amount: int) -> void:
    current_health = maxi(0, current_health - amount)
    health_changed.emit(current_health, MAX_HEALTH)
    if current_health == 0:
        died.emit()

func heal(amount: int) -> void:
    current_health = mini(MAX_HEALTH, current_health + amount)
    health_changed.emit(current_health, MAX_HEALTH)

# 14. Private methods
func _connect_signals() -> void:
    pass

func _apply_gravity(delta: float) -> void:
    if not is_on_floor():
        velocity.y += GRAVITY * delta

func _handle_movement(delta: float) -> void:
    var direction := Input.get_axis("move_left", "move_right")
    velocity.x = move_toward(velocity.x, direction * move_speed, acceleration * delta)

func _update_animations() -> void:
    pass

# 15. Inner classes (if any)
class DamageInfo:
    var amount: int
    var source: Node
    var is_critical: bool
    
    func _init(dmg: int, src: Node, crit: bool = false) -> void:
        amount = dmg
        source = src
        is_critical = crit
```

### Type Hints (REQUIRED)

Type hints are **mandatory** in this project. They enable:
- Static type checking in the editor
- Better autocompletion
- Compile-time error detection
- Performance optimizations

```gdscript
# Variables - ALWAYS type annotated
var health: int = 100
var velocity: Vector2 = Vector2.ZERO
var target: Node2D = null
var enemies: Array[Enemy] = []
var stats: Dictionary = {}

# Function parameters and return types - ALWAYS typed
func calculate_damage(base: int, multiplier: float) -> int:
    return int(base * multiplier)

func get_nearest_enemy() -> Enemy:
    return null  # Placeholder

func find_path(start: Vector2, end: Vector2) -> Array[Vector2]:
    return []

# Use 'void' for functions that don't return a value
func _ready() -> void:
    pass
```

---

## Node & Scene Guidelines

### Scene Composition (Prefer Over Inheritance)

Build complex entities by composing reusable component nodes:

```
Player (CharacterBody2D)
├── Sprite2D
├── CollisionShape2D
├── AnimationPlayer
├── AnimationTree
├── HealthComponent          # Reusable
├── HitboxComponent (Area2D) # Reusable
├── HurtboxComponent (Area2D)# Reusable
├── StateMachine
│   ├── IdleState
│   ├── RunState
│   ├── JumpState
│   ├── FallState
│   └── AttackState
└── AudioStreamPlayer2D
```

### Node Naming Conventions

| Node Type | Convention | Example |
|-----------|------------|---------|
| Standard nodes | PascalCase matching type | `Sprite2D`, `AnimationPlayer` |
| Custom nodes | Descriptive PascalCase | `HealthComponent`, `EnemySpawner` |
| Collision shapes | Purpose + type | `BodyCollision`, `AttackHitbox` |
| Markers/positions | Purpose + Marker2D | `SpawnPoint`, `GroundCheck` |

### Signal Best Practices

**Declaration with typed parameters:**
```gdscript
signal health_changed(current: int, max_health: int)
signal enemy_spawned(enemy: Enemy)
signal level_completed(time_taken: float, score: int)
```

**Modern connection syntax (Godot 4.x):**
```gdscript
func _ready() -> void:
    # Direct connection
    $Button.pressed.connect(_on_button_pressed)
    
    # Connection with bound arguments
    $Enemy.died.connect(_on_enemy_died.bind($Enemy))
    
    # One-shot connection (auto-disconnects after first emit)
    $Timer.timeout.connect(_on_timer_timeout, CONNECT_ONE_SHOT)
    
    # Deferred connection (calls on idle frame)
    $Area2D.body_entered.connect(_on_body_entered, CONNECT_DEFERRED)
```

**Always disconnect when necessary:**
```gdscript
func _exit_tree() -> void:
    # Prevent errors when node is freed
    if Events.player_died.is_connected(_on_player_died):
        Events.player_died.disconnect(_on_player_died)
```

---

## Common Patterns

### Autoload/Singleton Pattern

Use for truly global state only. Register in Project Settings > Autoload.

**Events Bus (events.gd):**
```gdscript
extends Node

# Game state events
signal game_started
signal game_paused
signal game_resumed
signal game_over(final_score: int)

# Player events
signal player_spawned(player: Player)
signal player_died
signal player_health_changed(current: int, maximum: int)

# Level events
signal level_loaded(level_name: String)
signal checkpoint_reached(checkpoint_id: int)
```

**Game Manager (game_manager.gd):**
```gdscript
extends Node

enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }

var current_state: GameState = GameState.MENU
var score: int = 0
var current_level: int = 1

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS  # Run even when paused

func pause_game() -> void:
    current_state = GameState.PAUSED
    get_tree().paused = true
    Events.game_paused.emit()

func resume_game() -> void:
    current_state = GameState.PLAYING
    get_tree().paused = false
    Events.game_resumed.emit()

func game_over() -> void:
    current_state = GameState.GAME_OVER
    Events.game_over.emit(score)
```

### State Machine Pattern

**Base State (state.gd):**
```gdscript
class_name State
extends Node

## Base class for all states. Override methods as needed.

var state_machine: StateMachine
var entity: CharacterBody2D

func enter() -> void:
    pass

func exit() -> void:
    pass

func update(_delta: float) -> void:
    pass

func physics_update(_delta: float) -> void:
    pass

func handle_input(_event: InputEvent) -> void:
    pass
```

**State Machine (state_machine.gd):**
```gdscript
class_name StateMachine
extends Node

@export var initial_state: State
@export var entity: CharacterBody2D

var current_state: State
var states: Dictionary = {}

func _ready() -> void:
    for child in get_children():
        if child is State:
            states[child.name.to_lower()] = child
            child.state_machine = self
            child.entity = entity
    
    if initial_state:
        current_state = initial_state
        current_state.enter()

func _process(delta: float) -> void:
    if current_state:
        current_state.update(delta)

func _physics_process(delta: float) -> void:
    if current_state:
        current_state.physics_update(delta)

func _unhandled_input(event: InputEvent) -> void:
    if current_state:
        current_state.handle_input(event)

func transition_to(state_name: String) -> void:
    var new_state := states.get(state_name.to_lower()) as State
    if not new_state:
        push_warning("State '%s' not found in StateMachine" % state_name)
        return
    
    if current_state:
        current_state.exit()
    
    current_state = new_state
    current_state.enter()
```

### Component Pattern

**Health Component (health_component.gd):**
```gdscript
class_name HealthComponent
extends Node

signal health_changed(current: int, maximum: int)
signal died
signal damage_taken(amount: int, source: Node)

@export var max_health: int = 100
@export var invincibility_time: float = 0.0

var current_health: int
var _invincible: bool = false

func _ready() -> void:
    current_health = max_health

func take_damage(amount: int, source: Node = null) -> void:
    if _invincible:
        return
    
    current_health = maxi(0, current_health - amount)
    damage_taken.emit(amount, source)
    health_changed.emit(current_health, max_health)
    
    if current_health == 0:
        died.emit()
    elif invincibility_time > 0:
        _start_invincibility()

func heal(amount: int) -> void:
    current_health = mini(max_health, current_health + amount)
    health_changed.emit(current_health, max_health)

func _start_invincibility() -> void:
    _invincible = true
    await get_tree().create_timer(invincibility_time).timeout
    _invincible = false
```

**Hitbox Component (hitbox_component.gd):**
```gdscript
class_name HitboxComponent
extends Area2D

signal hit_registered(hurtbox: HurtboxComponent)

@export var damage: int = 10
@export var knockback_force: float = 200.0

var owner_entity: Node

func _ready() -> void:
    owner_entity = get_parent()
    area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
    if area is HurtboxComponent:
        var hurtbox := area as HurtboxComponent
        if hurtbox.owner_entity != owner_entity:
            hurtbox.receive_hit(self)
            hit_registered.emit(hurtbox)
```

---

## Anti-Patterns (NEVER DO)

### Type Safety Violations

```gdscript
# NEVER: Using untyped variables
var health = 100  # Bad: no type
var enemies = []  # Bad: untyped array

# ALWAYS: Full type annotations
var health: int = 100
var enemies: Array[Enemy] = []
```

### Signal Anti-Patterns

```gdscript
# NEVER: Legacy string-based connection (Godot 3.x style)
connect("health_changed", self, "_on_health_changed")  # DEPRECATED

# ALWAYS: Modern Signal.connect() method
health_changed.connect(_on_health_changed)

# NEVER: Forgetting to disconnect from global signals
func _ready() -> void:
    Events.game_over.connect(_on_game_over)
    # Node gets freed, signal still connected = ERROR

# ALWAYS: Clean disconnection
func _exit_tree() -> void:
    if Events.game_over.is_connected(_on_game_over):
        Events.game_over.disconnect(_on_game_over)
```

### Node Reference Anti-Patterns

```gdscript
# NEVER: Getting nodes before they exist
var sprite = $Sprite2D  # May fail if called before _ready

# ALWAYS: Use @onready
@onready var sprite: Sprite2D = $Sprite2D

# NEVER: Assuming nodes exist
func _ready() -> void:
    $Player.take_damage(10)  # Crashes if Player doesn't exist

# ALWAYS: Null checks or is_instance_valid
func _ready() -> void:
    var player := get_node_or_null("Player") as Player
    if player:
        player.take_damage(10)
```

### Physics Anti-Patterns

```gdscript
# NEVER: Physics in _process()
func _process(delta: float) -> void:
    velocity.y += GRAVITY * delta
    move_and_slide()  # WRONG: Inconsistent physics

# ALWAYS: Physics in _physics_process()
func _physics_process(delta: float) -> void:
    velocity.y += GRAVITY * delta
    move_and_slide()

# NEVER: Modifying physics during physics callbacks without defer
func _on_body_entered(body: Node2D) -> void:
    body.queue_free()
    spawn_explosion()  # May cause issues

# ALWAYS: Defer scene tree modifications
func _on_body_entered(body: Node2D) -> void:
    body.queue_free()
    call_deferred("spawn_explosion")
```

### Performance Anti-Patterns

```gdscript
# NEVER: Creating objects every frame
func _physics_process(delta: float) -> void:
    var new_velocity := Vector2(speed, 0)  # Creates garbage

# ALWAYS: Reuse or modify in place
var _velocity: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
    _velocity.x = speed
    _velocity.y = 0

# NEVER: get_node() in loops
func _process(delta: float) -> void:
    var player = get_node("/root/Main/Player")  # Slow!
    
# ALWAYS: Cache node references
@onready var player: Player = get_node("/root/Main/Player")
```

---

## Project File Structure

```
echoes-of-the-void/
├── addons/                     # Third-party plugins (GUT, etc.)
├── assets/
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   ├── fonts/
│   ├── sprites/
│   │   ├── player/
│   │   ├── enemies/
│   │   ├── environment/
│   │   ├── items/
│   │   └── ui/
│   └── tilesets/
├── resources/                  # Custom Resource .tres files
│   ├── enemy_data/
│   ├── item_data/
│   └── level_data/
├── scenes/
│   ├── autoloads/              # Autoload scenes
│   ├── characters/
│   │   ├── player/
│   │   │   ├── player.tscn
│   │   │   └── player.gd
│   │   └── enemies/
│   │       ├── enemy_base.tscn
│   │       ├── enemy_base.gd
│   │       ├── slime/
│   │       ├── bat/
│   │       └── boss/
│   ├── components/             # Reusable components
│   │   ├── health_component.tscn
│   │   ├── hitbox_component.tscn
│   │   ├── hurtbox_component.tscn
│   │   └── state_machine.tscn
│   ├── levels/
│   │   ├── level_01/
│   │   ├── level_02/
│   │   └── level_manager.gd
│   ├── objects/                # Interactable objects
│   │   ├── collectibles/
│   │   ├── platforms/
│   │   └── hazards/
│   ├── ui/
│   │   ├── hud/
│   │   └── menus/
│   └── main.tscn
├── scripts/
│   ├── autoloads/
│   │   ├── events.gd
│   │   ├── game_manager.gd
│   │   └── save_manager.gd
│   ├── classes/                # Base classes
│   │   ├── state.gd
│   │   ├── state_machine.gd
│   │   └── entity.gd
│   ├── components/
│   │   ├── health_component.gd
│   │   ├── hitbox_component.gd
│   │   └── hurtbox_component.gd
│   ├── resources/              # Resource definitions
│   │   ├── enemy_data.gd
│   │   └── item_data.gd
│   └── utilities/
│       └── math_utils.gd
├── tests/                      # GUT test files
│   ├── unit/
│   │   ├── test_player.gd
│   │   └── test_health_component.gd
│   └── integration/
├── docs/                       # Documentation
├── project.godot
├── export_presets.cfg
├── AGENTS.md                   # This file
└── README.md
```

---

## Player Controller Guidelines

### Core 2D Platformer Physics

```gdscript
class_name Player
extends CharacterBody2D

## Echoes of the Void player controller.
## Implements responsive platformer movement with coyote time and jump buffering.

# Movement constants
const GRAVITY: float = 1200.0
const MAX_FALL_SPEED: float = 600.0
const COYOTE_TIME: float = 0.1
const JUMP_BUFFER_TIME: float = 0.1

# Exported for tuning
@export_group("Movement")
@export var move_speed: float = 200.0
@export var acceleration: float = 1500.0
@export var friction: float = 1000.0
@export var air_control: float = 0.7

@export_group("Jumping")
@export var jump_force: float = 350.0
@export var jump_cut_multiplier: float = 0.5
@export var max_jumps: int = 1

# State tracking
var _jumps_remaining: int = 0
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _was_on_floor: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _physics_process(delta: float) -> void:
    var on_floor := is_on_floor()
    
    # Update coyote time
    if on_floor:
        _coyote_timer = COYOTE_TIME
        _jumps_remaining = max_jumps
    elif _was_on_floor:
        # Just left the ground (didn't jump)
        pass
    
    _coyote_timer = maxf(0.0, _coyote_timer - delta)
    _jump_buffer_timer = maxf(0.0, _jump_buffer_timer - delta)
    _was_on_floor = on_floor
    
    # Gravity
    if not on_floor:
        velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
    
    # Horizontal movement
    var input_dir := Input.get_axis("move_left", "move_right")
    var control_mult := 1.0 if on_floor else air_control
    
    if input_dir != 0:
        velocity.x = move_toward(
            velocity.x,
            input_dir * move_speed,
            acceleration * control_mult * delta
        )
        sprite.flip_h = input_dir < 0
    else:
        velocity.x = move_toward(velocity.x, 0.0, friction * control_mult * delta)
    
    # Jump buffering - store jump intent
    if Input.is_action_just_pressed("jump"):
        _jump_buffer_timer = JUMP_BUFFER_TIME
    
    # Execute jump if buffered and can jump
    if _jump_buffer_timer > 0 and _can_jump():
        _perform_jump()
    
    # Variable jump height (release to cut jump short)
    if Input.is_action_just_released("jump") and velocity.y < 0:
        velocity.y *= jump_cut_multiplier
    
    move_and_slide()

func _can_jump() -> bool:
    return _coyote_timer > 0 or _jumps_remaining > 0

func _perform_jump() -> void:
    velocity.y = -jump_force
    _jumps_remaining -= 1
    _coyote_timer = 0.0
    _jump_buffer_timer = 0.0
```

### Required Input Actions

Define in Project Settings > Input Map:
- `move_left` - A / Left Arrow
- `move_right` - D / Right Arrow
- `jump` - Space / W / Up Arrow
- `attack` - Left Click / Z
- `dash` - Shift / X
- `pause` - Escape

---

## Enemy AI Guidelines

### Base Enemy Class

```gdscript
class_name Enemy
extends CharacterBody2D

## Base class for all enemies in Echoes of the Void.
## Extend this class to create specific enemy types.

signal died(enemy: Enemy)

@export_group("Stats")
@export var max_health: int = 30
@export var contact_damage: int = 10
@export var move_speed: float = 50.0

@export_group("Detection")
@export var detection_range: float = 200.0
@export var attack_range: float = 30.0

var current_health: int
var player: Player = null
var direction: int = 1

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_machine: StateMachine = $StateMachine
@onready var health_component: HealthComponent = $HealthComponent

func _ready() -> void:
    current_health = max_health
    health_component.died.connect(_on_died)
    _find_player()

func _find_player() -> void:
    # Find player in scene tree
    player = get_tree().get_first_node_in_group("player") as Player

func get_distance_to_player() -> float:
    if not player:
        return INF
    return global_position.distance_to(player.global_position)

func get_direction_to_player() -> int:
    if not player:
        return direction
    return 1 if player.global_position.x > global_position.x else -1

func can_see_player() -> bool:
    return get_distance_to_player() <= detection_range

func is_in_attack_range() -> bool:
    return get_distance_to_player() <= attack_range

func _on_died() -> void:
    died.emit(self)
    # Play death animation, spawn particles, etc.
    queue_free()
```

### AI Behavior Patterns

**Patrol State:**
```gdscript
class_name PatrolState
extends State

@export var patrol_speed: float = 50.0
@export var wait_time: float = 2.0

var _wait_timer: float = 0.0
var _direction: int = 1

func enter() -> void:
    entity.animation_player.play("walk")

func physics_update(delta: float) -> void:
    # Check for player
    if entity.can_see_player():
        state_machine.transition_to("chase")
        return
    
    # Check for walls or ledges
    if _should_turn():
        _direction *= -1
        _wait_timer = wait_time
    
    # Movement
    if _wait_timer > 0:
        _wait_timer -= delta
        entity.velocity.x = 0
    else:
        entity.velocity.x = _direction * patrol_speed
        entity.sprite.flip_h = _direction < 0
    
    entity.move_and_slide()

func _should_turn() -> bool:
    return entity.is_on_wall() or not _has_floor_ahead()

func _has_floor_ahead() -> bool:
    # Raycast downward ahead of enemy to check for floor
    var raycast: RayCast2D = entity.get_node("FloorCheck")
    return raycast.is_colliding()
```

**Chase State:**
```gdscript
class_name ChaseState
extends State

@export var chase_speed: float = 100.0

func enter() -> void:
    entity.animation_player.play("run")

func physics_update(delta: float) -> void:
    if not entity.can_see_player():
        state_machine.transition_to("patrol")
        return
    
    if entity.is_in_attack_range():
        state_machine.transition_to("attack")
        return
    
    var dir := entity.get_direction_to_player()
    entity.velocity.x = dir * chase_speed
    entity.sprite.flip_h = dir < 0
    
    entity.move_and_slide()
```

---

## Performance Guidelines

### Object Pooling

Use for frequently spawned objects (projectiles, effects, coins):

```gdscript
class_name ObjectPool
extends Node

@export var pooled_scene: PackedScene
@export var initial_size: int = 20

var _pool: Array[Node] = []

func _ready() -> void:
    for i in range(initial_size):
        _create_object()

func _create_object() -> Node:
    var obj := pooled_scene.instantiate()
    obj.process_mode = Node.PROCESS_MODE_DISABLED
    obj.hide()
    add_child(obj)
    _pool.append(obj)
    return obj

func get_object() -> Node:
    for obj in _pool:
        if not obj.visible:
            _activate(obj)
            return obj
    
    # Pool exhausted - expand
    var obj := _create_object()
    _activate(obj)
    return obj

func return_object(obj: Node) -> void:
    obj.hide()
    obj.process_mode = Node.PROCESS_MODE_DISABLED

func _activate(obj: Node) -> void:
    obj.show()
    obj.process_mode = Node.PROCESS_MODE_INHERIT
```

### Process Optimization

```gdscript
# Disable processing when not needed
func _ready() -> void:
    set_process(false)
    set_physics_process(false)

func activate() -> void:
    set_process(true)
    set_physics_process(true)

func deactivate() -> void:
    set_process(false)
    set_physics_process(false)

# Use visibility notifiers for off-screen entities
@onready var notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
    notifier.screen_entered.connect(func(): set_physics_process(true))
    notifier.screen_exited.connect(func(): set_physics_process(false))
```

### Delta Time Consistency

```gdscript
# ALWAYS multiply by delta for frame-rate independence
velocity.y += GRAVITY * delta

# For timers, count down with delta
_timer -= delta
if _timer <= 0:
    _do_action()
```

---

## Code Examples

### Correct Signal Usage

```gdscript
# Declaration with typed parameters
signal health_changed(current: int, maximum: int)
signal item_collected(item: ItemData)

# Emission
health_changed.emit(current_health, max_health)

# Connection in _ready()
func _ready() -> void:
    $HealthComponent.health_changed.connect(_on_health_changed)
    $HealthComponent.died.connect(_on_died)
    
    # With additional bound arguments
    for enemy in get_tree().get_nodes_in_group("enemies"):
        enemy.died.connect(_on_enemy_died.bind(enemy))

# Callbacks
func _on_health_changed(current: int, maximum: int) -> void:
    health_bar.value = float(current) / float(maximum)

func _on_enemy_died(enemy: Enemy) -> void:
    score += enemy.score_value
```

### Correct Type Annotations

```gdscript
# Basic types
var name: String = "Player"
var health: int = 100
var speed: float = 200.0
var is_alive: bool = true

# Node types
var player: Player = null
var sprite: Sprite2D = null

# Collections with type hints
var enemies: Array[Enemy] = []
var inventory: Array[ItemData] = []
var stats: Dictionary = {"strength": 10, "agility": 5}

# Nullable types
var current_target: Enemy = null

# Function signatures
func spawn_enemy(type: String, position: Vector2) -> Enemy:
    var enemy := enemy_scene.instantiate() as Enemy
    enemy.global_position = position
    return enemy

func get_health_percentage() -> float:
    return float(current_health) / float(max_health)
```

### Correct Export Syntax

```gdscript
# Basic exports
@export var speed: float = 200.0
@export var max_health: int = 100
@export var player_name: String = "Hero"

# Grouped exports (shows as collapsible in inspector)
@export_group("Movement")
@export var move_speed: float = 200.0
@export var jump_force: float = 400.0
@export var acceleration: float = 1500.0

@export_group("Combat")
@export var attack_damage: int = 10
@export var attack_range: float = 50.0

# Categorized exports (adds a header)
@export_category("Enemy Settings")
@export var detection_range: float = 200.0

# Range constraints
@export_range(0, 100, 1) var health: int = 100
@export_range(0.0, 10.0, 0.1) var multiplier: float = 1.0

# Resource exports
@export var weapon_data: WeaponData
@export var enemy_data: EnemyData

# Node path exports
@export var target_path: NodePath

# File path exports
@export_file("*.tscn") var next_level: String
@export_dir var save_directory: String

# Enum exports
@export var initial_state: State = State.IDLE

# Multiline text
@export_multiline var description: String = ""

# Flags (bitmask)
@export_flags("Fire", "Water", "Earth", "Wind") var elements: int = 0
```

---

## Version-Specific Notes

### Godot 4.5.1 Features

| Feature | Description |
|---------|-------------|
| GDScript 2.0 | New syntax with type annotations, `@export`, `@onready` |
| Vulkan Renderer | Forward+ rendering for modern graphics |
| Typed Arrays | `Array[Type]` for type-safe collections |
| First-class Signals | `signal.connect()` replaces string-based connections |
| Lambda Functions | `func(x): return x * 2` syntax supported |
| Await/Async | Native coroutine support with `await` |

### Breaking Changes from Godot 3.x

| Godot 3.x | Godot 4.x | Notes |
|-----------|-----------|-------|
| `export var` | `@export var` | Annotation syntax |
| `onready var` | `@onready var` | Annotation syntax |
| `connect("signal", object, "method")` | `signal.connect(callable)` | First-class signals |
| `yield(object, "signal")` | `await object.signal` | Async/await |
| `$Node.connect(...)` | `$Node.signal.connect(...)` | Signal access |
| `instance()` | `instantiate()` | Scene instantiation |
| `KinematicBody2D` | `CharacterBody2D` | Renamed node type |
| `move_and_slide(velocity)` | `velocity = ...; move_and_slide()` | Velocity is property |
| `OS.get_ticks_msec()` | `Time.get_ticks_msec()` | Time class |

### GDScript 2.0 vs 1.0

| GDScript 1.0 (Godot 3.x) | GDScript 2.0 (Godot 4.x) |
|--------------------------|--------------------------|
| Optional type hints | Recommended type hints |
| `setget` for properties | Explicit getter/setter |
| `tool` keyword | `@tool` annotation |
| `master`, `puppet` keywords | Removed (use MultiplayerAPI) |
| Implicit self | Explicit self in some cases |

### Resource Sharing Gotcha

When multiple instances share a Resource, modifying it affects ALL instances:

```gdscript
# PROBLEM: All enemies share the same stats resource
@export var stats: EnemyStats  # Shared by default!

# SOLUTION 1: Mark as local to scene in inspector
# Or use Resource.local_to_scene = true

# SOLUTION 2: Duplicate in code
func _ready() -> void:
    stats = stats.duplicate()
```

---

## Quick Reference Card

### Essential Annotations
- `@tool` - Run in editor
- `@export` - Show in inspector
- `@export_group("Name")` - Group exports
- `@onready` - Initialize after _ready
- `@icon("res://icon.png")` - Custom node icon

### Virtual Methods Order
1. `_init()` - Constructor
2. `_enter_tree()` - Added to tree
3. `_ready()` - Node and children ready
4. `_process(delta)` - Every frame
5. `_physics_process(delta)` - Fixed timestep
6. `_exit_tree()` - Removed from tree

### Common Node Methods
- `queue_free()` - Safe deletion
- `get_node("path")` / `$path` - Get child node
- `get_parent()` - Get parent node
- `add_child(node)` - Add child
- `move_and_slide()` - CharacterBody2D movement
- `is_on_floor()` - Ground check

### Input Checks
- `Input.is_action_pressed("action")` - Held
- `Input.is_action_just_pressed("action")` - Just pressed
- `Input.is_action_just_released("action")` - Just released
- `Input.get_axis("neg", "pos")` - -1 to 1 axis

---

## Research Reference

This document incorporates findings from:
`docs/research/godot-4-5-1-best-practices-2025-01-07.md`

For extended documentation on testing (GUT framework), advanced patterns, and performance profiling, refer to the research document.
