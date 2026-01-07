class_name JumpDust
extends GPUParticles2D

## Burst dust particles when player jumps.
## Particles disperse upward and outward from feet on takeoff.

const LIFETIME: float = 0.4


func _ready() -> void:
	# Configure as one-shot effect
	one_shot = true
	emitting = true
	
	# Self-destruct after particles finish
	await get_tree().create_timer(LIFETIME + 0.1).timeout
	queue_free()


## Spawns jump dust at the specified position.
## Call this as a static-like factory method.
static func spawn_at(scene_tree: SceneTree, spawn_position: Vector2) -> JumpDust:
	var particles: JumpDust = preload("res://scenes/effects/particles/jump_dust.tscn").instantiate()
	scene_tree.current_scene.add_child(particles)
	particles.global_position = spawn_position
	return particles
