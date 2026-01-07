class_name SpawnDebugger
extends Node2D

## Debug visualization tool for spawn points and checkpoints.
## Shows spawn/checkpoint positions, ground detection rays, and collision areas.
## Toggle visibility with F1 key in debug builds.
##
## Usage: Add as child of any level scene, or instantiate via code.
## Automatically finds PlayerSpawn, Checkpoints, and GeneratedGeometry.

# Visual constants
const SPAWN_COLOR: Color = Color(0.0, 1.0, 0.0, 0.8)  # Green for spawn point
const CHECKPOINT_INACTIVE_COLOR: Color = Color(0.5, 0.5, 0.5, 0.6)  # Gray for inactive
const CHECKPOINT_ACTIVE_COLOR: Color = Color(0.0, 1.0, 1.0, 0.8)  # Cyan for active
const GROUND_RAY_COLOR: Color = Color(1.0, 1.0, 0.0, 0.6)  # Yellow for ground rays
const GROUND_HIT_COLOR: Color = Color(0.0, 1.0, 0.0, 0.8)  # Green for ground hit
const GROUND_MISS_COLOR: Color = Color(1.0, 0.0, 0.0, 0.8)  # Red for ground miss
const PLATFORM_BOUNDS_COLOR: Color = Color(1.0, 1.0, 1.0, 0.3)  # White for platform outlines

const MARKER_RADIUS: float = 12.0
const RAY_LENGTH: float = 128.0
const LINE_WIDTH: float = 2.0

# Debug state
var _debug_visible: bool = false
var _level_base: Node = null
var _player_spawn: Marker2D = null
var _checkpoints: Array[Node] = []
var _generated_geometry: Node2D = null

# Cached ray results for visualization
var _spawn_ground_hit: bool = false
var _spawn_ground_point: Vector2 = Vector2.ZERO
var _checkpoint_ground_hits: Dictionary = {}  # checkpoint_node -> {hit: bool, point: Vector2}


func _ready() -> void:
	# Start hidden in release builds
	_debug_visible = OS.is_debug_build()
	visible = _debug_visible
	
	# Find level elements after a short delay to ensure scene is ready
	await get_tree().process_frame
	_find_level_elements()
	_perform_ground_checks()
	
	# Force redraw
	queue_redraw()


func _process(_delta: float) -> void:
	if not _debug_visible:
		return
	
	# Continuously update for any dynamic changes
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	# Toggle debug visualization with F1
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		_toggle_debug_visibility()
		get_viewport().set_input_as_handled()


func _toggle_debug_visibility() -> void:
	_debug_visible = not _debug_visible
	visible = _debug_visible
	
	if _debug_visible:
		# Refresh data when becoming visible
		_find_level_elements()
		_perform_ground_checks()
		queue_redraw()
		print("SpawnDebugger: Debug visualization ENABLED")
	else:
		print("SpawnDebugger: Debug visualization DISABLED")


func _find_level_elements() -> void:
	"""Find spawn point, checkpoints, and generated geometry in the level."""
	# Find parent level base
	_level_base = _find_parent_level_base()
	
	if _level_base == null:
		push_warning("SpawnDebugger: Could not find LevelBase parent")
		return
	
	# Find PlayerSpawn
	_player_spawn = _level_base.get_node_or_null("PlayerSpawn")
	if _player_spawn == null:
		push_warning("SpawnDebugger: PlayerSpawn not found in level")
	
	# Find all checkpoints
	_checkpoints.clear()
	var checkpoints_container: Node = _level_base.get_node_or_null("Checkpoints")
	if checkpoints_container:
		for child in checkpoints_container.get_children():
			if child.is_in_group("checkpoints"):
				_checkpoints.append(child)
	
	# Find generated geometry container
	_generated_geometry = _level_base.get_node_or_null("GeneratedGeometry")


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


func _perform_ground_checks() -> void:
	"""Cast rays to check for ground beneath spawn and checkpoints."""
	var space_state := get_world_2d().direct_space_state
	if space_state == null:
		return
	
	# Check spawn point
	if _player_spawn:
		var result := _cast_ground_ray(space_state, _player_spawn.global_position)
		_spawn_ground_hit = result.hit
		_spawn_ground_point = result.point
	
	# Check each checkpoint
	_checkpoint_ground_hits.clear()
	for checkpoint in _checkpoints:
		var pos: Vector2 = checkpoint.global_position
		# Account for spawn offset if present
		if "spawn_offset" in checkpoint:
			pos += checkpoint.spawn_offset
		
		var result := _cast_ground_ray(space_state, pos)
		_checkpoint_ground_hits[checkpoint] = result


func _cast_ground_ray(space_state: PhysicsDirectSpaceState2D, from_pos: Vector2) -> Dictionary:
	"""Cast a ray downward to detect ground."""
	var query := PhysicsRayQueryParameters2D.create(
		from_pos,
		from_pos + Vector2(0, RAY_LENGTH),
		0xFFFFFFFF  # Check all layers
	)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var result := space_state.intersect_ray(query)
	
	if result.is_empty():
		return {"hit": false, "point": from_pos + Vector2(0, RAY_LENGTH)}
	else:
		return {"hit": true, "point": result.position}


func _draw() -> void:
	if not _debug_visible:
		return
	
	# Draw spawn point marker
	if _player_spawn:
		_draw_spawn_marker(_player_spawn.global_position)
	
	# Draw checkpoint markers
	for checkpoint in _checkpoints:
		var pos: Vector2 = checkpoint.global_position
		var is_active: bool = false
		if checkpoint.has_method("is_activated"):
			is_active = checkpoint.is_activated()
		
		# Account for spawn offset
		var spawn_pos := pos
		if "spawn_offset" in checkpoint:
			spawn_pos += checkpoint.spawn_offset
		
		_draw_checkpoint_marker(pos, spawn_pos, is_active, checkpoint)
	
	# Draw platform bounds (optional, for context)
	if _generated_geometry:
		_draw_platform_bounds()
	
	# Draw legend
	_draw_legend()


func _draw_spawn_marker(pos: Vector2) -> void:
	"""Draw spawn point marker with ground ray."""
	var local_pos := to_local(pos)
	
	# Draw spawn marker (diamond shape)
	var diamond_points: PackedVector2Array = [
		local_pos + Vector2(0, -MARKER_RADIUS),
		local_pos + Vector2(MARKER_RADIUS, 0),
		local_pos + Vector2(0, MARKER_RADIUS),
		local_pos + Vector2(-MARKER_RADIUS, 0)
	]
	draw_colored_polygon(diamond_points, SPAWN_COLOR)
	draw_polyline(diamond_points + PackedVector2Array([diamond_points[0]]), Color.WHITE, LINE_WIDTH)
	
	# Draw "S" label
	draw_string(ThemeDB.fallback_font, local_pos + Vector2(-4, 5), "S", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.WHITE)
	
	# Draw ground ray
	var ray_end := to_local(_spawn_ground_point)
	var ray_color := GROUND_HIT_COLOR if _spawn_ground_hit else GROUND_MISS_COLOR
	draw_line(local_pos, ray_end, ray_color, LINE_WIDTH)
	
	# Draw ground hit point
	if _spawn_ground_hit:
		draw_circle(ray_end, 4.0, GROUND_HIT_COLOR)
	else:
		# Draw X for no ground
		draw_line(ray_end + Vector2(-4, -4), ray_end + Vector2(4, 4), GROUND_MISS_COLOR, LINE_WIDTH)
		draw_line(ray_end + Vector2(-4, 4), ray_end + Vector2(4, -4), GROUND_MISS_COLOR, LINE_WIDTH)


func _draw_checkpoint_marker(pos: Vector2, spawn_pos: Vector2, is_active: bool, checkpoint: Node) -> void:
	"""Draw checkpoint marker with ground ray."""
	var local_pos := to_local(pos)
	var local_spawn := to_local(spawn_pos)
	var color := CHECKPOINT_ACTIVE_COLOR if is_active else CHECKPOINT_INACTIVE_COLOR
	
	# Draw checkpoint marker (circle)
	draw_circle(local_pos, MARKER_RADIUS, color)
	draw_arc(local_pos, MARKER_RADIUS, 0, TAU, 32, Color.WHITE, LINE_WIDTH)
	
	# Draw "C" label
	var label := "C+" if is_active else "C"
	draw_string(ThemeDB.fallback_font, local_pos + Vector2(-4, 5), label, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)
	
	# Draw spawn offset indicator if different from checkpoint pos
	if pos.distance_to(spawn_pos) > 1.0:
		draw_dashed_line(local_pos, local_spawn, Color.YELLOW, 1.0, 4.0)
		draw_circle(local_spawn, 4.0, Color.YELLOW)
	
	# Draw ground ray from spawn position
	var ray_result: Dictionary = _checkpoint_ground_hits.get(checkpoint, {"hit": false, "point": spawn_pos + Vector2(0, RAY_LENGTH)})
	var ray_end := to_local(ray_result.point)
	var ray_color := GROUND_HIT_COLOR if ray_result.hit else GROUND_MISS_COLOR
	draw_line(local_spawn, ray_end, ray_color, LINE_WIDTH)
	
	# Draw ground hit point
	if ray_result.hit:
		draw_circle(ray_end, 4.0, GROUND_HIT_COLOR)
	else:
		draw_line(ray_end + Vector2(-4, -4), ray_end + Vector2(4, 4), GROUND_MISS_COLOR, LINE_WIDTH)
		draw_line(ray_end + Vector2(-4, 4), ray_end + Vector2(4, -4), GROUND_MISS_COLOR, LINE_WIDTH)


func _draw_platform_bounds() -> void:
	"""Draw outlines of generated platforms for context."""
	if _generated_geometry == null:
		return
	
	for child in _generated_geometry.get_children():
		if not child is StaticBody2D:
			continue
		
		var visual: ColorRect = child.get_node_or_null("Visual")
		if visual == null:
			continue
		
		var platform_pos := to_local(child.global_position)
		var platform_size: Vector2 = visual.size
		
		# Draw rectangle outline
		var rect := Rect2(platform_pos, platform_size)
		draw_rect(rect, PLATFORM_BOUNDS_COLOR, false, 1.0)


func _draw_legend() -> void:
	"""Draw a legend explaining the debug markers."""
	# Position legend in top-left, accounting for camera
	var camera := get_viewport().get_camera_2d()
	var legend_pos := Vector2(20, 20)
	
	if camera:
		legend_pos = camera.get_screen_center_position() - get_viewport_rect().size / 2 + Vector2(20, 20)
	
	legend_pos = to_local(legend_pos)
	
	# Background
	var bg_rect := Rect2(legend_pos - Vector2(5, 5), Vector2(180, 100))
	draw_rect(bg_rect, Color(0, 0, 0, 0.7))
	
	# Title
	var y_offset := 0.0
	draw_string(ThemeDB.fallback_font, legend_pos + Vector2(0, 12), "SPAWN DEBUGGER (F1)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	y_offset += 18
	
	# Spawn
	draw_circle(legend_pos + Vector2(8, y_offset + 8), 6, SPAWN_COLOR)
	draw_string(ThemeDB.fallback_font, legend_pos + Vector2(20, y_offset + 12), "Spawn Point", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
	y_offset += 16
	
	# Checkpoint inactive
	draw_circle(legend_pos + Vector2(8, y_offset + 8), 6, CHECKPOINT_INACTIVE_COLOR)
	draw_string(ThemeDB.fallback_font, legend_pos + Vector2(20, y_offset + 12), "Checkpoint (inactive)", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
	y_offset += 16
	
	# Checkpoint active
	draw_circle(legend_pos + Vector2(8, y_offset + 8), 6, CHECKPOINT_ACTIVE_COLOR)
	draw_string(ThemeDB.fallback_font, legend_pos + Vector2(20, y_offset + 12), "Checkpoint (active)", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
	y_offset += 16
	
	# Ground ray
	draw_line(legend_pos + Vector2(2, y_offset + 8), legend_pos + Vector2(14, y_offset + 8), GROUND_HIT_COLOR, 2.0)
	draw_string(ThemeDB.fallback_font, legend_pos + Vector2(20, y_offset + 12), "Ground OK / Missing", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)


## Manually refresh debug data (call when level changes).
func refresh() -> void:
	_find_level_elements()
	_perform_ground_checks()
	queue_redraw()


## Returns spawn ground check status for external use.
func get_spawn_status() -> Dictionary:
	return {
		"position": _player_spawn.global_position if _player_spawn else Vector2.ZERO,
		"has_ground": _spawn_ground_hit,
		"ground_point": _spawn_ground_point
	}


## Returns checkpoint statuses for external use.
func get_checkpoint_statuses() -> Array[Dictionary]:
	var statuses: Array[Dictionary] = []
	for checkpoint in _checkpoints:
		var result: Dictionary = _checkpoint_ground_hits.get(checkpoint, {"hit": false, "point": Vector2.ZERO})
		statuses.append({
			"position": checkpoint.global_position,
			"has_ground": result.hit,
			"ground_point": result.point,
			"is_active": checkpoint.is_activated() if checkpoint.has_method("is_activated") else false
		})
	return statuses
