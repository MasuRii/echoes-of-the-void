class_name JumpState
extends "res://scripts/classes/state.gd"

## Player jump state - rising through the air after jumping.
## Transitions to: Fall (velocity.y >= 0), WallSlide (touching wall + input toward wall)


func enter() -> void:
	actor.animation_player.play("jump")


func physics_update(_delta: float) -> void:
	# Check for variable jump height (cut jump on early release)
	if Input.is_action_just_released("jump"):
		actor.cut_jump()
	
	# Check for wall slide
	if actor.is_touching_wall() and not actor.is_on_floor():
		var input_dir: float = Input.get_axis("move_left", "move_right")
		var wall_dir: int = actor.get_wall_direction()
		# Only wall slide if pressing toward the wall
		if (wall_dir == -1 and input_dir < 0) or (wall_dir == 1 and input_dir > 0):
			state_machine.transition_to("wall_slide")
			return
	
	# Transition to fall when no longer rising
	if actor.velocity.y >= 0:
		state_machine.transition_to("fall")
		return
	
	# Buffer jump input for when we land
	if Input.is_action_just_pressed("jump"):
		# Check for double jump
		if actor.can_double_jump:
			actor.double_jump()
			# Stay in jump state since we're rising again
			return
		else:
			# Buffer the jump for landing
			actor.buffer_jump()
