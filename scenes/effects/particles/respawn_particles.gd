class_name RespawnParticles
extends GPUParticles2D

## Coalesce effect for player respawn.
## Particles converge inward to the player's position.

const LIFETIME: float = 0.6


func _ready() -> void:
	# Configure as one-shot effect
	one_shot = true
	emitting = true
	
	# Self-destruct after particles finish
	await get_tree().create_timer(LIFETIME + 0.2).timeout
	queue_free()


## Spawns respawn particles at the specified position.
## Call this as a static-like factory method.
static func spawn_at(scene_tree: SceneTree, spawn_position: Vector2) -> RespawnParticles:
	var particles: RespawnParticles = preload("res://scenes/effects/particles/respawn_particles.tscn").instantiate()
	scene_tree.current_scene.add_child(particles)
	particles.global_position = spawn_position
	return particles
