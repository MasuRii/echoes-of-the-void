class_name StateMachine
extends Node

## Finite State Machine controller for Echoes of the Void.
## Manages state transitions and delegates update calls to the current state.

## Preload the State class to ensure it's available.
const StateClass = preload("res://scripts/classes/state.gd")

## The initial state to start in when the scene is ready.
@export var initial_state: Node

## Reference to the actor (CharacterBody2D) that this state machine controls.
@export var actor: CharacterBody2D

## The currently active state.
var current_state: Node

## Dictionary mapping state names (lowercase) to State nodes.
var states: Dictionary = {}


func _ready() -> void:
	# Populate the states dictionary with all State children
	for child in get_children():
		if child is StateClass:
			states[child.name.to_lower()] = child
			child.state_machine = self
			child.actor = actor
	
	# Start with the initial state if set
	if initial_state:
		current_state = initial_state
		current_state.enter()


func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)


## Transitions to a new state by name.
## @param state_name: The name of the state to transition to (case-insensitive).
func transition_to(state_name: String) -> void:
	var new_state: Node = states.get(state_name.to_lower())
	if not new_state:
		push_warning("StateMachine: State '%s' not found in states dictionary" % state_name)
		return
	
	if new_state == current_state:
		return
	
	if current_state:
		current_state.exit()
	
	current_state = new_state
	current_state.enter()
