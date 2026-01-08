class_name ShadowCrawler
extends EnemyBase

## Shadow Crawler enemy - a basic patrol enemy.
## Walks back and forth on platforms, turning at ledges and walls.
## Damages the player on contact via HitboxComponent.

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var ledge_detector: RayCast2D = $LedgeDetector
@onready var wall_detector: RayCast2D = $WallDetector

# Cooldown to prevent rapid turning (getting stuck)
var _turn_cooldown: float = 0.0


func _ready() -> void:
	super._ready()
	
	# Initialize facing direction based on sprite flip
	if sprite != null and sprite.flip_h:
		facing_direction = -1
	
	# Ensure raycasts are enabled and have correct collision masks
	if ledge_detector != null:
		ledge_detector.enabled = true
		# Make sure ledge detector can see platforms (layer 3)
		ledge_detector.collision_mask = 0
		ledge_detector.set_collision_mask_value(3, true)  # Layer 3 = platforms
		# Enable hit_from_inside in case ray starts inside platform collision
		ledge_detector.hit_from_inside = true
	if wall_detector != null:
		wall_detector.enabled = true
		# Wall detector should also detect platforms
		wall_detector.collision_mask = 0
		wall_detector.set_collision_mask_value(3, true)  # Layer 3 = platforms
	
	# Initialize raycast directions based on starting facing direction
	_update_raycast_directions()
	
	# Start with walk animation since we patrol immediately on the ground
	if animation_player != null:
		animation_player.play("walk")


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Update turn cooldown
	if _turn_cooldown > 0.0:
		_turn_cooldown -= delta
	
	# Apply gravity
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 600.0)
	
	# Only patrol when on the floor
	if is_on_floor():
		_patrol()
		# Play walk animation while moving
		if animation_player != null and animation_player.current_animation != "walk":
			animation_player.play("walk")
	else:
		# Play idle when in the air (falling)
		if animation_player != null and animation_player.current_animation != "idle":
			animation_player.play("idle")
	
	move_and_slide()


## Handles patrol movement - walking and turning at ledges/walls.
func _patrol() -> void:
	# Check if we should turn around (respecting cooldown)
	if _turn_cooldown <= 0.0 and _should_turn():
		flip_direction()
		_update_raycast_directions()
		_turn_cooldown = 0.2 # Brief delay to prevent jitter
	
	# Move in facing direction
	velocity.x = facing_direction * move_speed


## Determines if the crawler should turn around.
func _should_turn() -> bool:
	# Turn if hitting a wall
	if is_on_wall():
		return true
	
	# Turn if wall detector hits something
	if wall_detector != null and wall_detector.is_colliding():
		return true
	
	# Turn if no floor ahead (ledge detection)
	if ledge_detector != null and not ledge_detector.is_colliding():
		return true
	
	return false


## Updates raycast directions when the crawler turns.
func _update_raycast_directions() -> void:
	# Ledge detector starts at the crawler's origin (foot level) and points 
	# forward and down to detect floor ahead.
	# The target goes 16px ahead (past body edge) and 24px down (into where platform should be).
	if ledge_detector != null:
		ledge_detector.position = Vector2.ZERO  # Start at origin (foot level)
		ledge_detector.target_position = Vector2(facing_direction * 16.0, 24.0)
		ledge_detector.force_raycast_update()
	
	# Wall detector should point forward past the body edge
	# Use 14.0 to detect walls slightly before the body collides
	if wall_detector != null:
		wall_detector.target_position = Vector2(facing_direction * 14.0, 0.0)
		wall_detector.force_raycast_update()


## Override flip_direction to also update sprite.
func flip_direction() -> void:
	facing_direction *= -1
	if sprite != null:
		sprite.flip_h = facing_direction < 0


## Override to add eye glow flicker on player detection (optional enhancement).
func _on_player_detected(_player_ref: CharacterBody2D) -> void:
	# Shadow crawlers don't chase, they just patrol
	# Could add an alert animation here in the future
	pass
