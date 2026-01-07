class_name WallSlideState
extends "res://scripts/classes/state.gd"

## Player wall slide state - sliding down a wall.
## Transitions to: Jump (wall jump on jump input), Fall (no wall contact or input away)


func enter() -> void:
	# Set wall sliding flag
	actor.is_wall_sliding = true
	# TODO: Play wall slide animation when available
	# actor.animation_player.play("wall_slide")
	# TODO: Play wall slide particles


func exit() -> void:
	actor.is_wall_sliding = false


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
