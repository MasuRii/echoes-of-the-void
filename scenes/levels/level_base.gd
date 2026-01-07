class_name LevelBase
extends Node2D

## Base class for all levels in Echoes of the Void.
## Provides common level functionality: spawn points, collectibles tracking,
## level exit handling, and camera limits configuration.
## Extend or use this scene as a base for individual levels.

# Signals
signal level_started
signal level_exit_triggered

# Level configuration
@export_group("Level Info")
## Display name for this level (shown in UI).
@export var level_name: String = "Unnamed Level"
## Path to the next level scene. Empty if this is the last level.
@export_file("*.tscn") var next_level: String = ""

@export_group("Collectibles")
## Total number of light shards in this level.
@export var total_shards: int = 0
## Number of echo crystals in this level (typically 1-3).
@export_range(0, 3) var crystal_count: int = 1

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
	_setup_level()
	_spawn_player()
	_spawn_hud()
	_configure_camera()
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


func _spawn_player() -> void:
	"""Spawn the player at the spawn point."""
	if player_spawn == null:
		push_error("LevelBase: PlayerSpawn Marker2D not found!")
		return
	
	# Preload and instantiate player
	var player_scene: PackedScene = preload("res://scenes/player/player.tscn")
	player = player_scene.instantiate()
	player.global_position = player_spawn.global_position
	
	# Set initial checkpoint to spawn position
	if player.has_method("set_last_checkpoint"):
		player.set_last_checkpoint(player_spawn.global_position)
	elif "last_checkpoint" in player:
		player.last_checkpoint = player_spawn.global_position
	
	add_child(player)
	
	# Emit player spawned event
	var events := _get_events()
	if events and events.has_signal("player_spawned"):
		events.player_spawned.emit(player)


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


func _get_events() -> Node:
	"""Get the Events autoload safely."""
	return get_node_or_null("/root/Events")


func _get_game_manager() -> Node:
	"""Get the GameManager autoload safely."""
	return get_node_or_null("/root/GameManager")


func _on_shard_collected(count: int, _total: int) -> void:
	"""Handle shard collection."""
	_shards_collected = count


func _on_crystal_collected(crystal_id: String) -> void:
	"""Handle crystal collection."""
	if crystal_id not in _crystals_collected:
		_crystals_collected.append(crystal_id)


func _on_player_died() -> void:
	"""Handle player death. Override for custom behavior."""
	pass


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
	"""Handle level completion. Show level complete screen."""
	# Show level complete screen
	var level_complete_scene: PackedScene = preload("res://scenes/ui/level_complete.tscn")
	var level_complete: Control = level_complete_scene.instantiate()
	add_child(level_complete)


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
	
	# Instantiate and show pause menu
	var pause_menu_scene: PackedScene = preload("res://scenes/ui/pause_menu.tscn")
	var pause_menu: Control = pause_menu_scene.instantiate()
	add_child(pause_menu)


## Manually set camera limits (useful for scrolling levels).
func set_camera_limits(left: int, right: int, top: int, bottom: int) -> void:
	camera_limit_left = left
	camera_limit_right = right
	camera_limit_top = top
	camera_limit_bottom = bottom
	_configure_camera()
