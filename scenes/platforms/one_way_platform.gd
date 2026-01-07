class_name OneWayPlatform
extends PlatformBase

## One-Way Platform for Echoes of the Void.
## Player can jump through from below and land on top.
## Visual: Semi-transparent appearance to indicate jump-through ability.

# Signals
signal player_landed


@export_group("Visual")
## Transparency level for the platform (0.0 = invisible, 1.0 = opaque).
@export_range(0.1, 1.0, 0.05) var transparency: float = 0.6
## Enable dashed/dotted line appearance.
@export var use_dashed_style: bool = true

# Internal references
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _on_platform_ready() -> void:
	# Force one-way collision for this platform type
	one_way = true
	_setup_one_way()
	_apply_visual_style()


## Applies the semi-transparent visual style to indicate one-way behavior.
func _apply_visual_style() -> void:
	if sprite:
		sprite.modulate.a = transparency
		
		# If using dashed style, add a subtle visual indicator
		if use_dashed_style:
			# Apply a slight cyan tint to differentiate from solid platforms
			sprite.modulate.r = 0.7
			sprite.modulate.g = 0.9
			sprite.modulate.b = 1.0


## Called when a body lands on this platform (connect via signal if needed).
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Only emit if player is falling down onto the platform
		if body is CharacterBody2D and body.velocity.y >= 0:
			player_landed.emit()


## Updates visual transparency at runtime.
func set_transparency(value: float) -> void:
	transparency = clampf(value, 0.1, 1.0)
	_apply_visual_style()


## Toggles dashed style at runtime.
func set_dashed_style(enabled: bool) -> void:
	use_dashed_style = enabled
	_apply_visual_style()
