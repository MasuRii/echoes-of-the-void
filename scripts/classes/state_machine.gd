class_name StateMachine
extends Node

## Finite State Machine controller for Echoes of the Void.
## Manages state transitions and delegates update calls to the current state.

## Preload the State class to ensure it's available.
const StateClass = preload("res://scripts/classes/state.gd")

## Path to the initial state to start in when the scene is ready.
@export var initial_state: NodePath

## Path to the actor (CharacterBody2D) that this state machine controls.
@export var actor: NodePath

## The currently active state.
var current_state: Node

## Reference to the resolved actor node.
var _actor: CharacterBody2D

## Dictionary mapping state names (lowercase) to State nodes.
var states: Dictionary = {}


func _ready() -> void:
	# Resolve actor path
	if actor:
		_actor = get_node_or_null(actor)
	
	if _actor == null:
		push_error("StateMachine: Could not resolve actor path '%s'" % actor)
		return
	
	# Populate the states dictionary with all State children
	for child in get_children():
		if child is StateClass:
			states[child.name.to_lower()] = child
			child.state_machine = self
			child.actor = _actor
	
	# Defer initial state entry to ensure actor's @onready vars are initialized
	# This is necessary because child _ready() runs before parent's @onready
	call_deferred("_enter_initial_state")


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


## Called deferred to enter the initial state after actor's @onready vars are ready.
func _enter_initial_state() -> void:
	# Resolve and start with the initial state
	var start_state: Node = null
	if initial_state:
		start_state = get_node_or_null(initial_state)
	
	# Fallback: if initial_state path didn't resolve, try to find "Idle" state
	if start_state == null and states.has("idle"):
		start_state = states["idle"]
	
	if start_state:
		current_state = start_state
		current_state.enter()
	else:
		push_error("StateMachine: No initial_state found!")
