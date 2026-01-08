class_name LevelBase
extends Node2D

## Base class for all levels in Echoes of the Void.
## Provides common level functionality: spawn points, collectibles tracking,
## level exit handling, and camera limits configuration.
## Extend or use this scene as a base for individual levels.

# Preload procedural generation systems
const PlatformGeneratorClass := preload("res://scripts/systems/platform_generator.gd")
const LevelLayoutsClass := preload("res://scripts/data/level_layouts.gd")
const LightingManagerClass := preload("res://scripts/systems/lighting_manager.gd")

# Signals
signal level_started
signal level_exit_triggered

# Level configuration
@export_group("Level Info")
## Display name for this level (shown in UI).
@export var level_name: String = "Unnamed Level"
## Path to the next level scene. Empty if this is the last level.
@export_file("*.tscn") var next_level: String = ""

@export_group("Procedural Geometry")
## Enable automatic geometry generation from level layouts.
@export var auto_generate_geometry: bool = true
## Key to look up layout data (e.g., "LEVEL_01", "LEVEL_02").
@export var level_layout_key: String = ""

@export_group("Collectibles")
## Total number of light shards in this level.
@export var total_shards: int = 0
## Number of echo crystals in this level (typically 1-3).
@export_range(0, 3) var crystal_count: int = 1

@export_group("Audio")
## Music track to play during this level (from assets/audio/music/).
@export var level_music: String = "level_ambience"
## Fade duration for music transitions in seconds.
@export var music_fade_duration: float = 1.5

@export_group("Camera Limits")
## Enable camera bounds for this level.
@export var use_camera_limits: bool = true
## Left camera boundary (world units).
@export var camera_limit_left: int = 0
## Right camera boundary (world units).
@export var camera_limit_right: int = 1920
## Top camera boundary (world units).
@export var camera_limit_top: int = 0
## Bottom camera boundary (world units).
@export var camera_limit_bottom: int = 1080

# Player reference
var player: CharacterBody2D = null

# Level state
var _shards_collected: int = 0
var _crystals_collected: Array[String] = []
var _level_completed: bool = false

# HUD reference
var _hud: CanvasLayer = null

# Container for generated geometry
var _generated_geometry: Node2D = null

# Lighting system references
var _lighting_data: Dictionary = {}

# Audio manager reference
var _audio_manager: Node = null

# Cached node references
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var level_exit: Area2D = $LevelExit
@onready var collectibles: Node2D = $Collectibles
@onready var enemies: Node2D = $Enemies
@onready var platforms: Node2D = $Platforms
@onready var hazards: Node2D = $Hazards
@onready var checkpoints: Node2D = $Checkpoints


func _ready() -> void:
	_connect_events()
	_generate_level_geometry()  # Generate geometry BEFORE player spawn
	_setup_level()
	_spawn_player()
	_restore_checkpoint_state()  # Restore saved checkpoint after player spawned
	_spawn_hud()
	_configure_camera()
	_setup_lighting()  # Setup lighting after player spawn
	_count_collectibles()
	_initialize_game_state()
	
	level_started.emit()


func _connect_events() -> void:
	"""Connect to global Events signals."""
	var events := _get_events()
	if events:
		events.shard_collected.connect(_on_shard_collected)
		events.crystal_collected.connect(_on_crystal_collected)
		events.player_died.connect(_on_player_died)


func _setup_level() -> void:
	"""Virtual method for level-specific setup. Override in subclasses."""
	pass


func _generate_level_geometry() -> void:
	"""Generate procedural level geometry from layout data."""
	if not auto_generate_geometry:
		return
	
	# Create container for generated geometry
	_generated_geometry = Node2D.new()
	_generated_geometry.name = "GeneratedGeometry"
	add_child(_generated_geometry)
	# Move to front so it's behind other elements
	move_child(_generated_geometry, 0)
	
	# Try to load layout from level_layouts.gd
	var layout: Variant = null
	if level_layout_key != "":
		layout = LevelLayoutsClass.get_layout(level_layout_key)
	
	if layout == null:
		# No layout defined - generate emergency ground at spawn
		push_warning("LevelBase: No layout found for key '%s', generating emergency ground" % level_layout_key)
		_generate_emergency_geometry()
		return
	
	# Validate layout
	if not LevelLayoutsClass.validate_layout(layout):
		push_warning("LevelBase: Invalid layout for '%s', generating emergency ground" % level_layout_key)
		_generate_emergency_geometry()
		return
	
	# Generate platforms from layout data
	var platform_count: int = 0
	for platform_data: Dictionary in layout["platforms"]:
		var pos: Vector2 = platform_data.get("pos", Vector2.ZERO)
		var size: Vector2 = platform_data.get("size", Vector2(64, 32))
		PlatformGeneratorClass.create_platform(_generated_geometry, pos, size)
		platform_count += 1
	
	# Generate walls from layout data
	var wall_count: int = 0
	for wall_data: Dictionary in layout["walls"]:
		var pos: Vector2 = wall_data.get("pos", Vector2.ZERO)
		var height: float = wall_data.get("height", 128.0)
		var side: String = wall_data.get("side", "left")
		PlatformGeneratorClass.create_wall(_generated_geometry, pos, height, side)
		wall_count += 1
	
	# Generate one-way platforms from layout data
	var one_way_count: int = 0
	for one_way_data: Dictionary in layout["one_way_platforms"]:
		var pos: Vector2 = one_way_data.get("pos", Vector2.ZERO)
		var width: float = one_way_data.get("width", 96.0)
		PlatformGeneratorClass.create_one_way_platform(_generated_geometry, pos, width)
		one_way_count += 1
	
	print("LevelBase: Generated geometry for '%s' - %d platforms, %d walls, %d one-way" % [
		level_layout_key, platform_count, wall_count, one_way_count
	])


func _generate_emergency_geometry() -> void:
	"""Generate emergency ground platform at spawn position as fallback."""
	if player_spawn == null:
		push_error("LevelBase: Cannot generate emergency geometry - no spawn point!")
		return
	
	# Create a ground platform below the spawn point
	var spawn_y: float = player_spawn.global_position.y + 32.0  # Slightly below spawn
	PlatformGeneratorClass.create_emergency_ground(_generated_geometry, spawn_y)
	print("LevelBase: Generated emergency ground at Y=%.0f" % spawn_y)


func _spawn_player() -> void:
	"""Spawn the player at the spawn point with validation."""
	if player_spawn == null:
		push_error("LevelBase: PlayerSpawn Marker2D not found!")
		return
	
	# Validate spawn position has ground beneath it
	var spawn_pos: Vector2 = player_spawn.global_position
	var has_ground: bool = _validate_spawn_has_ground(spawn_pos)
	
	if not has_ground:
		push_warning("LevelBase: No ground detected at spawn position (%.0f, %.0f), generating emergency platform" % [spawn_pos.x, spawn_pos.y])
		_generate_emergency_spawn_platform(spawn_pos)
	
	# Preload and instantiate player
	var player_scene: PackedScene = preload("res://scenes/player/player.tscn")
	player = player_scene.instantiate()
	player.global_position = spawn_pos
	
	# Set initial checkpoint to spawn position
	if player.has_method("set_last_checkpoint"):
		player.set_last_checkpoint(spawn_pos)
	elif "last_checkpoint" in player:
		player.last_checkpoint = spawn_pos
	
	add_child(player)
	
	print("LevelBase: Player spawned at (%.0f, %.0f)" % [spawn_pos.x, spawn_pos.y])
	
	# Emit player spawned event
	var events := _get_events()
	if events and events.has_signal("player_spawned"):
		events.player_spawned.emit(player)


func _restore_checkpoint_state() -> void:
	"""Restore saved checkpoint state from SaveManager on level load."""
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null:
		return
	
	var level_path: String = scene_file_path
	if not save_manager.has_saved_checkpoint(level_path):
		return
	
	var checkpoint_data: Dictionary = save_manager.get_active_checkpoint(level_path)
	if checkpoint_data.is_empty():
		return
	
	var saved_index: int = checkpoint_data.get("checkpoint_index", -1)
	var saved_position: Vector2 = checkpoint_data.get("position", Vector2.ZERO)
	
	if saved_position == Vector2.ZERO:
		return
	
	# Restore player's checkpoint position
	if player:
		if player.has_method("set_last_checkpoint"):
			player.set_last_checkpoint(saved_position)
		elif "last_checkpoint" in player:
			player.last_checkpoint = saved_position
		print("LevelBase: Restored checkpoint %d at (%.0f, %.0f)" % [saved_index, saved_position.x, saved_position.y])
	
	# Restore visual state of activated checkpoints
	if checkpoints:
		var current_index: int = 0
		for checkpoint in checkpoints.get_children():
			if checkpoint.is_in_group("checkpoints"):
				# Activate all checkpoints up to and including the saved one
				if current_index <= saved_index and checkpoint.has_method("set_activated"):
					checkpoint.set_activated(true)
				current_index += 1


func _validate_spawn_has_ground(spawn_pos: Vector2) -> bool:
	"""Check if there is solid ground below the spawn position."""
	# Check if any generated platform exists that would catch the player
	if _generated_geometry == null:
		return false
	
	# Player collision height (approximately 32 pixels, check 64 below for margin)
	var check_distance: float = 128.0
	var player_width: float = 16.0  # Half player width for checking
	
	for child in _generated_geometry.get_children():
		if not child is StaticBody2D:
			continue
		
		# Get the visual rect to determine platform bounds
		var visual: ColorRect = child.get_node_or_null("Visual")
		if visual == null:
			continue
		
		var platform_pos: Vector2 = child.position
		var platform_size: Vector2 = visual.size
		
		# Check if spawn is horizontally within platform bounds
		var platform_left: float = platform_pos.x - player_width
		var platform_right: float = platform_pos.x + platform_size.x + player_width
		
		if spawn_pos.x < platform_left or spawn_pos.x > platform_right:
			continue
		
		# Check if platform is below spawn but within check distance
		var platform_top: float = platform_pos.y
		if platform_top > spawn_pos.y and platform_top < spawn_pos.y + check_distance:
			return true
	
	return false


func _generate_emergency_spawn_platform(spawn_pos: Vector2) -> void:
	"""Generate a small emergency platform below the spawn point."""
	if _generated_geometry == null:
		_generated_geometry = Node2D.new()
		_generated_geometry.name = "GeneratedGeometry"
		add_child(_generated_geometry)
		move_child(_generated_geometry, 0)
	
	# Create a platform centered below spawn, 64 pixels down
	var platform_width: float = 256.0
	var platform_height: float = 32.0
	var platform_pos := Vector2(spawn_pos.x - platform_width / 2.0, spawn_pos.y + 48.0)
	
	PlatformGeneratorClass.create_platform(
		_generated_geometry,
		platform_pos,
		Vector2(platform_width, platform_height)
	)
	print("LevelBase: Emergency spawn platform created at (%.0f, %.0f)" % [platform_pos.x, platform_pos.y])


func _spawn_hud() -> void:
	"""Spawn the HUD for displaying collectibles."""
	var hud_scene: PackedScene = preload("res://scenes/ui/hud.tscn")
	_hud = hud_scene.instantiate()
	add_child(_hud)


func _configure_camera() -> void:
	"""Configure camera limits if player has a Camera2D child."""
	if player == null:
		return
	
	var camera: Camera2D = player.get_node_or_null("Camera2D")
	if camera == null:
		# Try to find a Camera2D anywhere in player's children
		for child in player.get_children():
			if child is Camera2D:
				camera = child
				break
	
	if camera and use_camera_limits:
		camera.limit_left = camera_limit_left
		camera.limit_right = camera_limit_right
		camera.limit_top = camera_limit_top
		camera.limit_bottom = camera_limit_bottom


func _setup_lighting() -> void:
	"""Setup level lighting using the LightingManager system."""
	# Calculate level bounds from camera limits
	var level_bounds := Rect2(
		Vector2(camera_limit_left, camera_limit_top),
		Vector2(camera_limit_right - camera_limit_left, camera_limit_bottom - camera_limit_top)
	)
	
	# Setup lighting with LightingManager
	_lighting_data = LightingManagerClass.setup_level_lighting(
		self,
		player,
		hazards,
		level_layout_key,
		level_bounds
	)


func _count_collectibles() -> void:
	"""Count collectibles in the level and update total_shards if set to 0."""
	if collectibles == null:
		return
	
	# Auto-count shards if not manually set
	if total_shards == 0:
		var shard_count: int = 0
		for child in collectibles.get_children():
			if child.is_in_group("light_shards"):
				shard_count += 1
		total_shards = shard_count
	
	# Count crystals
	var found_crystals: int = 0
	for child in collectibles.get_children():
		if child.is_in_group("echo_crystals"):
			found_crystals += 1
	
	if crystal_count == 0:
		crystal_count = found_crystals


func _initialize_game_state() -> void:
	"""Set up GameManager with level information."""
	var game_manager := _get_game_manager()
	if game_manager:
		game_manager.current_level = scene_file_path
		game_manager.total_shards = total_shards
		game_manager.collected_shards = 0
		game_manager.change_state(game_manager.GameState.PLAYING)
	
	# Start level music
	_start_level_music()


func _get_events() -> Node:
	"""Get the Events autoload safely."""
	return get_node_or_null("/root/Events")


func _get_game_manager() -> Node:
	"""Get the GameManager autoload safely."""
	return get_node_or_null("/root/GameManager")


func _get_audio_manager() -> Node:
	"""Get the AudioManager autoload safely."""
	if _audio_manager == null:
		_audio_manager = get_node_or_null("/root/AudioManager")
	return _audio_manager


func _start_level_music() -> void:
	"""Start playing level music with crossfade from any previous track."""
	var audio_mgr := _get_audio_manager()
	if audio_mgr == null:
		return
	
	if level_music.is_empty():
		return
	
	# Play level music with configured fade duration
	audio_mgr.play_music(level_music, music_fade_duration)


func _play_victory_music() -> void:
	"""Play victory jingle when level is completed."""
	var audio_mgr := _get_audio_manager()
	if audio_mgr == null:
		return
	
	# Play victory music with short fade
	audio_mgr.play_music("victory", 0.5)


func _on_shard_collected(count: int, _total: int) -> void:
	"""Handle shard collection."""
	_shards_collected = count


func _on_crystal_collected(crystal_id: String) -> void:
	"""Handle crystal collection."""
	if crystal_id not in _crystals_collected:
		_crystals_collected.append(crystal_id)


func _on_player_died() -> void:
	"""Handle player death. Reset dynamic platforms for fair respawn."""
	_reset_moving_platforms()


## Resets all moving platforms to their initial positions.
func _reset_moving_platforms() -> void:
	"""Reset moving platforms to start positions for player respawn."""
	# Check platforms container
	if platforms == null:
		return
	
	for platform in platforms.get_children():
		if platform.is_in_group("moving_platforms"):
			if platform.has_method("reset_position"):
				platform.reset_position()
	
	# Also check for any moving platforms that might be elsewhere in the tree
	var all_moving := get_tree().get_nodes_in_group("moving_platforms")
	for platform in all_moving:
		if platform.has_method("reset_position"):
			platform.reset_position()


func _on_level_exit_body_entered(body: Node2D) -> void:
	"""Handle player reaching the level exit."""
	if body != player:
		return
	
	if _level_completed:
		return
	
	_level_completed = true
	level_exit_triggered.emit()
	
	# Emit global event
	var events := _get_events()
	if events:
		events.level_completed.emit(level_name)
	
	# Load next level or show completion
	_complete_level()


func _complete_level() -> void:
	"""Handle level completion. Show level complete screen and play victory music."""
	# Save progress to SaveManager
	_save_level_progress()
	
	# Play victory music
	_play_victory_music()
	
	# Show level complete screen
	var level_complete_scene: PackedScene = preload("res://scenes/ui/level_complete.tscn")
	var level_complete: Control = level_complete_scene.instantiate()
	add_child(level_complete)


func _save_level_progress() -> void:
	"""Save level completion progress to SaveManager."""
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null:
		push_warning("LevelBase: SaveManager not found, progress not saved")
		return
	
	var level_path: String = scene_file_path
	
	# Save best shards count (only if better than previous best)
	save_manager.save_best_shards(level_path, _shards_collected)
	print("LevelBase: Saved shards %d for %s" % [_shards_collected, level_path])
	
	# Unlock next level if it exists
	if not next_level.is_empty():
		save_manager.unlock_level(next_level)
		print("LevelBase: Unlocked next level: %s" % next_level)
	
	# Clear checkpoint for this level since it's now completed
	save_manager.clear_checkpoint(level_path)


## Returns the current shard collection count.
func get_shards_collected() -> int:
	return _shards_collected


## Returns the total shards in this level.
func get_total_shards() -> int:
	return total_shards


## Returns array of collected crystal IDs.
func get_crystals_collected() -> Array[String]:
	return _crystals_collected


## Returns completion percentage (0.0 to 1.0).
func get_completion_percentage() -> float:
	if total_shards == 0:
		return 1.0
	return float(_shards_collected) / float(total_shards)


func _unhandled_input(event: InputEvent) -> void:
	"""Handle pause input to show pause menu."""
	if event.is_action_pressed("pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()


func _toggle_pause() -> void:
	"""Toggle pause state and show/hide pause menu."""
	var game_manager := _get_game_manager()
	if game_manager == null:
		return
	
	# Only allow pausing during gameplay
	if game_manager.current_state != game_manager.GameState.PLAYING:
		return
	
	# Change to paused state
	game_manager.change_state(game_manager.GameState.PAUSED)
	
	# Instantiate and show pause menu (now wrapped in CanvasLayer)
	var pause_menu_scene: PackedScene = preload("res://scenes/ui/pause_menu.tscn")
	var pause_menu_layer: CanvasLayer = pause_menu_scene.instantiate()
	add_child(pause_menu_layer)


## Manually set camera limits (useful for scrolling levels).
func set_camera_limits(left: int, right: int, top: int, bottom: int) -> void:
	camera_limit_left = left
	camera_limit_right = right
	camera_limit_top = top
	camera_limit_bottom = bottom
	_configure_camera()


## Resets all dynamic elements in the level (for level restart).
func reset_level_elements() -> void:
	"""Reset all dynamic elements to their initial state."""
	# Reset moving platforms
	_reset_moving_platforms()
	
	# Reset phase platforms if they have reset methods
	_reset_phase_platforms()
	
	# Reset crumbling platforms if they have reset methods
	_reset_crumbling_platforms()


## Resets all phase platforms to their initial state.
func _reset_phase_platforms() -> void:
	"""Reset phase platforms to their initial state."""
	if platforms == null:
		return
	
	for platform in platforms.get_children():
		if platform.is_in_group("phase_platforms") and platform.has_method("reset"):
			platform.reset()


## Resets all crumbling platforms to their initial state.
func _reset_crumbling_platforms() -> void:
	"""Reset crumbling platforms to their initial state."""
	if platforms == null:
		return
	
	for platform in platforms.get_children():
		if platform.is_in_group("crumbling_platforms") and platform.has_method("reset"):
			platform.reset()
