class_name EchoGhost
extends Node2D

## Fading player silhouette for echo trail effects.
## Spawns at player position, fades out, then self-destructs.

const FADE_DURATION: float = 0.3
const INITIAL_ALPHA: float = 0.5
const CYAN_TINT: Color = Color("#00FFFF")

var _elapsed_time: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	# Set initial modulation with cyan tint and starting alpha
	modulate = Color(CYAN_TINT.r, CYAN_TINT.g, CYAN_TINT.b, INITIAL_ALPHA)


func _process(delta: float) -> void:
	_elapsed_time += delta
	
	# Calculate current alpha based on elapsed time
	var progress: float = _elapsed_time / FADE_DURATION
	var current_alpha: float = lerpf(INITIAL_ALPHA, 0.0, progress)
	
	# Update modulation
	modulate.a = current_alpha
	
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
