# Echoes of the Void - Development Plan

> ⚠️ **CURRENT STATUS: PLAYABLE**
> 
> The game structure is complete and **procedural level geometry is now active**.
> All 5 levels will generate platforms, walls, and one-way platforms at runtime.
> 
> **Phases 1-9:** ✅ Complete (scenes, scripts, procedural geometry system)
> **Phases 10-15:** 🟡 Waiting - Verification and testing
>
> **⚡ All fixes are 100% code-based - NO manual Godot Editor work required**

> **Engine:** Godot 4.5.1
> **Genre:** Atmospheric 2D Precision Platformer  
> **Timeline:** 14 Days (1-2 weeks)  
> **Scope:** 5 Levels, Core Mechanics, Polish

---

## Project Overview

**Echoes of the Void** is a haunting 2D precision platformer where a lone silhouette navigates through fractured dimensions. The player controls a character leaving ethereal "echo trails" as they master advanced movement mechanics including wall jumping, double jumping, and precision landing.

**Visual Identity:** Stark black backgrounds with white/cyan silhouettes, glowing particle effects, and minimalist environmental storytelling.

**Core Loop:** Navigate challenging platforming sections → Collect Light Shards → Find Echo Crystals → Reach level exit → Unlock new areas.

---

## Development Timeline

### Week 1: Foundation & Core Gameplay
| Day | Focus | Deliverables |
|-----|-------|--------------|
| 1-2 | Project Setup & Architecture | Folder structure, autoloads, base classes |
| 3-4 | Player Controller | All movement mechanics functional |
| 5 | Camera & Effects | Camera system, screen effects |
| 6-7 | Enemies & Hazards | All 3 enemy types, death/respawn |

### Week 2: Content & Polish
| Day | Focus | Deliverables |
|-----|-------|--------------|
| 8-9 | Platforms & Collectibles | All platform types, pickups |
| 10-11 | Level Design | All 5 levels blocked out and refined |
| 12 | Visual Polish | Particles, lighting, trails |
| 13 | Audio & Juice | Sound effects, music, screen shake |
| 14 | Menus & Release | Main menu, settings, final testing |

---

## Phase 1: Foundation (Days 1-2)

### 1.1 Project Setup
- [x] Create new Godot 4.5.1 project named "echoes-of-the-void"
- [x] Configure project settings:
  - [x] Set window size to 1920x1080 (16:9 base resolution)
  - [x] Set stretch mode to `canvas_items`, aspect `expand`
  - [x] Configure 2D physics layers: `player`, `enemy`, `platform`, `hazard`, `collectible`
  - [x] Set default clear color to pure black `#000000`
- [x] Create folder structure (see File Structure section below)
- [x] Set up `.gitignore` for Godot project
- [x] Create initial `project.godot` configuration

### 1.2 Input Configuration
- [x] Define input actions in Project Settings → Input Map:
  - [x] `move_left` - A, Left Arrow, D-Pad Left
  - [x] `move_right` - D, Right Arrow, D-Pad Right
  - [x] `jump` - Space, W, Up Arrow, Gamepad South (A/X)
  - [x] `pause` - Escape, Start button
  - [x] `interact` - E, Gamepad West (X/Square)
  - [x] `restart` - R (debug/quick restart)

### 1.3 Core Autoloads
- [x] Create `scripts/autoloads/events.gd` - Signal bus for decoupled communication
  - [x] Signal: `player_died`
  - [x] Signal: `player_respawned`
  - [x] Signal: `shard_collected(count: int, total: int)`
  - [x] Signal: `crystal_collected(crystal_id: String)`
  - [x] Signal: `level_completed(level_name: String)`
  - [x] Signal: `checkpoint_reached(position: Vector2)`
  - [x] Signal: `game_paused(is_paused: bool)`

- [x] Create `scripts/autoloads/game_manager.gd` - Central game state controller
  - [x] Enum: `GameState { MENU, PLAYING, PAUSED, TRANSITIONING, GAME_OVER }`
  - [x] Track: `current_level: String`
  - [x] Track: `total_shards: int`, `collected_shards: int`
  - [x] Track: `collected_crystals: Array[String]`
  - [x] Method: `change_state(new_state: GameState) -> void`
  - [x] Method: `restart_level() -> void`
  - [x] Method: `load_level(level_path: String) -> void`
  - [x] Set `process_mode = PROCESS_MODE_ALWAYS` for pause handling

- [x] Create `scripts/autoloads/save_manager.gd` - Persistent data handler
  - [x] Save path: `user://echoes_save.json`
  - [x] Save: collected crystals per level
  - [x] Save: best shard counts per level
  - [x] Save: unlocked levels
  - [x] Save: audio/video settings
  - [x] Method: `save_game() -> void`
  - [x] Method: `load_game() -> void`
  - [x] Method: `has_save() -> bool`

- [x] Create `scripts/autoloads/audio_manager.gd` - Centralized audio control
  - [x] Audio bus: Master, Music, SFX
  - [x] Method: `play_sfx(sound_name: String) -> void`
  - [x] Method: `play_music(track_name: String, fade_duration: float = 1.0) -> void`
  - [x] Method: `set_music_volume(value: float) -> void`
  - [x] Method: `set_sfx_volume(value: float) -> void`
  - [x] Preload common SFX at startup

- [x] Register all autoloads in Project Settings → Autoload

### 1.4 Base Classes
- [x] Create `scripts/classes/state.gd` - FSM state base class
  ```gdscript
  class_name State extends Node
  var state_machine: StateMachine
  var actor: CharacterBody2D
  func enter() -> void: pass
  func exit() -> void: pass
  func update(_delta: float) -> void: pass
  func physics_update(_delta: float) -> void: pass
  ```

- [x] Create `scripts/classes/state_machine.gd` - FSM controller
  - [x] Export: `initial_state: State`
  - [x] Track: `current_state: State`
  - [x] Track: `states: Dictionary`
  - [x] Method: `transition_to(state_name: String) -> void`
  - [x] Call `physics_update()` in `_physics_process()`

- [x] Create `scripts/components/health_component.gd` - Reusable health logic
  - [x] Signal: `health_changed(current: int, max: int)`
  - [x] Signal: `died`
  - [x] Export: `max_health: int = 1`
  - [x] Method: `take_damage(amount: int = 1) -> void`
  - [x] Method: `heal(amount: int) -> void`

- [x] Create `scripts/components/hitbox_component.gd` - Damage dealer (Area2D)
  - [x] Export: `damage: int = 1`
  - [x] Connect `area_entered` to check for hurtbox

- [x] Create `scripts/components/hurtbox_component.gd` - Damage receiver (Area2D)
  - [x] Signal: `hurt(hitbox: HitboxComponent)`
  - [x] Detect hitbox collisions and emit signal

---

## Phase 2: Player Controller (Days 3-5)

### 2.1 Player Scene Setup
- [x] Create `scenes/player/player.tscn` as CharacterBody2D
- [x] Add child nodes:
  - [x] `Sprite2D` - Player visual (white silhouette)
  - [x] `CollisionShape2D` - Capsule shape (16x32 pixels recommended)
  - [x] `AnimationPlayer` - For sprite animations
  - [x] `StateMachine` (Node) - FSM container
  - [x] `CoyoteTimer` (Timer) - One-shot, 0.1s
  - [x] `JumpBufferTimer` (Timer) - One-shot, 0.15s
  - [x] `WallJumpCooldown` (Timer) - One-shot, 0.2s
  - [x] `EchoTrailTimer` (Timer) - Repeating, 0.05s for trail spawning
  - [x] `WallDetectorLeft` (RayCast2D) - Check wall on left
  - [x] `WallDetectorRight` (RayCast2D) - Check wall on right
  - [x] `HurtboxComponent` (Area2D) - Player damage receiver

### 2.2 Player Core Script
- [x] Create `scenes/player/player.gd` extending CharacterBody2D
- [x] Constants:
  ```gdscript
  const SPEED: float = 300.0
  const JUMP_VELOCITY: float = -450.0
  const GRAVITY: float = 980.0
  const MAX_FALL_SPEED: float = 600.0
  const WALL_SLIDE_SPEED: float = 100.0
  const WALL_JUMP_VELOCITY: Vector2 = Vector2(350.0, -400.0)
  const DOUBLE_JUMP_VELOCITY: float = -380.0
  ```
- [x] Track: `can_double_jump: bool`
- [x] Track: `is_wall_sliding: bool`
- [x] Track: `facing_direction: int = 1`
- [x] Track: `last_checkpoint: Vector2`
- [x] Implement `_physics_process()` with gravity and movement

### 2.3 Movement Mechanics
- [x] **Basic Horizontal Movement**
  - [x] Get input direction from `move_left`/`move_right`
  - [x] Apply acceleration/deceleration (lerp-based for smoothness)
  - [x] Flip sprite based on movement direction

- [x] **Variable Jump Height**
  - [x] Full jump on held input
  - [x] Cut jump velocity by 50% on early release
  - [x] Only cut if moving upward (`velocity.y < 0`)

- [x] **Coyote Time** (grace period after leaving platform)
  - [x] Start timer when leaving ground (not jumping)
  - [x] Allow jump if timer still running
  - [x] Duration: 0.1 seconds

- [x] **Jump Buffering** (input before landing)
  - [x] Start buffer timer on jump press while airborne
  - [x] Execute jump on landing if timer still running
  - [x] Duration: 0.15 seconds

- [x] **Double Jump**
  - [x] Reset `can_double_jump` on ground contact
  - [x] Consume double jump in air (one use)
  - [x] Use `DOUBLE_JUMP_VELOCITY` (slightly weaker than ground jump)
  - [x] Spawn echo effect on double jump activation

- [x] **Wall Slide**
  - [x] Detect wall contact using RayCast2D
  - [x] Only slide if pressing toward wall
  - [x] Reduce fall speed to `WALL_SLIDE_SPEED`
  - [x] Play wall slide particles

- [x] **Wall Jump**
  - [x] Jump away from wall with `WALL_JUMP_VELOCITY`
  - [x] Brief input lockout (0.15s) to prevent immediate return
  - [x] Reset double jump on wall jump
  - [x] Apply opposite horizontal velocity

### 2.4 Player States (FSM)
- [x] Create state scripts in `scenes/player/states/`:
  - [x] `idle_state.gd` - Standing still on ground
  - [x] `run_state.gd` - Moving horizontally on ground
  - [x] `jump_state.gd` - Rising through air
  - [x] `fall_state.gd` - Falling through air
  - [x] `wall_slide_state.gd` - Sliding down wall
  - [x] `death_state.gd` - Death animation, then respawn

- [x] State transitions:
  ```
  Idle -> Run (movement input)
  Idle -> Jump (jump input)
  Run -> Idle (no input + velocity near zero)
  Run -> Jump (jump input)
  Jump -> Fall (velocity.y >= 0)
  Fall -> Idle/Run (on floor)
  Fall -> WallSlide (touching wall + input toward wall)
  WallSlide -> Jump (jump input = wall jump)
  WallSlide -> Fall (no wall contact or input away)
  Any -> Death (health depleted)
  Death -> Idle (respawn complete)
  ```

### 2.5 Echo Trail Effect
- [x] Create `scenes/effects/echo_ghost.tscn` - Fading player silhouette
  - [x] Sprite2D with player texture
  - [x] Modulate with cyan tint `#00FFFF`
  - [x] Alpha fade from 0.5 to 0 over 0.3 seconds
  - [x] `queue_free()` after fade complete

- [x] Spawn echo ghosts:
  - [x] Every 0.05s while double jump is active
  - [x] On wall jump activation
  - [x] On double jump activation (burst of 3)

### 2.6 Player Death & Respawn
- [x] On `died` signal from HealthComponent:
  - [x] Transition to Death state
  - [x] Play death particles (white dispersion)
  - [x] Emit `Events.player_died`
  - [x] Wait 0.5s, then respawn at `last_checkpoint`
  - [x] Play respawn particles (coalesce effect)
  - [x] Emit `Events.player_respawned`

---

## Phase 3: Enemies & Hazards (Days 5-7)

### 3.1 Enemy Base Class
- [x] Create `scripts/classes/enemy_base.gd` extending CharacterBody2D
  - [x] Includes: HealthComponent, HitboxComponent
  - [x] Signal: `enemy_died`
  - [x] Virtual method: `_on_player_detected(player: Player) -> void`
  - [x] Common death effect (white particle burst)

### 3.2 Shadow Crawler (Patrol Enemy)
- [x] Create `scenes/enemies/shadow_crawler/shadow_crawler.tscn`
- [x] Node structure:
  - [x] CharacterBody2D (root)
  - [x] Sprite2D (dark silhouette with red eyes)
  - [x] CollisionShape2D (capsule)
  - [x] HitboxComponent (Area2D)
  - [x] RayCast2D (ground detection for ledge)
  - [x] RayCast2D (wall detection)
  - [x] AnimationPlayer

- [x] Create `scenes/enemies/shadow_crawler/shadow_crawler.gd`:
  - [x] Patrol between two points OR until ledge/wall
  - [x] Speed: 80 pixels/second
  - [x] Turn around at ledges (use RayCast2D to detect floor ahead)
  - [x] Turn around on wall collision
  - [x] Damage player on contact via HitboxComponent

### 3.3 Mirror Guard (Copies Player Movement)
- [x] Create `scenes/enemies/mirror_guard/mirror_guard.tscn`
- [x] Node structure:
  - [x] CharacterBody2D (root)
  - [x] Sprite2D (inverted color player silhouette)
  - [x] CollisionShape2D
  - [x] HitboxComponent (Area2D)
  - [x] DetectionArea (Area2D) - Large circular detection radius

- [x] Create `scenes/enemies/mirror_guard/mirror_guard.gd`:
  - [x] Track player reference when in detection area
  - [x] Mirror player's X velocity (inverted or same, configurable)
  - [x] Jump when player jumps (with slight delay: 0.1s)
  - [x] Speed matches player speed
  - [x] Export: `mirror_mode: bool = true` (true = same direction, false = opposite)

### 3.4 Pulse Orb (Sine-Wave Movement)
- [x] Create `scenes/enemies/pulse_orb/pulse_orb.tscn`
- [x] Node structure:
  - [x] CharacterBody2D (root)
  - [x] Sprite2D (glowing orb, cyan with white core)
  - [x] CollisionShape2D (circle)
  - [x] HitboxComponent (Area2D)
  - [x] PointLight2D (pulsing glow)
  - [x] GPUParticles2D (ambient particle trail)

- [x] Create `scenes/enemies/pulse_orb/pulse_orb.gd`:
  - [x] Movement: Sine wave pattern
  - [x] Export: `amplitude: float = 100.0` (wave height)
  - [x] Export: `frequency: float = 2.0` (oscillation speed)
  - [x] Export: `base_speed: float = 100.0` (horizontal movement)
  - [x] Export: `vertical_mode: bool = false` (switch to vertical sine)
  - [x] Calculate: `offset = sin(time * frequency) * amplitude`
  - [x] Light pulsing: Scale light energy with sine wave

### 3.5 Hazards (Static Dangers)
- [x] Create `scenes/hazards/spike.tscn`
  - [x] StaticBody2D with HitboxComponent
  - [x] Sprite2D (white spike silhouette)
  - [x] CollisionShape2D (thin triangle or box)
  - [x] Instant kill on contact

- [x] Create `scenes/hazards/void_pit.tscn`
  - [x] Area2D trigger zone
  - [x] Kill player on body_entered
  - [x] Particle effect (dark mist rising)

- [x] Create `scenes/hazards/laser_beam.tscn`
  - [x] Toggleable hazard (on/off timing)
  - [x] RayCast2D for instant hit detection
  - [x] Visual: Bright white line with glow
  - [x] Export: `on_duration: float = 2.0`
  - [x] Export: `off_duration: float = 1.5`
  - [x] Warning flicker before activating

---

## Phase 4: Platforms & Collectibles (Days 7-9)

### 4.1 Platform Base
- [x] Create `scripts/classes/platform_base.gd` extending StaticBody2D/AnimatableBody2D
  - [x] Export: `one_way: bool = false`
  - [x] Configure `collision_layer` and `collision_mask` for platform layer

### 4.2 Crumbling Platform
- [x] Create `scenes/platforms/crumbling_platform.tscn`
- [x] Node structure:
  - [x] StaticBody2D (root)
  - [x] Sprite2D (fractured appearance)
  - [x] CollisionShape2D
  - [x] Area2D (player detection)
  - [x] Timer (crumble delay)
  - [x] Timer (respawn timer)
  - [x] AnimationPlayer (shake, crumble, respawn)

- [x] Create `scenes/platforms/crumbling_platform.gd`:
  - [x] On player contact → start shake animation
  - [x] After `crumble_delay` (0.5s) → disable collision, play crumble
  - [x] Particles: pieces falling
  - [x] After `respawn_time` (3.0s) → rebuild with fade-in
  - [x] Export: `crumble_delay: float = 0.5`
  - [x] Export: `respawn_time: float = 3.0`

### 4.3 Moving Platform
- [x] Create `scenes/platforms/moving_platform.tscn`
- [x] Node structure:
  - [x] AnimatableBody2D (root) - For proper player carrying
  - [x] Sprite2D
  - [x] CollisionShape2D
  - [x] Path follow setup with Marker2D points

- [x] Create `scenes/platforms/moving_platform.gd`:
  - [x] Export: `speed: float = 100.0`
  - [x] Export: `wait_time: float = 0.5` (pause at endpoints)
  - [x] Export: `path_points: Array[Vector2]`
  - [x] Use `move_and_collide()` or tween between points
  - [x] Set `sync_to_physics = true` for smooth player riding

### 4.4 One-Way Platform
- [x] Create `scenes/platforms/one_way_platform.tscn`
- [x] StaticBody2D with one-way collision enabled
- [x] Visual: Semi-transparent or dashed appearance
- [x] Player passes through from below, lands from above

### 4.5 Disappearing/Reappearing Platform
- [x] Create `scenes/platforms/phase_platform.tscn`
- [x] Node structure:
  - [x] StaticBody2D (root)
  - [x] Sprite2D
  - [x] CollisionShape2D
  - [x] Timer (phase timer)

- [x] Create `scenes/platforms/phase_platform.gd`:
  - [x] Export: `visible_duration: float = 2.0`
  - [x] Export: `invisible_duration: float = 2.0`
  - [x] Export: `start_visible: bool = true`
  - [x] Export: `phase_offset: float = 0.0` (for synced groups)
  - [x] Fade out before disappearing (warning)
  - [x] Disable collision when invisible
  - [x] Particles: phase-in sparkle effect

### 4.6 Light Shard (Coins)
- [x] Create `scenes/collectibles/light_shard.tscn`
- [x] Node structure:
  - [x] Area2D (root)
  - [x] Sprite2D (small glowing white/cyan diamond)
  - [x] CollisionShape2D (circle)
  - [x] AnimationPlayer (float bob, sparkle)
  - [x] AudioStreamPlayer2D (collect sound)
  - [x] GPUParticles2D (ambient glow particles)

- [x] Create `scenes/collectibles/light_shard.gd`:
  - [x] On player contact:
    - [x] Play collect animation (scale up, fade out)
    - [x] Play collect sound
    - [x] Emit `Events.shard_collected`
    - [x] `queue_free()` or disable

### 4.7 Echo Crystal (Stars/Major Collectible)
- [x] Create `scenes/collectibles/echo_crystal.tscn`
- [x] Node structure:
  - [x] Area2D (root)
  - [x] Sprite2D (larger crystal, bright cyan with white core)
  - [x] CollisionShape2D
  - [x] AnimationPlayer (rotate, pulse glow)
  - [x] PointLight2D (strong glow)
  - [x] GPUParticles2D (swirling particles)
  - [x] AudioStreamPlayer2D

- [x] Create `scenes/collectibles/echo_crystal.gd`:
  - [x] Export: `crystal_id: String` (unique per crystal for save)
  - [x] Check if already collected via SaveManager
  - [x] On collection:
    - [x] Grand particle burst
    - [x] Emit `Events.crystal_collected(crystal_id)`
    - [x] Play triumphant sound
    - [x] Save collection state

### 4.8 Checkpoint
- [x] Create `scenes/objects/checkpoint.tscn`
- [x] Node structure:
  - [x] Area2D (root)
  - [x] Sprite2D (inactive: dim pillar, active: glowing)
  - [x] CollisionShape2D
  - [x] PointLight2D (activates on trigger)

- [x] Create `scenes/objects/checkpoint.gd`:
  - [x] On player enter (first time):
    - [x] Update `player.last_checkpoint`
    - [x] Emit `Events.checkpoint_reached`
    - [x] Activate glow animation
    - [x] Play activation sound

---

## Phase 5: Level Design (Days 9-11)

### 5.1 Level Template Setup
- [x] Create `scenes/levels/level_base.tscn` template:
  - [x] Node2D (root)
  - [x] TileMapLayer (environment/collision)
  - [x] Player spawn point (Marker2D)
  - [x] LevelExit (Area2D)
  - [x] Collectibles (Node2D container)
  - [x] Enemies (Node2D container)
  - [x] Platforms (Node2D container)
  - [x] Hazards (Node2D container)
  - [x] Checkpoints (Node2D container)
  - [x] ParallaxBackground
  - [x] Camera2D with limits

- [x] Create `scenes/levels/level_base.gd`:
  - [x] Export: `level_name: String`
  - [x] Export: `next_level: String` (path to next level)
  - [x] Export: `total_shards: int`
  - [x] Export: `crystal_count: int`
  - [x] Method: `_on_level_exit_entered() -> void`

### 5.2 TileSet Creation
- [x] Create `assets/tilesets/void_tileset.tres`:
  - [x] Ground tiles (solid white platforms)
  - [x] Wall tiles (vertical surfaces for wall jump)
  - [x] Decorative tiles (broken, cracked variations)
  - [x] Set up physics layers on collidable tiles
  - [x] One-way tiles (platform tops)

### 5.3 Level 1: Awakening (Tutorial)
- [x] Create `scenes/levels/level_01_awakening.tscn`
- [x] Design goals:
  - [x] Teach basic movement (run, jump)
  - [x] Introduce Light Shards (3-5 easy ones)
  - [x] First checkpoint
  - [x] Simple gap jumps, no enemies
  - [x] One hidden Echo Crystal (requires exploration)
  - [x] Estimated length: 30-60 seconds
- [x] Layout tasks:
  - [x] Starting chamber with visual cues
  - [x] Progressive gap sizes (small → medium)
  - [x] Height variation introduction
  - [x] Clear path to exit

### 5.4 Level 2: Fractured Paths
- [x] Create `scenes/levels/level_02_fractured_paths.tscn`
- [x] Design goals:
  - [x] Introduce wall jump
  - [x] First enemy: Shadow Crawlers (2-3 of them)
  - [x] Crumbling platforms introduction
  - [x] 5-7 Light Shards
  - [x] Two Checkpoints
  - [x] One Echo Crystal (wall jump challenge)
- [x] Layout tasks:
  - [x] Vertical section requiring wall jumps
  - [x] Crumbling platform sequence
  - [x] Enemy patrol patterns to navigate

### 5.5 Level 3: Mirror's Edge
- [x] Create `scenes/levels/level_03_mirrors_edge.tscn`
- [x] Design goals:
  - [x] Introduce double jump
  - [x] Mirror Guard enemy (1-2)
  - [x] Moving platforms
  - [x] Disappearing platforms
  - [x] 7-10 Light Shards
  - [x] Two Echo Crystals
- [x] Layout tasks:
  - [x] Wide gaps requiring double jump
  - [x] Mirror Guard puzzle sections
  - [x] Timed platform sequences
  - [x] Precision landing challenges

### 5.6 Level 4: Collapse
- [x] Create `scenes/levels/level_04_collapse.tscn`
- [x] Design goals:
  - [x] Challenge level - all mechanics combined
  - [x] Pulse Orbs introduction (4 with varied patterns)
  - [x] Laser beam hazards (5 positioned for timed gauntlets)
  - [x] Complex crumbling platform chains (7 crumbling platforms)
  - [x] 12 Light Shards
  - [x] Two Echo Crystals (difficult placement requiring skill)
- [x] Layout tasks:
  - [x] Multi-path sections (crumbling chains vs moving platforms)
  - [x] Timed hazard gauntlets (laser beams with phase platforms)
  - [x] Vertical chase sections (moving platforms + pulse orbs)
  - [x] Enemy combination challenges (Pulse Orbs + Shadow Crawlers)

### 5.7 Level 5: The Last Echo (Finale)
- [x] Create `scenes/levels/level_05_last_echo.tscn`
- [x] Design goals:
  - [x] Final challenge - mastery test
  - [x] All enemy types present (4 Shadow Crawlers, 3 Mirror Guards, 6 Pulse Orbs)
  - [x] Complex platform combinations (10 Crumbling, 8 Moving, 9 Phase platforms)
  - [x] Final Echo Crystal (requires all skills) - 3 total crystals at increasing difficulty
  - [x] Climactic ending sequence (grand finale area at top)
  - [x] 12-15 Light Shards (15 total)
- [x] Layout tasks:
  - [x] Grand scale environment (5120x2400 play area)
  - [x] Callback sections to earlier levels (wall jump sections, timing challenges)
  - [x] Optional "true ending" path for 100% completion (Crystal 3 at difficult height)
  - [x] Memorable finale area (bright exit glow, final vertical climb)

---

## Phase 6: Visual Polish (Days 11-13)

### 6.1 Particle Systems
- [x] Create `scenes/effects/particles/` folder with:
  - [x] `death_particles.tscn` - White dispersion burst on player death
  - [x] `respawn_particles.tscn` - Coalesce effect on respawn
  - [x] `footstep_dust.tscn` - Subtle dust when running
  - [x] `jump_dust.tscn` - Burst on jump
  - [x] `land_dust.tscn` - Impact on landing
  - [x] `wall_slide_sparks.tscn` - Friction effect on wall
  - [x] `shard_collect.tscn` - Sparkle burst
  - [x] `crystal_collect.tscn` - Grand particle celebration
  - [x] `enemy_death.tscn` - Shadow dispersion
  - [x] `platform_crumble.tscn` - Falling debris
  - [x] `ambient_void.tscn` - Floating particles in background

### 6.2 Lighting System
- [x] Configure project for 2D lighting:
  - [x] Enable `Rendering > 2D > Shadow Atlas > Size` if needed
  - [x] Set up canvas modulate for base darkness

- [x] Create light sources:
  - [x] Player subtle glow (PointLight2D, white, low energy)
  - [x] Collectible lights (Echo Crystals, Shards)
  - [x] Checkpoint activation lights
  - [x] Ambient level lighting (strategic PointLight2D placement)
  - [x] Hazard warning lights (red tint for danger zones)

### 6.3 Echo Trail Enhancement
- [x] Improve echo ghost visuals:
  - [x] Add subtle glow via CanvasModulate or shader
  - [x] Trail color progression (bright → dim)
  - [x] Smooth spawn interpolation
  - [x] Size variation (slight shrink over time)

### 6.4 Screen Effects
- [x] Create `scenes/effects/screen_effects.tscn`:
  - [x] Vignette overlay (subtle darkness at edges)
  - [x] CRT/scanline optional filter (togglable)
  - [x] Death fade to black
  - [x] Level transition fade

### 6.5 Animation Polish
- [x] Player animations:
  - [x] Idle breathing/subtle movement
  - [x] Run cycle (4-6 frames)
  - [x] Jump anticipation and apex
  - [x] Fall (arms up? dramatic pose)
  - [x] Wall slide (pressed against wall)
  - [x] Double jump spin

- [x] Enemy animations:
  - [x] Shadow Crawler walk cycle
  - [x] Mirror Guard idle stance
  - [x] Pulse Orb pulsing glow

---

## Phase 7: Audio & Juice (Days 13-14)

### 7.1 Sound Effects
- [x] Create/source SFX and place in `assets/audio/sfx/`:
  - [x] `jump.wav` - Whoosh on jump
  - [x] `double_jump.wav` - Echo/reverb jump
  - [x] `land.wav` - Soft thud
  - [x] `wall_slide.wav` - Friction/scrape (looping)
  - [x] `wall_jump.wav` - Kick-off sound
  - [x] `footstep_01.wav`, `footstep_02.wav` - Subtle steps
  - [x] `death.wav` - Dissolve/shatter
  - [x] `respawn.wav` - Reformation
  - [x] `shard_collect.wav` - Light chime
  - [x] `crystal_collect.wav` - Grand chime/chord
  - [x] `checkpoint.wav` - Activation tone
  - [x] `enemy_death.wav` - Shadow disperse
  - [x] `platform_crumble.wav` - Stone breaking
  - [x] `menu_select.wav` - UI blip
  - [x] `menu_confirm.wav` - UI confirm

### 7.2 Music
- [x] Create/source music tracks for `assets/audio/music/`:
  - [x] `main_menu.wav` - Atmospheric, mysterious
  - [x] `level_ambience.wav` - Subtle, tense background
  - [x] `level_intense.wav` - For challenging sections (optional)
  - [x] `victory.wav` - Level complete jingle (short)
  - [x] `game_complete.wav` - Ending theme

### 7.3 Screen Shake
- [x] Create `scripts/components/screen_shake.gd`:
  - [x] Attach to Camera2D
  - [x] Method: `shake(intensity: float, duration: float) -> void`
  - [x] Use random offset decay over duration
  - [x] Triggers:
    - [x] Player death (medium shake)
    - [x] Landing from height (light shake)
    - [x] Platform crumble (light shake)
    - [x] Enemy death (very light)

### 7.4 Hitstop/Freeze Frames
- [x] Create hitstop utility in GameManager:
  - [x] Method: `hitstop(duration: float = 0.05) -> void`
  - [x] Brief `Engine.time_scale = 0.0` then restore
  - [x] Use for:
    - [x] Player death moment
    - [x] Crystal collection
    - [ ] Boss hit (if added)

### 7.5 Camera System
- [x] Enhance Camera2D on player:
  - [x] Smooth follow with `position_smoothing_enabled = true`
  - [x] Smoothing speed: ~5.0
  - [x] Lookahead based on velocity
  - [x] Set camera limits per level (prevent seeing void)
  - [x] Vertical deadzone for platforming

---

## Phase 8: Menus & Completion (Day 14)

### 8.1 Main Menu
- [x] Create `scenes/ui/main_menu.tscn`:
  - [x] Title: "ECHOES OF THE VOID" (stylized text/logo)
  - [x] Buttons (VBoxContainer):
    - [x] "New Game" → Start Level 1
    - [x] "Continue" → Load saved progress (only if save exists)
    - [x] "Level Select" → Level selection screen
    - [x] "Settings" → Settings menu
    - [x] "Quit" → Exit game
  - [x] Background: Animated void particles
  - [x] Subtle animations on button hover

### 8.2 Pause Menu
- [x] Create `scenes/ui/pause_menu.tscn`:
  - [x] "PAUSED" header
  - [x] Buttons:
    - [x] "Resume" → Unpause
    - [x] "Restart Level" → Reload current level
    - [x] "Settings" → Settings menu
    - [x] "Main Menu" → Return to main menu
  - [x] Semi-transparent dark overlay
  - [x] `process_mode = PROCESS_MODE_WHEN_PAUSED`

### 8.3 Settings Menu
- [x] Create `scenes/ui/settings_menu.tscn`:
  - [x] Audio:
    - [x] Master Volume slider (0-100%)
    - [x] Music Volume slider
    - [x] SFX Volume slider
  - [x] Video:
    - [x] Fullscreen toggle
    - [x] VSync toggle
    - [x] Screen Shake toggle
  - [x] Controls:
    - [x] Display current bindings
    - [ ] (Optional: Rebinding)
  - [x] "Back" button
  - [x] Save settings on change

### 8.4 HUD
- [x] Create `scenes/ui/hud.tscn`:
  - [x] Shard counter (icon + "X / Y")
  - [x] Crystal indicators (3 slots, filled when collected)
  - [ ] (Optional) Timer for speedrunning
  - [x] Positioned in corners, minimal intrusion
  - [x] Fade in/out on activity

### 8.5 Level Complete Screen
- [x] Create `scenes/ui/level_complete.tscn`:
  - [x] "LEVEL COMPLETE" header
  - [x] Stats:
    - [x] Shards collected: X / Y
    - [x] Crystals found: X / 3
    - [ ] Time (optional)
  - [x] Buttons:
    - [x] "Next Level" → Load next
    - [x] "Replay" → Restart current
    - [x] "Level Select" → Back to select

### 8.6 Level Select
- [x] Create `scenes/ui/level_select.tscn`:
  - [x] Grid or list of levels
  - [x] Show completion status (crystals, shards)
  - [x] Lock/unlock based on progression
  - [ ] Preview image per level (optional)

### 8.7 Game Complete Screen
- [x] Create `scenes/ui/game_complete.tscn`:
  - [x] "THE END" or "ECHOES SILENCED"
  - [x] Total stats
  - [x] 100% completion recognition (if applicable)
  - [x] "Main Menu" button
  - [x] Credits option

### 8.8 Final Testing Checklist
> ⚠️ **BLOCKED** - See Phase 15 for updated checklist after critical fixes

- [ ] Complete playthrough of all 5 levels
- [ ] Verify all collectibles obtainable
- [ ] Verify all checkpoints functional
- [ ] Test all enemies behave correctly
- [ ] Test all platform types
- [ ] Settings save/load correctly
- [ ] Game save/load correctly
- [ ] No crashes or softlocks
- [ ] Performance acceptable (60 FPS target)
- [ ] Audio levels balanced
- [ ] Export builds for target platforms

---

## Technical Architecture

### Autoload Singletons
| Name | Script | Purpose |
|------|--------|---------|
| Events | `events.gd` | Global signal bus |
| GameManager | `game_manager.gd` | Game state, level management |
| SaveManager | `save_manager.gd` | Persistent data |
| AudioManager | `audio_manager.gd` | Sound playback control |

### Key Node Types Used
| System | Node Type | Notes |
|--------|-----------|-------|
| Player | CharacterBody2D | Physics-based character |
| Enemies | CharacterBody2D | For movement/collision |
| Platforms | StaticBody2D / AnimatableBody2D | AnimatableBody2D for moving platforms |
| Collectibles | Area2D | Trigger-based pickup |
| Hazards | Area2D / StaticBody2D | Depends on type |
| Cameras | Camera2D | One per level, follows player |
| Lighting | PointLight2D, DirectionalLight2D | 2D lighting system |
| Particles | GPUParticles2D | GPU-accelerated effects |
| UI | Control nodes | CanvasLayer for HUD |

### Scene Composition Pattern
```
Entity (CharacterBody2D)
├── Sprite2D
├── CollisionShape2D
├── AnimationPlayer
├── StateMachine
│   ├── IdleState
│   ├── MoveState
│   └── ...
├── HealthComponent
├── HitboxComponent (Area2D)
└── HurtboxComponent (Area2D)
```

### Signal Flow
```
Player hurt → HurtboxComponent.hurt
           → HealthComponent.take_damage()
           → HealthComponent.died (if health = 0)
           → Events.player_died
           → GameManager handles respawn
           → Player.respawn()
           → Events.player_respawned
```

---

## File Structure

```
echoes-of-the-void/
├── .gitignore
├── project.godot
├── plan.md                          # This file
├── README.md
│
├── assets/
│   ├── audio/
│   │   ├── music/
│   │   │   ├── main_menu.wav
│   │   │   ├── level_ambience.wav
│   │   │   └── victory.wav
│   │   └── sfx/
│   │       ├── jump.wav
│   │       ├── death.wav
│   │       └── ...
│   ├── fonts/
│   │   └── void_font.ttf
│   ├── sprites/
│   │   ├── player/
│   │   ├── enemies/
│   │   ├── platforms/
│   │   ├── collectibles/
│   │   └── ui/
│   └── tilesets/
│       └── void_tileset.tres
│
├── scenes/
│   ├── main.tscn                    # Entry point scene
│   ├── player/
│   │   ├── player.tscn
│   │   ├── player.gd
│   │   └── states/
│   │       ├── idle_state.gd
│   │       ├── run_state.gd
│   │       └── ...
│   ├── enemies/
│   │   ├── shadow_crawler/
│   │   ├── mirror_guard/
│   │   └── pulse_orb/
│   ├── platforms/
│   │   ├── crumbling_platform.tscn
│   │   ├── moving_platform.tscn
│   │   ├── one_way_platform.tscn
│   │   └── phase_platform.tscn
│   ├── collectibles/
│   │   ├── light_shard.tscn
│   │   └── echo_crystal.tscn
│   ├── hazards/
│   │   ├── spike.tscn
│   │   ├── void_pit.tscn
│   │   └── laser_beam.tscn
│   ├── objects/
│   │   └── checkpoint.tscn
│   ├── effects/
│   │   ├── echo_ghost.tscn
│   │   ├── screen_effects.tscn
│   │   └── particles/
│   │       └── ...
│   ├── levels/
│   │   ├── level_base.tscn
│   │   ├── level_base.gd
│   │   ├── level_01_awakening.tscn
│   │   ├── level_02_fractured_paths.tscn
│   │   ├── level_03_mirrors_edge.tscn
│   │   ├── level_04_collapse.tscn
│   │   └── level_05_last_echo.tscn
│   └── ui/
│       ├── main_menu.tscn
│       ├── pause_menu.tscn
│       ├── settings_menu.tscn
│       ├── hud.tscn
│       ├── level_complete.tscn
│       ├── level_select.tscn
│       └── game_complete.tscn
│
├── scripts/
│   ├── autoloads/
│   │   ├── events.gd
│   │   ├── game_manager.gd
│   │   ├── save_manager.gd
│   │   └── audio_manager.gd
│   ├── classes/
│   │   ├── state.gd
│   │   ├── state_machine.gd
│   │   ├── enemy_base.gd
│   │   └── platform_base.gd
│   └── components/
│       ├── health_component.gd
│       ├── hitbox_component.gd
│       ├── hurtbox_component.gd
│       └── screen_shake.gd
│
├── resources/
│   └── (custom .tres resources if needed)
│
└── tests/                           # GUT tests (optional)
    └── ...
```

---

## Definition of Done

A task is considered **COMPLETE** when:

### For Code/Scripts
- [ ] Script runs without errors
- [ ] Type hints on all variables, parameters, and return types
- [ ] Follows GDScript style guide (see Godot skill doc)
- [ ] No `push_error()` or `push_warning()` in normal operation
- [ ] Connected signals documented
- [ ] Exports have sensible defaults

### For Scenes
- [ ] Scene loads without errors
- [ ] All node references valid (`@onready` works)
- [ ] Collision layers/masks correctly configured
- [ ] Visual elements visible and properly positioned
- [ ] Required scripts attached

### For Levels
- [ ] Playable from start to exit
- [ ] All collectibles reachable
- [ ] All checkpoints functional
- [ ] Camera limits set
- [ ] No holes in collision
- [ ] Tested full playthrough 3+ times

### For Features
- [ ] Core functionality works
- [ ] Edge cases handled (e.g., double-press, interrupted actions)
- [ ] Integrates with existing systems (signals, autoloads)
- [ ] Visual/audio feedback present

### For Project Milestones
- [ ] All phase checkboxes completed
- [ ] No blocking bugs
- [ ] Performance acceptable (60 FPS)
- [ ] Save/load tested
- [ ] Menu navigation complete

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Scope creep | Stick to 5 levels, cut features before adding |
| Art asset delays | Use simple geometric shapes, polish later |
| Complex physics bugs | Use CharacterBody2D built-in functions, avoid custom physics |
| Save corruption | Test save/load frequently during development |
| Performance issues | Profile early, use object pooling for particles/enemies |

---

## Notes & Reminders

- **Commit frequently** - After each completed checkbox section
- **Test on target platforms** - Export and run regularly
- **Prioritize playability** - A working game beats a pretty broken one
- **Use placeholder assets** - Swap in final art later
- **Document as you go** - Update this plan when changes occur

---

## 🚨 CRITICAL FIXES REQUIRED (Blocking Issues)

> **Status:** The game is currently non-functional. The following issues must be addressed before any playtesting is possible.
> 
> **Approach:** All fixes will be **fully automated via code** - no manual Godot Editor work required.

### Summary of Current State

The project has all scene structures and scripts in place, but **critical implementation gaps** make the game unplayable:

1. **ALL 5 levels have NO tile geometry** - TileMapLayer nodes exist but contain no tiles
2. **Player immediately falls to death** - No ground to land on at spawn points  
3. **Placeholder textures added** - Player and entities now visible, but nothing to interact with
4. **Tileset exists but unused** - void_tileset.tres has 32 tiles defined with physics
5. **Game flow exists but untested** - Main menu, pause, level complete screens exist but flow is broken

### Solution: Programmatic Level Generation

Instead of manually painting tiles, we will:
1. **Create a procedural platform system** using StaticBody2D + ColorRect (code-generated)
2. **Define level layouts in data files** (JSON or GDScript dictionaries)
3. **Generate geometry at runtime** via level_base.gd or dedicated generator script
4. **Use placeholder colored rectangles** as platforms until art is ready

---

### Phase 9: Procedural Level Geometry System (BLOCKING)

> **Priority:** 🔴 CRITICAL - Game cannot be played without this
> **Estimated Time:** 3-4 hours
> **Approach:** 100% code-based, no manual editor work

#### 9.1 Create Platform Generator System
- [x] Create `scripts/systems/platform_generator.gd`
  - [x] Static method: `create_platform(parent: Node, pos: Vector2, size: Vector2, color: Color) -> StaticBody2D`
  - [x] Creates StaticBody2D with CollisionShape2D (RectangleShape2D)
  - [x] Adds ColorRect child for visual (uses color parameter)
  - [x] Sets collision_layer to platform layer (3)
  - [x] Returns the created platform node
- [x] Add method: `create_wall(parent: Node, pos: Vector2, height: float, side: String) -> StaticBody2D`
  - [x] Creates vertical wall for wall-jumping
  - [x] side parameter: "left" or "right" for proper positioning
- [x] Add method: `create_one_way_platform(parent: Node, pos: Vector2, width: float) -> StaticBody2D`
  - [x] Creates platform with one_way_collision enabled
  - [x] Semi-transparent visual to distinguish from solid

#### 9.2 Create Level Data Definition System
- [x] Create `scripts/data/level_layouts.gd` with level geometry data
  ```gdscript
  # Example structure for each level
  const LEVEL_01_LAYOUT = {
      "platforms": [
          {"pos": Vector2(0, 224), "size": Vector2(2560, 64)},  # Main ground
          {"pos": Vector2(768, 0), "size": Vector2(128, 128)},  # Crystal platform
      ],
      "walls": [
          {"pos": Vector2(700, 64), "height": 192, "side": "left"},
          {"pos": Vector2(836, 64), "height": 192, "side": "right"},
      ],
      "one_way_platforms": [
          {"pos": Vector2(400, 160), "width": 96},
      ]
  }
  ```
- [x] Define LEVEL_01_LAYOUT with platforms supporting all collectible positions
- [x] Define LEVEL_02_LAYOUT with vertical sections and wall-jump areas
- [x] Define LEVEL_03_LAYOUT with double-jump gaps
- [x] Define LEVEL_04_LAYOUT with complex multi-path sections
- [x] Define LEVEL_05_LAYOUT with grand finale vertical climb

#### 9.3 Integrate Generator with Level Base
- [x] Modify `scenes/levels/level_base.gd`:
  - [x] Add `@export var auto_generate_geometry: bool = true`
  - [x] Add `@export var level_layout_key: String = ""` (e.g., "LEVEL_01")
  - [x] In `_ready()`, call `_generate_level_geometry()` before player spawn
  - [x] Load layout from level_layouts.gd based on level_layout_key
  - [x] Create platforms under a "GeneratedGeometry" Node2D container
- [x] Add fallback: If no layout defined, generate simple ground at spawn

#### 9.4 Level 01: Awakening - Define Layout Data
- [x] Main ground platform: pos(0, 224), size(2560, 64)
- [x] Floating platforms for shards at Y=144-176
- [x] Wall section at X=700-836 for crystal access (Y=-64)
- [x] Checkpoint platform integrated with main ground
- [x] Exit platform at X=2400
- [x] Test: Player can reach all collectibles and exit

#### 9.5 Level 02: Fractured Paths - Define Layout Data  
- [x] Ground section at spawn: pos(0, 352), size(640, 64)
- [x] Vertical wall-jump shaft: walls at X=640-768, height 400
- [x] Elevated platforms for ShadowCrawler patrol
- [x] Gaps between platforms (96-128px) for jumping
- [x] Path leading upward to exit at Y=-192
- [x] Wall-jump challenge area for crystal at Y=-384

#### 9.6 Level 03: Mirror's Edge - Define Layout Data
- [x] Wider gaps (160-256px) requiring double jump
- [x] Platforms at varying heights for Mirror Guard
- [x] Moving platform anchor positions (static fallback if moving not working)
- [x] Phase platform positions
- [x] Two crystal challenge areas at different difficulties

#### 9.7 Level 04: Collapse - Define Layout Data
- [x] Multi-path branching structure
- [x] Crumbling platform chain positions
- [x] Laser beam safe zones
- [x] Pulse Orb navigation corridors
- [x] 12 shard positions with supporting platforms
- [x] 2 crystal challenge areas

#### 9.8 Level 05: The Last Echo - Define Layout Data
- [x] Grand scale: 5120x2400 play area
- [x] Vertical tower climb section
- [x] All enemy type patrol areas
- [x] 27 platform positions (10 crumbling, 8 moving, 9 phase)
- [x] 3 crystal positions at increasing difficulty
- [x] Epic finale area at top with bright exit

#### 9.9 Update Level Scene Files
- [x] Update level_01_awakening.tscn: set `level_layout_key = "LEVEL_01"`
- [x] Update level_02_fractured_paths.tscn: set `level_layout_key = "LEVEL_02"`
- [x] Update level_03_mirrors_edge.tscn: set `level_layout_key = "LEVEL_03"`
- [x] Update level_04_collapse.tscn: set `level_layout_key = "LEVEL_04"`
- [x] Update level_05_last_echo.tscn: set `level_layout_key = "LEVEL_05"`

---

### Phase 10: Player Flow & Game Loop Fixes

> **Priority:** 🟠 HIGH - Required for complete game experience
> **Estimated Time:** 2-3 hours
> **Approach:** Code fixes and verification scripts

#### 10.1 Spawn & Respawn System Fixes
- [x] Add spawn validation in level_base.gd `_spawn_player()`:
  - [x] Check if generated ground exists at spawn position
  - [x] If no ground, auto-generate emergency platform
  - [x] Log warning if spawn position seems invalid
- [x] Fix checkpoint respawn in player.gd:
  - [x] Verify `last_checkpoint` is set on level load
  - [x] Add null check before respawn teleport
  - [x] Emit proper signals on respawn
- [x] Create `scripts/debug/spawn_debugger.gd`:
  - [x] Visualize spawn point and checkpoint positions
  - [x] Show ground detection rays
  - [x] Toggle with F1 key in debug builds

#### 10.2 Level Transition Flow Fixes
- [x] Fix GameManager.load_level():
  - [x] Add scene existence validation before loading
  - [x] Add transition animation (fade to black)
  - [x] Proper cleanup of previous level
- [x] Fix level_complete.gd "Next Level" button:
  - [x] Verify next_level path is valid
  - [x] Handle last level (show game complete instead)
- [x] Create transition test script that auto-walks through all levels

#### 10.3 Checkpoint System Implementation
- [ ] Verify checkpoint.gd `_on_body_entered` implementation
- [ ] Add checkpoint activation particles (programmatic)
- [ ] Add checkpoint state to SaveManager:
  - [ ] Save active checkpoint per level
  - [ ] Restore on level reload
- [ ] Test multi-checkpoint levels (level 2+)

#### 10.4 Collectible System Verification
- [ ] Verify light_shard.gd emits correct signals
- [ ] Verify echo_crystal.gd saves to SaveManager
- [ ] Fix HUD shard counter connection:
  - [ ] Connect to Events.shard_collected in hud.gd
  - [ ] Update display on collection
- [ ] Add collection sound fallback (if audio missing)

#### 10.5 Save/Load System Implementation
- [ ] Verify SaveManager.save_game() writes correctly
- [ ] Verify SaveManager.load_game() reads correctly
- [ ] Add save file migration (for future updates)
- [ ] Create `scripts/debug/save_debugger.gd`:
  - [ ] Print save file contents on F2
  - [ ] Allow save file reset on Shift+F2
- [ ] Test full save/load cycle programmatically

---

### Phase 11: Asset & Visual Fixes

> **Priority:** 🟡 MEDIUM - Game playable but visually incomplete
> **Estimated Time:** 2-3 hours
> **Approach:** Programmatic asset generation and fixes

#### 11.1 Platform Visual System
- [ ] Create platform visual styles in platform_generator.gd:
  - [ ] Solid platform: White/light gray (#CCCCCC)
  - [ ] One-way platform: Semi-transparent white (#FFFFFF80)
  - [ ] Wall: Slightly different shade (#AAAAAA)
  - [ ] Hazard platform: Red tint (#FF6666)
- [ ] Add optional outline/border to platforms
- [ ] Add subtle gradient or texture via shader (optional)

#### 11.2 Placeholder Texture Improvements (COMPLETED)
- [x] Player placeholder (32x32, cyan modulate)
- [x] Light Shard placeholder (24x24, cyan)
- [x] Echo Crystal placeholder (32x32, cyan)
- [x] Shadow Crawler placeholder (20x16, purple)
- [x] Mirror Guard placeholder (16x32, light blue)
- [x] Pulse Orb placeholder (24x24, cyan)
- [x] Checkpoint placeholder (16x64, gray → cyan)

#### 11.3 Programmatic Particle Systems
- [ ] Create `scripts/effects/particle_factory.gd`:
  - [ ] Method: `create_burst_particles(color: Color, count: int) -> GPUParticles2D`
  - [ ] Method: `create_trail_particles(color: Color) -> GPUParticles2D`
  - [ ] Method: `create_ambient_particles() -> GPUParticles2D`
- [ ] Generate particles programmatically where .tscn files missing
- [ ] Add fallback: If particle scene not found, create basic version

#### 11.4 Lighting System Setup
- [ ] Create `scripts/systems/lighting_manager.gd`:
  - [ ] Auto-add player glow if missing
  - [ ] Create ambient level lighting based on level bounds
  - [ ] Add danger zone lighting near hazards
- [ ] Integrate with level_base.gd on level load
- [ ] Add CanvasModulate adjustment per level (darker for later levels)

---

### Phase 12: Enemy & Hazard Fixes

> **Priority:** 🟡 MEDIUM - Affects gameplay challenge
> **Estimated Time:** 1-2 hours
> **Approach:** Code verification and fixes

#### 12.1 Shadow Crawler Fixes
- [ ] Verify shadow_crawler.gd movement code
- [ ] Add ground detection for patrol (RayCast2D check)
- [ ] Fix ledge detection logic
- [ ] Add fallback behavior if no ground detected (stop or turn)
- [ ] Test damage dealing via HitboxComponent

#### 12.2 Mirror Guard Fixes
- [ ] Verify mirror_guard.gd player tracking
- [ ] Fix mirroring calculation
- [ ] Add jump delay timer
- [ ] Test in level 3 context

#### 12.3 Pulse Orb Fixes
- [ ] Verify sine wave calculation in pulse_orb.gd
- [ ] Add visual pulse sync with movement
- [ ] Test amplitude and frequency exports
- [ ] Verify collision with player

#### 12.4 Hazard Fixes
- [ ] Verify spike.gd instant kill
- [ ] Verify void_pit.gd detection
- [ ] Fix laser_beam.gd toggle timing:
  - [ ] Verify Timer connections
  - [ ] Add visual warning before activation
  - [ ] Test on/off cycle

---

### Phase 13: Platform Mechanics Fixes

> **Priority:** 🟡 MEDIUM - Required for level progression
> **Estimated Time:** 1-2 hours
> **Approach:** Code verification and fixes

#### 13.1 Crumbling Platform Fixes
- [ ] Verify crumbling_platform.gd detection
- [ ] Fix Timer connections for crumble/respawn
- [ ] Add shake animation before crumble
- [ ] Test collision disable/enable cycle
- [ ] Add placeholder crumble visual (scale/fade)

#### 13.2 Moving Platform Fixes
- [ ] Verify moving_platform.gd path following
- [ ] Fix player carrying (AnimatableBody2D sync_to_physics)
- [ ] Test with simple 2-point path
- [ ] Add platform position reset on level restart

#### 13.3 One-Way Platform Verification
- [ ] Verify one_way_collision setting in generator
- [ ] Test player passes through from below
- [ ] Test player lands from above
- [ ] Verify visual distinction

#### 13.4 Phase Platform Fixes
- [ ] Verify phase_platform.gd timer logic
- [ ] Fix collision toggle
- [ ] Add fade animation before disappear
- [ ] Test phase_offset synchronization
- [ ] Add audio cue on phase change

---

### Phase 14: Audio System Fixes

> **Priority:** 🟢 LOW - Game playable without
> **Estimated Time:** 1 hour
> **Approach:** Fallback sounds and verification

#### 14.1 Audio Fallback System
- [ ] Create `scripts/systems/audio_fallback.gd`:
  - [ ] Generate simple beep/tone sounds programmatically
  - [ ] Use as fallback when .wav files missing
  - [ ] AudioStreamGenerator for procedural audio
- [ ] Integrate with AudioManager:
  - [ ] Check if sound file exists
  - [ ] Use fallback if missing
  - [ ] Log warning for missing audio

#### 14.2 Sound Effect Connections
- [ ] Verify player.gd calls AudioManager.play_sfx()
- [ ] Verify collectible scripts play sounds
- [ ] Verify checkpoint activation sound
- [ ] Verify menu button sounds

#### 14.3 Music System Verification
- [ ] Verify main_menu.gd starts music
- [ ] Verify level_base.gd handles level music
- [ ] Test volume controls in settings
- [ ] Test crossfade on transitions

---

### Phase 15: Automated Testing & Verification

> **Priority:** 🟢 After all above phases complete
> **Approach:** Automated test scripts

#### 15.1 Create Automated Test Suite
- [ ] Create `scripts/tests/level_test_runner.gd`:
  - [ ] Auto-load each level
  - [ ] Verify player spawns on ground
  - [ ] Verify no immediate death
  - [ ] Verify collectibles count matches expected
  - [ ] Verify exit is reachable (pathfinding check)
- [ ] Create `scripts/tests/flow_test_runner.gd`:
  - [ ] Test menu → level 1 → complete → level 2
  - [ ] Test pause/unpause
  - [ ] Test death/respawn
  - [ ] Test save/load cycle

#### 15.2 Debug Visualization Tools
- [ ] Create `scripts/debug/level_visualizer.gd`:
  - [ ] Draw platform bounds
  - [ ] Show collectible positions
  - [ ] Show enemy patrol paths
  - [ ] Show checkpoint coverage
  - [ ] Toggle with F3

#### 15.3 Performance Profiling
- [ ] Add frame time logging
- [ ] Check particle system performance
- [ ] Verify 60 FPS target
- [ ] Profile memory usage

---

### Issue Tracking

| Issue ID | Description | Status | Priority | Phase |
|----------|-------------|--------|----------|-------|
| ISS-001 | All levels missing geometry | ✅ FIXED | - | 9 |
| ISS-002 | Player falls through world | ✅ FIXED | - | 9 |
| ISS-003 | Placeholder textures missing | ✅ FIXED | - | 11 |
| ISS-004 | Game flow untested | OPEN | 🟠 HIGH | 10 |
| ISS-005 | Checkpoint system untested | OPEN | 🟠 HIGH | 10 |
| ISS-006 | Save/load system untested | OPEN | 🟠 HIGH | 10 |
| ISS-007 | Enemy behavior untested | OPEN | 🟡 MEDIUM | 12 |
| ISS-008 | Platform mechanics untested | OPEN | 🟡 MEDIUM | 13 |
| ISS-009 | Audio system untested | OPEN | 🟢 LOW | 14 |

---

### Technical Architecture: Procedural Generation

#### Platform Generator Flow
```
Level Load
    ↓
level_base._ready()
    ↓
_generate_level_geometry()
    ↓
Load layout from level_layouts.gd
    ↓
For each platform in layout:
    → PlatformGenerator.create_platform()
    → Add to GeneratedGeometry node
    ↓
For each wall in layout:
    → PlatformGenerator.create_wall()
    ↓
For each one_way in layout:
    → PlatformGenerator.create_one_way_platform()
    ↓
Spawn player (now has ground to land on)
```

#### Platform Data Format
```gdscript
# level_layouts.gd
const LAYOUTS = {
    "LEVEL_01": {
        "platforms": [
            # Main ground - full width
            {"pos": Vector2(0, 224), "size": Vector2(2560, 64), "type": "solid"},
            # Elevated platform for shard 3
            {"pos": Vector2(864, 112), "size": Vector2(64, 32), "type": "solid"},
        ],
        "walls": [
            # Wall jump section for crystal
            {"pos": Vector2(700, -64), "height": 288, "side": "left"},
            {"pos": Vector2(836, -64), "height": 288, "side": "right"},
        ],
        "one_way_platforms": [],
        "metadata": {
            "ground_y": 224,
            "spawn_check": true
        }
    }
}
```

#### Generated Node Structure
```
Level (Node2D)
├── GeneratedGeometry (Node2D)      ← Created by generator
│   ├── Platform_0 (StaticBody2D)
│   │   ├── CollisionShape2D
│   │   └── ColorRect
│   ├── Platform_1 (StaticBody2D)
│   ├── Wall_0 (StaticBody2D)
│   └── OneWay_0 (StaticBody2D)
├── TileMapLayer (unused, kept for future)
├── PlayerSpawn
├── Player (spawned after geometry)
├── Collectibles
├── Enemies
└── ...
```

---

*Last Updated: January 2026*
*Engine: Godot 4.5.1*
