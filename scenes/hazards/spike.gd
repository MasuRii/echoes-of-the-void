class_name Spike
extends StaticBody2D

## Static spike hazard that damages the player on contact.
## Instant kill - deals maximum damage to ensure death.
## Uses HitboxComponent for collision detection with player's HurtboxComponent.

@export var damage: int = 999  # High damage for instant kill

@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	# Add to hazards group for identification
	add_to_group("hazards")
	
	# Sync the hitbox damage with our exported damage value
	if hitbox:
		hitbox.damage = damage
	
	# Ensure spike has a visual - create placeholder if missing
	if sprite and sprite.texture == null:
		_create_placeholder_visual()


## Creates a placeholder triangle-like visual for the spike.
func _create_placeholder_visual() -> void:
	# Create a PlaceholderTexture2D for visibility
	var placeholder := PlaceholderTexture2D.new()
	placeholder.size = Vector2(16, 16)
	sprite.texture = placeholder
	
	# Use red tint to indicate danger
	sprite.modulate = Color(1.0, 0.3, 0.3, 1.0)  # Reddish warning color
