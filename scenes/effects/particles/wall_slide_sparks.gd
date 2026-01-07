class_name WallSlideSparks
extends GPUParticles2D

## Friction spark effect when player is wall sliding.
## Emits small sparks that fly horizontally away from the wall.

const LIFETIME: float = 0.4

## Direction sparks should fly: 1 = right (wall on left), -1 = left (wall on right)
var spark_direction: int = 1


func _ready() -> void:
	# Configure as continuous emission while active
	one_shot = false
	emitting = true


## Call this to stop emitting and clean up after particles finish.
func stop_and_cleanup() -> void:
	emitting = false
	await get_tree().create_timer(LIFETIME + 0.1).timeout
	queue_free()


## Sets the direction sparks should fly (away from wall).
## direction: 1 = sparks fly right, -1 = sparks fly left
func set_spark_direction(direction: int) -> void:
	spark_direction = direction
	if process_material is ParticleProcessMaterial:
		var mat := process_material as ParticleProcessMaterial
		mat.direction = Vector3(direction, 0, 0)


## Spawns wall slide sparks at the specified position.
## Call this as a static-like factory method.
## direction: 1 = wall on left (sparks fly right), -1 = wall on right (sparks fly left)
static func spawn_at(scene_tree: SceneTree, spawn_position: Vector2, direction: int = 1) -> WallSlideSparks:
	var particles: WallSlideSparks = preload("res://scenes/effects/particles/wall_slide_sparks.tscn").instantiate()
	scene_tree.current_scene.add_child(particles)
	particles.global_position = spawn_position
	particles.set_spark_direction(direction)
	return particles
