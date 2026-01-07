class_name PhasePlatform
extends PlatformBase

## Disappearing/reappearing platform that cycles between visible and invisible states.
## Provides a warning fade before disappearing to give players time to react.
## Extends PlatformBase for collision layer configuration.

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
@export var phase_offset: float = 0.0

@export_group("Visual Settings")
## Duration of the warning fade before disappearing.
@export var warning_duration: float = 0.5
## Duration of the phase-in sparkle/fade effect.
@export var phase_in_duration: float = 0.3
## Minimum alpha during warning flicker.
@export var warning_min_alpha: float = 0.3

# State tracking
enum PhaseState { VISIBLE, WARNING, INVISIBLE, PHASING_IN }
var _current_state: PhaseState = PhaseState.VISIBLE
var _phase_timer: float = 0.0
var _warning_timer: float = 0.0
var _original_modulate: Color

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var phase_timer_node: Timer = $PhaseTimer
@onready var phase_particles: GPUParticles2D = $PhaseParticles


func _ready() -> void:
	super._ready()
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
	if phase_offset > 0.0:
		_phase_timer = maxf(0.0, _phase_timer - phase_offset)


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
