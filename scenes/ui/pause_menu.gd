extends Control
## Pause menu for Echoes of the Void.
## Displayed when the game is paused. Allows resuming, restarting, settings, or returning to menu.

# Cached references to autoloads
var _game_manager: Node = null
var _audio_manager: Node = null

# Button references
@onready var resume_button: Button = $PanelContainer/VBoxContainer/MenuButtons/ResumeButton
@onready var restart_button: Button = $PanelContainer/VBoxContainer/MenuButtons/RestartButton
@onready var settings_button: Button = $PanelContainer/VBoxContainer/MenuButtons/SettingsButton
@onready var main_menu_button: Button = $PanelContainer/VBoxContainer/MenuButtons/MainMenuButton

# Main menu path constant
const MAIN_MENU_PATH: String = "res://scenes/ui/main_menu.tscn"


func _ready() -> void:
	# This menu should work even when the game is paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Get autoload references
	_game_manager = get_node_or_null("/root/GameManager")
	_audio_manager = get_node_or_null("/root/AudioManager")
	
	# Connect button signals
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	
	# Connect hover sounds to all buttons
	for button in [resume_button, restart_button, settings_button, main_menu_button]:
		button.mouse_entered.connect(_on_button_hovered)
		button.focus_entered.connect(_on_button_hovered)
	
	# Set initial focus to resume button
	resume_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	# Allow unpausing with the pause action
	if event.is_action_pressed("pause"):
		_on_resume_pressed()
		get_viewport().set_input_as_handled()


func _on_resume_pressed() -> void:
	"""Resume the game and hide the pause menu."""
	_play_confirm_sound()
	
	if _game_manager:
		_game_manager.change_state(_game_manager.GameState.PLAYING)
	
	# Hide and free this menu
	queue_free()


func _on_restart_pressed() -> void:
	"""Restart the current level."""
	_play_confirm_sound()
	
	# Small delay to hear the confirm sound
	await get_tree().create_timer(0.1).timeout
	
	if _game_manager:
		_game_manager.restart_level()
	
	# Free the pause menu
	queue_free()


func _on_settings_pressed() -> void:
	"""Open the settings menu."""
	_play_confirm_sound()
	
	# Load and display the settings menu
	var settings_scene: PackedScene = load("res://scenes/ui/settings_menu.tscn")
	if settings_scene:
		var settings_menu: Control = settings_scene.instantiate()
		add_child(settings_menu)
	else:
		push_error("PauseMenu: Failed to load settings_menu.tscn")


func _on_main_menu_pressed() -> void:
	"""Return to the main menu."""
	_play_confirm_sound()
	
	# Small delay to hear the confirm sound
	await get_tree().create_timer(0.1).timeout
	
	# Unpause the game before changing scenes
	get_tree().paused = false
	
	if _game_manager:
		_game_manager.change_state(_game_manager.GameState.MENU)
	
	var error := get_tree().change_scene_to_file(MAIN_MENU_PATH)
	if error != OK:
		push_error("PauseMenu: Failed to load main menu: %s" % MAIN_MENU_PATH)


func _on_button_hovered() -> void:
	"""Play hover sound when a button is hovered or focused."""
	if _audio_manager:
		_audio_manager.play_sfx("menu_select", -5.0)


func _play_confirm_sound() -> void:
	"""Play button confirm sound."""
	if _audio_manager:
		_audio_manager.play_sfx("menu_confirm")
