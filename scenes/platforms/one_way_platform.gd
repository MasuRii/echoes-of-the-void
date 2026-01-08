class_name OneWayPlatform
extends PlatformBase

## One-Way Platform for Echoes of the Void.
## Player can jump through from below and land on top.
## Visual: Semi-transparent appearance with dashed styling to indicate jump-through ability.
## Includes programmatic fallback visuals when no sprite texture exists.

# Signals
signal player_landed

# Visual constants
const COLOR_ONE_WAY := Color(0.7, 0.9, 1.0, 0.5)  # Cyan-tinted semi-transparent
const COLOR_DASH := Color(1.0, 1.0, 1.0, 0.8)  # Bright white for dashes
const DASH_WIDTH := 12.0
const DASH_GAP := 8.0
const PLATFORM_HEIGHT := 8.0

@export_group("Visual")
## Transparency level for the platform (0.0 = invisible, 1.0 = opaque).
@export_range(0.1, 1.0, 0.05) var transparency: float = 0.5
## Enable dashed/dotted line appearance to indicate one-way.
@export var use_dashed_style: bool = true

@export_group("Size")
## Platform width in pixels.
@export var platform_width: float = 64.0
## Platform height in pixels.
@export var platform_height: float = 8.0

# Internal references
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Container for programmatic visuals
var _visual_container: Control = null


func _on_platform_ready() -> void:
	# Force one-way collision for this platform type
	one_way = true
	_setup_one_way()
	
	# Add to group for easy identification
	add_to_group("one_way_platforms")
	
	# Setup visuals - use programmatic if sprite has no texture
	_setup_visual()


## Sets up the visual representation of the one-way platform.
func _setup_visual() -> void:
	# Check if sprite has a valid texture
	var has_sprite_texture: bool = sprite != null and sprite.texture != null
	
	if has_sprite_texture:
		# Use the existing sprite with styling
		_apply_sprite_style()
	else:
		# Hide the empty sprite if it exists
		if sprite:
			sprite.visible = false
		# Create programmatic visuals
		_create_programmatic_visual()


## Applies visual styling to the existing sprite.
func _apply_sprite_style() -> void:
	if sprite == null:
		return
	
	sprite.modulate.a = transparency
	
	# Apply cyan tint to differentiate from solid platforms
	if use_dashed_style:
		sprite.modulate.r = COLOR_ONE_WAY.r
		sprite.modulate.g = COLOR_ONE_WAY.g
		sprite.modulate.b = COLOR_ONE_WAY.b


## Creates programmatic visuals when no sprite texture exists.
func _create_programmatic_visual() -> void:
	# Determine platform size from collision shape or exports
	var size := Vector2(platform_width, platform_height)
	
	if collision_shape and collision_shape.shape is RectangleShape2D:
		size = collision_shape.shape.size
	
	# Create visual container
	_visual_container = Control.new()
	_visual_container.name = "ProgrammaticVisual"
	_visual_container.size = size
	# Position to center on collision (collision is centered, visual needs offset)
	_visual_container.position = -size / 2.0
	add_child(_visual_container)
	
	if use_dashed_style:
		_create_dashed_visual(size)
	else:
		_create_simple_visual(size)


## Creates a dashed line visual to indicate one-way platform.
func _create_dashed_visual(size: Vector2) -> void:
	# Background (semi-transparent fill)
	var background := ColorRect.new()
	background.name = "Background"
	background.size = size
	background.color = COLOR_ONE_WAY
	background.color.a = transparency * 0.5
	background.position = Vector2.ZERO
	_visual_container.add_child(background)
	
	# Create dashed top line
	var dash_x: float = 2.0  # Start with small margin
	var dash_index: int = 0
	
	while dash_x < size.x - 2.0:
		var dash_width: float = minf(DASH_WIDTH, size.x - dash_x - 2.0)
		if dash_width < 4.0:
			break
		
		var dash := ColorRect.new()
		dash.name = "Dash_%d" % dash_index
		dash.size = Vector2(dash_width, 2.0)
		dash.color = COLOR_DASH
		dash.position = Vector2(dash_x, 0.0)
		_visual_container.add_child(dash)
		
		dash_x += DASH_WIDTH + DASH_GAP
		dash_index += 1
	
	# Add subtle border at bottom to show it's thin
	var bottom_line := ColorRect.new()
	bottom_line.name = "BottomLine"
	bottom_line.size = Vector2(size.x, 1.0)
	bottom_line.color = Color(1.0, 1.0, 1.0, transparency * 0.3)
	bottom_line.position = Vector2(0, size.y - 1.0)
	_visual_container.add_child(bottom_line)


## Creates a simple semi-transparent visual.
func _create_simple_visual(size: Vector2) -> void:
	var rect := ColorRect.new()
	rect.name = "Fill"
	rect.size = size
	rect.color = COLOR_ONE_WAY
	rect.color.a = transparency
	rect.position = Vector2.ZERO
	_visual_container.add_child(rect)
	
	# Add top border
	var top_border := ColorRect.new()
	top_border.name = "TopBorder"
	top_border.size = Vector2(size.x, 2.0)
	top_border.color = Color(1.0, 1.0, 1.0, 0.8)
	top_border.position = Vector2.ZERO
	_visual_container.add_child(top_border)


## Called when a body lands on this platform (connect via signal if needed).
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Only emit if player is falling down onto the platform
		if body is CharacterBody2D and body.velocity.y >= 0:
			player_landed.emit()


## Updates visual transparency at runtime.
func set_transparency(value: float) -> void:
	transparency = clampf(value, 0.1, 1.0)
	_refresh_visual()


## Toggles dashed style at runtime.
func set_dashed_style(enabled: bool) -> void:
	use_dashed_style = enabled
	_refresh_visual()


## Refreshes the visual after property changes.
func _refresh_visual() -> void:
	# Remove existing programmatic visual
	if _visual_container:
		_visual_container.queue_free()
		_visual_container = null
	
	# Re-setup visuals
	_setup_visual()
