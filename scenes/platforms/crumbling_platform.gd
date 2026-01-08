class_name CrumblingPlatform
extends PlatformBase

## Crumbling platform that shakes and breaks when stepped on.
## After crumbling, respawns after a configurable time.
## Extends PlatformBase for collision layer configuration.

# Signals
signal started_crumbling
signal crumbled
signal respawned

# Exported properties
@export_group("Crumble Settings")
## Delay before the platform crumbles after player contact.
@export var crumble_delay: float = 0.5
## Time before the platform respawns after crumbling.
@export var respawn_time: float = 3.0
## Intensity of the shake effect before crumbling.
@export var shake_intensity: float = 2.0

@export_group("Visual Settings")
## Platform visual color when active.
@export var platform_color: Color = Color(0.8, 0.8, 0.9, 1.0)
## Platform size (for auto-generated visual if Sprite2D has no texture).
@export var platform_size: Vector2 = Vector2(64.0, 16.0)

# State tracking
enum PlatformState { IDLE, SHAKING, CRUMBLED, RESPAWNING }
var _current_state: PlatformState = PlatformState.IDLE
var _shake_offset: Vector2 = Vector2.ZERO
var _original_position: Vector2
var _visual_container: Control = null  # For programmatic visual

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var player_detector: Area2D = $PlayerDetector
@onready var crumble_timer: Timer = $CrumbleTimer
@onready var respawn_timer: Timer = $RespawnTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var crumble_particles: GPUParticles2D = $CrumbleParticles


func _ready() -> void:
	super._ready()
	_original_position = position
	
	# Setup placeholder visual if Sprite2D has no texture
	_setup_placeholder_visual()
	
	# Connect signals
	player_detector.body_entered.connect(_on_player_entered)
	crumble_timer.timeout.connect(_on_crumble_timer_timeout)
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	
	# Configure timers
	crumble_timer.wait_time = crumble_delay
	crumble_timer.one_shot = true
	respawn_timer.wait_time = respawn_time
	respawn_timer.one_shot = true


## Creates a placeholder visual using ColorRect if Sprite2D has no texture.
func _setup_placeholder_visual() -> void:
	# Check if Sprite2D has a valid texture
	if sprite and sprite.texture != null:
		return  # Use the existing sprite
	
	# Get size from collision shape if available
	if collision_shape and collision_shape.shape is RectangleShape2D:
		platform_size = (collision_shape.shape as RectangleShape2D).size
	
	# Hide the empty sprite
	if sprite:
		sprite.visible = false
	
	# Create ColorRect-based visual
	_visual_container = Control.new()
	_visual_container.name = "VisualContainer"
	_visual_container.size = platform_size
	_visual_container.position = -platform_size / 2.0  # Center on node position
	
	# Main fill
	var fill := ColorRect.new()
	fill.name = "Fill"
	fill.size = platform_size
	fill.color = platform_color
	fill.position = Vector2.ZERO
	_visual_container.add_child(fill)
	
	# Add border
	var border_width: float = 2.0
	var border_color := Color(1.0, 1.0, 1.0, 0.8)
	
	if platform_size.x > border_width * 4 and platform_size.y > border_width * 4:
		# Top border
		var top := ColorRect.new()
		top.size = Vector2(platform_size.x, border_width)
		top.color = border_color
		_visual_container.add_child(top)
		
		# Bottom border
		var bottom := ColorRect.new()
		bottom.size = Vector2(platform_size.x, border_width)
		bottom.color = border_color
		bottom.position = Vector2(0, platform_size.y - border_width)
		_visual_container.add_child(bottom)
		
		# Left border
		var left := ColorRect.new()
		left.size = Vector2(border_width, platform_size.y)
		left.color = border_color
		_visual_container.add_child(left)
		
		# Right border
		var right := ColorRect.new()
		right.size = Vector2(border_width, platform_size.y)
		right.color = border_color
		right.position = Vector2(platform_size.x - border_width, 0)
		_visual_container.add_child(right)
	
	add_child(_visual_container)


func _physics_process(delta: float) -> void:
	if _current_state == PlatformState.SHAKING:
		_apply_shake(delta)


## Applies a random shake offset to the platform position.
func _apply_shake(_delta: float) -> void:
	_shake_offset = Vector2(
		randf_range(-shake_intensity, shake_intensity),
		randf_range(-shake_intensity, shake_intensity)
	)
	position = _original_position + _shake_offset


## Called when the player steps on the platform.
func _on_player_entered(body: Node2D) -> void:
	if body.is_in_group("player") and _current_state == PlatformState.IDLE:
		_start_crumbling()


## Starts the crumbling sequence with shake animation.
func _start_crumbling() -> void:
	_current_state = PlatformState.SHAKING
	crumble_timer.start()
	started_crumbling.emit()
	
	# Play shake animation if available
	if animation_player.has_animation("shake"):
		animation_player.play("shake")
	else:
		# Programmatic warning flash effect
		_play_warning_flash()


## Called when the crumble delay timer expires.
func _on_crumble_timer_timeout() -> void:
	_crumble()


## Performs the actual crumble - disables collision and hides platform.
func _crumble() -> void:
	_current_state = PlatformState.CRUMBLED
	position = _original_position  # Reset position before hiding
	
	# Emit particles for falling debris
	if crumble_particles:
		crumble_particles.emitting = true
	
	# Play crumble animation if available, otherwise use programmatic effect
	if animation_player.has_animation("crumble"):
		animation_player.play("crumble")
		# Disable collision and hide after animation
		deactivate(true)
	else:
		# Use programmatic scale/fade crumble effect
		_play_crumble_effect()
		# Disable collision but keep visible for the effect
		_set_collision_enabled(false)
		_is_active = false
	
	# Request light screen shake via Events signal bus
	var events := get_node_or_null("/root/Events")
	if events:
		events.screen_shake_requested.emit(3.0, 0.1)
	
	crumbled.emit()
	
	# Start respawn timer
	respawn_timer.start()


## Called when the respawn timer expires.
func _on_respawn_timer_timeout() -> void:
	_respawn()


## Respawns the platform with a fade-in effect.
func _respawn() -> void:
	_current_state = PlatformState.RESPAWNING
	position = _original_position
	
	# Reset scale if it was modified during crumble
	scale = Vector2.ONE
	
	# Make sure visual is visible again
	visible = true
	_set_visual_visible(true)
	
	# Play respawn animation if available
	if animation_player.has_animation("respawn"):
		animation_player.play("respawn")
		# Reactivate collision after animation starts
		_set_collision_enabled(true)
		_is_active = true
	else:
		# Programmatic scale-up and fade-in effect
		modulate.a = 0.0
		scale = Vector2(0.8, 0.5)
		
		var respawn_tween := create_tween()
		respawn_tween.set_parallel(true)
		respawn_tween.tween_property(self, "modulate:a", 1.0, 0.3)
		respawn_tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		
		# Enable collision after a slight delay (so player doesn't get pushed)
		await respawn_tween.finished
		_set_collision_enabled(true)
		_is_active = true
	
	_current_state = PlatformState.IDLE
	respawned.emit()


## Returns the current state of the platform.
func get_state() -> PlatformState:
	return _current_state


## Override to add custom ready logic.
func _on_platform_ready() -> void:
	# Add to group for easy identification
	add_to_group("crumbling_platforms")


## Plays a programmatic warning flash effect (red tint pulsing).
func _play_warning_flash() -> void:
	var warning_color := Color(1.0, 0.6, 0.6, 1.0)  # Reddish tint
	var original_color := modulate
	
	# Create a fast flashing tween during the shake phase
	var flash_tween := create_tween()
	flash_tween.set_loops(int(crumble_delay / 0.1))  # Flash multiple times
	flash_tween.tween_property(self, "modulate", warning_color, 0.05)
	flash_tween.tween_property(self, "modulate", original_color, 0.05)


## Plays a programmatic scale-down and fade effect for crumbling.
func _play_crumble_effect() -> void:
	# Scale down and fade out effect
	var crumble_tween := create_tween()
	crumble_tween.set_parallel(true)
	crumble_tween.tween_property(self, "modulate:a", 0.0, 0.15)
	crumble_tween.tween_property(self, "scale", Vector2(0.8, 0.3), 0.15)
	
	# Wait for effect to complete before deactivating
	await crumble_tween.finished
	scale = Vector2.ONE  # Reset scale for respawn


## Sets visibility of the platform visual (handles both Sprite2D and ColorRect visual).
func _set_visual_visible(is_visible: bool) -> void:
	if sprite and sprite.texture != null:
		sprite.visible = is_visible
	if _visual_container:
		_visual_container.visible = is_visible
