class_name WallSlideState
extends "res://scripts/classes/state.gd"

## Player wall slide state - sliding down a wall.
## Transitions to: Jump (wall jump on jump input), Fall (no wall contact or input away)

# Reference to active wall slide particles
var _wall_slide_particles: GPUParticles2D = null


func enter() -> void:
	# Set wall sliding flag
	actor.is_wall_sliding = true
	# Play wall slide animation
	actor.animation_player.play("wall_slide")
	# Adjust sprite rotation based on wall direction (lean into the wall)
	var wall_dir: int = actor.get_wall_direction()
	# Flip the rotation direction based on which wall we're sliding on
	# Positive rotation leans right (for left wall), negative leans left (for right wall)
	actor.get_node("Sprite2D").rotation = 0.1 * wall_dir
	# Spawn wall slide particles (sparks fly away from wall)
	_spawn_wall_slide_particles(wall_dir)


func exit() -> void:
	actor.is_wall_sliding = false
	# Reset sprite rotation when exiting wall slide
	actor.get_node("Sprite2D").rotation = 0.0
	# Stop and cleanup wall slide particles
	_cleanup_wall_slide_particles()


func physics_update(_delta: float) -> void:
	# Check for jump input (wall jump)
	if Input.is_action_just_pressed("jump"):
		actor.wall_jump()
		state_machine.transition_to("jump")
		return
	
	# Check if we've landed
	if actor.is_on_floor():
		var input_dir: float = Input.get_axis("move_left", "move_right")
		if input_dir != 0:
			state_machine.transition_to("run")
		else:
			state_machine.transition_to("idle")
		return
	
	# Check if still touching wall
	if not actor.is_touching_wall():
		state_machine.transition_to("fall")
		return
	
	# Check if still pressing toward the wall
	var input_dir: float = Input.get_axis("move_left", "move_right")
	var wall_dir: int = actor.get_wall_direction()
	var pressing_toward_wall: bool = false
	
	if (wall_dir == -1 and input_dir < 0) or (wall_dir == 1 and input_dir > 0):
		pressing_toward_wall = true
	
	# Exit wall slide if not pressing toward wall
	if not pressing_toward_wall:
		state_machine.transition_to("fall")
		return
	
	# Update particle position to follow player while sliding
	if _wall_slide_particles and is_instance_valid(_wall_slide_particles):
		_wall_slide_particles.global_position = actor.global_position


## Spawns wall slide sparks at the player's position.
## wall_dir: -1 = wall on left, 1 = wall on right
func _spawn_wall_slide_particles(wall_dir: int) -> void:
	# Sparks fly away from the wall, so direction is opposite of wall_dir
	var spark_direction: int = -wall_dir
	_wall_slide_particles = WallSlideSparks.spawn_at(
		actor.get_tree(),
		actor.global_position,
		spark_direction
	)


## Stops and cleans up wall slide particles.
func _cleanup_wall_slide_particles() -> void:
	if _wall_slide_particles and is_instance_valid(_wall_slide_particles):
		_wall_slide_particles.stop_and_cleanup()
		_wall_slide_particles = null
