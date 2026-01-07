class_name ScreenShake
extends Node

## Screen shake component for Camera2D.
## Attach as a child of a Camera2D to enable shake effects.
## Uses random offset decay for natural-feeling camera shake.

# Shake state
var _shake_intensity: float = 0.0
var _shake_duration: float = 0.0
var _shake_timer: float = 0.0
var _original_offset: Vector2 = Vector2.ZERO

# Reference to parent camera
var _camera: Camera2D = null


func _ready() -> void:
	# Get parent camera reference
	var parent := get_parent()
	if parent is Camera2D:
		_camera = parent
		_original_offset = _camera.offset
	else:
		push_warning("ScreenShake: Parent is not a Camera2D! Shake will not work.")


func _process(delta: float) -> void:
	if _camera == null:
		return
	
	if _shake_timer > 0.0:
		_shake_timer -= delta
		
		# Calculate decay (shake gets weaker as it progresses)
		var decay: float = _shake_timer / _shake_duration if _shake_duration > 0.0 else 0.0
		var current_intensity: float = _shake_intensity * decay
		
		# Apply random offset
		var offset_x: float = randf_range(-current_intensity, current_intensity)
		var offset_y: float = randf_range(-current_intensity, current_intensity)
		_camera.offset = _original_offset + Vector2(offset_x, offset_y)
	else:
		# Shake finished - reset offset
		if _camera.offset != _original_offset:
			_camera.offset = _original_offset


## Start a screen shake effect.
## @param intensity: Maximum pixel offset for shake (higher = more intense).
## @param duration: How long the shake lasts in seconds.
func shake(intensity: float, duration: float) -> void:
	if _camera == null:
		return
	
	# Only override if new shake is more intense
	if intensity > _shake_intensity * (_shake_timer / _shake_duration if _shake_duration > 0.0 else 0.0):
		_shake_intensity = intensity
		_shake_duration = duration
		_shake_timer = duration


## Stop any current shake immediately.
func stop_shake() -> void:
	_shake_timer = 0.0
	if _camera != null:
		_camera.offset = _original_offset


## Convenience methods for common shake intensities

## Light shake - for subtle feedback (enemy death, small impacts).
func shake_light() -> void:
	shake(3.0, 0.1)


## Medium shake - for moderate feedback (player death, platform crumble).
func shake_medium() -> void:
	shake(6.0, 0.2)


## Heavy shake - for significant events (boss hits, explosions).
func shake_heavy() -> void:
	shake(10.0, 0.3)


## Landing shake - scales with fall velocity.
func shake_landing(fall_velocity: float) -> void:
	# Only shake if landing from significant height
	if fall_velocity > 200.0:
		var intensity: float = remap(fall_velocity, 200.0, 600.0, 1.0, 4.0)
		intensity = clampf(intensity, 1.0, 4.0)
		shake(intensity, 0.1)
