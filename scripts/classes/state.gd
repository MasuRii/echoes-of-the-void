class_name State
extends Node

## Base class for all FSM states in Echoes of the Void.
## Override methods as needed for specific state behaviors.

## Reference to the parent state machine controller.
## Note: Typed as Node to avoid circular dependency; will be StateMachine at runtime.
var state_machine: Node

## Reference to the actor (typically CharacterBody2D) that owns this state.
var actor: CharacterBody2D


## Called when entering this state.
func enter() -> void:
	pass


## Called when exiting this state.
func exit() -> void:
	pass


## Called every frame (from _process).
func update(_delta: float) -> void:
	pass


## Called every physics frame (from _physics_process).
func physics_update(_delta: float) -> void:
	pass


## Called to handle input events (optional override).
func handle_input(_event: InputEvent) -> void:
	pass
