class_name EchoGhost
extends Node2D

## Fading player silhouette for echo trail effects.
## Spawns at player position, fades out, then self-destructs.

const FADE_DURATION: float = 0.3
const INITIAL_ALPHA: float = 0.5
const INITIAL_LIGHT_ENERGY: float = 0.4
const SCALE_END_MULTIPLIER: float = 0.7  # Shrink to 70% of original size

# Color progression: bright cyan-white → deep blue as trail ages
const COLOR_START: Color = Color(0.7, 1.0, 1.0, 1.0)  # Bright cyan-white
const COLOR_END: Color = Color(0.0, 0.4, 0.8, 1.0)    # Deep blue

var _elapsed_time: float = 0.0
var _initial_scale: Vector2 = Vector2.ONE

@onready var sprite: Sprite2D = $Sprite2D
@onready var ghost_glow: PointLight2D = $GhostGlow


func _ready() -> void:
	# Set initial modulation with starting color and alpha
	modulate = Color(COLOR_START.r, COLOR_START.g, COLOR_START.b, INITIAL_ALPHA)
	# Store initial scale for shrink animation
	_initial_scale = scale


func _process(delta: float) -> void:
	_elapsed_time += delta
	
	# Calculate current alpha based on elapsed time
	var progress: float = _elapsed_time / FADE_DURATION
	var current_alpha: float = lerpf(INITIAL_ALPHA, 0.0, progress)
	
	# Lerp color from bright cyan-white to deep blue as trail ages
	var current_color: Color = COLOR_START.lerp(COLOR_END, progress)
	
	# Update modulation with both color progression and alpha fade
	modulate = Color(current_color.r, current_color.g, current_color.b, current_alpha)
	
	# Shrink scale over time for visual progression
	var target_scale: Vector2 = _initial_scale * SCALE_END_MULTIPLIER
	scale = _initial_scale.lerp(target_scale, progress)
	
	# Fade the glow light energy along with the sprite
	if ghost_glow:
		ghost_glow.energy = lerpf(INITIAL_LIGHT_ENERGY, 0.0, progress)
	
	# Self-destruct when fade is complete
	if _elapsed_time >= FADE_DURATION:
		queue_free()


## Initializes the echo ghost with player sprite data.
## Call this immediately after instantiation.
func initialize(player_sprite: Sprite2D, spawn_position: Vector2, flip_h: bool = false) -> void:
	global_position = spawn_position
	
	# Copy texture from player sprite if available
	if player_sprite and player_sprite.texture:
		$Sprite2D.texture = player_sprite.texture
	
	# Match player sprite orientation
	$Sprite2D.flip_h = flip_h
	$Sprite2D.position = player_sprite.position if player_sprite else Vector2.ZERO
	$Sprite2D.scale = player_sprite.scale if player_sprite else Vector2.ONE
