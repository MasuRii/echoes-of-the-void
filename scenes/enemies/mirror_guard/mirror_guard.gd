class_name MirrorGuard
extends EnemyBase

## Mirror Guard enemy - copies player movement.
## When the player enters its detection area, it mirrors the player's X velocity
## and jumps when the player jumps (with a slight delay).
## Damages the player on contact via HitboxComponent.

# Signals
signal started_mirroring
signal stopped_mirroring

# Exported properties
@export_group("Mirroring")
## If true, mirrors player direction (same direction). If false, moves opposite.
@export var mirror_mode: bool = true
## Delay before mirroring a jump (in seconds).
@export var jump_delay: float = 0.1
## How fast the guard accelerates to match player speed.
@export var mirror_acceleration: float = 1500.0

@export_group("Detection")
## Radius of the detection area for player tracking.
@export var detection_radius: float = 150.0

# Constants
const JUMP_VELOCITY: float = -400.0
const MAX_SPEED: float = 300.0

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var detection_area: Area2D = $DetectionArea

# Internal state
var _is_mirroring: bool = false
var _player_ref: CharacterBody2D = null
var _pending_jump: bool = false
var _jump_delay_timer: float = 0.0
var _last_player_on_floor: bool = true


func _ready() -> void:
	super._ready()
	
	# Set up detection area connections
	if detection_area != null:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)
		
		# Configure detection radius via collision shape
		var shape := detection_area.get_node_or_null("DetectionShape") as CollisionShape2D
		if shape != null and shape.shape is CircleShape2D:
			(shape.shape as CircleShape2D).radius = detection_radius


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Apply gravity
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 600.0)
	
	# Handle mirroring behavior
	if _is_mirroring and _player_ref != null:
		_mirror_player(delta)
	else:
		# When not mirroring, slow down gradually
		velocity.x = move_toward(velocity.x, 0.0, mirror_acceleration * delta)
	
	# Handle pending jump with delay
	if _pending_jump:
		_jump_delay_timer -= delta
		if _jump_delay_timer <= 0.0:
			_execute_jump()
			_pending_jump = false
	
	move_and_slide()
	
	# Update sprite facing direction
	_update_sprite()


## Mirrors the player's horizontal movement.
func _mirror_player(delta: float) -> void:
	if _player_ref == null:
		return
	
	# Get player's current velocity
	var player_velocity_x: float = _player_ref.velocity.x
	
	# Calculate target velocity based on mirror mode
	var target_velocity_x: float
	if mirror_mode:
		# Same direction as player
		target_velocity_x = player_velocity_x
	else:
		# Opposite direction
		target_velocity_x = -player_velocity_x
	
	# Clamp to max speed
	target_velocity_x = clampf(target_velocity_x, -MAX_SPEED, MAX_SPEED)
	
	# Smoothly accelerate toward target velocity
	velocity.x = move_toward(velocity.x, target_velocity_x, mirror_acceleration * delta)
	
	# Check for player jump (detect when player leaves ground while moving upward)
	var player_on_floor: bool = _player_ref.is_on_floor()
	if _last_player_on_floor and not player_on_floor and _player_ref.velocity.y < 0:
		# Player just jumped - queue our jump with delay
		_queue_jump()
	
	_last_player_on_floor = player_on_floor


## Queues a jump to be executed after the delay.
func _queue_jump() -> void:
	if not _pending_jump and is_on_floor():
		_pending_jump = true
		_jump_delay_timer = jump_delay


## Executes the actual jump.
func _execute_jump() -> void:
	if is_on_floor():
		velocity.y = JUMP_VELOCITY


## Updates sprite direction based on movement.
func _update_sprite() -> void:
	if sprite == null:
		return
	
	if velocity.x > 10.0:
		sprite.flip_h = false
		facing_direction = 1
	elif velocity.x < -10.0:
		sprite.flip_h = true
		facing_direction = -1


## Called when a body enters the detection area.
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_ref = body as CharacterBody2D
		_is_mirroring = true
		_last_player_on_floor = _player_ref.is_on_floor()
		started_mirroring.emit()


## Called when a body exits the detection area.
func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body == _player_ref:
		_player_ref = null
		_is_mirroring = false
		_pending_jump = false
		stopped_mirroring.emit()


## Override for player detection (called by base class).
func _on_player_detected(_player_detected: CharacterBody2D) -> void:
	# Mirror Guard uses detection area instead of base class detection
	pass


## Override can_see_player to work with our detection area.
func _can_see_player() -> bool:
	return _is_mirroring and _player_ref != null
