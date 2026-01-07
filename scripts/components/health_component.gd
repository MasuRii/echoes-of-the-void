class_name HealthComponent
extends Node

## Reusable health component for any entity requiring health management.
## Emits signals when health changes or entity dies.

# Signals
signal health_changed(current: int, max_health: int)
signal died

# Exported properties
@export var max_health: int = 1

# Current health tracking
var current_health: int = 0

func _ready() -> void:
	current_health = max_health


## Apply damage to this entity. Emits health_changed and potentially died.
func take_damage(amount: int = 1) -> void:
	if current_health <= 0:
		return  # Already dead
	
	current_health = maxi(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		died.emit()


## Heal this entity by the specified amount, capped at max_health.
func heal(amount: int) -> void:
	if current_health <= 0:
		return  # Can't heal dead entities
	
	current_health = mini(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)


## Reset health to max (useful for respawning).
func reset_health() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


## Check if entity is still alive.
func is_alive() -> bool:
	return current_health > 0
