class_name LandDust
extends GPUParticles2D

## Impact dust particles when player lands on ground.
## Particles burst outward and upward from feet on landing impact.

const LIFETIME: float = 0.5


func _ready() -> void:
	# Configure as one-shot effect
	one_shot = true
	emitting = true
	
	# Self-destruct after particles finish
	await get_tree().create_timer(LIFETIME + 0.1).timeout
	queue_free()


## Spawns land dust at the specified position.
## Call this as a static-like factory method.
static func spawn_at(scene_tree: SceneTree, spawn_position: Vector2) -> LandDust:
	var particles: LandDust = preload("res://scenes/effects/particles/land_dust.tscn").instantiate()
	scene_tree.current_scene.add_child(particles)
	particles.global_position = spawn_position
	return particles
