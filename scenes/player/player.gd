class_name Player
extends CharacterBody2D

## Player character controller for Echoes of the Void.
## Handles movement, jumping, wall mechanics, and echo trail effects.

# Movement constants
const SPEED: float = 300.0
const JUMP_VELOCITY: float = -450.0
const GRAVITY: float = 980.0
const MAX_FALL_SPEED: float = 600.0
const WALL_SLIDE_SPEED: float = 100.0
const WALL_JUMP_VELOCITY: Vector2 = Vector2(350.0, -400.0)
const DOUBLE_JUMP_VELOCITY: float = -380.0
const ACCELERATION: float = 2000.0
const FRICTION: float = 1500.0
const AIR_CONTROL: float = 0.7

# State tracking
var can_double_jump: bool = true
var is_wall_sliding: bool = false
var facing_direction: int = 1
var last_checkpoint: Vector2 = Vector2.ZERO
var _was_on_floor: bool = false
var _input_locked: bool = false
var _input_lock_timer: float = 0.0

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_machine: Node = $StateMachine
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_buffer_timer: Timer = $JumpBufferTimer
@onready var wall_jump_cooldown: Timer = $WallJumpCooldown
@onready var echo_trail_timer: Timer = $EchoTrailTimer
@onready var wall_detector_left: RayCast2D = $WallDetectorLeft
@onready var wall_detector_right: RayCast2D = $WallDetectorRight
@onready var hurtbox: Area2D = $HurtboxComponent


func _ready() -> void:
	# Store initial position as first checkpoint
	last_checkpoint = global_position
	
	# Add player to group for easy access
	add_to_group("player")


func _physics_process(delta: float) -> void:
	# Handle input lock (for wall jumps)
	if _input_locked:
		_input_lock_timer -= delta
		if _input_lock_timer <= 0.0:
			_input_locked = false
	
	# Track floor state for coyote time
	var on_floor := is_on_floor()
	
	# Reset double jump when on floor
	if on_floor:
		can_double_jump = true
	
	# Handle coyote time - start timer when leaving floor (not from jumping)
	if _was_on_floor and not on_floor and velocity.y >= 0:
		coyote_timer.start()
	
	_was_on_floor = on_floor
	
	# Apply gravity
	_apply_gravity(delta)
	
	# Handle movement
	_handle_movement(delta)
	
	# Check for wall sliding
	_check_wall_slide()
	
	# Update sprite direction
	_update_sprite_direction()
	
	# Move the character
	move_and_slide()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		if is_wall_sliding:
			# Slower fall speed when wall sliding
			velocity.y = minf(velocity.y + GRAVITY * delta, WALL_SLIDE_SPEED)
		else:
			# Normal gravity with max fall speed
			velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)


func _handle_movement(delta: float) -> void:
	# Don't process movement if input is locked
	if _input_locked:
		return
	
	var input_dir := Input.get_axis("move_left", "move_right")
	var control_mult := 1.0 if is_on_floor() else AIR_CONTROL
	
	if input_dir != 0:
		# Accelerate toward target speed
		velocity.x = move_toward(
			velocity.x,
			input_dir * SPEED,
			ACCELERATION * control_mult * delta
		)
		facing_direction = int(sign(input_dir))
	else:
		# Apply friction
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * control_mult * delta)


func _check_wall_slide() -> void:
	if is_on_floor():
		is_wall_sliding = false
		return
	
	var input_dir := Input.get_axis("move_left", "move_right")
	var touching_wall := is_touching_wall()
	var pressing_toward_wall := false
	
	if touching_wall:
		if wall_detector_left.is_colliding() and input_dir < 0:
			pressing_toward_wall = true
		elif wall_detector_right.is_colliding() and input_dir > 0:
			pressing_toward_wall = true
	
	is_wall_sliding = touching_wall and pressing_toward_wall and velocity.y > 0


func _update_sprite_direction() -> void:
	if facing_direction != 0:
		sprite.flip_h = facing_direction < 0


## Returns true if player is touching a wall (left or right).
func is_touching_wall() -> bool:
	return wall_detector_left.is_colliding() or wall_detector_right.is_colliding()


## Returns the direction of the wall being touched (-1 for left, 1 for right, 0 for none).
func get_wall_direction() -> int:
	if wall_detector_left.is_colliding():
		return -1
	elif wall_detector_right.is_colliding():
		return 1
	return 0


## Checks if the player can jump (on floor or coyote time).
func can_jump() -> bool:
	return is_on_floor() or not coyote_timer.is_stopped()


## Checks if a jump input is buffered.
func has_buffered_jump() -> bool:
	return not jump_buffer_timer.is_stopped()


## Performs a regular jump.
func jump() -> void:
	velocity.y = JUMP_VELOCITY
	coyote_timer.stop()
	jump_buffer_timer.stop()


## Performs a double jump (weaker than regular jump).
func double_jump() -> void:
	if can_double_jump:
		velocity.y = DOUBLE_JUMP_VELOCITY
		can_double_jump = false
		# TODO: Spawn echo effect burst


## Performs a wall jump.
func wall_jump() -> void:
	var wall_dir := get_wall_direction()
	if wall_dir == 0:
		return
	
	# Jump away from wall
	velocity.x = -wall_dir * WALL_JUMP_VELOCITY.x
	velocity.y = WALL_JUMP_VELOCITY.y
	
	# Reset double jump
	can_double_jump = true
	
	# Lock input briefly to prevent immediate return to wall
	_input_locked = true
	_input_lock_timer = 0.15
	
	# Update facing direction
	facing_direction = -wall_dir
	
	is_wall_sliding = false
	wall_jump_cooldown.start()
	
	# TODO: Spawn echo effect


## Buffers a jump input for execution on landing.
func buffer_jump() -> void:
	jump_buffer_timer.start()


## Cuts jump velocity for variable jump height.
func cut_jump() -> void:
	if velocity.y < 0:
		velocity.y *= 0.5


## Respawns the player at the last checkpoint.
func respawn() -> void:
	global_position = last_checkpoint
	velocity = Vector2.ZERO
	can_double_jump = true
	is_wall_sliding = false
	_input_locked = false
	Events.player_respawned.emit()


## Called when the player dies.
func die() -> void:
	Events.player_died.emit()
	# TODO: Play death particles, transition to death state
	# For now, respawn after brief delay
	await get_tree().create_timer(0.5).timeout
	respawn()
