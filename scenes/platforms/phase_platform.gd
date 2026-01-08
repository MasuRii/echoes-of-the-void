class_name PhasePlatform
extends PlatformBase

## Disappearing/reappearing platform that cycles between visible and invisible states.
## Provides a warning fade before disappearing to give players time to react.
## Extends PlatformBase for collision layer configuration.
##
## State Machine Flow:
##   VISIBLE -> WARNING (flicker) -> INVISIBLE -> PHASING_IN -> VISIBLE
##
## Audio cues are played on phase_out and phase_in events via AudioManager.

# Signals
signal phase_out_started
signal phase_out_completed
signal phase_in_started
signal phase_in_completed

# Exported properties
@export_group("Phase Timing")
## Duration the platform remains visible and solid.
@export var visible_duration: float = 2.0
## Duration the platform remains invisible and non-solid.
@export var invisible_duration: float = 2.0
## Whether the platform starts in visible state.
@export var start_visible: bool = true
## Time offset for syncing multiple platforms (0.0 = no offset).
## Use to create staggered phase patterns (e.g., offset 1.0 = starts 1 second later in cycle).
@export var phase_offset: float = 0.0

@export_group("Visual Settings")
## Duration of the warning fade before disappearing.
@export var warning_duration: float = 0.5
## Duration of the phase-in sparkle/fade effect.
@export var phase_in_duration: float = 0.3
## Minimum alpha during warning flicker.
@export var warning_min_alpha: float = 0.3
## Color for programmatic placeholder visual.
@export var platform_color: Color = Color(0.5, 0.9, 1.0, 0.9)

@export_group("Audio")
## Enable audio cues on phase change.
@export var enable_audio: bool = true

# State tracking
enum PhaseState { VISIBLE, WARNING, INVISIBLE, PHASING_IN }
var _current_state: PhaseState = PhaseState.VISIBLE
var _phase_timer: float = 0.0
var _warning_timer: float = 0.0
var _original_modulate: Color
var _visual_container: ColorRect = null

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var phase_timer_node: Timer = $PhaseTimer
@onready var phase_particles: GPUParticles2D = $PhaseParticles

# Audio manager reference
var _audio_manager: Node = null


func _ready() -> void:
	super._ready()
	
	# Get audio manager reference
	_audio_manager = get_node_or_null("/root/AudioManager")
	
	# Setup programmatic visual if no texture
	_setup_visual()
	
	_original_modulate = modulate
	
	# Configure initial state based on start_visible
	if start_visible:
		_current_state = PhaseState.VISIBLE
		_phase_timer = visible_duration
		activate()
	else:
		_current_state = PhaseState.INVISIBLE
		_phase_timer = invisible_duration
		modulate.a = 0.0
		deactivate(false)  # Don't hide, we control visibility via modulate
	
	# Apply phase offset by adjusting the initial timer
	# This allows multiple platforms to be synced in staggered patterns
	if phase_offset > 0.0:
		# Calculate how far into the total cycle we should start
		var total_cycle: float = visible_duration + invisible_duration
		var effective_offset: float = fmod(phase_offset, total_cycle)
		_phase_timer = maxf(0.0, _phase_timer - effective_offset)


func _physics_process(delta: float) -> void:
	_phase_timer -= delta
	
	match _current_state:
		PhaseState.VISIBLE:
			_process_visible_state()
		PhaseState.WARNING:
			_process_warning_state(delta)
		PhaseState.INVISIBLE:
			_process_invisible_state()
		PhaseState.PHASING_IN:
			_process_phasing_in_state(delta)


## Sets up programmatic visual if no texture is assigned to Sprite2D.
## Creates a ColorRect-based visual with a distinctive ethereal appearance.
func _setup_visual() -> void:
	if sprite and sprite.texture:
		# Texture exists, no need for placeholder
		return
	
	# Hide the empty sprite
	if sprite:
		sprite.visible = false
	
	# Get size from collision shape
	var platform_size := Vector2(64, 16)  # Default size
	if collision_shape and collision_shape.shape is RectangleShape2D:
		platform_size = (collision_shape.shape as RectangleShape2D).size
	
	# Create visual container
	_visual_container = ColorRect.new()
	_visual_container.name = "PlaceholderVisual"
	_visual_container.size = platform_size
	_visual_container.position = -platform_size / 2  # Center on platform
	_visual_container.color = platform_color
	add_child(_visual_container)
	
	# Add a subtle border for phase platforms (dashed effect simulation)
	var border := ColorRect.new()
	border.name = "Border"
	border.size = platform_size
	border.position = Vector2.ZERO
	border.color = Color(1.0, 1.0, 1.0, 0.5)  # White semi-transparent border
	# Make it just a border by overlaying a smaller inner rect
	var inner := ColorRect.new()
	inner.name = "Inner"
	inner.size = platform_size - Vector2(4, 4)
	inner.position = Vector2(2, 2)
	inner.color = platform_color
	border.add_child(inner)
	_visual_container.add_child(border)


## Processes the visible state - waiting to start warning.
func _process_visible_state() -> void:
	if _phase_timer <= warning_duration:
		_start_warning()


## Starts the warning phase with flicker effect.
func _start_warning() -> void:
	_current_state = PhaseState.WARNING
	_warning_timer = 0.0
	phase_out_started.emit()


## Processes the warning state with flicker animation.
func _process_warning_state(delta: float) -> void:
	_warning_timer += delta
	
	# Flicker effect: oscillate alpha rapidly
	var flicker_speed: float = 20.0
	var flicker: float = (sin(_warning_timer * flicker_speed) + 1.0) / 2.0
	modulate.a = lerpf(warning_min_alpha, 1.0, flicker)
	
	if _phase_timer <= 0.0:
		_phase_out()


## Performs the phase out - makes platform invisible and non-solid.
func _phase_out() -> void:
	_current_state = PhaseState.INVISIBLE
	_phase_timer = invisible_duration
	modulate.a = 0.0
	
	# Disable collision
	_set_collision_enabled(false)
	
	# Play phase-out audio cue
	_play_phase_sound("phase_out")
	
	# Emit particles for phase-out effect
	if phase_particles:
		phase_particles.emitting = true
	
	phase_out_completed.emit()


## Processes the invisible state - waiting to phase in.
func _process_invisible_state() -> void:
	if _phase_timer <= 0.0:
		_start_phase_in()


## Starts the phase in process.
func _start_phase_in() -> void:
	_current_state = PhaseState.PHASING_IN
	_phase_timer = phase_in_duration
	phase_in_started.emit()
	
	# Play phase-in audio cue
	_play_phase_sound("phase_in")
	
	# Emit particles for phase-in effect
	if phase_particles:
		phase_particles.emitting = true


## Processes the phasing in state with fade effect.
func _process_phasing_in_state(delta: float) -> void:
	# Calculate progress (0 to 1)
	var progress: float = 1.0 - (_phase_timer / phase_in_duration)
	progress = clampf(progress, 0.0, 1.0)
	
	# Fade in with slight sparkle
	var sparkle: float = sin(progress * PI * 4.0) * 0.1
	modulate.a = progress + sparkle
	
	if _phase_timer <= 0.0:
		_complete_phase_in()


## Completes the phase in - makes platform fully visible and solid.
func _complete_phase_in() -> void:
	_current_state = PhaseState.VISIBLE
	_phase_timer = visible_duration
	modulate = _original_modulate
	
	# Enable collision
	_set_collision_enabled(true)
	
	phase_in_completed.emit()


## Returns the current phase state.
func get_state() -> PhaseState:
	return _current_state


## Returns whether the platform is currently solid (collidable).
func is_solid() -> bool:
	return _current_state == PhaseState.VISIBLE or _current_state == PhaseState.WARNING


## Forces the platform to a specific state (useful for level design).
func force_state(new_state: PhaseState) -> void:
	_current_state = new_state
	
	match new_state:
		PhaseState.VISIBLE:
			_phase_timer = visible_duration
			modulate = _original_modulate
			_set_collision_enabled(true)
		PhaseState.INVISIBLE:
			_phase_timer = invisible_duration
			modulate.a = 0.0
			_set_collision_enabled(false)
		PhaseState.WARNING:
			_phase_timer = warning_duration
			_warning_timer = 0.0
		PhaseState.PHASING_IN:
			_phase_timer = phase_in_duration


## Override to add custom ready logic.
func _on_platform_ready() -> void:
	# Add to group for easy identification
	add_to_group("phase_platforms")


## Plays audio cue for phase change events.
## Uses AudioManager if available, with graceful fallback if not.
func _play_phase_sound(sound_type: String) -> void:
	if not enable_audio:
		return
	
	if _audio_manager == null:
		return
	
	# Map sound types to audio names
	# Uses existing sounds as placeholders until dedicated phase sounds exist
	var sound_name: String
	match sound_type:
		"phase_out":
			# Use a subtle sound for phase out (checkpoint sound as placeholder)
			sound_name = "checkpoint"
		"phase_in":
			# Use similar sound for phase in
			sound_name = "checkpoint"
		_:
			return
	
	# Play 2D positional audio at platform position
	if _audio_manager.has_method("play_sfx_2d"):
		_audio_manager.play_sfx_2d(sound_name, global_position, -10.0)  # Quieter than default


## Resets the platform to its initial state (useful for level restart).
func reset() -> void:
	if start_visible:
		_current_state = PhaseState.VISIBLE
		_phase_timer = visible_duration
		modulate = _original_modulate
		_set_collision_enabled(true)
	else:
		_current_state = PhaseState.INVISIBLE
		_phase_timer = invisible_duration
		modulate.a = 0.0
		_set_collision_enabled(false)
	
	# Reapply phase offset
	if phase_offset > 0.0:
		var total_cycle: float = visible_duration + invisible_duration
		var effective_offset: float = fmod(phase_offset, total_cycle)
		_phase_timer = maxf(0.0, _phase_timer - effective_offset)
