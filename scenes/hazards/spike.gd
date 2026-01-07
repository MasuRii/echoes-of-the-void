class_name Spike
extends StaticBody2D

## Static spike hazard that damages the player on contact.
## Instant kill - deals maximum damage to ensure death.

@export var damage: int = 999  # High damage for instant kill

@onready var hitbox: Area2D = $HitboxComponent


func _ready() -> void:
	# Set the hitbox damage via the script's property
	if hitbox.has_method("get") and "damage" in hitbox:
		hitbox.damage = damage
	else:
		# Direct property access - HitboxComponent has damage export
		hitbox.set("damage", damage)
