extends Node
## Debug tool for visualizing and testing the save system.
## Toggle save info display with F2, reset save with Shift+F2.
## Add to any scene or as an autoload for debugging.
class_name SaveDebugger

# Debug display state
var _debug_visible: bool = false

# Reference to debug label (created dynamically)
var _debug_label: Label = null
var _canvas_layer: CanvasLayer = null


func _ready() -> void:
	# Only enable in debug builds
	if not OS.is_debug_build():
		set_process_input(false)
		return
	
	_create_debug_ui()
	print("SaveDebugger: Ready - Press F2 to show save data, Shift+F2 to reset save")


func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F2:
			if event.shift_pressed:
				# Shift+F2: Reset save file
				_reset_save_file()
			else:
				# F2: Toggle save data display
				_toggle_debug_display()


func _process(_delta: float) -> void:
	if _debug_visible and _debug_label != null:
		_update_debug_display()


func _create_debug_ui() -> void:
	"""Create the debug UI overlay."""
	# Create canvas layer for HUD overlay
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 100  # On top of everything
	add_child(_canvas_layer)
	
	# Create background panel
	var panel := PanelContainer.new()
	panel.name = "SaveDebugPanel"
	panel.visible = false
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.position = Vector2(-420, 10)
	panel.custom_minimum_size = Vector2(400, 300)
	
	# Style the panel with semi-transparent background
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.85)
	style.border_color = Color(0.0, 1.0, 1.0, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	_canvas_layer.add_child(panel)
	
	# Create label for save data display
	_debug_label = Label.new()
	_debug_label.name = "SaveDataLabel"
	_debug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_debug_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_debug_label.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0))
	_debug_label.add_theme_font_size_override("font_size", 12)
	panel.add_child(_debug_label)


func _toggle_debug_display() -> void:
	"""Toggle the save data debug overlay."""
	_debug_visible = not _debug_visible
	
	var panel := _canvas_layer.get_node_or_null("SaveDebugPanel")
	if panel:
		panel.visible = _debug_visible
	
	if _debug_visible:
		print("SaveDebugger: Displaying save data")
		_update_debug_display()
	else:
		print("SaveDebugger: Hidden")


func _update_debug_display() -> void:
	"""Update the debug label with current save data."""
	if _debug_label == null:
		return
	
	if not is_instance_valid(SaveManager):
		_debug_label.text = "SaveManager not available"
		return
	
	var text := "=== SAVE DATA DEBUG ===\n"
	text += "File: %s\n" % SaveManager.SAVE_PATH
	text += "Exists: %s\n" % str(SaveManager.has_save())
	text += "Version: %s\n\n" % str(SaveManager.save_data.get("save_version", "N/A"))
	
	# Unlocked Levels
	text += "--- UNLOCKED LEVELS ---\n"
	var unlocked: Array = SaveManager.get_unlocked_levels()
	if unlocked.is_empty():
		text += "  (none)\n"
	else:
		for level_path: String in unlocked:
			var level_name: String = level_path.get_file().get_basename()
			text += "  - %s\n" % level_name
	
	# Collected Crystals
	text += "\n--- CRYSTALS ---\n"
	var crystals: Dictionary = SaveManager.save_data.get("collected_crystals", {})
	if crystals.is_empty():
		text += "  (none collected)\n"
	else:
		for level_name: String in crystals.keys():
			var crystal_list: Array = crystals[level_name]
			text += "  %s: %s\n" % [level_name.get_file().get_basename(), str(crystal_list)]
	
	# Best Shards
	text += "\n--- BEST SHARDS ---\n"
	var shards: Dictionary = SaveManager.save_data.get("best_shards", {})
	if shards.is_empty():
		text += "  (no records)\n"
	else:
		for level_name: String in shards.keys():
			text += "  %s: %d\n" % [level_name.get_file().get_basename(), shards[level_name]]
	
	# Active Checkpoints
	text += "\n--- CHECKPOINTS ---\n"
	var checkpoints: Dictionary = SaveManager.save_data.get("active_checkpoints", {})
	if checkpoints.is_empty():
		text += "  (none active)\n"
	else:
		for level_path: String in checkpoints.keys():
			var cp_data: Dictionary = checkpoints[level_path]
			var idx: int = cp_data.get("checkpoint_index", -1)
			var pos: Dictionary = cp_data.get("position", {})
			text += "  %s: idx=%d pos=(%d,%d)\n" % [
				level_path.get_file().get_basename(),
				idx,
				int(pos.get("x", 0)),
				int(pos.get("y", 0))
			]
	
	# Settings
	text += "\n--- SETTINGS ---\n"
	var settings: Dictionary = SaveManager.get_all_settings()
	for key: String in settings.keys():
		text += "  %s: %s\n" % [key, str(settings[key])]
	
	text += "\n[F2] Toggle | [Shift+F2] Reset"
	
	_debug_label.text = text


func _reset_save_file() -> void:
	"""Reset the save file to defaults."""
	print("SaveDebugger: Resetting save file...")
	SaveManager.delete_save()
	print("SaveDebugger: Save file reset to defaults")
	
	# Update display if visible
	if _debug_visible:
		_update_debug_display()


# ============================================================
# Programmatic Test Functions (for automated testing)
# ============================================================

static func run_save_load_test() -> Dictionary:
	"""Run a full save/load cycle test. Returns test results dictionary."""
	var results := {
		"passed": true,
		"tests": [],
		"errors": []
	}
	
	print("\n=== SaveManager Test Suite ===\n")
	
	# Test 1: Save file creation
	var test_1 := _test_save_file_creation()
	results["tests"].append(test_1)
	if not test_1["passed"]:
		results["passed"] = false
		results["errors"].append(test_1["error"])
	
	# Test 2: Crystal save/load
	var test_2 := _test_crystal_persistence()
	results["tests"].append(test_2)
	if not test_2["passed"]:
		results["passed"] = false
		results["errors"].append(test_2["error"])
	
	# Test 3: Shard save/load
	var test_3 := _test_shard_persistence()
	results["tests"].append(test_3)
	if not test_3["passed"]:
		results["passed"] = false
		results["errors"].append(test_3["error"])
	
	# Test 4: Level unlock save/load
	var test_4 := _test_level_unlock_persistence()
	results["tests"].append(test_4)
	if not test_4["passed"]:
		results["passed"] = false
		results["errors"].append(test_4["error"])
	
	# Test 5: Checkpoint save/load
	var test_5 := _test_checkpoint_persistence()
	results["tests"].append(test_5)
	if not test_5["passed"]:
		results["passed"] = false
		results["errors"].append(test_5["error"])
	
	# Test 6: Settings save/load
	var test_6 := _test_settings_persistence()
	results["tests"].append(test_6)
	if not test_6["passed"]:
		results["passed"] = false
		results["errors"].append(test_6["error"])
	
	# Summary
	var passed_count := 0
	for test: Dictionary in results["tests"]:
		if test["passed"]:
			passed_count += 1
	
	print("\n=== Test Results: %d/%d Passed ===" % [passed_count, results["tests"].size()])
	if results["passed"]:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED:")
		for err: String in results["errors"]:
			print("  - %s" % err)
	
	return results


static func _test_save_file_creation() -> Dictionary:
	"""Test that save file can be created."""
	print("Test 1: Save file creation...")
	
	# Force a save
	SaveManager.save_game()
	
	# Check file exists
	if SaveManager.has_save():
		print("  PASSED: Save file created")
		return {"name": "save_file_creation", "passed": true, "error": ""}
	else:
		print("  FAILED: Save file not created")
		return {"name": "save_file_creation", "passed": false, "error": "Save file was not created"}


static func _test_crystal_persistence() -> Dictionary:
	"""Test crystal save/load cycle."""
	print("Test 2: Crystal persistence...")
	
	var test_level := "test_level"
	var test_crystal := "test_crystal_001"
	
	# Save a crystal
	SaveManager.save_crystal(test_level, test_crystal)
	
	# Reload from disk
	SaveManager.load_game()
	
	# Check if crystal was persisted
	if SaveManager.is_crystal_collected(test_level, test_crystal):
		print("  PASSED: Crystal persisted correctly")
		return {"name": "crystal_persistence", "passed": true, "error": ""}
	else:
		print("  FAILED: Crystal not found after reload")
		return {"name": "crystal_persistence", "passed": false, "error": "Crystal not persisted"}


static func _test_shard_persistence() -> Dictionary:
	"""Test shard best score save/load cycle."""
	print("Test 3: Shard persistence...")
	
	var test_level := "test_level"
	var test_count := 42
	
	# Save shard count
	SaveManager.save_best_shards(test_level, test_count)
	
	# Reload from disk
	SaveManager.load_game()
	
	# Check if shards were persisted
	var loaded_count: int = SaveManager.get_best_shards(test_level)
	if loaded_count == test_count:
		print("  PASSED: Shard count persisted correctly (%d)" % loaded_count)
		return {"name": "shard_persistence", "passed": true, "error": ""}
	else:
		print("  FAILED: Shard count mismatch (expected %d, got %d)" % [test_count, loaded_count])
		return {"name": "shard_persistence", "passed": false, "error": "Shard count mismatch"}


static func _test_level_unlock_persistence() -> Dictionary:
	"""Test level unlock save/load cycle."""
	print("Test 4: Level unlock persistence...")
	
	var test_level := "res://scenes/levels/test_level.tscn"
	
	# Unlock level
	SaveManager.unlock_level(test_level)
	
	# Reload from disk
	SaveManager.load_game()
	
	# Check if level was persisted
	if SaveManager.is_level_unlocked(test_level):
		print("  PASSED: Level unlock persisted correctly")
		return {"name": "level_unlock_persistence", "passed": true, "error": ""}
	else:
		print("  FAILED: Level unlock not found after reload")
		return {"name": "level_unlock_persistence", "passed": false, "error": "Level unlock not persisted"}


static func _test_checkpoint_persistence() -> Dictionary:
	"""Test checkpoint save/load cycle."""
	print("Test 5: Checkpoint persistence...")
	
	var test_level := "res://scenes/levels/test_level.tscn"
	var test_index := 2
	var test_pos := Vector2(150.5, 200.25)
	
	# Save checkpoint
	SaveManager.save_checkpoint(test_level, test_index, test_pos)
	
	# Reload from disk
	SaveManager.load_game()
	
	# Check if checkpoint was persisted
	var loaded: Dictionary = SaveManager.get_active_checkpoint(test_level)
	if loaded.is_empty():
		print("  FAILED: Checkpoint not found after reload")
		return {"name": "checkpoint_persistence", "passed": false, "error": "Checkpoint not persisted"}
	
	var loaded_idx: int = loaded.get("checkpoint_index", -1)
	var loaded_pos: Vector2 = loaded.get("position", Vector2.ZERO)
	
	if loaded_idx == test_index and loaded_pos.is_equal_approx(test_pos):
		print("  PASSED: Checkpoint persisted correctly (idx=%d, pos=%s)" % [loaded_idx, str(loaded_pos)])
		return {"name": "checkpoint_persistence", "passed": true, "error": ""}
	else:
		print("  FAILED: Checkpoint data mismatch")
		return {"name": "checkpoint_persistence", "passed": false, "error": "Checkpoint data mismatch"}


static func _test_settings_persistence() -> Dictionary:
	"""Test settings save/load cycle."""
	print("Test 6: Settings persistence...")
	
	var test_key := "test_setting"
	var test_value := 0.75
	
	# Save setting
	SaveManager.set_setting(test_key, test_value)
	
	# Reload from disk
	SaveManager.load_game()
	
	# Check if setting was persisted
	var loaded_value: Variant = SaveManager.get_setting(test_key, null)
	if loaded_value != null and is_equal_approx(loaded_value, test_value):
		print("  PASSED: Setting persisted correctly (%s = %s)" % [test_key, str(loaded_value)])
		return {"name": "settings_persistence", "passed": true, "error": ""}
	else:
		print("  FAILED: Setting not found or mismatch (expected %s, got %s)" % [str(test_value), str(loaded_value)])
		return {"name": "settings_persistence", "passed": false, "error": "Setting not persisted"}
