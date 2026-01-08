class_name LevelVisualizer
extends Node2D

## Debug visualization tool for level elements.
## Shows platform bounds, collectible positions, enemy patrol paths, and checkpoint coverage.
## Toggle visibility with F3 key in debug builds.
##
## Usage: Add as child of any level scene, or instantiate via code.
## Automatically finds and visualizes all level elements.

# Visual constants - Platforms
const PLATFORM_SOLID_COLOR: Color = Color(1.0, 1.0, 1.0, 0.2)  # White for solid platforms
const PLATFORM_SOLID_BORDER: Color = Color(1.0, 1.0, 1.0, 0.6)  # White border
const PLATFORM_ONEWAY_COLOR: Color = Color(0.0, 1.0, 1.0, 0.2)  # Cyan for one-way
const PLATFORM_ONEWAY_BORDER: Color = Color(0.0, 1.0, 1.0, 0.6)  # Cyan border
const WALL_COLOR: Color = Color(0.7, 0.7, 1.0, 0.2)  # Light blue for walls
const WALL_BORDER: Color = Color(0.7, 0.7, 1.0, 0.6)  # Light blue border

# Visual constants - Collectibles
const SHARD_COLOR: Color = Color(1.0, 1.0, 0.0, 0.8)  # Yellow for shards
const SHARD_RADIUS: float = 10.0
const CRYSTAL_COLOR: Color = Color(0.0, 1.0, 1.0, 0.8)  # Cyan for crystals
const CRYSTAL_RADIUS: float = 16.0
const COLLECTED_ALPHA: float = 0.3  # Dimmer for collected items

# Visual constants - Enemies
const ENEMY_COLOR: Color = Color(1.0, 0.0, 0.5, 0.7)  # Magenta for enemies
const ENEMY_RADIUS: float = 12.0
const PATROL_PATH_COLOR: Color = Color(1.0, 0.0, 0.5, 0.4)  # Patrol path line
const PATROL_PATH_WIDTH: float = 2.0
const DETECTION_AREA_COLOR: Color = Color(1.0, 0.5, 0.0, 0.15)  # Orange for detection

# Visual constants - Checkpoints
const CHECKPOINT_INACTIVE_COLOR: Color = Color(0.5, 0.5, 0.5, 0.5)  # Gray
const CHECKPOINT_ACTIVE_COLOR: Color = Color(0.0, 1.0, 0.0, 0.7)  # Green
const CHECKPOINT_RADIUS: float = 20.0
const RESPAWN_ZONE_COLOR: Color = Color(0.0, 1.0, 0.0, 0.1)  # Green zone

# Visual constants - Hazards
const HAZARD_COLOR: Color = Color(1.0, 0.0, 0.0, 0.5)  # Red for hazards
const HAZARD_BORDER: Color = Color(1.0, 0.0, 0.0, 0.8)  # Red border

# Visual constants - Level bounds
const EXIT_COLOR: Color = Color(0.0, 1.0, 0.0, 0.5)  # Green for exit
const EXIT_BORDER: Color = Color(0.0, 1.0, 0.0, 0.8)  # Green border
const CAMERA_LIMIT_COLOR: Color = Color(1.0, 1.0, 0.0, 0.3)  # Yellow for camera bounds

const LINE_WIDTH: float = 2.0

# Debug state
var _debug_visible: bool = false
var _level_base: Node = null

# Cached level elements
var _generated_geometry: Node2D = null
var _collectibles: Node2D = null
var _enemies: Node2D = null
var _checkpoints: Node2D = null
var _hazards: Node2D = null
var _platforms_node: Node2D = null
var _level_exit: Area2D = null

# Display toggles (can be cycled with number keys while visualizer is active)
var _show_platforms: bool = true
var _show_collectibles: bool = true
var _show_enemies: bool = true
var _show_checkpoints: bool = true
var _show_hazards: bool = true
var _show_camera_bounds: bool = true


func _ready() -> void:
	# Start hidden in release builds
	_debug_visible = OS.is_debug_build()
	visible = _debug_visible
	
	# Find level elements after a short delay to ensure scene is ready
	await get_tree().process_frame
	_find_level_elements()
	
	# Force redraw
	queue_redraw()


func _process(_delta: float) -> void:
	if not _debug_visible:
		return
	
	# Continuously update for any dynamic changes (enemies moving, etc.)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	# Toggle debug visualization with F3
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		if event.shift_pressed:
			# Shift+F3: Cycle through display modes
			_cycle_display_modes()
		else:
			# F3: Toggle all visualization
			_toggle_debug_visibility()
		get_viewport().set_input_as_handled()


func _toggle_debug_visibility() -> void:
	_debug_visible = not _debug_visible
	visible = _debug_visible
	
	if _debug_visible:
		# Refresh data when becoming visible
		_find_level_elements()
		queue_redraw()
		print("LevelVisualizer: Debug visualization ENABLED (F3 toggle, Shift+F3 cycle modes)")
	else:
		print("LevelVisualizer: Debug visualization DISABLED")


func _cycle_display_modes() -> void:
	"""Cycle through different visualization modes."""
	# Simple cycle: All -> Platforms only -> Collectibles only -> Enemies only -> etc.
	# For now, just toggle each category with repeated Shift+F3
	if _show_platforms and _show_collectibles and _show_enemies and _show_checkpoints and _show_hazards:
		# Show only platforms
		_show_platforms = true
		_show_collectibles = false
		_show_enemies = false
		_show_checkpoints = false
		_show_hazards = false
		print("LevelVisualizer: Showing PLATFORMS only")
	elif _show_platforms and not _show_collectibles:
		# Show only collectibles
		_show_platforms = false
		_show_collectibles = true
		_show_enemies = false
		_show_checkpoints = false
		_show_hazards = false
		print("LevelVisualizer: Showing COLLECTIBLES only")
	elif _show_collectibles and not _show_enemies:
		# Show only enemies
		_show_platforms = false
		_show_collectibles = false
		_show_enemies = true
		_show_checkpoints = false
		_show_hazards = false
		print("LevelVisualizer: Showing ENEMIES only")
	elif _show_enemies and not _show_checkpoints:
		# Show only checkpoints
		_show_platforms = false
		_show_collectibles = false
		_show_enemies = false
		_show_checkpoints = true
		_show_hazards = false
		print("LevelVisualizer: Showing CHECKPOINTS only")
	elif _show_checkpoints and not _show_hazards:
		# Show only hazards
		_show_platforms = false
		_show_collectibles = false
		_show_enemies = false
		_show_checkpoints = false
		_show_hazards = true
		print("LevelVisualizer: Showing HAZARDS only")
	else:
		# Reset to show all
		_show_platforms = true
		_show_collectibles = true
		_show_enemies = true
		_show_checkpoints = true
		_show_hazards = true
		print("LevelVisualizer: Showing ALL elements")
	
	queue_redraw()


func _find_level_elements() -> void:
	"""Find all level elements for visualization."""
	# Find parent level base
	_level_base = _find_parent_level_base()
	
	if _level_base == null:
		push_warning("LevelVisualizer: Could not find LevelBase parent")
		return
	
	# Find all level element containers
	_generated_geometry = _level_base.get_node_or_null("GeneratedGeometry")
	_collectibles = _level_base.get_node_or_null("Collectibles")
	_enemies = _level_base.get_node_or_null("Enemies")
	_checkpoints = _level_base.get_node_or_null("Checkpoints")
	_hazards = _level_base.get_node_or_null("Hazards")
	_platforms_node = _level_base.get_node_or_null("Platforms")
	_level_exit = _level_base.get_node_or_null("LevelExit")


func _find_parent_level_base() -> Node:
	"""Walk up the tree to find a LevelBase node."""
	var current: Node = get_parent()
	while current != null:
		if current is LevelBase:
			return current
		# Also check by class name string for flexibility
		if current.get_script() and current.get_script().get_global_name() == "LevelBase":
			return current
		current = current.get_parent()
	
	# Fallback: look for common level structure
	var root := get_tree().current_scene
	if root and root.has_node("PlayerSpawn"):
		return root
	
	return null


func _draw() -> void:
	if not _debug_visible:
		return
	
	# Draw in order: camera bounds (background) -> platforms -> hazards -> collectibles -> enemies -> checkpoints
	if _show_camera_bounds:
		_draw_camera_bounds()
	
	if _show_platforms:
		_draw_platforms()
	
	if _show_hazards:
		_draw_hazards()
	
	if _show_collectibles:
		_draw_collectibles()
	
	if _show_enemies:
		_draw_enemies()
	
	if _show_checkpoints:
		_draw_checkpoints()
	
	# Draw level exit
	_draw_level_exit()
	
	# Draw legend
	_draw_legend()


func _draw_platforms() -> void:
	"""Draw outlines of all platforms (generated and static)."""
	# Draw generated geometry
	if _generated_geometry:
		for child in _generated_geometry.get_children():
			if not child is StaticBody2D:
				continue
			
			_draw_platform_node(child)
	
	# Draw static platforms from Platforms node
	if _platforms_node:
		for child in _platforms_node.get_children():
			if child is StaticBody2D or child is AnimatableBody2D:
				_draw_platform_node(child)


func _draw_platform_node(platform: Node2D) -> void:
	"""Draw a single platform node."""
	# Try to find the visual bounds
	var visual: Control = platform.get_node_or_null("Visual")
	var collision: CollisionShape2D = platform.get_node_or_null("CollisionShape2D")
	
	var platform_pos := to_local(platform.global_position)
	var platform_size: Vector2
	var color: Color = PLATFORM_SOLID_COLOR
	var border: Color = PLATFORM_SOLID_BORDER
	
	# Determine platform type and size
	if visual != null:
		platform_size = visual.size
	elif collision != null and collision.shape is RectangleShape2D:
		platform_size = (collision.shape as RectangleShape2D).size
		platform_pos -= platform_size / 2  # Collision shapes are centered
	else:
		# Fallback size
		platform_size = Vector2(64, 32)
	
	# Check if one-way platform
	if collision and collision.one_way_collision:
		color = PLATFORM_ONEWAY_COLOR
		border = PLATFORM_ONEWAY_BORDER
	
	# Check if it's a wall (height > width significantly)
	if platform_size.y > platform_size.x * 2:
		color = WALL_COLOR
		border = WALL_BORDER
	
	# Draw rectangle
	var rect := Rect2(platform_pos, platform_size)
	draw_rect(rect, color, true)
	draw_rect(rect, border, false, LINE_WIDTH)


func _draw_collectibles() -> void:
	"""Draw all collectibles with status indicators."""
	if _collectibles == null:
		return
	
	for child in _collectibles.get_children():
		var local_pos := to_local(child.global_position)
		
		# Determine collectible type
		if child.is_in_group("light_shards") or "shard" in child.name.to_lower():
			# Light Shard
			var color := SHARD_COLOR
			if not child.visible:
				color.a *= COLLECTED_ALPHA  # Dimmer if collected
			
			_draw_diamond(local_pos, SHARD_RADIUS, color)
			draw_string(ThemeDB.fallback_font, local_pos + Vector2(-3, 4), "S", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color.WHITE)
			
		elif child.is_in_group("echo_crystals") or "crystal" in child.name.to_lower():
			# Echo Crystal
			var color := CRYSTAL_COLOR
			if not child.visible:
				color.a *= COLLECTED_ALPHA  # Dimmer if collected
			
			_draw_hexagon(local_pos, CRYSTAL_RADIUS, color)
			draw_string(ThemeDB.fallback_font, local_pos + Vector2(-4, 5), "C", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)
			
			# Draw crystal ID if available
			if "crystal_id" in child:
				var id_text: String = child.crystal_id.get_slice("_", -1) if "_" in child.crystal_id else child.crystal_id
				draw_string(ThemeDB.fallback_font, local_pos + Vector2(CRYSTAL_RADIUS + 4, 4), id_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, CRYSTAL_COLOR)


func _draw_enemies() -> void:
	"""Draw all enemies with patrol paths and detection areas."""
	if _enemies == null:
		return
	
	for child in _enemies.get_children():
		var local_pos := to_local(child.global_position)
		
		# Draw enemy marker
		draw_circle(local_pos, ENEMY_RADIUS, ENEMY_COLOR)
		draw_arc(local_pos, ENEMY_RADIUS, 0, TAU, 24, Color.WHITE, LINE_WIDTH)
		
		# Determine enemy type and draw specifics
		var enemy_type := "?"
		if "crawler" in child.name.to_lower() or child.is_in_group("shadow_crawlers"):
			enemy_type = "SC"
			_draw_patrol_path(child, local_pos)
		elif "mirror" in child.name.to_lower() or child.is_in_group("mirror_guards"):
			enemy_type = "MG"
			_draw_detection_area(child, local_pos)
		elif "pulse" in child.name.to_lower() or "orb" in child.name.to_lower() or child.is_in_group("pulse_orbs"):
			enemy_type = "PO"
			_draw_sine_wave_path(child, local_pos)
		
		# Draw enemy type label
		draw_string(ThemeDB.fallback_font, local_pos + Vector2(-6, 4), enemy_type, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color.WHITE)


func _draw_patrol_path(enemy: Node, local_pos: Vector2) -> void:
	"""Draw patrol path for Shadow Crawler type enemies."""
	# Check for patrol-related properties
	var patrol_distance := 100.0  # Default patrol distance
	
	if "patrol_distance" in enemy:
		patrol_distance = enemy.patrol_distance
	elif enemy.has_method("get_patrol_distance"):
		patrol_distance = enemy.get_patrol_distance()
	
	# Draw patrol line
	var patrol_left := local_pos + Vector2(-patrol_distance / 2, 0)
	var patrol_right := local_pos + Vector2(patrol_distance / 2, 0)
	
	draw_dashed_line(patrol_left, patrol_right, PATROL_PATH_COLOR, PATROL_PATH_WIDTH, 8.0)
	
	# Draw end markers
	draw_line(patrol_left + Vector2(0, -10), patrol_left + Vector2(0, 10), PATROL_PATH_COLOR, PATROL_PATH_WIDTH)
	draw_line(patrol_right + Vector2(0, -10), patrol_right + Vector2(0, 10), PATROL_PATH_COLOR, PATROL_PATH_WIDTH)


func _draw_detection_area(enemy: Node, local_pos: Vector2) -> void:
	"""Draw detection area for Mirror Guard type enemies."""
	# Look for detection area child
	var detection_area: Area2D = enemy.get_node_or_null("DetectionArea")
	var detection_radius := 200.0  # Default
	
	if detection_area:
		var collision: CollisionShape2D = detection_area.get_node_or_null("CollisionShape2D")
		if collision and collision.shape is CircleShape2D:
			detection_radius = (collision.shape as CircleShape2D).radius
	
	# Draw detection circle
	draw_circle(local_pos, detection_radius, DETECTION_AREA_COLOR)
	draw_arc(local_pos, detection_radius, 0, TAU, 32, Color(1.0, 0.5, 0.0, 0.4), 1.0)


func _draw_sine_wave_path(enemy: Node, local_pos: Vector2) -> void:
	"""Draw sine wave movement path for Pulse Orb enemies."""
	var amplitude := 100.0
	var frequency := 2.0
	var vertical_mode := false
	var wave_length := 200.0  # How much path to show
	
	# Try to get actual values from enemy
	if "amplitude" in enemy:
		amplitude = enemy.amplitude
	if "frequency" in enemy:
		frequency = enemy.frequency
	if "vertical_mode" in enemy:
		vertical_mode = enemy.vertical_mode
	
	# Draw sine wave path
	var points: PackedVector2Array = []
	var steps := 30
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var x := (t - 0.5) * wave_length
		var y := sin(t * frequency * TAU) * amplitude
		
		if vertical_mode:
			points.append(local_pos + Vector2(y, x))
		else:
			points.append(local_pos + Vector2(x, y))
	
	draw_polyline(points, PATROL_PATH_COLOR, PATROL_PATH_WIDTH)


func _draw_checkpoints() -> void:
	"""Draw checkpoint positions with respawn zones."""
	if _checkpoints == null:
		return
	
	for child in _checkpoints.get_children():
		if not child.is_in_group("checkpoints"):
			continue
		
		var local_pos := to_local(child.global_position)
		
		# Check if checkpoint is active
		var is_active := false
		if "activated" in child:
			is_active = child.activated
		elif child.has_method("is_activated"):
			is_active = child.is_activated()
		
		var color := CHECKPOINT_ACTIVE_COLOR if is_active else CHECKPOINT_INACTIVE_COLOR
		
		# Draw respawn zone (larger circle showing safe landing area)
		draw_circle(local_pos, CHECKPOINT_RADIUS * 2, RESPAWN_ZONE_COLOR)
		
		# Draw checkpoint marker
		draw_circle(local_pos, CHECKPOINT_RADIUS, color)
		draw_arc(local_pos, CHECKPOINT_RADIUS, 0, TAU, 24, Color.WHITE, LINE_WIDTH)
		
		# Draw label
		var label := "CP*" if is_active else "CP"
		draw_string(ThemeDB.fallback_font, local_pos + Vector2(-8, 5), label, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color.WHITE)
		
		# Draw spawn offset if present
		if "spawn_offset" in child:
			var spawn_pos: Vector2 = local_pos + child.spawn_offset
			draw_dashed_line(local_pos, spawn_pos, Color.YELLOW, 1.0, 4.0)
			draw_circle(spawn_pos, 4.0, Color.YELLOW)


func _draw_hazards() -> void:
	"""Draw hazard areas and danger zones."""
	if _hazards == null:
		return
	
	for child in _hazards.get_children():
		var local_pos := to_local(child.global_position)
		
		# Determine hazard type and draw appropriately
		if "spike" in child.name.to_lower() or child.is_in_group("spikes"):
			_draw_hazard_marker(child, local_pos, "!")
		elif "void" in child.name.to_lower() or "pit" in child.name.to_lower():
			_draw_hazard_zone(child, local_pos, "V")
		elif "laser" in child.name.to_lower() or child.is_in_group("lasers"):
			_draw_laser_hazard(child, local_pos)
		else:
			# Generic hazard
			_draw_hazard_marker(child, local_pos, "H")


func _draw_hazard_marker(hazard: Node, local_pos: Vector2, label: String) -> void:
	"""Draw a point hazard marker."""
	# Try to get collision bounds
	var collision: CollisionShape2D = hazard.get_node_or_null("CollisionShape2D")
	
	if collision and collision.shape is RectangleShape2D:
		var size: Vector2 = (collision.shape as RectangleShape2D).size
		var rect := Rect2(local_pos - size / 2, size)
		draw_rect(rect, HAZARD_COLOR, true)
		draw_rect(rect, HAZARD_BORDER, false, LINE_WIDTH)
	else:
		# Draw triangle for point hazard
		var triangle_points := PackedVector2Array([
			local_pos + Vector2(0, -12),
			local_pos + Vector2(10, 10),
			local_pos + Vector2(-10, 10)
		])
		draw_colored_polygon(triangle_points, HAZARD_COLOR)
		draw_polyline(triangle_points + PackedVector2Array([triangle_points[0]]), HAZARD_BORDER, LINE_WIDTH)
	
	draw_string(ThemeDB.fallback_font, local_pos + Vector2(-3, 5), label, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)


func _draw_hazard_zone(hazard: Node, local_pos: Vector2, label: String) -> void:
	"""Draw a zone hazard (like void pit)."""
	var area: Area2D = hazard if hazard is Area2D else hazard.get_node_or_null("Area2D")
	
	if area:
		var collision: CollisionShape2D = area.get_node_or_null("CollisionShape2D")
		if collision and collision.shape is RectangleShape2D:
			var size: Vector2 = (collision.shape as RectangleShape2D).size
			var rect := Rect2(local_pos - size / 2, size)
			draw_rect(rect, HAZARD_COLOR, true)
			draw_rect(rect, HAZARD_BORDER, false, LINE_WIDTH)
			draw_string(ThemeDB.fallback_font, local_pos + Vector2(-3, 5), label, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)
			return
	
	# Fallback to marker
	_draw_hazard_marker(hazard, local_pos, label)


func _draw_laser_hazard(hazard: Node, local_pos: Vector2) -> void:
	"""Draw a laser beam hazard with direction indicator."""
	# Try to determine laser direction and state
	var is_active := true
	if "is_active" in hazard:
		is_active = hazard.is_active
	elif hazard.has_method("is_active"):
		is_active = hazard.is_active()
	
	var color: Color = HAZARD_BORDER if is_active else Color(1.0, 0.0, 0.0, 0.3)
	
	# Try to find raycast direction
	var raycast: RayCast2D = hazard.get_node_or_null("RayCast2D")
	var end_pos := local_pos + Vector2(100, 0)  # Default horizontal
	
	if raycast:
		end_pos = to_local(raycast.global_position + raycast.target_position.rotated(raycast.global_rotation))
	
	draw_line(local_pos, end_pos, color, 3.0 if is_active else 1.0)
	draw_string(ThemeDB.fallback_font, local_pos + Vector2(-5, -8), "LB", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, color)


func _draw_level_exit() -> void:
	"""Draw the level exit area."""
	if _level_exit == null:
		return
	
	var local_pos := to_local(_level_exit.global_position)
	var collision: CollisionShape2D = _level_exit.get_node_or_null("CollisionShape2D")
	
	if collision and collision.shape is RectangleShape2D:
		var size: Vector2 = (collision.shape as RectangleShape2D).size
		var rect := Rect2(local_pos - size / 2, size)
		draw_rect(rect, EXIT_COLOR, true)
		draw_rect(rect, EXIT_BORDER, false, LINE_WIDTH)
	else:
		# Draw circle for exit
		draw_circle(local_pos, 24.0, EXIT_COLOR)
		draw_arc(local_pos, 24.0, 0, TAU, 24, EXIT_BORDER, LINE_WIDTH)
	
	draw_string(ThemeDB.fallback_font, local_pos + Vector2(-12, 5), "EXIT", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)


func _draw_camera_bounds() -> void:
	"""Draw camera limit bounds if available."""
	if _level_base == null:
		return
	
	if not ("use_camera_limits" in _level_base and _level_base.use_camera_limits):
		return
	
	var left: int = _level_base.camera_limit_left if "camera_limit_left" in _level_base else 0
	var right: int = _level_base.camera_limit_right if "camera_limit_right" in _level_base else 1920
	var top: int = _level_base.camera_limit_top if "camera_limit_top" in _level_base else 0
	var bottom: int = _level_base.camera_limit_bottom if "camera_limit_bottom" in _level_base else 1080
	
	var top_left := to_local(Vector2(left, top))
	var bottom_right := to_local(Vector2(right, bottom))
	
	var rect := Rect2(top_left, bottom_right - top_left)
	draw_rect(rect, CAMERA_LIMIT_COLOR, false, LINE_WIDTH)


func _draw_diamond(center: Vector2, radius: float, color: Color) -> void:
	"""Draw a diamond shape."""
	var points: PackedVector2Array = [
		center + Vector2(0, -radius),
		center + Vector2(radius, 0),
		center + Vector2(0, radius),
		center + Vector2(-radius, 0)
	]
	draw_colored_polygon(points, color)
	draw_polyline(points + PackedVector2Array([points[0]]), Color.WHITE, 1.0)


func _draw_hexagon(center: Vector2, radius: float, color: Color) -> void:
	"""Draw a hexagon shape."""
	var points: PackedVector2Array = []
	for i in range(6):
		var angle := float(i) * TAU / 6.0 - PI / 2.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, color)
	draw_polyline(points + PackedVector2Array([points[0]]), Color.WHITE, 1.0)


func _draw_legend() -> void:
	"""Draw a legend explaining the debug markers."""
	# Position legend in top-left, accounting for camera
	var camera := get_viewport().get_camera_2d()
	var legend_pos := Vector2(20, 20)
	
	if camera:
		legend_pos = camera.get_screen_center_position() - get_viewport_rect().size / 2 + Vector2(20, 20)
	
	legend_pos = to_local(legend_pos)
	
	# Calculate visible categories for legend height
	var visible_count := 0
	if _show_platforms:
		visible_count += 2
	if _show_collectibles:
		visible_count += 2
	if _show_enemies:
		visible_count += 1
	if _show_checkpoints:
		visible_count += 1
	if _show_hazards:
		visible_count += 1
	visible_count += 2  # Exit and header
	
	var legend_height := 24 + visible_count * 16
	
	# Background
	var bg_rect := Rect2(legend_pos - Vector2(5, 5), Vector2(190, legend_height))
	draw_rect(bg_rect, Color(0, 0, 0, 0.75))
	draw_rect(bg_rect, Color.WHITE, false, 1.0)
	
	# Title
	var y_offset := 0.0
	draw_string(ThemeDB.fallback_font, legend_pos + Vector2(0, 12), "LEVEL VISUALIZER (F3)", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
	y_offset += 18
	
	# Draw legend items based on what's visible
	if _show_platforms:
		# Solid platform
		draw_rect(Rect2(legend_pos + Vector2(0, y_offset + 2), Vector2(12, 10)), PLATFORM_SOLID_BORDER)
		draw_string(ThemeDB.fallback_font, legend_pos + Vector2(18, y_offset + 11), "Platform", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
		y_offset += 14
		
		# One-way platform
		draw_rect(Rect2(legend_pos + Vector2(0, y_offset + 2), Vector2(12, 10)), PLATFORM_ONEWAY_BORDER)
		draw_string(ThemeDB.fallback_font, legend_pos + Vector2(18, y_offset + 11), "One-Way", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
		y_offset += 14
	
	if _show_collectibles:
		# Shard
		_draw_diamond(legend_pos + Vector2(6, y_offset + 7), 5.0, SHARD_COLOR)
		draw_string(ThemeDB.fallback_font, legend_pos + Vector2(18, y_offset + 11), "Light Shard", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
		y_offset += 14
		
		# Crystal
		draw_circle(legend_pos + Vector2(6, y_offset + 7), 5.0, CRYSTAL_COLOR)
		draw_string(ThemeDB.fallback_font, legend_pos + Vector2(18, y_offset + 11), "Echo Crystal", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
		y_offset += 14
	
	if _show_enemies:
		# Enemy
		draw_circle(legend_pos + Vector2(6, y_offset + 7), 5.0, ENEMY_COLOR)
		draw_string(ThemeDB.fallback_font, legend_pos + Vector2(18, y_offset + 11), "Enemy", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
		y_offset += 14
	
	if _show_checkpoints:
		# Checkpoint
		draw_circle(legend_pos + Vector2(6, y_offset + 7), 5.0, CHECKPOINT_ACTIVE_COLOR)
		draw_string(ThemeDB.fallback_font, legend_pos + Vector2(18, y_offset + 11), "Checkpoint", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
		y_offset += 14
	
	if _show_hazards:
		# Hazard
		draw_circle(legend_pos + Vector2(6, y_offset + 7), 5.0, HAZARD_COLOR)
		draw_string(ThemeDB.fallback_font, legend_pos + Vector2(18, y_offset + 11), "Hazard", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
		y_offset += 14
	
	# Exit always shown
	draw_circle(legend_pos + Vector2(6, y_offset + 7), 5.0, EXIT_COLOR)
	draw_string(ThemeDB.fallback_font, legend_pos + Vector2(18, y_offset + 11), "Exit", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
	y_offset += 16
	
	# Mode hint
	draw_string(ThemeDB.fallback_font, legend_pos + Vector2(0, y_offset + 11), "[Shift+F3] Cycle modes", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.GRAY)


## Manually refresh debug data (call when level changes).
func refresh() -> void:
	_find_level_elements()
	queue_redraw()


## Get summary of level elements for external use.
func get_level_summary() -> Dictionary:
	_find_level_elements()
	
	var summary := {
		"platforms": 0,
		"shards": 0,
		"crystals": 0,
		"enemies": {
			"shadow_crawlers": 0,
			"mirror_guards": 0,
			"pulse_orbs": 0,
			"total": 0
		},
		"checkpoints": 0,
		"hazards": 0,
		"has_exit": _level_exit != null
	}
	
	# Count platforms
	if _generated_geometry:
		summary.platforms += _generated_geometry.get_child_count()
	if _platforms_node:
		summary.platforms += _platforms_node.get_child_count()
	
	# Count collectibles
	if _collectibles:
		for child in _collectibles.get_children():
			if child.is_in_group("light_shards") or "shard" in child.name.to_lower():
				summary.shards += 1
			elif child.is_in_group("echo_crystals") or "crystal" in child.name.to_lower():
				summary.crystals += 1
	
	# Count enemies
	if _enemies:
		for child in _enemies.get_children():
			summary.enemies.total += 1
			if "crawler" in child.name.to_lower() or child.is_in_group("shadow_crawlers"):
				summary.enemies.shadow_crawlers += 1
			elif "mirror" in child.name.to_lower() or child.is_in_group("mirror_guards"):
				summary.enemies.mirror_guards += 1
			elif "pulse" in child.name.to_lower() or "orb" in child.name.to_lower() or child.is_in_group("pulse_orbs"):
				summary.enemies.pulse_orbs += 1
	
	# Count checkpoints
	if _checkpoints:
		for child in _checkpoints.get_children():
			if child.is_in_group("checkpoints"):
				summary.checkpoints += 1
	
	# Count hazards
	if _hazards:
		summary.hazards = _hazards.get_child_count()
	
	return summary


## Print level summary to console.
func print_summary() -> void:
	var summary := get_level_summary()
	print("\n=== LEVEL SUMMARY ===")
	print("Platforms: %d" % summary.platforms)
	print("Collectibles: %d shards, %d crystals" % [summary.shards, summary.crystals])
	print("Enemies: %d total (SC: %d, MG: %d, PO: %d)" % [
		summary.enemies.total,
		summary.enemies.shadow_crawlers,
		summary.enemies.mirror_guards,
		summary.enemies.pulse_orbs
	])
	print("Checkpoints: %d" % summary.checkpoints)
	print("Hazards: %d" % summary.hazards)
	print("Has Exit: %s" % ("Yes" if summary.has_exit else "No"))
	print("=====================\n")
