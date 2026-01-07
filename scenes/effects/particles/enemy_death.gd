class_name EnemyDeathParticles
extends GPUParticles2D

## Shadow dispersion effect for enemy death.
## Dark particles scatter outward when an enemy is destroyed.

const LIFETIME: float = 0.6


func _ready() -> void:
	# Configure as one-shot effect
	one_shot = true
	emitting = true
	
	# Self-destruct after particles finish
	await get_tree().create_timer(LIFETIME + 0.2).timeout
	queue_free()


## Spawns enemy death particles at the specified position.
## Call this as a static-like factory method.
static func spawn_at(scene_tree: SceneTree, spawn_position: Vector2) -> EnemyDeathParticles:
	var particles: EnemyDeathParticles = preload("res://scenes/effects/particles/enemy_death.tscn").instantiate()
	scene_tree.current_scene.add_child(particles)
	particles.global_position = spawn_position
	return particles
