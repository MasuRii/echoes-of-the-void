class_name DeathParticles
extends GPUParticles2D

## White dispersion burst effect for player death.
## Particles explode outward from the player's position.

const LIFETIME: float = 0.8


func _ready() -> void:
	# Configure as one-shot effect
	one_shot = true
	emitting = true
	
	# Self-destruct after particles finish
	await get_tree().create_timer(LIFETIME + 0.2).timeout
	queue_free()


## Spawns death particles at the specified position.
## Call this as a static-like factory method.
static func spawn_at(scene_tree: SceneTree, spawn_position: Vector2) -> DeathParticles:
	var particles: DeathParticles = preload("res://scenes/effects/particles/death_particles.tscn").instantiate()
	scene_tree.current_scene.add_child(particles)
	particles.global_position = spawn_position
	return particles
