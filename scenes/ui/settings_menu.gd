extends Control
## Settings menu for Echoes of the Void.
## Allows adjusting audio, video, and viewing control bindings.
## Settings are saved automatically when changed.

# Cached references to autoloads
var _audio_manager: Node = null
var _save_manager: Node = null

# Audio slider references
@onready var master_slider: HSlider = $CenterContainer/VBoxContainer/SettingsContainer/AudioSection/MasterVolume/Slider
@onready var master_value_label: Label = $CenterContainer/VBoxContainer/SettingsContainer/AudioSection/MasterVolume/ValueLabel
@onready var music_slider: HSlider = $CenterContainer/VBoxContainer/SettingsContainer/AudioSection/MusicVolume/Slider
@onready var music_value_label: Label = $CenterContainer/VBoxContainer/SettingsContainer/AudioSection/MusicVolume/ValueLabel
@onready var sfx_slider: HSlider = $CenterContainer/VBoxContainer/SettingsContainer/AudioSection/SFXVolume/Slider
@onready var sfx_value_label: Label = $CenterContainer/VBoxContainer/SettingsContainer/AudioSection/SFXVolume/ValueLabel

# Video toggle references
@onready var fullscreen_checkbox: CheckBox = $CenterContainer/VBoxContainer/SettingsContainer/VideoSection/FullscreenToggle/CheckBox
@onready var vsync_checkbox: CheckBox = $CenterContainer/VBoxContainer/SettingsContainer/VideoSection/VSyncToggle/CheckBox
@onready var screen_shake_checkbox: CheckBox = $CenterContainer/VBoxContainer/SettingsContainer/VideoSection/ScreenShakeToggle/CheckBox

# Back button reference
@onready var back_button: Button = $CenterContainer/VBoxContainer/BackButton

# Track if we're initializing (to avoid triggering save during setup)
var _initializing: bool = true


func _ready() -> void:
	# This menu should work even when the game is paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Get autoload references
	_audio_manager = get_node_or_null("/root/AudioManager")
	_save_manager = get_node_or_null("/root/SaveManager")
	
	# Connect slider signals
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	
	# Connect checkbox signals
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	vsync_checkbox.toggled.connect(_on_vsync_toggled)
	screen_shake_checkbox.toggled.connect(_on_screen_shake_toggled)
	
	# Connect back button
	back_button.pressed.connect(_on_back_pressed)
	
	# Connect hover sounds to interactive elements
	_connect_hover_sounds()
	
	# Load current settings into UI
	_load_settings()
	
	# Set initial focus
	master_slider.grab_focus()
	
	# Done initializing
	_initializing = false


func _unhandled_input(event: InputEvent) -> void:
	# Allow closing settings with pause/escape action
	if event.is_action_pressed("pause"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()


func _connect_hover_sounds() -> void:
	"""Connect hover/focus sounds to all interactive elements."""
	var interactive_elements: Array[Control] = [
		master_slider, music_slider, sfx_slider,
		fullscreen_checkbox, vsync_checkbox, screen_shake_checkbox,
		back_button
	]
	
	for element in interactive_elements:
		element.mouse_entered.connect(_on_element_hovered)
		element.focus_entered.connect(_on_element_hovered)


func _load_settings() -> void:
	"""Load current settings from SaveManager and AudioManager into UI."""
	# Audio settings
	if _audio_manager:
		master_slider.value = _audio_manager.get_master_volume() * 100.0
		music_slider.value = _audio_manager.get_music_volume() * 100.0
		sfx_slider.value = _audio_manager.get_sfx_volume() * 100.0
	elif _save_manager:
		# Fallback to save manager if audio manager not available
		master_slider.value = _save_manager.get_setting("master_volume", 1.0) * 100.0
		music_slider.value = _save_manager.get_setting("music_volume", 0.8) * 100.0
		sfx_slider.value = _save_manager.get_setting("sfx_volume", 1.0) * 100.0
	
	# Update value labels
	_update_volume_label(master_value_label, master_slider.value)
	_update_volume_label(music_value_label, music_slider.value)
	_update_volume_label(sfx_value_label, sfx_slider.value)
	
	# Video settings
	if _save_manager:
		fullscreen_checkbox.button_pressed = _save_manager.get_setting("fullscreen", false)
		vsync_checkbox.button_pressed = _save_manager.get_setting("vsync", true)
		screen_shake_checkbox.button_pressed = _save_manager.get_setting("screen_shake", true)
	else:
		# Default values
		fullscreen_checkbox.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		vsync_checkbox.button_pressed = true
		screen_shake_checkbox.button_pressed = true


func _update_volume_label(label: Label, value: float) -> void:
	"""Update a volume label to show the current percentage."""
	label.text = "%d%%" % int(value)


# ============================================================
# Audio Callbacks
# ============================================================

func _on_master_volume_changed(value: float) -> void:
	"""Handle master volume slider change."""
	_update_volume_label(master_value_label, value)
	
	if _initializing:
		return
	
	var linear_value: float = value / 100.0
	if _audio_manager:
		_audio_manager.set_master_volume(linear_value)


func _on_music_volume_changed(value: float) -> void:
	"""Handle music volume slider change."""
	_update_volume_label(music_value_label, value)
	
	if _initializing:
		return
	
	var linear_value: float = value / 100.0
	if _audio_manager:
		_audio_manager.set_music_volume(linear_value)


func _on_sfx_volume_changed(value: float) -> void:
	"""Handle SFX volume slider change."""
	_update_volume_label(sfx_value_label, value)
	
	if _initializing:
		return
	
	var linear_value: float = value / 100.0
	if _audio_manager:
		_audio_manager.set_sfx_volume(linear_value)
	
	# Play a test sound so user can hear the change
	if _audio_manager and not _initializing:
		_audio_manager.play_sfx("menu_select", -5.0)


# ============================================================
# Video Callbacks
# ============================================================

func _on_fullscreen_toggled(pressed: bool) -> void:
	"""Handle fullscreen toggle."""
	if _initializing:
		return
	
	_play_confirm_sound()
	
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	if _save_manager:
		_save_manager.set_setting("fullscreen", pressed)


func _on_vsync_toggled(pressed: bool) -> void:
	"""Handle VSync toggle."""
	if _initializing:
		return
	
	_play_confirm_sound()
	
	if pressed:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	if _save_manager:
		_save_manager.set_setting("vsync", pressed)


func _on_screen_shake_toggled(pressed: bool) -> void:
	"""Handle screen shake toggle."""
	if _initializing:
		return
	
	_play_confirm_sound()
	
	if _save_manager:
		_save_manager.set_setting("screen_shake", pressed)


# ============================================================
# Navigation
# ============================================================

func _on_back_pressed() -> void:
	"""Close the settings menu and return to previous menu."""
	_play_confirm_sound()
	
	# Small delay to hear the confirm sound
	await get_tree().create_timer(0.1).timeout
	
	# Remove this menu
	queue_free()


func _on_element_hovered() -> void:
	"""Play hover sound when an element is hovered or focused."""
	if _audio_manager and not _initializing:
		_audio_manager.play_sfx("menu_select", -8.0)


func _play_confirm_sound() -> void:
	"""Play button confirm sound."""
	if _audio_manager:
		_audio_manager.play_sfx("menu_confirm")
