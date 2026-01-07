class_name RunState
extends "res://scripts/classes/state.gd"

## Player run state - moving horizontally on ground.
## Transitions to: Idle (no input + velocity near zero), Jump (jump input), Fall (no floor)


func enter() -> void:
	# TODO: Play run animation when available
	# actor.animation_player.play("run")
	pass


func physics_update(_delta: float) -> void:
	# Check if we left the ground
	if not actor.is_on_floor():
		state_machine.transition_to("fall")
		return
	
	# Check for buffered jump
	if actor.has_buffered_jump():
		actor.jump()
		state_machine.transition_to("jump")
		return
	
	# Check for jump input
	if Input.is_action_just_pressed("jump"):
		actor.jump()
		state_machine.transition_to("jump")
		return
	
	# Check for movement input
	var input_dir := Input.get_axis("move_left", "move_right")
	
	# Transition to idle if no input and velocity near zero
	if input_dir == 0 and absf(actor.velocity.x) < 10.0:
		state_machine.transition_to("idle")
		return
