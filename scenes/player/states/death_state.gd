class_name DeathState
extends "res://scripts/classes/state.gd"

## Player death state - handles death animation and respawn.
## Transitions to: Idle (after respawn complete)

# Preload particle scenes
const DEATH_PARTICLES_SCENE: PackedScene = preload("res://scenes/effects/particles/death_particles.tscn")
const RESPAWN_PARTICLES_SCENE: PackedScene = preload("res://scenes/effects/particles/respawn_particles.tscn")

# Duration before respawn occurs
const RESPAWN_DELAY: float = 0.5

# Internal timer for respawn
var _respawn_timer: float = 0.0
var _has_respawned: bool = false


func enter() -> void:
	# Stop all movement
	actor.velocity = Vector2.ZERO
	
	# Disable collision during death
	actor.set_collision_layer_value(1, false)
	actor.set_collision_mask_value(1, false)
	
	# Emit death signal
	Events.player_died.emit()
	
	# Reset respawn timer
	_respawn_timer = RESPAWN_DELAY
	_has_respawned = false
	
	# TODO: Play death animation when available
	# actor.animation_player.play("death")
	
	# Play death particles (white dispersion burst)
	_spawn_death_particles()
	
	# Make player semi-transparent during death
	actor.modulate.a = 0.5


func exit() -> void:
	# Re-enable collision
	actor.set_collision_layer_value(1, true)
	actor.set_collision_mask_value(1, true)
	
	# Restore full opacity
	actor.modulate.a = 1.0


func physics_update(delta: float) -> void:
	if _has_respawned:
		return
	
	# Count down respawn timer
	_respawn_timer -= delta
	
	if _respawn_timer <= 0.0:
		_perform_respawn()


func _perform_respawn() -> void:
	_has_respawned = true
	
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
