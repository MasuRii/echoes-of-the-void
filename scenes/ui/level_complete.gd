extends Control
## Level complete screen for Echoes of the Void.
## Displays stats after completing a level and provides navigation options.

# Path constants
const MAIN_MENU_PATH: String = "res://scenes/ui/main_menu.tscn"
const LEVEL_SELECT_PATH: String = "res://scenes/ui/level_select.tscn"
const GAME_COMPLETE_PATH: String = "res://scenes/ui/game_complete.tscn"

# Cached references to autoloads
var _game_manager: Node = null
var _audio_manager: Node = null
var _save_manager: Node = null

# Level data
var _level_name: String = ""
var _next_level_path: String = ""
var _shards_collected: int = 0
var _total_shards: int = 0
var _crystals_collected: int = 0
var _total_crystals: int = 3
var _completion_time: float = 0.0

# Node references
@onready var header_label: Label = $PanelContainer/VBoxContainer/HeaderLabel
@onready var shards_label: Label = $PanelContainer/VBoxContainer/StatsContainer/ShardsLabel
@onready var crystals_label: Label = $PanelContainer/VBoxContainer/StatsContainer/CrystalsLabel
@onready var time_label: Label = $PanelContainer/VBoxContainer/StatsContainer/TimeLabel
@onready var crystal_indicators: HBoxContainer = $PanelContainer/VBoxContainer/StatsContainer/CrystalIndicators
@onready var next_level_button: Button = $PanelContainer/VBoxContainer/ButtonContainer/NextLevelButton
@onready var replay_button: Button = $PanelContainer/VBoxContainer/ButtonContainer/ReplayButton
@onready var level_select_button: Button = $PanelContainer/VBoxContainer/ButtonContainer/LevelSelectButton


func _ready() -> void:
	# This screen should work even when the game is paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Get autoload references
	_game_manager = get_node_or_null("/root/GameManager")
	_audio_manager = get_node_or_null("/root/AudioManager")
	_save_manager = get_node_or_null("/root/SaveManager")
	
	# Connect button signals
	next_level_button.pressed.connect(_on_next_level_pressed)
	replay_button.pressed.connect(_on_replay_pressed)
	level_select_button.pressed.connect(_on_level_select_pressed)
	
	# Connect hover sounds to all buttons
	for button in [next_level_button, replay_button, level_select_button]:
		button.mouse_entered.connect(_on_button_hovered)
		button.focus_entered.connect(_on_button_hovered)
	
	# Get data from GameManager
	_load_level_data()
	
	# Update display
	_update_display()
	
	# Pause the game
	get_tree().paused = true
	
	# Set initial focus
	if _next_level_path.is_empty():
		# Last level - show game complete screen instead
		_show_game_complete()
		return
	else:
		next_level_button.grab_focus()
	
	# Play victory sound
	if _audio_manager:
		_audio_manager.play_music("victory")


func _load_level_data() -> void:
	"""Load level stats from GameManager."""
	if _game_manager:
		_shards_collected = _game_manager.collected_shards
		_total_shards = _game_manager.total_shards
		_crystals_collected = _game_manager.collected_crystals.size()
	
	# Get level-specific data from parent level scene
	var level_base := _find_level_base()
	if level_base:
		_level_name = level_base.level_name
		_next_level_path = level_base.next_level
		_total_crystals = level_base.crystal_count


func _find_level_base() -> Node:
	"""Find the LevelBase node in the scene tree."""
	# Walk up the tree to find a LevelBase
	var parent := get_parent()
	while parent:
		if parent is LevelBase:
			return parent
		parent = parent.get_parent()
	
	# Try to find in main scene
	var root := get_tree().current_scene
	if root is LevelBase:
		return root
	
	return null


func _update_display() -> void:
	"""Update the UI elements with current stats."""
	# Header
	if header_label:
		header_label.text = "LEVEL COMPLETE"
	
	# Shards
	if shards_label:
		shards_label.text = "Shards: %d / %d" % [_shards_collected, _total_shards]
	
	# Crystals
	if crystals_label:
		crystals_label.text = "Crystals: %d / %d" % [_crystals_collected, _total_crystals]
	
	# Time
	if time_label:
		time_label.text = "Time: %s" % _format_time(_completion_time)
	
	# Update crystal indicators
	_update_crystal_indicators()


func _update_crystal_indicators() -> void:
	"""Update the visual crystal indicators."""
	if crystal_indicators == null:
		return
	
	for i in range(crystal_indicators.get_child_count()):
		var indicator := crystal_indicators.get_child(i) as TextureRect
		if indicator:
			if i < _crystals_collected:
				# Collected - bright cyan
				indicator.modulate = Color(0.0, 1.0, 1.0, 1.0)
			else:
				# Not collected - dim gray
				indicator.modulate = Color(0.3, 0.3, 0.3, 0.5)


func _on_next_level_pressed() -> void:
	"""Load the next level."""
	_play_confirm_sound()
	
	if _next_level_path.is_empty():
		# No next level - shouldn't happen if button is visible
		return
	
	# Validate next level path exists before attempting to load
	if not ResourceLoader.exists(_next_level_path):
		push_error("LevelComplete: Next level scene does not exist: %s" % _next_level_path)
		# Fall back to level select or main menu
		_on_level_select_pressed()
		return
	
	# Small delay to hear the confirm sound
	await get_tree().create_timer(0.1).timeout
	
	# Unpause and load next level
	get_tree().paused = false
	
	if _game_manager:
		_game_manager.load_level(_next_level_path)
	else:
		get_tree().change_scene_to_file(_next_level_path)


func _on_replay_pressed() -> void:
	"""Restart the current level."""
	_play_confirm_sound()
	
	# Small delay to hear the confirm sound
	await get_tree().create_timer(0.1).timeout
	
	# Unpause and restart
	get_tree().paused = false
	
	if _game_manager:
		_game_manager.restart_level()
	
	queue_free()


func _on_level_select_pressed() -> void:
	"""Return to level select screen."""
	_play_confirm_sound()
	
	# Small delay to hear the confirm sound
	await get_tree().create_timer(0.1).timeout
	
	# Unpause and change scene
	get_tree().paused = false
	
	if _game_manager:
		_game_manager.change_state(_game_manager.GameState.MENU)
	
	# Check if level select exists, otherwise go to main menu
	if ResourceLoader.exists(LEVEL_SELECT_PATH):
		get_tree().change_scene_to_file(LEVEL_SELECT_PATH)
	else:
		get_tree().change_scene_to_file(MAIN_MENU_PATH)


func _on_button_hovered() -> void:
	"""Play hover sound when a button is hovered or focused."""
	if _audio_manager:
		_audio_manager.play_sfx("menu_select", -5.0)


func _play_confirm_sound() -> void:
	"""Play button confirm sound."""
	if _audio_manager:
		_audio_manager.play_sfx("menu_confirm")


func _show_game_complete() -> void:
	"""Show game complete screen instead of level complete for the final level."""
	# Hide this screen
	visible = false
	
	# Load and show game complete screen
	var game_complete_scene: PackedScene = load(GAME_COMPLETE_PATH)
	if game_complete_scene:
		var game_complete: Control = game_complete_scene.instantiate()
		get_parent().add_child(game_complete)
	
	# Free this level complete screen
	queue_free()


## Set level completion data manually (alternative to auto-detection).
func set_completion_data(level_name: String, next_level: String, 
		shards_collected: int, total_shards: int,
		crystals_collected: int, total_crystals: int) -> void:
	_level_name = level_name
	_next_level_path = next_level
	_shards_collected = shards_collected
	_total_shards = total_shards
	_crystals_collected = crystals_collected
	_total_crystals = total_crystals
	_update_display()
	
	# Update button visibility
	next_level_button.visible = not _next_level_path.is_empty()


## Set the completion time for display.
func set_completion_time(time_seconds: float) -> void:
	_completion_time = time_seconds
	if time_label:
		time_label.text = "Time: %s" % _format_time(_completion_time)


## Format time in seconds to MM:SS.ms format for speedrun display.
func _format_time(time_seconds: float) -> String:
	var minutes: int = int(time_seconds) / 60
	var seconds: int = int(time_seconds) % 60
	var milliseconds: int = int((time_seconds - int(time_seconds)) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, milliseconds]
