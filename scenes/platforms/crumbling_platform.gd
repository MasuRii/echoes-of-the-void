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

# State tracking
enum PlatformState { IDLE, SHAKING, CRUMBLED, RESPAWNING }
var _current_state: PlatformState = PlatformState.IDLE
var _shake_offset: Vector2 = Vector2.ZERO
var _original_position: Vector2

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
	
	# Connect signals
	player_detector.body_entered.connect(_on_player_entered)
	crumble_timer.timeout.connect(_on_crumble_timer_timeout)
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	
	# Configure timers
	crumble_timer.wait_time = crumble_delay
	crumble_timer.one_shot = true
	respawn_timer.wait_time = respawn_time
	respawn_timer.one_shot = true


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
	
	# Play crumble animation if available
	if animation_player.has_animation("crumble"):
		animation_player.play("crumble")
	
	# Request light screen shake via Events signal bus
	var events := get_node_or_null("/root/Events")
	if events:
		events.screen_shake_requested.emit(3.0, 0.1)
	
	# Disable collision and hide sprite
	deactivate(true)
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
	
	# Reactivate the platform
	activate()
	
	# Play respawn animation if available
	if animation_player.has_animation("respawn"):
		animation_player.play("respawn")
	else:
		# Default fade-in effect using modulate
		modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 1.0, 0.3)
	
	_current_state = PlatformState.IDLE
	respawned.emit()


## Returns the current state of the platform.
func get_state() -> PlatformState:
	return _current_state


## Override to add custom ready logic.
func _on_platform_ready() -> void:
	# Add to group for easy identification
	add_to_group("crumbling_platforms")
