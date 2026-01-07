class_name PlatformBase
extends StaticBody2D

## Base class for all platforms in Echoes of the Void.
## Provides common functionality: collision configuration, one-way support.
## Extend this class to create specific platform types.
## Note: For moving platforms, use AnimatableBody2D by extending MovingPlatformBase instead.

# Constants for collision layers (matching project.godot)
const COLLISION_LAYER_PLAYER: int = 1
const COLLISION_LAYER_ENEMY: int = 2
const COLLISION_LAYER_PLATFORM: int = 3
const COLLISION_LAYER_HAZARD: int = 4
const COLLISION_LAYER_COLLECTIBLE: int = 5

# Exported properties
@export_group("Platform Settings")
## If true, player can jump through from below and land on top.
@export var one_way: bool = false

@export_group("Collision")
## Enable collision with players.
@export var collide_with_player: bool = true
## Enable collision with enemies.
@export var collide_with_enemies: bool = true

# Internal state
var _is_active: bool = true


func _ready() -> void:
	_setup_collision_layers()
	_setup_one_way()
	_on_platform_ready()


## Configures collision layers and masks based on export settings.
func _setup_collision_layers() -> void:
	# Set this platform to be on the platform layer
	set_collision_layer_value(COLLISION_LAYER_PLATFORM, true)
	
	# Clear all mask layers first, then set based on settings
	collision_mask = 0
	
	if collide_with_player:
		set_collision_mask_value(COLLISION_LAYER_PLAYER, true)
	
	if collide_with_enemies:
		set_collision_mask_value(COLLISION_LAYER_ENEMY, true)


## Configures one-way collision if enabled.
func _setup_one_way() -> void:
	# Find and configure collision shape for one-way
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.one_way_collision = one_way
			child.one_way_collision_margin = 4.0


## Virtual method called after _ready() setup is complete.
## Override in subclasses for custom initialization.
func _on_platform_ready() -> void:
	pass


## Activates the platform (enables collision and visibility).
func activate() -> void:
	_is_active = true
	_set_collision_enabled(true)
	visible = true


## Deactivates the platform (disables collision and optionally hides).
func deactivate(hide_platform: bool = true) -> void:
	_is_active = false
	_set_collision_enabled(false)
	if hide_platform:
		visible = false


## Enables or disables all collision shapes.
func _set_collision_enabled(enabled: bool) -> void:
	for child in get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", not enabled)
		elif child is CollisionPolygon2D:
			child.set_deferred("disabled", not enabled)


## Returns whether the platform is currently active.
func is_active() -> bool:
	return _is_active


## Sets the one-way collision state at runtime.
func set_one_way(enabled: bool) -> void:
	one_way = enabled
	_setup_one_way()
