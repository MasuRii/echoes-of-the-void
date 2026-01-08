extends CanvasLayer
## Unified Debug Manager for Echoes of the Void.
## Provides a debug overlay with key bindings reference, game state info,
## and quick access to all debug tools.
##
## Toggle with F12 in debug builds.
## Shows all available debug keys and current game state.

# Singleton pattern - add to autoloads as "DebugManager" for global access
# Or instance in any level scene for testing

const DEBUG_KEYS: Array[Dictionary] = [
	{"key": "F1", "action": "Spawn Debugger", "description": "Visualize spawn point and checkpoint positions"},
	{"key": "F2", "action": "Save Debugger", "description": "Print save file contents to console"},
	{"key": "Shift+F2", "action": "Reset Save", "description": "Clear save data and start fresh"},
	{"key": "F3", "action": "Level Visualizer", "description": "Show platform bounds, collectibles, enemies"},
	{"key": "Shift+F3", "action": "Cycle Visualizer Mode", "description": "Switch display modes (all/platforms/collectibles/enemies)"},
	{"key": "F4", "action": "Level Test Runner", "description": "Run automated level verification tests"},
	{"key": "F5", "action": "Flow Test Runner", "description": "Run game flow tests (menu, pause, death, save)"},
	{"key": "F6", "action": "Performance Profiler", "description": "Show FPS, frame time, memory stats"},
	{"key": "Shift+F6", "action": "Reset Profiler Stats", "description": "Clear performance statistics"},
	{"key": "F12", "action": "Debug Manager (this)", "description": "Toggle this debug overlay"},
	{"key": "R", "action": "Quick Restart", "description": "Restart current level instantly"},
	{"key": "Escape", "action": "Pause Menu", "description": "Toggle pause menu"},
]

# UI references
var _overlay: Control = null
var _panel: PanelContainer = null
var _content: VBoxContainer = null
var _state_label: Label = null
var _is_visible: bool = false

# Cached autoload references
var _game_manager: Node = null
var _save_manager: Node = null
var _events: Node = null

# Update timer
var _update_timer: float = 0.0
const UPDATE_INTERVAL: float = 0.25  # Update state display every 0.25 seconds


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	
	# Set layer to render above everything
	layer = 100
	
	# Cache autoload references
	_game_manager = get_node_or_null("/root/GameManager")
	_save_manager = get_node_or_null("/root/SaveManager")
	_events = get_node_or_null("/root/Events")
	
	# Build the debug overlay UI
	_build_overlay()
	
	# Start hidden
	_overlay.visible = false
	_is_visible = false
	
	print("[DebugManager] Initialized. Press F12 to toggle debug overlay.")


func _build_overlay() -> void:
	"""Build the debug overlay UI programmatically."""
	# Main overlay control (full screen)
	_overlay = Control.new()
	_overlay.name = "DebugOverlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)
	
	# Semi-transparent background
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.0, 0.0, 0.0, 0.85)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(bg)
	
	# Main scroll container for content
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 40)
	scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(scroll)
	
	# Content container
	_content = VBoxContainer.new()
	_content.name = "Content"
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(_content)
	
	# Title
	var title := Label.new()
	title.text = "DEBUG MANAGER"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.CYAN)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(title)
	
	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "Press F12 to close | Echoes of the Void Debug Tools"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(subtitle)
	
	_add_separator()
	
	# Game State Section
	var state_header := Label.new()
	state_header.text = "CURRENT GAME STATE"
	state_header.add_theme_font_size_override("font_size", 20)
	state_header.add_theme_color_override("font_color", Color.YELLOW)
	_content.add_child(state_header)
	
	_state_label = Label.new()
	_state_label.text = _get_game_state_text()
	_state_label.add_theme_font_size_override("font_size", 14)
	_state_label.add_theme_color_override("font_color", Color.WHITE)
	_content.add_child(_state_label)
	
	_add_separator()
	
	# Debug Keys Section
	var keys_header := Label.new()
	keys_header.text = "DEBUG KEY BINDINGS"
	keys_header.add_theme_font_size_override("font_size", 20)
	keys_header.add_theme_color_override("font_color", Color.YELLOW)
	_content.add_child(keys_header)
	
	# Key bindings grid
	for key_info in DEBUG_KEYS:
		_add_key_row(key_info["key"], key_info["action"], key_info["description"])
	
	_add_separator()
	
	# Testing Checklist Section
	var checklist_header := Label.new()
	checklist_header.text = "FINAL TESTING CHECKLIST (Phase 8.8)"
	checklist_header.add_theme_font_size_override("font_size", 20)
	checklist_header.add_theme_color_override("font_color", Color.YELLOW)
	_content.add_child(checklist_header)
	
	var checklist_items := [
		"[ ] Complete playthrough of all 5 levels",
		"[ ] Verify all collectibles obtainable",
		"[ ] Verify all checkpoints functional",
		"[ ] Test all enemies behave correctly",
		"[ ] Test all platform types",
		"[ ] Settings save/load correctly",
		"[ ] Game save/load correctly",
		"[ ] No crashes or softlocks",
		"[ ] Performance acceptable (60 FPS target)",
		"[ ] Audio levels balanced",
		"[ ] Export builds for target platforms",
	]
	
	for item in checklist_items:
		var item_label := Label.new()
		item_label.text = "  " + item
		item_label.add_theme_font_size_override("font_size", 14)
		item_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		_content.add_child(item_label)
	
	_add_separator()
	
	# Quick Actions Section
	var actions_header := Label.new()
	actions_header.text = "QUICK ACTIONS (in overlay)"
	actions_header.add_theme_font_size_override("font_size", 20)
	actions_header.add_theme_color_override("font_color", Color.YELLOW)
	_content.add_child(actions_header)
	
	var actions_text := Label.new()
	actions_text.text = """
  Press 1-5 to load Level 1-5 directly
  Press M to return to Main Menu
  Press G to give 999 shards (test HUD)
  Press I to toggle invincibility
  Press T to teleport player to mouse position
"""
	actions_text.add_theme_font_size_override("font_size", 14)
	actions_text.add_theme_color_override("font_color", Color.WHITE)
	_content.add_child(actions_text)


func _add_separator() -> void:
	"""Add a visual separator to the content."""
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 20)
	_content.add_child(sep)


func _add_key_row(key: String, action: String, description: String) -> void:
	"""Add a key binding row to the overlay."""
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Key label (fixed width)
	var key_label := Label.new()
	key_label.text = key
	key_label.custom_minimum_size.x = 100
	key_label.add_theme_font_size_override("font_size", 16)
	key_label.add_theme_color_override("font_color", Color.CYAN)
	row.add_child(key_label)
	
	# Action label (fixed width)
	var action_label := Label.new()
	action_label.text = action
	action_label.custom_minimum_size.x = 200
	action_label.add_theme_font_size_override("font_size", 14)
	action_label.add_theme_color_override("font_color", Color.WHITE)
	row.add_child(action_label)
	
	# Description label
	var desc_label := Label.new()
	desc_label.text = "- " + description
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	row.add_child(desc_label)
	
	_content.add_child(row)


func _get_game_state_text() -> String:
	"""Generate current game state text."""
	var lines: PackedStringArray = []
	
	# Game Manager state
	if _game_manager:
		var state_name := "UNKNOWN"
		match _game_manager.current_state:
			_game_manager.GameState.MENU:
				state_name = "MENU"
			_game_manager.GameState.PLAYING:
				state_name = "PLAYING"
			_game_manager.GameState.PAUSED:
				state_name = "PAUSED"
			_game_manager.GameState.TRANSITIONING:
				state_name = "TRANSITIONING"
			_game_manager.GameState.GAME_OVER:
				state_name = "GAME_OVER"
		
		lines.append("  Game State: %s" % state_name)
		lines.append("  Current Level: %s" % _game_manager.current_level.get_file() if _game_manager.current_level else "None")
		lines.append("  Shards: %d / %d" % [_game_manager.collected_shards, _game_manager.total_shards])
	else:
		lines.append("  GameManager: NOT FOUND")
	
	# Player info
	var player := _find_player()
	if player:
		lines.append("  Player Position: (%.0f, %.0f)" % [player.global_position.x, player.global_position.y])
		if "last_checkpoint" in player:
			lines.append("  Last Checkpoint: (%.0f, %.0f)" % [player.last_checkpoint.x, player.last_checkpoint.y])
		if "can_double_jump" in player:
			lines.append("  Can Double Jump: %s" % player.can_double_jump)
	else:
		lines.append("  Player: NOT FOUND")
	
	# Performance
	lines.append("  FPS: %.1f" % Engine.get_frames_per_second())
	lines.append("  Tree Paused: %s" % get_tree().paused)
	
	# Save data
	if _save_manager:
		var has_save: bool = _save_manager.has_save() as bool
		lines.append("  Save File Exists: %s" % has_save)
	
	return "\n".join(lines)


func _find_player() -> CharacterBody2D:
	"""Find the player node in the current scene."""
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0] is CharacterBody2D:
		return players[0]
	return null


func _process(delta: float) -> void:
	if not _is_visible:
		return
	
	# Update state display periodically
	_update_timer += delta
	if _update_timer >= UPDATE_INTERVAL:
		_update_timer = 0.0
		if _state_label:
			_state_label.text = _get_game_state_text()


func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	
	if not event is InputEventKey or not event.pressed:
		return
	
	var key_event := event as InputEventKey
	
	# F12 toggles the overlay
	if key_event.keycode == KEY_F12:
		_toggle_overlay()
		get_viewport().set_input_as_handled()
		return
	
	# Only process quick actions when overlay is visible
	if not _is_visible:
		return
	
	# Quick level loading (1-5)
	if key_event.keycode >= KEY_1 and key_event.keycode <= KEY_5:
		var level_index: int = key_event.keycode - KEY_1
		_load_level_quick(level_index)
		get_viewport().set_input_as_handled()
		return
	
	# M = Main Menu
	if key_event.keycode == KEY_M:
		_return_to_menu()
		get_viewport().set_input_as_handled()
		return
	
	# G = Give shards
	if key_event.keycode == KEY_G:
		_give_shards()
		get_viewport().set_input_as_handled()
		return
	
	# I = Toggle invincibility
	if key_event.keycode == KEY_I:
		_toggle_invincibility()
		get_viewport().set_input_as_handled()
		return
	
	# T = Teleport to mouse
	if key_event.keycode == KEY_T:
		_teleport_to_mouse()
		get_viewport().set_input_as_handled()
		return


func _toggle_overlay() -> void:
	"""Toggle the debug overlay visibility."""
	_is_visible = not _is_visible
	_overlay.visible = _is_visible
	
	if _is_visible:
		# Update state immediately when shown
		if _state_label:
			_state_label.text = _get_game_state_text()
		print("[DebugManager] Overlay opened")
	else:
		print("[DebugManager] Overlay closed")


func _load_level_quick(index: int) -> void:
	"""Quickly load a level by index (0-4)."""
	const LEVEL_PATHS: Array[String] = [
		"res://scenes/levels/level_01_awakening.tscn",
		"res://scenes/levels/level_02_fractured_paths.tscn",
		"res://scenes/levels/level_03_mirrors_edge.tscn",
		"res://scenes/levels/level_04_collapse.tscn",
		"res://scenes/levels/level_05_last_echo.tscn"
	]
	
	if index < 0 or index >= LEVEL_PATHS.size():
		print("[DebugManager] Invalid level index: %d" % index)
		return
	
	if _game_manager:
		print("[DebugManager] Loading Level %d..." % (index + 1))
		_toggle_overlay()  # Close overlay before loading
		_game_manager.load_level(LEVEL_PATHS[index], false)
	else:
		print("[DebugManager] GameManager not available")


func _return_to_menu() -> void:
	"""Return to main menu."""
	if _game_manager:
		print("[DebugManager] Returning to main menu...")
		_toggle_overlay()
		get_tree().paused = false  # Ensure unpaused
		_game_manager.change_state(_game_manager.GameState.MENU)
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	else:
		print("[DebugManager] GameManager not available")


func _give_shards() -> void:
	"""Give the player lots of shards for testing."""
	if _game_manager:
		_game_manager.collected_shards = 999
		print("[DebugManager] Gave 999 shards")
		
		# Emit event to update HUD
		if _events and _events.has_signal("shard_collected"):
			_events.shard_collected.emit(999, 999)
	else:
		print("[DebugManager] GameManager not available")


func _toggle_invincibility() -> void:
	"""Toggle player invincibility."""
	var player := _find_player()
	if player == null:
		print("[DebugManager] Player not found")
		return
	
	var health_component := player.get_node_or_null("HealthComponent")
	if health_component == null:
		print("[DebugManager] HealthComponent not found on player")
		return
	
	# Toggle invincibility by setting max_health very high or normal
	if health_component.max_health > 100:
		health_component.max_health = 1
		health_component.current_health = 1
		print("[DebugManager] Invincibility OFF (health reset to 1)")
	else:
		health_component.max_health = 99999
		health_component.current_health = 99999
		print("[DebugManager] Invincibility ON (health set to 99999)")


func _teleport_to_mouse() -> void:
	"""Teleport player to current mouse position."""
	var player := _find_player()
	if player == null:
		print("[DebugManager] Player not found")
		return
	
	var mouse_pos := player.get_global_mouse_position()
	player.global_position = mouse_pos
	print("[DebugManager] Teleported player to (%.0f, %.0f)" % [mouse_pos.x, mouse_pos.y])


## Check if the debug overlay is currently visible.
func is_overlay_visible() -> bool:
	return _is_visible


## Programmatically show the overlay.
func show_overlay() -> void:
	if not _is_visible:
		_toggle_overlay()


## Programmatically hide the overlay.
func hide_overlay() -> void:
	if _is_visible:
		_toggle_overlay()


## Print a summary of all available debug tools.
static func print_help() -> void:
	print("")
	print("=" .repeat(60))
	print("ECHOES OF THE VOID - DEBUG TOOLS")
	print("=" .repeat(60))
	print("")
	print("Available Debug Keys (in debug builds only):")
	print("")
	print("  F1          - Spawn Debugger (visualize spawn/checkpoints)")
	print("  F2          - Save Debugger (print save data)")
	print("  Shift+F2    - Reset Save Data")
	print("  F3          - Level Visualizer (show bounds/entities)")
	print("  Shift+F3    - Cycle Visualizer Mode")
	print("  F4          - Level Test Runner (automated tests)")
	print("  F5          - Flow Test Runner (game flow tests)")
	print("  F6          - Performance Profiler")
	print("  Shift+F6    - Reset Profiler Stats")
	print("  F12         - Debug Manager Overlay")
	print("")
	print("Quick Actions (when overlay is open):")
	print("  1-5         - Load Level 1-5")
	print("  M           - Return to Main Menu")
	print("  G           - Give 999 Shards")
	print("  I           - Toggle Invincibility")
	print("  T           - Teleport to Mouse")
	print("")
	print("=" .repeat(60))
