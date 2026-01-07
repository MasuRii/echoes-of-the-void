extends Node
## Persistent data handler for Echoes of the Void.
## Register as autoload "SaveManager" in Project Settings > Autoload.
## NOTE: Should be registered AFTER Events and GameManager autoloads.

# Save file path
const SAVE_PATH: String = "user://echoes_save.json"

# Save file version for migration support
const CURRENT_SAVE_VERSION: int = 1

# Default save data structure
var _default_save_data: Dictionary = {
	"save_version": CURRENT_SAVE_VERSION,
	"collected_crystals": {},  # level_name: Array[String] of crystal_ids
	"best_shards": {},         # level_name: int (best shard count)
	"unlocked_levels": ["res://scenes/levels/level_01_awakening.tscn"],
	"active_checkpoints": {},  # level_path: {checkpoint_index: int, position: {x: float, y: float}}
	"settings": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"fullscreen": false,
		"vsync": true,
		"screen_shake": true
	}
}

# Current save data in memory
var save_data: Dictionary = {}


func _ready() -> void:
	# Load existing save or initialize with defaults
	load_game()


func save_game() -> void:
	"""Save current game data to file."""
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Failed to open save file for writing: %s" % FileAccess.get_open_error())
		return
	
	var json_string := JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()


func load_game() -> void:
	"""Load game data from file, or initialize defaults if no save exists."""
	if not FileAccess.file_exists(SAVE_PATH):
		# No save file exists - initialize with defaults
		save_data = _default_save_data.duplicate(true)
		return
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: Failed to open save file for reading: %s" % FileAccess.get_open_error())
		save_data = _default_save_data.duplicate(true)
		return
	
	var json_text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("SaveManager: Failed to parse save file at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		save_data = _default_save_data.duplicate(true)
		return
	
	save_data = json.data
	
	# Run migration if save version differs
	_migrate_save_data()
	
	# Merge any missing default keys (for forwards compatibility)
	_merge_defaults()


func has_save() -> bool:
	"""Check if a save file exists."""
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	"""Delete the save file and reset to defaults."""
	if FileAccess.file_exists(SAVE_PATH):
		var error := DirAccess.remove_absolute(SAVE_PATH)
		if error != OK:
			push_error("SaveManager: Failed to delete save file")
	
	save_data = _default_save_data.duplicate(true)


# ============================================================
# Crystal Tracking
# ============================================================

func save_crystal(level_name: String, crystal_id: String) -> void:
	"""Record a crystal as collected for the given level."""
	if not save_data.has("collected_crystals"):
		save_data["collected_crystals"] = {}
	
	if not save_data["collected_crystals"].has(level_name):
		save_data["collected_crystals"][level_name] = []
	
	var crystals: Array = save_data["collected_crystals"][level_name]
	if crystal_id not in crystals:
		crystals.append(crystal_id)
		save_game()


func is_crystal_collected(level_name: String, crystal_id: String) -> bool:
	"""Check if a crystal has been collected in the given level."""
	if not save_data.has("collected_crystals"):
		return false
	if not save_data["collected_crystals"].has(level_name):
		return false
	
	return crystal_id in save_data["collected_crystals"][level_name]


func get_collected_crystals(level_name: String) -> Array:
	"""Get all collected crystal IDs for a level."""
	if not save_data.has("collected_crystals"):
		return []
	if not save_data["collected_crystals"].has(level_name):
		return []
	
	return save_data["collected_crystals"][level_name].duplicate()


# ============================================================
# Shard Best Scores
# ============================================================

func save_best_shards(level_name: String, shard_count: int) -> void:
	"""Save the best shard count for a level (only if better than existing)."""
	if not save_data.has("best_shards"):
		save_data["best_shards"] = {}
	
	var current_best: int = save_data["best_shards"].get(level_name, 0)
	if shard_count > current_best:
		save_data["best_shards"][level_name] = shard_count
		save_game()


func get_best_shards(level_name: String) -> int:
	"""Get the best shard count for a level."""
	if not save_data.has("best_shards"):
		return 0
	
	return save_data["best_shards"].get(level_name, 0)


# ============================================================
# Level Unlocks
# ============================================================

func unlock_level(level_path: String) -> void:
	"""Unlock a level for the player."""
	if not save_data.has("unlocked_levels"):
		save_data["unlocked_levels"] = []
	
	if level_path not in save_data["unlocked_levels"]:
		save_data["unlocked_levels"].append(level_path)
		save_game()


func is_level_unlocked(level_path: String) -> bool:
	"""Check if a level is unlocked."""
	if not save_data.has("unlocked_levels"):
		return false
	
	return level_path in save_data["unlocked_levels"]


func get_unlocked_levels() -> Array:
	"""Get all unlocked level paths."""
	if not save_data.has("unlocked_levels"):
		return []
	
	return save_data["unlocked_levels"].duplicate()


# ============================================================
# Checkpoint State (Per-Level Active Checkpoint)
# ============================================================

func save_checkpoint(level_path: String, checkpoint_index: int, checkpoint_position: Vector2) -> void:
	"""Save the active checkpoint for a level."""
	if not save_data.has("active_checkpoints"):
		save_data["active_checkpoints"] = {}
	
	save_data["active_checkpoints"][level_path] = {
		"checkpoint_index": checkpoint_index,
		"position": {"x": checkpoint_position.x, "y": checkpoint_position.y}
	}
	save_game()


func get_active_checkpoint(level_path: String) -> Dictionary:
	"""Get the active checkpoint data for a level.
	Returns empty dict if no checkpoint saved, otherwise:
	{checkpoint_index: int, position: Vector2}"""
	if not save_data.has("active_checkpoints"):
		return {}
	if not save_data["active_checkpoints"].has(level_path):
		return {}
	
	var data: Dictionary = save_data["active_checkpoints"][level_path]
	# Convert stored position back to Vector2
	var pos_data: Dictionary = data.get("position", {})
	return {
		"checkpoint_index": data.get("checkpoint_index", 0),
		"position": Vector2(pos_data.get("x", 0.0), pos_data.get("y", 0.0))
	}


func clear_checkpoint(level_path: String) -> void:
	"""Clear the saved checkpoint for a level (e.g., on level restart)."""
	if not save_data.has("active_checkpoints"):
		return
	if save_data["active_checkpoints"].has(level_path):
		save_data["active_checkpoints"].erase(level_path)
		save_game()


func has_saved_checkpoint(level_path: String) -> bool:
	"""Check if a checkpoint has been saved for a level."""
	if not save_data.has("active_checkpoints"):
		return false
	return save_data["active_checkpoints"].has(level_path)


# ============================================================
# Settings
# ============================================================

func get_setting(key: String, default_value: Variant = null) -> Variant:
	"""Get a setting value."""
	if not save_data.has("settings"):
		return default_value
	
	return save_data["settings"].get(key, default_value)


func set_setting(key: String, value: Variant) -> void:
	"""Set a setting value and save."""
	if not save_data.has("settings"):
		save_data["settings"] = {}
	
	save_data["settings"][key] = value
	save_game()


func get_all_settings() -> Dictionary:
	"""Get all settings as a dictionary."""
	if not save_data.has("settings"):
		return _default_save_data["settings"].duplicate()
	
	return save_data["settings"].duplicate()


# ============================================================
# Internal Helpers
# ============================================================

func _merge_defaults() -> void:
	"""Merge default values into save_data for any missing keys (forwards compatibility)."""
	for key in _default_save_data.keys():
		if not save_data.has(key):
			save_data[key] = _default_save_data[key].duplicate(true) if _default_save_data[key] is Dictionary or _default_save_data[key] is Array else _default_save_data[key]
		elif _default_save_data[key] is Dictionary and save_data[key] is Dictionary:
			# Merge nested dictionary keys
			for sub_key in _default_save_data[key].keys():
				if not save_data[key].has(sub_key):
					save_data[key][sub_key] = _default_save_data[key][sub_key]


func _migrate_save_data() -> void:
	"""Migrate save data from older versions to current version.
	Each migration step handles one version upgrade."""
	var saved_version: int = save_data.get("save_version", 0)
	
	if saved_version == CURRENT_SAVE_VERSION:
		return  # Already up to date
	
	# Migration from version 0 (pre-versioning) to version 1
	if saved_version < 1:
		# Version 1 adds: save_version field, active_checkpoints structure
		if not save_data.has("active_checkpoints"):
			save_data["active_checkpoints"] = {}
		save_data["save_version"] = 1
		print("SaveManager: Migrated save from version 0 to 1")
	
	# Future migrations go here:
	# if saved_version < 2:
	#     # Migration logic for version 2
	#     save_data["save_version"] = 2
	#     print("SaveManager: Migrated save from version 1 to 2")
	
	# Save the migrated data
	if saved_version != CURRENT_SAVE_VERSION:
		save_game()
		print("SaveManager: Save file migration complete (v%d -> v%d)" % [saved_version, CURRENT_SAVE_VERSION])
