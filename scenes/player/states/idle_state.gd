class_name IdleState
extends "res://scripts/classes/state.gd"

## Player idle state - standing still on ground.
## Transitions to: Run (movement input), Jump (jump input), Fall (no floor)


func enter() -> void:
	# Reset velocity when entering idle
	actor.velocity.x = 0.0
	# Reset sprite rotation in case coming from double jump spin
	actor.sprite.rotation = 0.0
	# Play idle breathing animation
	actor.animation_player.play("idle")


func physics_update(_delta: float) -> void:
	# Apply gravity (in case we're somehow not on floor)
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
	if input_dir != 0:
		state_machine.transition_to("run")
		return
