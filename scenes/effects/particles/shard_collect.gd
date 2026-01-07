class_name ShardCollectParticles
extends GPUParticles2D

## Sparkle burst effect for Light Shard collection.
## Cyan/white particles burst outward in a celebratory pattern.

const LIFETIME: float = 0.5


func _ready() -> void:
	# Configure as one-shot effect
	one_shot = true
	emitting = true
	
	# Self-destruct after particles finish
	await get_tree().create_timer(LIFETIME + 0.2).timeout
	queue_free()


## Spawns shard collect particles at the specified position.
## Call this as a static-like factory method.
static func spawn_at(scene_tree: SceneTree, spawn_position: Vector2) -> ShardCollectParticles:
	var particles: ShardCollectParticles = preload("res://scenes/effects/particles/shard_collect.tscn").instantiate()
	scene_tree.current_scene.add_child(particles)
	particles.global_position = spawn_position
	return particles
