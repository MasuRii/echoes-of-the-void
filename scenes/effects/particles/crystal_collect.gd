class_name CrystalCollectParticles
extends GPUParticles2D

## Grand particle celebration effect for Echo Crystal collection.
## A spectacular burst of bright cyan and white particles with extended duration
## to celebrate the major collectible pickup.

const LIFETIME: float = 1.0


func _ready() -> void:
	# Configure as one-shot effect
	one_shot = true
	emitting = true
	
	# Self-destruct after particles finish
	await get_tree().create_timer(LIFETIME + 0.3).timeout
	queue_free()


## Spawns crystal collect celebration particles at the specified position.
## Call this as a static-like factory method.
static func spawn_at(scene_tree: SceneTree, spawn_position: Vector2) -> CrystalCollectParticles:
	var particles: CrystalCollectParticles = preload("res://scenes/effects/particles/crystal_collect.tscn").instantiate()
	scene_tree.current_scene.add_child(particles)
	particles.global_position = spawn_position
	return particles
