extends Control
## Main menu for Echoes of the Void.
## Handles navigation to game, settings, level select, and exit.

# Cached references to autoloads
var _game_manager: Node = null
var _save_manager: Node = null
var _audio_manager: Node = null

# Button references
@onready var new_game_button: Button = $CenterContainer/VBoxContainer/MenuButtons/NewGameButton
@onready var continue_button: Button = $CenterContainer/VBoxContainer/MenuButtons/ContinueButton
@onready var level_select_button: Button = $CenterContainer/VBoxContainer/MenuButtons/LevelSelectButton
@onready var settings_button: Button = $CenterContainer/VBoxContainer/MenuButtons/SettingsButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/MenuButtons/QuitButton

# First level path constant
const FIRST_LEVEL: String = "res://scenes/levels/level_01_awakening.tscn"


func _ready() -> void:
	# Get autoload references
	_game_manager = get_node_or_null("/root/GameManager")
	_save_manager = get_node_or_null("/root/SaveManager")
	_audio_manager = get_node_or_null("/root/AudioManager")
	
	# Connect button signals
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	level_select_button.pressed.connect(_on_level_select_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Connect hover sounds to all buttons
	for button in [new_game_button, continue_button, level_select_button, settings_button, quit_button]:
		button.mouse_entered.connect(_on_button_hovered)
		button.focus_entered.connect(_on_button_hovered)
	
	# Update continue button visibility based on save data
	_update_continue_button()
	
	# Set initial focus to first button
	if continue_button.visible:
		continue_button.grab_focus()
	else:
		new_game_button.grab_focus()
	
	# Play menu music
	if _audio_manager:
		_audio_manager.play_music("main_menu", 2.0)
	
	# Set game state to menu
	if _game_manager:
		_game_manager.change_state(_game_manager.GameState.MENU)


func _update_continue_button() -> void:
	"""Show/hide continue button based on whether a save exists."""
	if _save_manager and _save_manager.has_save():
		continue_button.visible = true
	else:
		continue_button.visible = false


func _on_new_game_pressed() -> void:
	"""Start a new game from level 1."""
	_play_confirm_sound()
	
	# Optionally reset save data for a true "new game"
	# For now, just start level 1
	if _game_manager:
		_game_manager.load_level(FIRST_LEVEL)


func _on_continue_pressed() -> void:
	"""Continue from the latest unlocked level."""
	_play_confirm_sound()
	
	if _save_manager and _game_manager:
		var unlocked_levels: Array = _save_manager.get_unlocked_levels()
		if unlocked_levels.size() > 0:
			# Load the last unlocked level (most recent progress)
			var last_level: String = unlocked_levels[unlocked_levels.size() - 1]
			_game_manager.load_level(last_level)
		else:
			# Fallback to first level
			_game_manager.load_level(FIRST_LEVEL)


func _on_level_select_pressed() -> void:
	"""Open the level select screen."""
	_play_confirm_sound()
	# TODO: Implement level select screen transition
	# For now, this is a placeholder
	push_warning("MainMenu: Level Select not yet implemented")


func _on_settings_pressed() -> void:
	"""Open the settings menu."""
	_play_confirm_sound()
	
	# Load and display the settings menu
	var settings_scene: PackedScene = load("res://scenes/ui/settings_menu.tscn")
	if settings_scene:
		var settings_menu: Control = settings_scene.instantiate()
		add_child(settings_menu)
	else:
		push_error("MainMenu: Failed to load settings_menu.tscn")


func _on_quit_pressed() -> void:
	"""Exit the game."""
	_play_confirm_sound()
	
	# Small delay to hear the confirm sound
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()


func _on_button_hovered() -> void:
	"""Play hover sound when a button is hovered or focused."""
	if _audio_manager:
		_audio_manager.play_sfx("menu_select", -5.0)


func _play_confirm_sound() -> void:
	"""Play button confirm sound."""
	if _audio_manager:
		_audio_manager.play_sfx("menu_confirm")
