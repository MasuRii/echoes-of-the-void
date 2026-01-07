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


func _ready() -> void:
	super._ready()
	
	# Initialize facing direction based on sprite flip
	if sprite != null and sprite.flip_h:
		facing_direction = -1
	
	# Ensure raycasts are enabled
	if ledge_detector != null:
		ledge_detector.enabled = true
	if wall_detector != null:
		wall_detector.enabled = true


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Apply gravity
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 600.0)
	
	# Only patrol when on the floor
	if is_on_floor():
		_patrol()
	
	move_and_slide()


## Handles patrol movement - walking and turning at ledges/walls.
func _patrol() -> void:
	# Check if we should turn around
	if _should_turn():
		flip_direction()
		_update_raycast_directions()
	
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
	# Ledge detector should point down and slightly ahead
	if ledge_detector != null:
		ledge_detector.target_position = Vector2(facing_direction * 12.0, 20.0)
	
	# Wall detector should point forward
	if wall_detector != null:
		wall_detector.target_position = Vector2(facing_direction * 10.0, 0.0)


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
