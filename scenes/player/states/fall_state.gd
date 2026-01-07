class_name FallState
extends "res://scripts/classes/state.gd"

## Player fall state - falling through the air.
## Transitions to: Idle/Run (on floor), WallSlide (touching wall + input toward wall), Jump (double jump)


func enter() -> void:
	# TODO: Play fall animation when available
	# actor.animation_player.play("fall")
	pass


func physics_update(_delta: float) -> void:
	# Check if we landed
	if actor.is_on_floor():
		# Check for buffered jump
		if actor.has_buffered_jump():
			actor.jump()
			state_machine.transition_to("jump")
			return
		
		# Transition to idle or run based on input
		var input_dir: float = Input.get_axis("move_left", "move_right")
		if input_dir != 0:
			state_machine.transition_to("run")
		else:
			state_machine.transition_to("idle")
		return
	
	# Check for wall slide
	if actor.is_touching_wall():
		var input_dir: float = Input.get_axis("move_left", "move_right")
		var wall_dir: int = actor.get_wall_direction()
		# Only wall slide if pressing toward the wall and falling
		if (wall_dir == -1 and input_dir < 0) or (wall_dir == 1 and input_dir > 0):
			if actor.velocity.y > 0:
				state_machine.transition_to("wall_slide")
				return
	
	# Check for jump input
	if Input.is_action_just_pressed("jump"):
		# Check for coyote time jump
		if actor.can_jump():
			actor.jump()
			state_machine.transition_to("jump")
			return
		# Check for double jump
		elif actor.can_double_jump:
			actor.double_jump()
			state_machine.transition_to("jump")
			return
		else:
			# Buffer the jump for landing
			actor.buffer_jump()
