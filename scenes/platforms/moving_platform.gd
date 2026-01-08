class_name MovingPlatform
extends AnimatableBody2D

## Moving platform that travels between defined waypoints.
## Uses AnimatableBody2D for proper player carrying behavior.
## Supports configurable speed, wait times at endpoints, and ping-pong or loop modes.

# Signals
signal reached_waypoint(waypoint_index: int)
signal direction_changed(is_forward: bool)

# Constants for collision layers (matching project.godot)
const COLLISION_LAYER_PLAYER: int = 1
const COLLISION_LAYER_ENEMY: int = 2
const COLLISION_LAYER_PLATFORM: int = 3

# Exported properties
@export_group("Movement")
## Movement speed in pixels per second.
@export var speed: float = 100.0
## Time to wait at each endpoint before moving again.
@export var wait_time: float = 0.5
## Array of waypoint positions (relative to starting position).
@export var path_points: Array[Vector2] = [Vector2.ZERO, Vector2(0, -100)]

@export_group("Behavior")
## If true, platform ping-pongs between endpoints. If false, loops back to start.
@export var ping_pong_mode: bool = true
## If true, starts moving immediately. If false, waits for activation.
@export var auto_start: bool = true
## If true, platform starts paused at the first waypoint.
@export var start_paused: bool = false

@export_group("Platform Settings")
## If true, player can jump through from below and land on top.
@export var one_way: bool = false
## Enable collision with players.
@export var collide_with_player: bool = true
## Enable collision with enemies.
@export var collide_with_enemies: bool = true

# State tracking
var _current_waypoint_index: int = 0
var _moving_forward: bool = true
var _is_waiting: bool = false
var _is_active: bool = true
var _start_position: Vector2

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var wait_timer: Timer = $WaitTimer


func _ready() -> void:
	_start_position = global_position
	_setup_collision_layers()
	_setup_one_way()
	_setup_timer()
	_setup_visual()
	
	# Enable sync_to_physics for smooth player riding
	sync_to_physics = true
	
	# Add to group for easy identification
	add_to_group("moving_platforms")
	
	# Handle initial state
	if start_paused or not auto_start:
		_is_active = false
	
	# Convert relative path points to absolute positions
	_convert_path_to_absolute()


## Sets up collision layers and masks.
func _setup_collision_layers() -> void:
	# Set this platform to be on the platform layer
	set_collision_layer_value(COLLISION_LAYER_PLATFORM, true)
	
	# Clear and set collision masks based on settings
	collision_mask = 0
	
	if collide_with_player:
		set_collision_mask_value(COLLISION_LAYER_PLAYER, true)
	
	if collide_with_enemies:
		set_collision_mask_value(COLLISION_LAYER_ENEMY, true)


## Configures one-way collision if enabled.
func _setup_one_way() -> void:
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.one_way_collision = one_way
			child.one_way_collision_margin = 4.0


## Sets up the wait timer.
func _setup_timer() -> void:
	wait_timer.one_shot = true
	wait_timer.wait_time = wait_time
	wait_timer.timeout.connect(_on_wait_timer_timeout)


## Sets up placeholder visual if no texture/visual exists.
func _setup_visual() -> void:
	# Check if we already have a Visual ColorRect
	var visual: ColorRect = get_node_or_null("Visual")
	if visual != null:
		return  # Visual already exists
	
	# Check if Sprite2D has a texture
	if sprite and sprite.texture != null:
		return  # Sprite has a valid texture
	
	# Create programmatic placeholder visual
	var platform_color := Color(0.5, 0.75, 0.9, 1.0)  # Light blue
	var border_color := Color(0.7, 0.9, 1.0, 1.0)  # Brighter border
	var inner_color := Color(0.4, 0.65, 0.8, 1.0)  # Darker inner
	
	# Get collision shape size for visual sizing
	var shape_size := Vector2(64, 16)  # Default
	if collision_shape and collision_shape.shape is RectangleShape2D:
		shape_size = collision_shape.shape.size
	
	# Create main visual container
	visual = ColorRect.new()
	visual.name = "Visual"
	visual.position = -shape_size / 2.0
	visual.size = shape_size
	visual.color = border_color
	add_child(visual)
	
	# Create inner visual for depth effect
	var inner := ColorRect.new()
	inner.name = "Inner"
	inner.position = Vector2(2, 2)
	inner.size = shape_size - Vector2(4, 4)
	inner.color = inner_color
	visual.add_child(inner)


## Converts relative path points to absolute world positions.
func _convert_path_to_absolute() -> void:
	for i in range(path_points.size()):
		path_points[i] = _start_position + path_points[i]


func _physics_process(delta: float) -> void:
	if not _is_active or _is_waiting:
		return
	
	if path_points.is_empty():
		return
	
	_move_toward_waypoint(delta)


## Moves the platform toward the current target waypoint.
func _move_toward_waypoint(delta: float) -> void:
	var target_position: Vector2 = path_points[_current_waypoint_index]
	var direction: Vector2 = (target_position - global_position).normalized()
	var distance_to_target: float = global_position.distance_to(target_position)
	var move_distance: float = speed * delta
	
	if move_distance >= distance_to_target:
		# Reached the waypoint
		global_position = target_position
		_on_reached_waypoint()
	else:
		# Move toward waypoint
		global_position += direction * move_distance


## Called when the platform reaches a waypoint.
func _on_reached_waypoint() -> void:
	reached_waypoint.emit(_current_waypoint_index)
	
	# Determine next waypoint
	if ping_pong_mode:
		_handle_ping_pong_mode()
	else:
		_handle_loop_mode()
	
	# Wait at waypoint if configured
	if wait_time > 0:
		_is_waiting = true
		wait_timer.start()


## Handles waypoint progression in ping-pong mode.
func _handle_ping_pong_mode() -> void:
	if _moving_forward:
		if _current_waypoint_index >= path_points.size() - 1:
			# Reached end, reverse direction
			_moving_forward = false
			_current_waypoint_index -= 1
			direction_changed.emit(_moving_forward)
		else:
			_current_waypoint_index += 1
	else:
		if _current_waypoint_index <= 0:
			# Reached start, reverse direction
			_moving_forward = true
			_current_waypoint_index += 1
			direction_changed.emit(_moving_forward)
		else:
			_current_waypoint_index -= 1


## Handles waypoint progression in loop mode.
func _handle_loop_mode() -> void:
	_current_waypoint_index += 1
	if _current_waypoint_index >= path_points.size():
		_current_waypoint_index = 0


## Called when the wait timer expires.
func _on_wait_timer_timeout() -> void:
	_is_waiting = false


## Activates the platform, starting movement.
func activate() -> void:
	_is_active = true


## Deactivates the platform, stopping movement.
func deactivate() -> void:
	_is_active = false


## Returns whether the platform is currently active.
func is_active() -> bool:
	return _is_active


## Returns whether the platform is currently waiting at a waypoint.
func is_waiting() -> bool:
	return _is_waiting


## Returns the current waypoint index.
func get_current_waypoint_index() -> int:
	return _current_waypoint_index


## Sets a new speed at runtime.
func set_speed(new_speed: float) -> void:
	speed = new_speed


## Sets new wait time at runtime.
func set_wait_time(new_wait_time: float) -> void:
	wait_time = new_wait_time
	wait_timer.wait_time = new_wait_time


## Teleports the platform to a specific waypoint index.
func teleport_to_waypoint(index: int) -> void:
	if index >= 0 and index < path_points.size():
		_current_waypoint_index = index
		global_position = path_points[index]


## Resets the platform to its initial state (for level restarts).
func reset_position() -> void:
	# Stop waiting if applicable
	_is_waiting = false
	wait_timer.stop()
	
	# Reset waypoint tracking
	_current_waypoint_index = 0
	_moving_forward = true
	
	# Teleport back to starting position
	global_position = _start_position
	
	# Re-convert path points since they were made absolute
	# We need to recalculate based on the stored start position
	_reconvert_path_to_absolute()
	
	# Reactivate if it was auto-start
	if auto_start and not start_paused:
		_is_active = true


## Reconverts path points back to absolute positions from start position.
## Used after reset when we need to restore the original path.
func _reconvert_path_to_absolute() -> void:
	# First convert back to relative (subtract old start position which is current absolute)
	# Since path_points are already absolute from the first conversion,
	# we need to calculate relative offsets from the first waypoint
	if path_points.is_empty():
		return
	
	var first_point: Vector2 = path_points[0]
	var relative_offsets: Array[Vector2] = []
	
	for point in path_points:
		relative_offsets.append(point - first_point)
	
	# Now apply to the start position
	for i in range(relative_offsets.size()):
		path_points[i] = _start_position + relative_offsets[i]
