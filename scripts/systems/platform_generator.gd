class_name PlatformGenerator
extends RefCounted

## Procedural platform generation system for Echoes of the Void.
## Creates platforms, walls, and one-way platforms programmatically.
## All geometry is code-generated, no manual Godot Editor work required.

# Collision layer constants (matching project.godot and platform_base.gd)
const COLLISION_LAYER_PLAYER: int = 1
const COLLISION_LAYER_ENEMY: int = 2
const COLLISION_LAYER_PLATFORM: int = 3
const COLLISION_LAYER_HAZARD: int = 4
const COLLISION_LAYER_COLLECTIBLE: int = 5

# Default visual colors
const COLOR_SOLID_PLATFORM := Color(0.8, 0.8, 0.8, 1.0)  # Light gray #CCCCCC
const COLOR_ONE_WAY_PLATFORM := Color(1.0, 1.0, 1.0, 0.5)  # Semi-transparent white
const COLOR_WALL := Color(0.667, 0.667, 0.667, 1.0)  # Slightly darker #AAAAAA
const COLOR_HAZARD_PLATFORM := Color(1.0, 0.4, 0.4, 1.0)  # Red tint #FF6666

# Default wall width
const WALL_WIDTH: float = 32.0

# Border/outline settings
const BORDER_ENABLED: bool = true
const BORDER_WIDTH: float = 2.0
const BORDER_COLOR := Color(1.0, 1.0, 1.0, 0.8)  # Bright white border


## Creates a bordered visual container with optional outline.
## Returns a Control node containing the fill and optional border.
static func _create_bordered_visual(
	size: Vector2,
	fill_color: Color,
	show_border: bool = BORDER_ENABLED
) -> Control:
	var container := Control.new()
	container.name = "Visual"
	container.custom_minimum_size = size
	container.size = size
	
	# Main fill
	var fill := ColorRect.new()
	fill.name = "Fill"
	fill.size = size
	fill.color = fill_color
	fill.position = Vector2.ZERO
	container.add_child(fill)
	
	# Border overlay (only if enabled and size allows)
	if show_border and size.x > BORDER_WIDTH * 4 and size.y > BORDER_WIDTH * 4:
		# Top border
		var top := ColorRect.new()
		top.name = "BorderTop"
		top.size = Vector2(size.x, BORDER_WIDTH)
		top.color = BORDER_COLOR
		top.position = Vector2.ZERO
		container.add_child(top)
		
		# Bottom border
		var bottom := ColorRect.new()
		bottom.name = "BorderBottom"
		bottom.size = Vector2(size.x, BORDER_WIDTH)
		bottom.color = BORDER_COLOR
		bottom.position = Vector2(0, size.y - BORDER_WIDTH)
		container.add_child(bottom)
		
		# Left border
		var left := ColorRect.new()
		left.name = "BorderLeft"
		left.size = Vector2(BORDER_WIDTH, size.y)
		left.color = BORDER_COLOR
		left.position = Vector2.ZERO
		container.add_child(left)
		
		# Right border
		var right := ColorRect.new()
		right.name = "BorderRight"
		right.size = Vector2(BORDER_WIDTH, size.y)
		right.color = BORDER_COLOR
		right.position = Vector2(size.x - BORDER_WIDTH, 0)
		container.add_child(right)
	
	return container


## Creates a solid platform with collision and visual.
## Returns the created StaticBody2D node.
static func create_platform(
	parent: Node,
	pos: Vector2,
	size: Vector2,
	color: Color = COLOR_SOLID_PLATFORM
) -> StaticBody2D:
	var platform := StaticBody2D.new()
	platform.name = "GeneratedPlatform_%d" % parent.get_child_count()
	platform.position = pos
	
	# Set collision layer to platform layer (layer 3)
	platform.collision_layer = 0
	platform.set_collision_layer_value(COLLISION_LAYER_PLATFORM, true)
	
	# Set collision mask to detect player and enemies
	platform.collision_mask = 0
	platform.set_collision_mask_value(COLLISION_LAYER_PLAYER, true)
	platform.set_collision_mask_value(COLLISION_LAYER_ENEMY, true)
	
	# Create collision shape
	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = size
	collision_shape.shape = rect_shape
	# Center the collision shape at the platform's position
	collision_shape.position = size / 2.0
	platform.add_child(collision_shape)
	
	# Create bordered visual
	var visual := _create_bordered_visual(size, color, BORDER_ENABLED)
	visual.position = Vector2.ZERO
	platform.add_child(visual)
	
	# Add to parent
	parent.add_child(platform)
	
	return platform


## Creates a vertical wall for wall-jumping.
## side parameter: "left" or "right" for proper positioning.
## Returns the created StaticBody2D node.
static func create_wall(
	parent: Node,
	pos: Vector2,
	height: float,
	side: String = "left"
) -> StaticBody2D:
	var wall := StaticBody2D.new()
	wall.name = "GeneratedWall_%s_%d" % [side, parent.get_child_count()]
	wall.position = pos
	
	# Set collision layer to platform layer (layer 3)
	wall.collision_layer = 0
	wall.set_collision_layer_value(COLLISION_LAYER_PLATFORM, true)
	
	# Set collision mask to detect player and enemies
	wall.collision_mask = 0
	wall.set_collision_mask_value(COLLISION_LAYER_PLAYER, true)
	wall.set_collision_mask_value(COLLISION_LAYER_ENEMY, true)
	
	# Calculate wall size
	var size := Vector2(WALL_WIDTH, height)
	
	# Create collision shape
	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = size
	collision_shape.shape = rect_shape
	# Position depends on side - left wall collision is at right edge, right wall at left edge
	if side == "right":
		collision_shape.position = Vector2(size.x / 2.0, size.y / 2.0)
	else:  # "left" default
		collision_shape.position = Vector2(size.x / 2.0, size.y / 2.0)
	wall.add_child(collision_shape)
	
	# Create bordered visual
	var visual := _create_bordered_visual(size, COLOR_WALL, BORDER_ENABLED)
	visual.position = Vector2.ZERO
	wall.add_child(visual)
	
	# Add to parent
	parent.add_child(wall)
	
	return wall


## Creates a one-way platform that player can jump through from below.
## Returns the created StaticBody2D node.
static func create_one_way_platform(
	parent: Node,
	pos: Vector2,
	width: float,
	thickness: float = 16.0
) -> StaticBody2D:
	var platform := StaticBody2D.new()
	platform.name = "GeneratedOneWay_%d" % parent.get_child_count()
	platform.position = pos
	
	# Set collision layer to platform layer (layer 3)
	platform.collision_layer = 0
	platform.set_collision_layer_value(COLLISION_LAYER_PLATFORM, true)
	
	# Set collision mask to detect player and enemies
	platform.collision_mask = 0
	platform.set_collision_mask_value(COLLISION_LAYER_PLAYER, true)
	platform.set_collision_mask_value(COLLISION_LAYER_ENEMY, true)
	
	var size := Vector2(width, thickness)
	
	# Create collision shape with one-way enabled
	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = size
	collision_shape.shape = rect_shape
	collision_shape.position = size / 2.0
	collision_shape.one_way_collision = true
	collision_shape.one_way_collision_margin = 4.0
	platform.add_child(collision_shape)
	
	# Create bordered visual (semi-transparent to indicate one-way)
	# Use dashed/lighter border for one-way platforms
	var visual := _create_bordered_visual(size, COLOR_ONE_WAY_PLATFORM, BORDER_ENABLED)
	visual.position = Vector2.ZERO
	platform.add_child(visual)
	
	# Add to parent
	parent.add_child(platform)
	
	return platform


## Creates a hazard-styled platform (visual only - no damage).
## Use in combination with hazard nodes for actual damage.
static func create_hazard_platform(
	parent: Node,
	pos: Vector2,
	size: Vector2
) -> StaticBody2D:
	return create_platform(parent, pos, size, COLOR_HAZARD_PLATFORM)


## Utility: Creates a simple ground platform spanning the level width.
## Useful as emergency fallback when no layout is defined.
static func create_emergency_ground(
	parent: Node,
	spawn_y: float,
	width: float = 2560.0,
	thickness: float = 64.0
) -> StaticBody2D:
	var pos := Vector2(0, spawn_y)
	var size := Vector2(width, thickness)
	var ground := create_platform(parent, pos, size, COLOR_SOLID_PLATFORM)
	ground.name = "EmergencyGround"
	return ground
