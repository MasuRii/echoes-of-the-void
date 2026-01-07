class_name PlatformCrumble
extends GPUParticles2D

## Falling debris particles when platforms crumble.
## Particles fall downward like broken platform pieces.

const LIFETIME: float = 0.8


func _ready() -> void:
	# Configure as one-shot effect
	one_shot = true
	emitting = true
	
	# Self-destruct after particles finish
	await get_tree().create_timer(LIFETIME + 0.1).timeout
	queue_free()


## Spawns platform crumble debris at the specified position.
## Call this as a static-like factory method.
static func spawn_at(scene_tree: SceneTree, spawn_position: Vector2) -> PlatformCrumble:
	var particles: PlatformCrumble = preload("res://scenes/effects/particles/platform_crumble.tscn").instantiate()
	scene_tree.current_scene.add_child(particles)
	particles.global_position = spawn_position
	return particles
