class_name DeathState
extends "res://scripts/classes/state.gd"

## Player death state - handles death animation and respawn.
## Transitions to: Idle (after respawn complete)
## Uses a SceneTreeTimer for respawn to work correctly during hitstop.

# Preload particle scenes
const DEATH_PARTICLES_SCENE: PackedScene = preload("res://scenes/effects/particles/death_particles.tscn")
const RESPAWN_PARTICLES_SCENE: PackedScene = preload("res://scenes/effects/particles/respawn_particles.tscn")

# Duration before respawn occurs
const RESPAWN_DELAY: float = 0.5

# Internal state for respawn
var _has_respawned: bool = false
var _respawn_timer_started: bool = false


func enter() -> void:
	# CRITICAL: First ensure time_scale is normal in case we're entering death from a stuck state
	if Engine.time_scale != 1.0:
		Engine.time_scale = 1.0
	
	# Stop all movement
	actor.velocity = Vector2.ZERO
	
	# Disable collision during death
	actor.set_collision_layer_value(1, false)
	actor.set_collision_mask_value(1, false)
	
	# Emit death signal
	Events.player_died.emit()
	
	# Reset respawn state
	_has_respawned = false
	_respawn_timer_started = false
	
	# TODO: Play death animation when available
	# actor.animation_player.play("death")
	
	# Play death particles (white dispersion burst)
	_spawn_death_particles()
	
	# Make player semi-transparent during death
	actor.modulate.a = 0.5
	
	# Start respawn timer using SceneTreeTimer (ignores time_scale with process_always=true)
	# Parameters: time, process_always, process_in_physics, ignore_time_scale
	_start_respawn_timer()


func exit() -> void:
	# Re-enable collision
	actor.set_collision_layer_value(1, true)
	actor.set_collision_mask_value(1, true)
	
	# Restore full opacity
	actor.modulate.a = 1.0


func physics_update(_delta: float) -> void:
	# Respawn is now handled by the SceneTreeTimer, not delta-based countdown
	# This method is kept for potential future animation updates during death
	pass


func _start_respawn_timer() -> void:
	"""Start the respawn timer using a SceneTreeTimer that ignores time scale."""
	if _respawn_timer_started:
		return
	_respawn_timer_started = true
	
	# Use SceneTreeTimer with ignore_time_scale=true so it works during hitstop
	var tree := actor.get_tree()
	if tree == null:
		push_warning("DeathState: Tree is null, respawning immediately")
		_perform_respawn()
		return
	
	await tree.create_timer(RESPAWN_DELAY, true, false, true).timeout
	
	# Ensure time_scale is reset (safety fallback in case hitstop got stuck)
	if Engine.time_scale != 1.0:
		Engine.time_scale = 1.0
	
	# Only perform respawn if we haven't already (state might have been exited)
	if not _has_respawned:
		_perform_respawn()


func _perform_respawn() -> void:
	_has_respawned = true
	
	# Safety: ensure time_scale is normal before respawn
	if Engine.time_scale != 1.0:
		Engine.time_scale = 1.0
	
	# Call the player's respawn method
	actor.respawn()
	
	# Play respawn particles (coalesce effect) at new position
	_spawn_respawn_particles()
	
	# Transition back to idle state
	state_machine.transition_to("idle")


## Spawns death particles at the player's current position.
func _spawn_death_particles() -> void:
	var particles: GPUParticles2D = DEATH_PARTICLES_SCENE.instantiate()
	actor.get_tree().current_scene.add_child(particles)
	particles.global_position = actor.global_position


## Spawns respawn particles at the player's respawn position.
func _spawn_respawn_particles() -> void:
	var particles: GPUParticles2D = RESPAWN_PARTICLES_SCENE.instantiate()
	actor.get_tree().current_scene.add_child(particles)
	particles.global_position = actor.global_position
