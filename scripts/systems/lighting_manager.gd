class_name LightingManager
extends RefCounted

## Lighting management system for Echoes of the Void.
## Creates player glow, ambient level lighting, and danger zone lighting.
## All lighting is code-generated, no manual Godot Editor work required.

# Default light colors
const COLOR_PLAYER_GLOW := Color(1.0, 1.0, 1.0, 1.0)  # White glow
const COLOR_AMBIENT := Color(0.5, 0.6, 0.7, 1.0)  # Subtle cool blue-white
const COLOR_DANGER := Color(1.0, 0.3, 0.2, 1.0)  # Red warning tint
const COLOR_CRYSTAL := Color(0.0, 1.0, 1.0, 1.0)  # Cyan for crystals
const COLOR_CHECKPOINT := Color(0.0, 0.8, 1.0, 1.0)  # Bright cyan for checkpoints
const COLOR_SHARD := Color(0.8, 1.0, 1.0, 1.0)  # Light cyan for shards

# Default light intensities
const PLAYER_GLOW_ENERGY: float = 0.3
const PLAYER_GLOW_SCALE: float = 1.5
const AMBIENT_ENERGY: float = 0.2
const DANGER_ENERGY: float = 0.5
const DANGER_RANGE: float = 128.0  # Detection range for hazards

# Canvas modulate darkness levels per level
const LEVEL_DARKNESS: Dictionary = {
	"LEVEL_01": Color(0.95, 0.95, 0.95, 1.0),  # Very light - tutorial
	"LEVEL_02": Color(0.90, 0.90, 0.92, 1.0),  # Slightly darker
	"LEVEL_03": Color(0.85, 0.85, 0.90, 1.0),  # Moderate
	"LEVEL_04": Color(0.75, 0.75, 0.82, 1.0),  # Darker
	"LEVEL_05": Color(0.70, 0.70, 0.78, 1.0),  # Darkest - finale
	"DEFAULT": Color(0.85, 0.85, 0.90, 1.0)
}


## Creates a PointLight2D for the player character with a subtle glow effect.
## Returns the created PointLight2D node.
static func create_player_glow(
	parent: Node,
	energy: float = PLAYER_GLOW_ENERGY,
	texture_scale: float = PLAYER_GLOW_SCALE
) -> PointLight2D:
	var light := PointLight2D.new()
	light.name = "PlayerGlow"
	
	# Create a simple radial gradient texture for the glow
	var gradient := GradientTexture2D.new()
	gradient.width = 128
	gradient.height = 128
	gradient.fill = GradientTexture2D.FILL_RADIAL
	gradient.fill_from = Vector2(0.5, 0.5)
	gradient.fill_to = Vector2(0.5, 0.0)
	
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 1.0, 1.0, 1.0))  # Center bright
	grad.set_color(1, Color(1.0, 1.0, 1.0, 0.0))  # Edge transparent
	gradient.gradient = grad
	
	light.texture = gradient
	light.texture_scale = texture_scale
	light.energy = energy
	light.color = COLOR_PLAYER_GLOW
	light.blend_mode = Light2D.BLEND_MODE_ADD
	
	parent.add_child(light)
	
	return light


## Checks if the player has a glow light and adds one if missing.
## Should be called after player is spawned in the level.
static func ensure_player_glow(player: CharacterBody2D) -> void:
	if player == null:
		return
	
	# Check if player already has a glow light
	var existing_glow := player.get_node_or_null("PlayerGlow")
	if existing_glow != null:
		return
	
	# Also check for any PointLight2D that could serve as glow
	for child in player.get_children():
		if child is PointLight2D:
			return
	
	# No glow found, create one
	create_player_glow(player)


## Creates ambient lighting for a level based on the level bounds.
## Places several subtle point lights across the level to provide base illumination.
## Returns an array of the created PointLight2D nodes.
static func create_ambient_lighting(
	parent: Node,
	level_bounds: Rect2,
	light_count: int = 4,
	energy: float = AMBIENT_ENERGY
) -> Array[PointLight2D]:
	var lights: Array[PointLight2D] = []
	
	# Container for ambient lights
	var container := Node2D.new()
	container.name = "AmbientLights"
	parent.add_child(container)
	
	# Calculate spacing for lights across the level
	var cols: int = maxi(2, ceili(sqrt(float(light_count))))
	var rows: int = maxi(1, light_count / cols)
	
	var spacing_x: float = level_bounds.size.x / float(cols + 1)
	var spacing_y: float = level_bounds.size.y / float(rows + 1)
	
	for row in range(rows):
		for col in range(cols):
			if lights.size() >= light_count:
				break
			
			var x: float = level_bounds.position.x + spacing_x * (col + 1)
			var y: float = level_bounds.position.y + spacing_y * (row + 1)
			
			var light := _create_ambient_point_light(energy)
			light.name = "AmbientLight_%d" % lights.size()
			light.position = Vector2(x, y)
			container.add_child(light)
			lights.append(light)
	
	return lights


## Creates a single ambient point light with soft falloff.
static func _create_ambient_point_light(energy: float) -> PointLight2D:
	var light := PointLight2D.new()
	
	# Create a large soft radial gradient
	var gradient := GradientTexture2D.new()
	gradient.width = 256
	gradient.height = 256
	gradient.fill = GradientTexture2D.FILL_RADIAL
	gradient.fill_from = Vector2(0.5, 0.5)
	gradient.fill_to = Vector2(0.5, 0.0)
	
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 1.0, 1.0, 0.8))
	grad.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	gradient.gradient = grad
	
	light.texture = gradient
	light.texture_scale = 3.0  # Large coverage
	light.energy = energy
	light.color = COLOR_AMBIENT
	light.blend_mode = Light2D.BLEND_MODE_ADD
	
	return light


## Creates danger zone lighting near hazard nodes.
## Scans for nodes in the "hazards" group and adds red warning lights.
## Returns an array of the created PointLight2D nodes.
static func create_danger_zone_lighting(
	level: Node,
	hazards_container: Node
) -> Array[PointLight2D]:
	var lights: Array[PointLight2D] = []
	
	if hazards_container == null:
		return lights
	
	# Container for danger lights
	var container := Node2D.new()
	container.name = "DangerLights"
	level.add_child(container)
	
	# Find all hazards and add danger lights
	var hazard_index: int = 0
	for hazard in hazards_container.get_children():
		# Skip if hazard already has a light
		var has_light := false
		for child in hazard.get_children():
			if child is PointLight2D:
				has_light = true
				break
		
		if has_light:
			continue
		
		# Create danger light at hazard position
		var light := _create_danger_point_light()
		light.name = "DangerLight_%d" % hazard_index
		light.position = hazard.position
		container.add_child(light)
		lights.append(light)
		hazard_index += 1
	
	return lights


## Creates a single danger zone point light with red warning tint.
static func _create_danger_point_light() -> PointLight2D:
	var light := PointLight2D.new()
	
	# Create a smaller, more intense radial gradient
	var gradient := GradientTexture2D.new()
	gradient.width = 128
	gradient.height = 128
	gradient.fill = GradientTexture2D.FILL_RADIAL
	gradient.fill_from = Vector2(0.5, 0.5)
	gradient.fill_to = Vector2(0.5, 0.0)
	
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 1.0, 1.0, 0.9))
	grad.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	gradient.gradient = grad
	
	light.texture = gradient
	light.texture_scale = 1.5
	light.energy = DANGER_ENERGY
	light.color = COLOR_DANGER
	light.blend_mode = Light2D.BLEND_MODE_ADD
	
	return light


## Creates a CanvasModulate node for overall level darkness adjustment.
## Later levels are darker to increase atmosphere.
static func create_canvas_modulate(
	parent: Node,
	level_key: String
) -> CanvasModulate:
	var modulate := CanvasModulate.new()
	modulate.name = "LevelModulate"
	
	# Get darkness level from the level key or use default
	var darkness_color: Color = LEVEL_DARKNESS.get(level_key, LEVEL_DARKNESS["DEFAULT"])
	modulate.color = darkness_color
	
	parent.add_child(modulate)
	
	return modulate


## Main setup function - initializes all level lighting.
## Call this from level_base.gd after geometry is generated.
## Returns a Dictionary with references to created lighting nodes.
static func setup_level_lighting(
	level: Node,
	player: CharacterBody2D,
	hazards_container: Node,
	level_key: String,
	level_bounds: Rect2
) -> Dictionary:
	var result := {
		"player_glow": null,
		"canvas_modulate": null,
		"ambient_lights": [],
		"danger_lights": []
	}
	
	# Add player glow if missing
	if player != null:
		ensure_player_glow(player)
		result["player_glow"] = player.get_node_or_null("PlayerGlow")
	
	# Create canvas modulate for level darkness
	result["canvas_modulate"] = create_canvas_modulate(level, level_key)
	
	# Create ambient lighting based on level bounds
	var ambient_count: int = 4
	if level_bounds.size.x > 3000:
		ambient_count = 6
	if level_bounds.size.x > 5000:
		ambient_count = 8
	result["ambient_lights"] = create_ambient_lighting(level, level_bounds, ambient_count)
	
	# Create danger zone lighting near hazards
	if hazards_container != null:
		result["danger_lights"] = create_danger_zone_lighting(level, hazards_container)
	
	print("LightingManager: Setup complete for '%s' - %d ambient lights, %d danger lights" % [
		level_key,
		result["ambient_lights"].size(),
		result["danger_lights"].size()
	])
	
	return result


## Utility: Creates a glow light for collectibles (crystals, shards).
## Can be attached to collectible nodes for visual enhancement.
static func create_collectible_glow(
	parent: Node,
	is_crystal: bool = false
) -> PointLight2D:
	var light := PointLight2D.new()
	light.name = "CollectibleGlow"
	
	var gradient := GradientTexture2D.new()
	gradient.width = 64
	gradient.height = 64
	gradient.fill = GradientTexture2D.FILL_RADIAL
	gradient.fill_from = Vector2(0.5, 0.5)
	gradient.fill_to = Vector2(0.5, 0.0)
	
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	grad.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	gradient.gradient = grad
	
	light.texture = gradient
	
	if is_crystal:
		light.texture_scale = 2.0
		light.energy = 0.6
		light.color = COLOR_CRYSTAL
	else:
		light.texture_scale = 1.0
		light.energy = 0.3
		light.color = COLOR_SHARD
	
	light.blend_mode = Light2D.BLEND_MODE_ADD
	
	parent.add_child(light)
	
	return light


## Utility: Creates a glow light for checkpoints.
static func create_checkpoint_glow(
	parent: Node,
	is_active: bool = false
) -> PointLight2D:
	var light := PointLight2D.new()
	light.name = "CheckpointGlow"
	
	var gradient := GradientTexture2D.new()
	gradient.width = 64
	gradient.height = 64
	gradient.fill = GradientTexture2D.FILL_RADIAL
	gradient.fill_from = Vector2(0.5, 0.5)
	gradient.fill_to = Vector2(0.5, 0.0)
	
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	grad.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	gradient.gradient = grad
	
	light.texture = gradient
	light.texture_scale = 1.5
	light.energy = 0.4 if is_active else 0.1
	light.color = COLOR_CHECKPOINT if is_active else Color(0.5, 0.5, 0.5, 1.0)
	light.blend_mode = Light2D.BLEND_MODE_ADD
	
	parent.add_child(light)
	
	return light
