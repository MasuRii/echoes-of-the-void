class_name EnemyBase
extends CharacterBody2D

## Base class for all enemies in Echoes of the Void.
## Provides common functionality: health, hitbox, death handling, and player detection.
## Extend this class to create specific enemy types.

# Signals
signal enemy_died

# Exported properties
@export_group("Movement")
@export var move_speed: float = 80.0
@export var gravity: float = 980.0

@export_group("Detection")
@export var can_detect_player: bool = true

# Internal state
var facing_direction: int = 1
var is_dead: bool = false

# Component references (found via node path)
var health_component: Node
var hitbox_component: Node

# Cached player reference
var _player: CharacterBody2D = null

# Preload death particles (reuse from player death system)
const DEATH_PARTICLES_SCENE: PackedScene = preload("res://scenes/effects/particles/death_particles.tscn")


func _ready() -> void:
	_setup_components()
	_find_player()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Apply gravity
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 600.0)
	
	# Check for player detection
	if can_detect_player and _player != null:
		if _can_see_player():
			_on_player_detected(_player)
	
	move_and_slide()


## Sets up component connections.
func _setup_components() -> void:
	# Auto-find components by node name
	health_component = get_node_or_null("HealthComponent")
	hitbox_component = get_node_or_null("HitboxComponent")
	
	# Connect health component signals
	if health_component != null:
		if health_component.has_signal("died"):
			health_component.died.connect(_on_died)
	else:
		push_warning("EnemyBase: No HealthComponent found on %s" % name)
	
	# Set hitbox owner
	if hitbox_component != null:
		hitbox_component.owner_entity = self


## Finds the player in the scene tree.
func _find_player() -> void:
	# Try to find player in the "player" group
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0] as CharacterBody2D


## Virtual method called when player is detected.
## Override in subclasses to implement specific AI behavior.
func _on_player_detected(_player_ref: CharacterBody2D) -> void:
	pass


## Virtual method to determine if player is visible.
## Override in subclasses for custom detection logic.
func _can_see_player() -> bool:
	return _player != null and not _player.get("is_dead")


## Called when health reaches zero.
func _on_died() -> void:
	if is_dead:
		return
	
	is_dead = true
	
	# Stop all movement
	velocity = Vector2.ZERO
	
	# Disable collision
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	# Disable hitbox
	if hitbox_component != null:
		hitbox_component.set_deferred("monitoring", false)
		hitbox_component.set_deferred("monitorable", false)
	
	# Emit death signal
	enemy_died.emit()
	
	# Play death effect
	_spawn_death_particles()
	
	# Fade out and destroy
	_death_sequence()


## Spawns death particles at enemy position.
func _spawn_death_particles() -> void:
	var particles: GPUParticles2D = DEATH_PARTICLES_SCENE.instantiate()
	get_tree().current_scene.add_child(particles)
	particles.global_position = global_position


## Handles death animation and cleanup.
func _death_sequence() -> void:
	# Fade out over 0.3 seconds
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	# Clean up
	queue_free()


## Flips the enemy's facing direction.
func flip_direction() -> void:
	facing_direction *= -1
	# Flip sprite if it exists
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		sprite.flip_h = facing_direction < 0


## Gets the horizontal direction toward the player.
func get_direction_to_player() -> int:
	if _player == null:
		return facing_direction
	return 1 if _player.global_position.x > global_position.x else -1


## Gets the distance to the player.
func get_distance_to_player() -> float:
	if _player == null:
		return INF
	return global_position.distance_to(_player.global_position)


## Takes damage from an external source.
func take_damage(amount: int = 1) -> void:
	if health_component != null and health_component.has_method("take_damage"):
		health_component.take_damage(amount)
