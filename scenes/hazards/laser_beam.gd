class_name LaserBeam
extends Node2D

## Toggleable laser beam hazard with on/off timing.
## Uses RayCast2D for instant hit detection.
## Features warning flicker before activating.

# Signals
signal laser_activated
signal laser_deactivated
signal player_hit

# Exported properties
@export_group("Timing")
@export var on_duration: float = 2.0
@export var off_duration: float = 1.5
@export var warning_duration: float = 0.5
@export var start_active: bool = true

@export_group("Damage")
@export var damage: int = 999  # Instant kill

@export_group("Visual")
@export var beam_color: Color = Color.WHITE
@export var warning_color: Color = Color(1.0, 0.3, 0.3, 0.5)  # Red-ish warning
@export var beam_width: float = 4.0

# State tracking
enum LaserState { OFF, WARNING, ON }
var current_state: LaserState = LaserState.OFF
var _state_timer: float = 0.0
var _flicker_timer: float = 0.0
var _flicker_visible: bool = true

# Node references
@onready var raycast: RayCast2D = $RayCast2D
@onready var beam_line: Line2D = $BeamLine
@onready var point_light: PointLight2D = $PointLight2D
@onready var end_point_light: PointLight2D = $EndPointLight2D


func _ready() -> void:
	# Add to hazards group
	add_to_group("hazards")
	
	# Initialize state
	if start_active:
		_enter_state(LaserState.ON)
	else:
		_enter_state(LaserState.OFF)
	
	# Configure beam line visual
	beam_line.width = beam_width
	beam_line.default_color = beam_color


func _process(delta: float) -> void:
	_state_timer -= delta
	
	match current_state:
		LaserState.OFF:
			if _state_timer <= 0.0:
				_enter_state(LaserState.WARNING)
		
		LaserState.WARNING:
			# Flicker effect
			_flicker_timer -= delta
			if _flicker_timer <= 0.0:
				_flicker_timer = 0.05
				_flicker_visible = not _flicker_visible
				_update_warning_visual()
			
			if _state_timer <= 0.0:
				_enter_state(LaserState.ON)
		
		LaserState.ON:
			if _state_timer <= 0.0:
				_enter_state(LaserState.OFF)


func _physics_process(_delta: float) -> void:
	if current_state == LaserState.ON:
		_check_for_player()
		_update_beam_visual()


## Enter a new laser state and set up accordingly.
func _enter_state(new_state: LaserState) -> void:
	current_state = new_state
	
	match new_state:
		LaserState.OFF:
			_state_timer = off_duration
			beam_line.visible = false
			point_light.enabled = false
			end_point_light.enabled = false
			laser_deactivated.emit()
		
		LaserState.WARNING:
			_state_timer = warning_duration
			_flicker_timer = 0.05
			_flicker_visible = true
			beam_line.visible = true
			beam_line.default_color = warning_color
			beam_line.width = beam_width * 0.5
			point_light.enabled = true
			point_light.energy = 0.3
			end_point_light.enabled = false
			_update_beam_visual()
		
		LaserState.ON:
			_state_timer = on_duration
			beam_line.visible = true
			beam_line.default_color = beam_color
			beam_line.width = beam_width
			point_light.enabled = true
			point_light.energy = 1.0
			end_point_light.enabled = true
			laser_activated.emit()
			_update_beam_visual()


## Update the warning flicker visual.
func _update_warning_visual() -> void:
	if current_state == LaserState.WARNING:
		beam_line.visible = _flicker_visible


## Update beam line to match raycast collision point.
func _update_beam_visual() -> void:
	if not raycast.is_colliding():
		# Extend to full target position
		beam_line.points = PackedVector2Array([Vector2.ZERO, raycast.target_position])
		end_point_light.position = raycast.target_position
	else:
		# End at collision point
		var collision_point: Vector2 = to_local(raycast.get_collision_point())
		beam_line.points = PackedVector2Array([Vector2.ZERO, collision_point])
		end_point_light.position = collision_point


## Check if the laser is hitting the player.
func _check_for_player() -> void:
	if raycast.is_colliding():
		var collider: Object = raycast.get_collider()
		if collider is Node and collider.is_in_group("player"):
			_damage_player(collider as Node2D)


## Deal damage to the player.
func _damage_player(player: Node2D) -> void:
	player_hit.emit()
	
	# Deal damage via health component
	if player.has_node("HealthComponent"):
		var health_component: Node = player.get_node("HealthComponent")
		health_component.take_damage(damage)
	elif player.has_method("die"):
		# Fallback to direct die method
		player.die()


## Manually turn the laser on.
func activate() -> void:
	_enter_state(LaserState.ON)


## Manually turn the laser off.
func deactivate() -> void:
	_enter_state(LaserState.OFF)


## Check if the laser is currently active (damaging).
func is_active() -> bool:
	return current_state == LaserState.ON
