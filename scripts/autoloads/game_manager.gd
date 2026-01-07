extends Node
## Central game state controller for Echoes of the Void.
## Register as autoload "GameManager" in Project Settings > Autoload.
## NOTE: Events autoload must be registered BEFORE GameManager.

# Game states
enum GameState { MENU, PLAYING, PAUSED, TRANSITIONING, GAME_OVER }

# Signals
signal state_changed(new_state: GameState)

# Current game state
var current_state: GameState = GameState.MENU

# Level tracking
var current_level: String = ""

# Collectible tracking
var total_shards: int = 0
var collected_shards: int = 0
var collected_crystals: Array[String] = []

# Cached reference to Events autoload
var _events: Node = null


func _ready() -> void:
	# Run even when game is paused so we can handle unpause
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Get Events autoload reference and connect signals
	_connect_events()


func _connect_events() -> void:
	"""Connect to Events autoload signals."""
	_events = get_node_or_null("/root/Events")
	if _events == null:
		push_warning("GameManager: Events autoload not found. Signal connections skipped.")
		return
	
	_events.player_died.connect(_on_player_died)
	_events.shard_collected.connect(_on_shard_collected)
	_events.crystal_collected.connect(_on_crystal_collected)


func change_state(new_state: GameState) -> void:
	"""Change the current game state and handle transitions."""
	var old_state := current_state
	current_state = new_state
	state_changed.emit(new_state)
	
	match new_state:
		GameState.PAUSED:
			get_tree().paused = true
			if _events:
				_events.game_paused.emit(true)
		GameState.PLAYING:
			if old_state == GameState.PAUSED:
				get_tree().paused = false
				if _events:
					_events.game_paused.emit(false)
		GameState.GAME_OVER:
			get_tree().paused = true


func restart_level() -> void:
	"""Restart the current level from the beginning."""
	if current_level.is_empty():
		push_warning("GameManager: No current level set to restart")
		return
	
	# Reset collectible tracking for this level
	collected_shards = 0
	
	# Reload the current level
	get_tree().paused = false
	change_state(GameState.TRANSITIONING)
	
	var error := get_tree().change_scene_to_file(current_level)
	if error != OK:
		push_error("GameManager: Failed to restart level: %s" % current_level)
		return
	
	# Wait a frame then set to playing
	await get_tree().process_frame
	change_state(GameState.PLAYING)


func load_level(level_path: String, with_transition: bool = true) -> void:
	"""Load a new level by path with optional fade transition."""
	if level_path.is_empty():
		push_warning("GameManager: Cannot load empty level path")
		return
	
	# Validate scene exists before attempting to load
	if not ResourceLoader.exists(level_path):
		push_error("GameManager: Level scene does not exist: %s" % level_path)
		return
	
	change_state(GameState.TRANSITIONING)
	
	# Reset level-specific tracking
	collected_shards = 0
	total_shards = 0
	
	# Perform transition animation if enabled
	if with_transition:
		await _perform_fade_transition(0.3)  # Fade out
	
	# Clean up any lingering references from previous level
	_cleanup_previous_level()
	
	var error := get_tree().change_scene_to_file(level_path)
	if error != OK:
		push_error("GameManager: Failed to load level: %s" % level_path)
		change_state(GameState.MENU)
		return
	
	current_level = level_path
	
	# Wait a frame then set to playing
	await get_tree().process_frame
	
	# Fade in after level loads
	if with_transition:
		await _perform_fade_in(0.3)
	
	change_state(GameState.PLAYING)


func _cleanup_previous_level() -> void:
	"""Clean up references and state from the previous level."""
	# Clear any lingering crystal references for the new level
	# Note: We don't clear collected_crystals as those are persistent across levels
	pass


func _perform_fade_transition(duration: float) -> void:
	"""Perform a fade to black transition."""
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 100  # Render on top of everything
	fade_layer.name = "TransitionFade"
	get_tree().root.add_child(fade_layer)
	
	var fade_rect := ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.modulate.a = 0.0
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(fade_rect)
	
	# Fade out (transparent to black)
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tween.finished
	
	# Store reference to remove after fade in
	set_meta("_transition_layer", fade_layer)


func _perform_fade_in(duration: float) -> void:
	"""Perform a fade in from black transition."""
	var fade_layer: CanvasLayer = get_meta("_transition_layer", null)
	if fade_layer == null:
		# No transition layer exists, create one already at black
		fade_layer = CanvasLayer.new()
		fade_layer.layer = 100
		fade_layer.name = "TransitionFade"
		get_tree().root.add_child(fade_layer)
		
		var fade_rect := ColorRect.new()
		fade_rect.color = Color.BLACK
		fade_rect.modulate.a = 1.0
		fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		fade_layer.add_child(fade_rect)
	
	var fade_rect: ColorRect = fade_layer.get_child(0) as ColorRect
	if fade_rect:
		# Fade in (black to transparent)
		var tween := create_tween()
		tween.tween_property(fade_rect, "modulate:a", 0.0, duration)
		await tween.finished
	
	# Clean up
	fade_layer.queue_free()
	if has_meta("_transition_layer"):
		remove_meta("_transition_layer")


func _on_player_died() -> void:
	"""Handle player death event."""
	# Note: Player handles their own respawn via checkpoint
	# This is for any global death handling (stats, etc.)
	pass


func _on_shard_collected(count: int, total: int) -> void:
	"""Handle shard collection event."""
	collected_shards = count
	total_shards = total


func _on_crystal_collected(crystal_id: String) -> void:
	"""Handle crystal collection event."""
	if crystal_id not in collected_crystals:
		collected_crystals.append(crystal_id)


## Applies a brief hitstop/freeze frame effect for impact.
## Sets Engine.time_scale to 0.0 for the given duration, then restores it.
## Commonly used for: player death, crystal collection, impactful moments.
func hitstop(duration: float = 0.05) -> void:
	if duration <= 0.0:
		return
	
	# Store original time scale (normally 1.0, but could be different)
	var original_time_scale := Engine.time_scale
	
	# Freeze time
	Engine.time_scale = 0.0
	
	# Wait using a timer that ignores time scale (we use process_mode)
	# Create a SceneTreeTimer that is NOT affected by time_scale
	await get_tree().create_timer(duration, true, false, true).timeout
	
	# Restore time scale
	Engine.time_scale = original_time_scale
