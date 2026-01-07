class_name PulseOrb
extends EnemyBase

## Pulse Orb enemy - moves in a sine-wave pattern.
## Floats through the air, ignoring gravity, with a pulsing light effect.
## Damages the player on contact via HitboxComponent.

# Exported properties
@export_group("Movement")
## Wave height (how far up/down the orb moves from center).
@export var amplitude: float = 100.0
## Oscillation speed (cycles per second).
@export var frequency: float = 2.0
## Horizontal movement speed.
@export var base_speed: float = 100.0
## If true, sine wave is vertical; if false, sine wave is horizontal.
@export var vertical_mode: bool = false

@export_group("Visuals")
## Minimum light energy during pulse.
@export var min_light_energy: float = 0.5
## Maximum light energy during pulse.
@export var max_light_energy: float = 1.5
## Light pulse frequency (can differ from movement).
@export var light_pulse_frequency: float = 3.0

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var point_light: PointLight2D = $PointLight2D
@onready var particles: GPUParticles2D = $GPUParticles2D

# Internal state
var _time_elapsed: float = 0.0
var _start_position: Vector2
var _base_light_energy: float = 1.0


func _ready() -> void:
	super._ready()
	
	# Store starting position for sine wave calculation
	_start_position = global_position
	
	# Store base light energy for pulsing
	if point_light != null:
		_base_light_energy = point_light.energy
	
	# Pulse Orb ignores gravity (floating enemy)
	gravity = 0.0


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	_time_elapsed += delta
	
	# Calculate sine wave offset
	var sine_offset: float = sin(_time_elapsed * frequency * TAU) * amplitude
	
	# Apply movement based on mode
	if vertical_mode:
		# Vertical sine wave: move up/down while traveling horizontally
		var target_y: float = _start_position.y + sine_offset
		velocity.x = base_speed * facing_direction
		# Calculate required Y velocity to reach target position
		velocity.y = (target_y - global_position.y) * 10.0
	else:
		# Horizontal sine wave: move horizontally with offset
		var target_x: float = _start_position.x + (_time_elapsed * base_speed * facing_direction)
		velocity.x = base_speed * facing_direction
		velocity.y = sine_offset - (global_position.y - _start_position.y)
		velocity.y *= 10.0  # Smooth transition speed
	
	# Update light pulsing
	_update_light_pulse()
	
	# Update sprite (optional rotation for visual effect)
	_update_sprite()
	
	# Move but don't use floor detection (floating)
	move_and_slide()
	
	# Check for walls to turn around
	if is_on_wall():
		_turn_around()


## Updates the pulsing light effect.
func _update_light_pulse() -> void:
	if point_light == null:
		return
	
	# Calculate light energy based on sine wave
	var pulse: float = sin(_time_elapsed * light_pulse_frequency * TAU)
	var normalized_pulse: float = (pulse + 1.0) / 2.0  # Normalize to 0-1 range
	
	# Interpolate between min and max energy
	point_light.energy = lerpf(min_light_energy, max_light_energy, normalized_pulse)


## Updates sprite rotation for visual effect.
func _update_sprite() -> void:
	if sprite == null:
		return
	
	# Subtle rotation based on movement
	sprite.rotation = sin(_time_elapsed * 2.0) * 0.2


## Turns the orb around when hitting a wall.
func _turn_around() -> void:
	facing_direction *= -1
	# Reset X start position when turning
	if not vertical_mode:
		_start_position.x = global_position.x
		_time_elapsed = 0.0


## Override base class gravity application (we handle our own movement).
func _can_see_player() -> bool:
	# Pulse Orb doesn't actively chase player, just patrols
	return false


## Override death sequence to stop particles.
func _death_sequence() -> void:
	# Stop emitting particles
	if particles != null:
		particles.emitting = false
	
	# Fade out light
	if point_light != null:
		var light_tween := create_tween()
		light_tween.tween_property(point_light, "energy", 0.0, 0.3)
	
	# Call parent death sequence
	await super._death_sequence()
