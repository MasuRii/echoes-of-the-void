class_name FootstepDust
extends GPUParticles2D

## Subtle dust particles when player is running on ground.
## Small, quick puffs that fade out behind the player.

const LIFETIME: float = 0.3


func _ready() -> void:
	# Configure as one-shot effect
	one_shot = true
	emitting = true
	
	# Self-destruct after particles finish
	await get_tree().create_timer(LIFETIME + 0.1).timeout
	queue_free()


## Spawns footstep dust at the specified position.
## Call this as a static-like factory method.
static func spawn_at(scene_tree: SceneTree, spawn_position: Vector2) -> FootstepDust:
	var particles: FootstepDust = preload("res://scenes/effects/particles/footstep_dust.tscn").instantiate()
	scene_tree.current_scene.add_child(particles)
	particles.global_position = spawn_position
	return particles
