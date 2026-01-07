extends Control
## Game complete screen for Echoes of the Void.
## Displays total stats after completing all levels and provides final options.

# Path constants
const MAIN_MENU_PATH: String = "res://scenes/ui/main_menu.tscn"

# Level data for calculating totals (mirrored from level_select.gd)
const LEVELS: Array[Dictionary] = [
	{
		"name": "Awakening",
		"path": "res://scenes/levels/level_01_awakening.tscn",
		"shards": 5,
		"crystals": 1
	},
	{
		"name": "Fractured Paths",
		"path": "res://scenes/levels/level_02_fractured_paths.tscn",
		"shards": 7,
		"crystals": 1
	},
	{
		"name": "Mirror's Edge",
		"path": "res://scenes/levels/level_03_mirrors_edge.tscn",
		"shards": 10,
		"crystals": 2
	},
	{
		"name": "Collapse",
		"path": "res://scenes/levels/level_04_collapse.tscn",
		"shards": 12,
		"crystals": 2
	},
	{
		"name": "The Last Echo",
		"path": "res://scenes/levels/level_05_last_echo.tscn",
		"shards": 15,
		"crystals": 3
	}
]

# Cached autoload references
var _save_manager: Node = null
var _audio_manager: Node = null
var _game_manager: Node = null

# Total stats across all levels
var _total_shards_collected: int = 0
var _total_shards_available: int = 0
var _total_crystals_collected: int = 0
var _total_crystals_available: int = 0

# Node references
@onready var header_label: Label = $PanelContainer/VBoxContainer/HeaderLabel
@onready var subtitle_label: Label = $PanelContainer/VBoxContainer/SubtitleLabel
@onready var total_shards_label: Label = $PanelContainer/VBoxContainer/StatsContainer/TotalShardsLabel
@onready var total_crystals_label: Label = $PanelContainer/VBoxContainer/StatsContainer/TotalCrystalsLabel
@onready var completion_label: Label = $PanelContainer/VBoxContainer/StatsContainer/CompletionLabel
@onready var main_menu_button: Button = $PanelContainer/VBoxContainer/ButtonContainer/MainMenuButton
@onready var credits_button: Button = $PanelContainer/VBoxContainer/ButtonContainer/CreditsButton


func _ready() -> void:
	# This screen should work even when the game is paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Get autoload references
	_save_manager = get_node_or_null("/root/SaveManager")
	_audio_manager = get_node_or_null("/root/AudioManager")
	_game_manager = get_node_or_null("/root/GameManager")
	
	# Connect button signals
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	
	# Connect hover sounds to all buttons
	for button in [main_menu_button, credits_button]:
		button.mouse_entered.connect(_on_button_hovered)
		button.focus_entered.connect(_on_button_hovered)
	
	# Calculate total stats
	_calculate_total_stats()
	
	# Update display
	_update_display()
	
	# Pause the game
	get_tree().paused = true
	
	# Set initial focus
	main_menu_button.grab_focus()
	
	# Play game complete music
	if _audio_manager:
		_audio_manager.play_music("game_complete")


func _calculate_total_stats() -> void:
	"""Calculate total stats from all levels."""
	_total_shards_available = 0
	_total_crystals_available = 0
	_total_shards_collected = 0
	_total_crystals_collected = 0
	
	for level_data in LEVELS:
		_total_shards_available += level_data.shards
		_total_crystals_available += level_data.crystals
		
		if _save_manager:
			# Get best shards for this level
			_total_shards_collected += _save_manager.get_best_shards(level_data.path)
			
			# Get collected crystals for this level
			var crystals: Array = _save_manager.get_collected_crystals(level_data.path)
			_total_crystals_collected += crystals.size()


func _update_display() -> void:
	"""Update the UI elements with total stats."""
	# Check for 100% completion
	var is_perfect: bool = (_total_shards_collected >= _total_shards_available and 
		_total_crystals_collected >= _total_crystals_available)
	
	# Header
	if header_label:
		if is_perfect:
			header_label.text = "PERFECT COMPLETION"
			header_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0, 1.0))  # Gold
		else:
			header_label.text = "ECHOES SILENCED"
	
	# Subtitle
	if subtitle_label:
		if is_perfect:
			subtitle_label.text = "You have conquered the void completely."
		else:
			subtitle_label.text = "The void grows quiet... for now."
	
	# Total shards
	if total_shards_label:
		total_shards_label.text = "Total Shards: %d / %d" % [_total_shards_collected, _total_shards_available]
	
	# Total crystals
	if total_crystals_label:
		total_crystals_label.text = "Total Crystals: %d / %d" % [_total_crystals_collected, _total_crystals_available]
	
	# Completion percentage
	if completion_label:
		var total_items: int = _total_shards_available + _total_crystals_available
		var collected_items: int = _total_shards_collected + _total_crystals_collected
		var percentage: float = 0.0
		if total_items > 0:
			percentage = (float(collected_items) / float(total_items)) * 100.0
		
		completion_label.text = "Completion: %.0f%%" % percentage
		
		# Color based on completion
		if is_perfect:
			completion_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0, 1.0))  # Gold
		elif percentage >= 75.0:
			completion_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.5, 1.0))  # Green
		elif percentage >= 50.0:
			completion_label.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0, 1.0))  # Cyan


func _on_main_menu_pressed() -> void:
	"""Return to main menu."""
	_play_confirm_sound()
	
	# Small delay to hear the confirm sound
	await get_tree().create_timer(0.1).timeout
	
	# Unpause and change scene
	get_tree().paused = false
	
	if _game_manager:
		_game_manager.change_state(_game_manager.GameState.MENU)
	
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func _on_credits_pressed() -> void:
	"""Show credits (simple version - just display in label for now)."""
	_play_confirm_sound()
	
	# For this simple implementation, show credits in the subtitle area
	if subtitle_label:
		subtitle_label.text = "Created with Godot 4.5.1\n\nThank you for playing!"
	
	# Hide the credits button after showing
	credits_button.visible = false


func _on_button_hovered() -> void:
	"""Play hover sound when a button is hovered or focused."""
	if _audio_manager:
		_audio_manager.play_sfx("menu_select", -5.0)


func _play_confirm_sound() -> void:
	"""Play button confirm sound."""
	if _audio_manager:
		_audio_manager.play_sfx("menu_confirm")
