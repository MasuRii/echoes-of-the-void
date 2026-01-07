class_name ScreenEffects
extends CanvasLayer

## Screen effects controller for Echoes of the Void.
## Handles vignette, CRT filter, and screen fades.

signal fade_completed

# Fade constants
const DEATH_FADE_DURATION: float = 0.4
const LEVEL_TRANSITION_DURATION: float = 0.6

# Exports
@export var vignette_enabled: bool = true:
	set(value):
		vignette_enabled = value
		if is_inside_tree() and vignette_rect:
			vignette_rect.visible = value

@export var crt_enabled: bool = false:
	set(value):
		crt_enabled = value
		if is_inside_tree() and crt_rect:
			crt_rect.visible = value

@export_range(0.0, 1.0) var vignette_intensity: float = 0.4:
	set(value):
		vignette_intensity = value
		if is_inside_tree() and vignette_rect and vignette_rect.material:
			(vignette_rect.material as ShaderMaterial).set_shader_parameter("intensity", value)

@export_range(0.0, 1.0) var crt_intensity: float = 0.3:
	set(value):
		crt_intensity = value
		if is_inside_tree() and crt_rect and crt_rect.material:
			(crt_rect.material as ShaderMaterial).set_shader_parameter("intensity", value)

# Private state
var _is_fading: bool = false

# Node references
@onready var vignette_rect: ColorRect = $VignetteRect
@onready var crt_rect: ColorRect = $CRTRect
@onready var fade_rect: ColorRect = $FadeRect


func _ready() -> void:
	# Ensure this layer is always on top
	layer = 100
	
	# Initialize states
	vignette_rect.visible = vignette_enabled
	crt_rect.visible = crt_enabled
	fade_rect.modulate.a = 0.0
	fade_rect.visible = true
	
	# Apply initial shader parameters
	if vignette_rect.material:
		(vignette_rect.material as ShaderMaterial).set_shader_parameter("intensity", vignette_intensity)
	if crt_rect.material:
		(crt_rect.material as ShaderMaterial).set_shader_parameter("intensity", crt_intensity)


## Fade screen to black for death effect
func fade_to_death() -> void:
	if _is_fading:
		return
	await _fade_to_black(DEATH_FADE_DURATION)


## Fade screen to black for level transition
func fade_to_transition() -> void:
	if _is_fading:
		return
	await _fade_to_black(LEVEL_TRANSITION_DURATION)


## Fade screen from black (after death respawn or level load)
func fade_from_black(duration: float = 0.5) -> void:
	if _is_fading:
		return
	_is_fading = true
	
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, duration)
	await tween.finished
	
	_is_fading = false
	fade_completed.emit()


## Instant fade to black (no animation)
func set_black() -> void:
	fade_rect.modulate.a = 1.0


## Instant clear (no animation)
func set_clear() -> void:
	fade_rect.modulate.a = 0.0


## Toggle vignette effect
func toggle_vignette() -> void:
	vignette_enabled = not vignette_enabled


## Toggle CRT effect
func toggle_crt() -> void:
	crt_enabled = not crt_enabled


## Private fade helper
func _fade_to_black(duration: float) -> void:
	_is_fading = true
	
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tween.finished
	
	_is_fading = false
	fade_completed.emit()
