class_name EchoCrystal
extends Area2D

## Major collectible that persists across sessions.
## Unique per crystal_id - checks SaveManager on spawn and saves on collection.
## Emits crystal_collected signal via Events autoload when collected.

# Signals
signal collected(crystal_id: String)

# Export for unique identification
@export var crystal_id: String = "crystal_01"

# Animation constants
const ROTATION_SPEED: float = 0.5  # Rotations per second
const BOB_AMPLITUDE: float = 6.0
const BOB_FREQUENCY: float = 1.5
const COLLECT_DURATION: float = 0.5
const PULSE_INTENSITY_MIN: float = 1.0
const PULSE_INTENSITY_MAX: float = 2.0
const PULSE_FREQUENCY: float = 2.0

# Colors
const CRYSTAL_COLOR: Color = Color("#00FFFF")
const CORE_COLOR: Color = Color("#FFFFFF")
const GLOW_COLOR: Color = Color("#00FFFF")

# State tracking
var _is_collected: bool = false
var _already_collected: bool = false  # True if loaded from save
var _time_elapsed: float = 0.0
var _initial_y: float = 0.0

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var swirl_particles: GPUParticles2D = $SwirlParticles
@onready var point_light: PointLight2D = $PointLight2D


func _ready() -> void:
	# Store initial position for bob animation
	_initial_y = position.y
	
	# Add to groups
	add_to_group("collectibles")
	add_to_group("echo_crystals")
	
	# Check if already collected via SaveManager
	_check_already_collected()
	
	# If already collected, hide and disable
	if _already_collected:
		_hide_collected()
		return
	
	# Connect body_entered signal
	body_entered.connect(_on_body_entered)
	
	# Start animations if they exist
	if animation_player.has_animation("idle"):
		animation_player.play("idle")


func _process(delta: float) -> void:
	if _is_collected or _already_collected:
		return
	
	_time_elapsed += delta
	
	# Bob up and down (slower than light shard)
	position.y = _initial_y + sin(_time_elapsed * BOB_FREQUENCY * TAU) * BOB_AMPLITUDE
	
	# Rotate slowly
	sprite.rotation += ROTATION_SPEED * TAU * delta
	
	# Pulse the light
	if point_light:
		var pulse_factor := (sin(_time_elapsed * PULSE_FREQUENCY * TAU) + 1.0) / 2.0
		point_light.energy = lerpf(PULSE_INTENSITY_MIN, PULSE_INTENSITY_MAX, pulse_factor)


## Check SaveManager to see if this crystal was already collected.
func _check_already_collected() -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null:
		return
	
	var game_manager := get_node_or_null("/root/GameManager")
	var level_name: String = ""
	if game_manager:
		level_name = game_manager.current_level
	
	# If no level name, try to get from scene tree
	if level_name.is_empty():
		var scene := get_tree().current_scene
		if scene:
			level_name = scene.scene_file_path
	
	if not level_name.is_empty():
		_already_collected = save_manager.is_crystal_collected(level_name, crystal_id)


## Hide the crystal if already collected.
func _hide_collected() -> void:
	visible = false
	collision_shape.set_deferred("disabled", true)
	if swirl_particles:
		swirl_particles.emitting = false
	if point_light:
		point_light.visible = false
	set_process(false)


## Called when a body enters the collection area.
func _on_body_entered(body: Node2D) -> void:
	if _is_collected or _already_collected:
		return
	
	# Only collect if player touches it
	if body.is_in_group("player"):
		_collect()


## Handles the collection sequence.
func _collect() -> void:
	_is_collected = true
	
	# Disable further collisions
	collision_shape.set_deferred("disabled", true)
	
	# Trigger hitstop for impact on major collectible
	var game_manager := get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("hitstop"):
		game_manager.hitstop(0.05)  # Brief freeze for crystal collection
	
	# Emit local signal
	collected.emit(crystal_id)
	
	# Save to SaveManager
	_save_collection()
	
	# Emit global event
	_emit_crystal_collected_event()
	
	# Play collect sound - use local player if available, otherwise fallback to AudioManager
	if audio_player and audio_player.stream:
		audio_player.play()
	else:
		# Fallback to AudioManager for centralized sound
		var audio_manager := get_node_or_null("/root/AudioManager")
		if audio_manager:
			audio_manager.play_sfx("crystal_collect")
	
	# Create grand particle burst
	_spawn_celebration_particles()
	
	# Play collection animation (scale up, glow brighter, then fade out)
	var tween := create_tween()
	tween.set_parallel(true)
	
	# Scale up
	tween.tween_property(sprite, "scale", sprite.scale * 2.0, COLLECT_DURATION * 0.6).set_ease(Tween.EASE_OUT)
	
	# Flash bright
	tween.tween_property(sprite, "modulate", Color.WHITE * 2.0, COLLECT_DURATION * 0.3).set_ease(Tween.EASE_OUT)
	
	# Pulse light to max
	if point_light:
		tween.tween_property(point_light, "energy", 4.0, COLLECT_DURATION * 0.3).set_ease(Tween.EASE_OUT)
	
	# Stop swirl particles
	if swirl_particles:
		swirl_particles.emitting = false
	
	await tween.finished
	
	# Fade out phase
	var fade_tween := create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(sprite, "modulate:a", 0.0, COLLECT_DURATION * 0.4).set_ease(Tween.EASE_IN)
	if point_light:
		fade_tween.tween_property(point_light, "energy", 0.0, COLLECT_DURATION * 0.4).set_ease(Tween.EASE_IN)
	
	await fade_tween.finished
	
	# Wait for audio to finish if playing
	if audio_player and audio_player.playing:
		await audio_player.finished
	
	queue_free()


## Save crystal collection to persistent storage.
func _save_collection() -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null:
		push_warning("EchoCrystal: SaveManager autoload not found")
		return
	
	var game_manager := get_node_or_null("/root/GameManager")
	var level_name: String = ""
	if game_manager:
		level_name = game_manager.current_level
	
	# If no level name, try to get from scene tree
	if level_name.is_empty():
		var scene := get_tree().current_scene
		if scene:
			level_name = scene.scene_file_path
	
	if not level_name.is_empty():
		save_manager.save_crystal(level_name, crystal_id)


## Emits the crystal_collected event.
func _emit_crystal_collected_event() -> void:
	var events := get_node_or_null("/root/Events")
	if events == null:
		push_warning("EchoCrystal: Events autoload not found")
		return
	
	events.crystal_collected.emit(crystal_id)


## Spawns celebration particles on collection.
func _spawn_celebration_particles() -> void:
	# Create a one-shot burst particle effect
	if swirl_particles:
		# Emit a final burst using the existing particles
		swirl_particles.amount = 32
		swirl_particles.explosiveness = 1.0
		swirl_particles.one_shot = true
		swirl_particles.emitting = true
