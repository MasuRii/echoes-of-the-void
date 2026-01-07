class_name Checkpoint
extends Area2D

## Checkpoint pillar that saves the player's respawn position.
## Activates when the player enters, updating their last_checkpoint.
## Emits checkpoint_reached signal via Events autoload when activated.

# Signals
signal activated(checkpoint_position: Vector2)

# Export for offset spawn position if needed
@export var spawn_offset: Vector2 = Vector2.ZERO
## Unique index for this checkpoint within the level (auto-assigned in _ready if -1)
@export var checkpoint_index: int = -1

# Animation constants
const ACTIVATION_DURATION: float = 0.5
const IDLE_PULSE_FREQUENCY: float = 1.5
const IDLE_PULSE_INTENSITY_MIN: float = 0.3
const IDLE_PULSE_INTENSITY_MAX: float = 0.8
const ACTIVE_PULSE_INTENSITY_MIN: float = 0.8
const ACTIVE_PULSE_INTENSITY_MAX: float = 1.5

# Colors
const INACTIVE_COLOR: Color = Color(0.3, 0.3, 0.3, 1.0)  # Dim gray
const ACTIVE_COLOR: Color = Color(0.0, 1.0, 1.0, 1.0)     # Cyan
const GLOW_COLOR: Color = Color(0.0, 1.0, 1.0, 1.0)       # Cyan

# State tracking
var _is_activated: bool = false
var _time_elapsed: float = 0.0

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var point_light: PointLight2D = $PointLight2D
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var particles: GPUParticles2D = $ActivationParticles


func _ready() -> void:
	# Add to checkpoint group
	add_to_group("checkpoints")
	
	# Auto-assign checkpoint index if not set
	if checkpoint_index < 0:
		checkpoint_index = _get_sibling_checkpoint_index()
	
	# Set initial appearance (inactive)
	_set_inactive_appearance()
	
	# Connect body_entered signal
	body_entered.connect(_on_body_entered)


## Gets this checkpoint's index based on sibling order in the Checkpoints container.
func _get_sibling_checkpoint_index() -> int:
	var parent := get_parent()
	if parent == null:
		return 0
	
	var index: int = 0
	for child in parent.get_children():
		if child == self:
			return index
		if child.is_in_group("checkpoints"):
			index += 1
	return index


func _process(delta: float) -> void:
	_time_elapsed += delta
	
	# Pulse the light based on activation state
	if point_light and point_light.visible:
		var pulse_factor := (sin(_time_elapsed * IDLE_PULSE_FREQUENCY * TAU) + 1.0) / 2.0
		
		if _is_activated:
			point_light.energy = lerpf(ACTIVE_PULSE_INTENSITY_MIN, ACTIVE_PULSE_INTENSITY_MAX, pulse_factor)
		else:
			point_light.energy = lerpf(IDLE_PULSE_INTENSITY_MIN, IDLE_PULSE_INTENSITY_MAX, pulse_factor)


## Sets the checkpoint to inactive (dim) appearance.
func _set_inactive_appearance() -> void:
	if sprite:
		sprite.modulate = INACTIVE_COLOR
	if point_light:
		point_light.visible = false
	if particles:
		particles.emitting = false


## Sets the checkpoint to active (glowing) appearance.
func _set_active_appearance() -> void:
	if sprite:
		sprite.modulate = ACTIVE_COLOR
	if point_light:
		point_light.visible = true
		point_light.color = GLOW_COLOR
		point_light.energy = ACTIVE_PULSE_INTENSITY_MAX


## Called when a body enters the checkpoint area.
func _on_body_entered(body: Node2D) -> void:
	# Only trigger for player
	if not body.is_in_group("player"):
		return
	
	# Only activate if not already activated
	if _is_activated:
		return
	
	_activate(body)


## Activates the checkpoint and updates the player's respawn position.
func _activate(player: Node2D) -> void:
	_is_activated = true
	
	# Calculate spawn position (checkpoint position + offset)
	var spawn_position := global_position + spawn_offset
	
	# Update player's last checkpoint
	if "last_checkpoint" in player:
		player.last_checkpoint = spawn_position
	
	# Emit local signal
	activated.emit(spawn_position)
	
	# Emit global event
	_emit_checkpoint_reached_event(spawn_position)
	
	# Save checkpoint to SaveManager for persistence
	_save_checkpoint_state(spawn_position)
	
	# Play activation sound
	if audio_player and audio_player.stream:
		audio_player.play()
	
	# Play activation animation
	_play_activation_animation()


## Saves the checkpoint state to SaveManager for persistence across restarts.
func _save_checkpoint_state(spawn_position: Vector2) -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null:
		push_warning("Checkpoint: SaveManager autoload not found, checkpoint won't persist")
		return
	
	# Get current level path
	var level_path: String = ""
	var game_manager := get_node_or_null("/root/GameManager")
	if game_manager and "current_level" in game_manager:
		level_path = game_manager.current_level
	
	if level_path.is_empty():
		# Try to get from scene tree
		level_path = get_tree().current_scene.scene_file_path if get_tree().current_scene else ""
	
	if level_path.is_empty():
		push_warning("Checkpoint: Could not determine level path, checkpoint won't persist")
		return
	
	save_manager.save_checkpoint(level_path, checkpoint_index, spawn_position)
	print("Checkpoint: Saved checkpoint %d at (%.0f, %.0f) for %s" % [checkpoint_index, spawn_position.x, spawn_position.y, level_path])


## Plays the checkpoint activation visual effects.
func _play_activation_animation() -> void:
	# Start particles
	if particles:
		particles.emitting = true
	
	# Animate from inactive to active
	var tween := create_tween()
	tween.set_parallel(true)
	
	# Flash bright first
	if sprite:
		tween.tween_property(sprite, "modulate", Color.WHITE, ACTIVATION_DURATION * 0.3).set_ease(Tween.EASE_OUT)
	
	# Turn on light with a burst
	if point_light:
		point_light.visible = true
		point_light.energy = 0.0
		tween.tween_property(point_light, "energy", 3.0, ACTIVATION_DURATION * 0.3).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	
	# Settle to active color
	var settle_tween := create_tween()
	settle_tween.set_parallel(true)
	
	if sprite:
		settle_tween.tween_property(sprite, "modulate", ACTIVE_COLOR, ACTIVATION_DURATION * 0.5).set_ease(Tween.EASE_IN_OUT)
	
	if point_light:
		settle_tween.tween_property(point_light, "energy", ACTIVE_PULSE_INTENSITY_MAX, ACTIVATION_DURATION * 0.5).set_ease(Tween.EASE_IN_OUT)


## Emits the checkpoint_reached event via Events autoload.
func _emit_checkpoint_reached_event(checkpoint_position: Vector2) -> void:
	var events := get_node_or_null("/root/Events")
	if events == null:
		push_warning("Checkpoint: Events autoload not found")
		return
	
	events.checkpoint_reached.emit(checkpoint_position)


## Returns whether this checkpoint has been activated.
func is_activated() -> bool:
	return _is_activated


## Forcefully sets the checkpoint state (for save/load purposes).
func set_activated(value: bool) -> void:
	_is_activated = value
	if value:
		_set_active_appearance()
	else:
		_set_inactive_appearance()
