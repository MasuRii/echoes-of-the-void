class_name VoidPit
extends Area2D

## Void pit hazard that instantly kills the player on contact.
## Represents bottomless pits or areas of corruption.
## Uses body_entered for direct CharacterBody2D detection.

# Signals
signal player_fell_in

# Particle node reference
@onready var mist_particles: GPUParticles2D = $MistParticles


func _ready() -> void:
	# Add to hazards group
	add_to_group("hazards")
	
	# Connect body_entered signal
	body_entered.connect(_on_body_entered)


## Called when a body enters the void pit.
func _on_body_entered(body: Node2D) -> void:
	# Check if the body is the player
	if body.is_in_group("player"):
		player_fell_in.emit()
		
		# Deal instant kill damage via health component
		if body.has_node("HealthComponent"):
			var health_component: Node = body.get_node("HealthComponent")
			health_component.take_damage(999)
		elif body.has_method("die"):
			# Fallback to direct die method
			body.die()
