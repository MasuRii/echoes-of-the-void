extends Control
## Level select screen for Echoes of the Void.
## Shows all levels with completion status and lock states.

# Level data structure - defines all levels in order
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
var _game_manager: Node = null
var _audio_manager: Node = null

# Node references
@onready var level_grid: GridContainer = $CenterContainer/VBoxContainer/LevelGrid
@onready var back_button: Button = $CenterContainer/VBoxContainer/BackButton

# Template button to clone
var _button_template: Button = null


func _ready() -> void:
	# Get autoload references
	_save_manager = get_node_or_null("/root/SaveManager")
	_game_manager = get_node_or_null("/root/GameManager")
	_audio_manager = get_node_or_null("/root/AudioManager")
	
	# Connect back button
	back_button.pressed.connect(_on_back_pressed)
	back_button.mouse_entered.connect(_on_button_hovered)
	back_button.focus_entered.connect(_on_button_hovered)
	
	# Create level buttons
	_create_level_buttons()
	
	# Give focus to first unlocked level
	_focus_first_unlocked()


func _create_level_buttons() -> void:
	"""Generate buttons for each level with status indicators."""
	for i in range(LEVELS.size()):
		var level_data: Dictionary = LEVELS[i]
		var level_button: PanelContainer = _create_level_panel(i + 1, level_data)
		level_grid.add_child(level_button)


func _create_level_panel(level_number: int, level_data: Dictionary) -> PanelContainer:
	"""Create a single level panel with name, number, and stats."""
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 140)
	
	# Check if level is unlocked
	var is_unlocked: bool = _is_level_unlocked(level_data.path)
	
	# Create VBox for content
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(vbox)
	
	# Add margin
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(margin)
	
	var content_vbox := VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 6)
	margin.add_child(content_vbox)
	
	# Level number and name
	var title_label := Label.new()
	title_label.text = "%d. %s" % [level_number, level_data.name]
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	if is_unlocked:
		title_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0, 1.0))
	else:
		title_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5, 1.0))
	content_vbox.add_child(title_label)
	
	# Stats section
	var stats_container := VBoxContainer.new()
	stats_container.add_theme_constant_override("separation", 2)
	content_vbox.add_child(stats_container)
	
	if is_unlocked:
		# Show collected shards
		var best_shards: int = 0
		if _save_manager:
			best_shards = _save_manager.get_best_shards(level_data.path)
		
		var shards_label := Label.new()
		shards_label.text = "Shards: %d / %d" % [best_shards, level_data.shards]
		shards_label.add_theme_font_size_override("font_size", 14)
		shards_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8, 1.0))
		shards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_container.add_child(shards_label)
		
		# Show best time if available
		var best_time: float = -1.0
		if _save_manager:
			best_time = _save_manager.get_best_time(level_data.path)
		
		if best_time > 0.0:
			var time_label := Label.new()
			time_label.text = "Best: %s" % _format_time(best_time)
			time_label.add_theme_font_size_override("font_size", 14)
			time_label.add_theme_color_override("font_color", Color(0.0, 0.9, 0.8, 1.0))  # Teal for time
			time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			stats_container.add_child(time_label)
		
		# Show crystal status with visual indicators
		var crystals_hbox := HBoxContainer.new()
		crystals_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		crystals_hbox.add_theme_constant_override("separation", 4)
		stats_container.add_child(crystals_hbox)
		
		var crystals_label := Label.new()
		crystals_label.text = "Crystals: "
		crystals_label.add_theme_font_size_override("font_size", 14)
		crystals_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8, 1.0))
		crystals_hbox.add_child(crystals_label)
		
		# Get collected crystals for this level
		var collected_crystals: Array = []
		if _save_manager:
			collected_crystals = _save_manager.get_collected_crystals(level_data.path)
		
		for j in range(level_data.crystals):
			var crystal_icon := Label.new()
			if j < collected_crystals.size():
				crystal_icon.text = "[*]"
				crystal_icon.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0, 1.0))
			else:
				crystal_icon.text = "[ ]"
				crystal_icon.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6, 1.0))
			crystal_icon.add_theme_font_size_override("font_size", 14)
			crystals_hbox.add_child(crystal_icon)
	else:
		# Show locked message
		var lock_label := Label.new()
		lock_label.text = "LOCKED"
		lock_label.add_theme_font_size_override("font_size", 16)
		lock_label.add_theme_color_override("font_color", Color(0.5, 0.3, 0.3, 1.0))
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_container.add_child(lock_label)
	
	# Add spacer
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(spacer)
	
	# Play button
	var play_button := Button.new()
	play_button.text = "PLAY" if is_unlocked else "---"
	play_button.custom_minimum_size = Vector2(100, 36)
	play_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play_button.add_theme_font_size_override("font_size", 16)
	play_button.disabled = not is_unlocked
	
	if is_unlocked:
		play_button.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0, 1.0))
		play_button.add_theme_color_override("font_hover_color", Color(0.0, 1.0, 1.0, 1.0))
		play_button.add_theme_color_override("font_focus_color", Color(0.0, 1.0, 1.0, 1.0))
		play_button.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
		play_button.pressed.connect(_on_level_selected.bind(level_data.path))
		play_button.mouse_entered.connect(_on_button_hovered)
		play_button.focus_entered.connect(_on_button_hovered)
	else:
		play_button.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4, 1.0))
	
	# Store button reference for focus navigation
	play_button.set_meta("level_path", level_data.path)
	play_button.set_meta("is_unlocked", is_unlocked)
	
	content_vbox.add_child(play_button)
	
	return panel


func _is_level_unlocked(level_path: String) -> bool:
	"""Check if a level is unlocked."""
	# First level is always unlocked
	if level_path == LEVELS[0].path:
		return true
	
	if _save_manager:
		return _save_manager.is_level_unlocked(level_path)
	
	return false


func _focus_first_unlocked() -> void:
	"""Give focus to the first unlocked level's play button."""
	# Find all play buttons in the grid
	for panel in level_grid.get_children():
		if panel is PanelContainer:
			var button := _find_play_button(panel)
			if button and button.has_meta("is_unlocked") and button.get_meta("is_unlocked"):
				button.grab_focus()
				return
	
	# Fallback to back button
	back_button.grab_focus()


func _find_play_button(node: Node) -> Button:
	"""Recursively find the play button in a panel."""
	for child in node.get_children():
		if child is Button:
			return child
		var found := _find_play_button(child)
		if found:
			return found
	return null


func _on_level_selected(level_path: String) -> void:
	"""Load the selected level."""
	_play_confirm_sound()
	
	if _game_manager:
		_game_manager.load_level(level_path)


func _on_back_pressed() -> void:
	"""Return to main menu or close overlay."""
	_play_confirm_sound()
	
	# If opened as overlay (has parent that's main menu), just close self
	var parent := get_parent()
	if parent and parent.name == "MainMenu":
		queue_free()
	else:
		# Standalone scene - go to main menu
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_button_hovered() -> void:
	"""Play hover sound when a button is hovered or focused."""
	if _audio_manager:
		_audio_manager.play_sfx("menu_select", -5.0)


func _play_confirm_sound() -> void:
	"""Play button confirm sound."""
	if _audio_manager:
		_audio_manager.play_sfx("menu_confirm")


func _unhandled_input(event: InputEvent) -> void:
	"""Handle escape to go back."""
	if event.is_action_pressed("pause"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()


## Format time in seconds to MM:SS.ms format for speedrun display.
func _format_time(time_seconds: float) -> String:
	var minutes: int = int(time_seconds) / 60
	var seconds: int = int(time_seconds) % 60
	var milliseconds: int = int((time_seconds - int(time_seconds)) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, milliseconds]
