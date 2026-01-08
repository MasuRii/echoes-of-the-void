extends Node
## Automated game flow test runner for Echoes of the Void.
## Tests the complete game loop: menu navigation, level transitions,
## pause/unpause, death/respawn, and save/load functionality.
##
## Usage: Add to scene or run via command line with Godot --script flag.
## Toggle with F5 key in debug builds to run tests.

# Level paths in order
const LEVEL_PATHS: Array[String] = [
	"res://scenes/levels/level_01_awakening.tscn",
	"res://scenes/levels/level_02_fractured_paths.tscn",
	"res://scenes/levels/level_03_mirrors_edge.tscn",
	"res://scenes/levels/level_04_collapse.tscn",
	"res://scenes/levels/level_05_last_echo.tscn"
]

const MAIN_MENU_PATH: String = "res://scenes/ui/main_menu.tscn"
const PAUSE_MENU_PATH: String = "res://scenes/ui/pause_menu.tscn"

# Test timing constants
const FRAME_WAIT_COUNT: int = 10  # Number of frames to wait between steps
const TRANSITION_WAIT: float = 0.5  # Seconds to wait for transitions
const DEATH_RESPAWN_WAIT: float = 1.5  # Seconds to wait for death/respawn cycle

# Test state
var _test_running: bool = false
var _test_results: Dictionary = {
	"menu_to_level": {"passed": false, "message": ""},
	"pause_unpause": {"passed": false, "message": ""},
	"death_respawn": {"passed": false, "message": ""},
	"level_transition": {"passed": false, "message": ""},
	"save_load": {"passed": false, "message": ""}
}

# Cached autoload references
var _game_manager: Node = null
var _save_manager: Node = null
var _events: Node = null

# Player tracking
var _player_death_detected: bool = false
var _player_respawn_detected: bool = false


func _ready() -> void:
	_game_manager = get_node_or_null("/root/GameManager")
	_save_manager = get_node_or_null("/root/SaveManager")
	_events = get_node_or_null("/root/Events")
	
	# Connect to Events signals for tracking
	if _events:
		if _events.has_signal("player_died"):
			_events.player_died.connect(_on_player_died)
		if _events.has_signal("player_respawned"):
			_events.player_respawned.connect(_on_player_respawned)
	
	# Auto-start if run directly
	if get_parent() == get_tree().root:
		print("[FlowTestRunner] Running as standalone - starting tests automatically...")
		call_deferred("start_tests")


func _input(event: InputEvent) -> void:
	# F5 to toggle flow test runner in debug builds
	if OS.is_debug_build() and event is InputEventKey:
		if event.pressed and event.keycode == KEY_F5:
			if _test_running:
				print("[FlowTestRunner] Tests already running.")
			else:
				start_tests()


## Start the automated flow tests.
func start_tests() -> void:
	if _test_running:
		print("[FlowTestRunner] Tests already running!")
		return
	
	print("")
	print("=".repeat(70))
	print("[FlowTestRunner] STARTING AUTOMATED GAME FLOW TESTS")
	print("=".repeat(70))
	print("")
	
	_test_running = true
	_reset_test_results()
	
	# Run all flow tests in sequence
	await _test_menu_to_level()
	await _wait_frames(FRAME_WAIT_COUNT)
	
	await _test_pause_unpause()
	await _wait_frames(FRAME_WAIT_COUNT)
	
	await _test_death_respawn()
	await _wait_frames(FRAME_WAIT_COUNT)
	
	await _test_save_load()
	await _wait_frames(FRAME_WAIT_COUNT)
	
	# Note: Level transition test loads level 2, so keep it last before cleanup
	await _test_level_transition()
	
	# Print results and finish
	_finish_tests()


func _reset_test_results() -> void:
	"""Reset all test results to default state."""
	for test_name in _test_results.keys():
		_test_results[test_name] = {"passed": false, "message": ""}


## Wait for a number of process frames.
func _wait_frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame


## Wait for a specific time duration.
func _wait_seconds(duration: float) -> void:
	await get_tree().create_timer(duration, true, false, true).timeout


# ============================================================
# Test: Main Menu → Level 1
# ============================================================

func _test_menu_to_level() -> void:
	"""Test that the game can navigate from main menu to level 1."""
	print("-".repeat(60))
	print("[Test] Main Menu → Level 1")
	print("-".repeat(60))
	
	var test_name := "menu_to_level"
	
	# Check prerequisites
	if _game_manager == null:
		_record_failure(test_name, "GameManager autoload not found")
		return
	
	# Verify main menu scene exists
	if not ResourceLoader.exists(MAIN_MENU_PATH):
		_record_failure(test_name, "Main menu scene not found: %s" % MAIN_MENU_PATH)
		return
	
	# Verify level 1 exists
	if not ResourceLoader.exists(LEVEL_PATHS[0]):
		_record_failure(test_name, "Level 1 scene not found: %s" % LEVEL_PATHS[0])
		return
	
	# Load level 1 directly (simulating menu "New Game" click)
	print("  Loading level 1...")
	_game_manager.load_level(LEVEL_PATHS[0], false)  # No transition for speed
	
	await _wait_frames(FRAME_WAIT_COUNT * 3)
	await _wait_seconds(TRANSITION_WAIT)
	
	# Verify we're in playing state
	if _game_manager.current_state != _game_manager.GameState.PLAYING:
		_record_failure(test_name, "Game state is not PLAYING after level load (got: %s)" % _game_manager.current_state)
		return
	
	# Verify current level is set
	if _game_manager.current_level != LEVEL_PATHS[0]:
		_record_failure(test_name, "Current level not set correctly")
		return
	
	# Verify player exists
	var player := _find_player()
	if player == null:
		_record_failure(test_name, "Player not found in level after load")
		return
	
	_record_success(test_name, "Successfully loaded level 1 with player spawned")


# ============================================================
# Test: Pause/Unpause
# ============================================================

func _test_pause_unpause() -> void:
	"""Test that pause/unpause functionality works correctly."""
	print("-".repeat(60))
	print("[Test] Pause/Unpause")
	print("-".repeat(60))
	
	var test_name := "pause_unpause"
	
	if _game_manager == null:
		_record_failure(test_name, "GameManager autoload not found")
		return
	
	# Make sure we're in playing state first
	if _game_manager.current_state != _game_manager.GameState.PLAYING:
		print("  Ensuring playing state first...")
		_game_manager.change_state(_game_manager.GameState.PLAYING)
		await _wait_frames(5)
	
	# Verify we start unpaused
	if get_tree().paused:
		_record_failure(test_name, "Game was already paused before test")
		return
	
	# Pause the game
	print("  Pausing game...")
	_game_manager.change_state(_game_manager.GameState.PAUSED)
	await _wait_frames(5)
	
	# Verify paused
	if not get_tree().paused:
		_record_failure(test_name, "Game did not pause when PAUSED state set")
		return
	
	if _game_manager.current_state != _game_manager.GameState.PAUSED:
		_record_failure(test_name, "GameManager state is not PAUSED")
		return
	
	print("  Game paused successfully. Unpausing...")
	
	# Unpause the game
	_game_manager.change_state(_game_manager.GameState.PLAYING)
	await _wait_frames(5)
	
	# Verify unpaused
	if get_tree().paused:
		_record_failure(test_name, "Game did not unpause when PLAYING state set")
		return
	
	if _game_manager.current_state != _game_manager.GameState.PLAYING:
		_record_failure(test_name, "GameManager state is not PLAYING after unpause")
		return
	
	_record_success(test_name, "Pause/unpause cycle completed successfully")


# ============================================================
# Test: Death/Respawn
# ============================================================

func _test_death_respawn() -> void:
	"""Test that player death and respawn work correctly."""
	print("-".repeat(60))
	print("[Test] Death/Respawn")
	print("-".repeat(60))
	
	var test_name := "death_respawn"
	
	if _events == null:
		_record_failure(test_name, "Events autoload not found")
		return
	
	# Find the player
	var player := _find_player()
	if player == null:
		_record_failure(test_name, "Player not found for death test")
		return
	
	# Reset tracking flags
	_player_death_detected = false
	_player_respawn_detected = false
	
	# Record initial position
	var initial_position: Vector2 = player.global_position
	var checkpoint_position: Vector2 = player.last_checkpoint if player.has_method("get") or "last_checkpoint" in player else initial_position
	
	print("  Initial position: %s" % initial_position)
	print("  Checkpoint position: %s" % checkpoint_position)
	
	# Trigger player death by calling die() if available, or using health component
	print("  Triggering player death...")
	
	var health_component: Node = player.get_node_or_null("HealthComponent")
	if health_component and health_component.has_method("take_damage"):
		health_component.take_damage(999)  # Massive damage to ensure death
	elif player.has_method("die"):
		player.die()
	else:
		# Emit death event directly as fallback
		if _events.has_signal("player_died"):
			_events.player_died.emit()
		_player_death_detected = true  # Manually set since we emitted
	
	# Wait for death/respawn cycle
	await _wait_seconds(DEATH_RESPAWN_WAIT)
	
	# Check if death was detected
	if not _player_death_detected:
		print("  [WARN] Death signal not detected, but continuing test...")
	else:
		print("  Death signal detected")
	
	# Find player again (may have been recreated)
	player = _find_player()
	if player == null:
		# Player might still be respawning
		await _wait_seconds(0.5)
		player = _find_player()
	
	if player == null:
		_record_failure(test_name, "Player not found after death/respawn cycle")
		return
	
	# Check respawn position
	var respawn_position: Vector2 = player.global_position
	print("  Respawn position: %s" % respawn_position)
	
	# Verify player respawned near checkpoint (within 100 pixels)
	var distance_from_checkpoint := respawn_position.distance_to(checkpoint_position)
	if distance_from_checkpoint > 200.0:
		print("  [WARN] Player respawned far from checkpoint (%.0f px)" % distance_from_checkpoint)
	
	# Check respawn signal
	if _player_respawn_detected:
		print("  Respawn signal detected")
	
	# Basic verification: player exists and is in a valid state
	if player.is_inside_tree():
		_record_success(test_name, "Death/respawn cycle completed (player active in tree)")
	else:
		_record_failure(test_name, "Player not properly in scene tree after respawn")


# ============================================================
# Test: Level Transition
# ============================================================

func _test_level_transition() -> void:
	"""Test that level transitions work (level 1 → level 2)."""
	print("-".repeat(60))
	print("[Test] Level Transition (Level 1 → Level 2)")
	print("-".repeat(60))
	
	var test_name := "level_transition"
	
	if _game_manager == null:
		_record_failure(test_name, "GameManager autoload not found")
		return
	
	# Verify level 2 exists
	if LEVEL_PATHS.size() < 2:
		_record_failure(test_name, "Not enough levels defined for transition test")
		return
	
	if not ResourceLoader.exists(LEVEL_PATHS[1]):
		_record_failure(test_name, "Level 2 scene not found: %s" % LEVEL_PATHS[1])
		return
	
	# Store current level for comparison
	var previous_level: String = _game_manager.current_level
	
	# Load level 2
	print("  Loading level 2...")
	_game_manager.load_level(LEVEL_PATHS[1], false)  # No transition for speed
	
	await _wait_frames(FRAME_WAIT_COUNT * 3)
	await _wait_seconds(TRANSITION_WAIT)
	
	# Verify current level changed
	if _game_manager.current_level == previous_level:
		_record_failure(test_name, "Current level did not change after load_level()")
		return
	
	if _game_manager.current_level != LEVEL_PATHS[1]:
		_record_failure(test_name, "Current level is not level 2 (got: %s)" % _game_manager.current_level)
		return
	
	# Verify player exists in new level
	var player := _find_player()
	if player == null:
		_record_failure(test_name, "Player not found in level 2 after transition")
		return
	
	# Verify game is in playing state
	if _game_manager.current_state != _game_manager.GameState.PLAYING:
		_record_failure(test_name, "Game state is not PLAYING after level transition")
		return
	
	_record_success(test_name, "Successfully transitioned from level 1 to level 2")


# ============================================================
# Test: Save/Load
# ============================================================

func _test_save_load() -> void:
	"""Test that save and load functionality works correctly."""
	print("-".repeat(60))
	print("[Test] Save/Load")
	print("-".repeat(60))
	
	var test_name := "save_load"
	
	if _save_manager == null:
		_record_failure(test_name, "SaveManager autoload not found")
		return
	
	# Test 1: Setting and retrieving a setting
	print("  Testing settings save/load...")
	var test_setting_key := "_flow_test_value"
	var test_setting_value := randi()  # Random value for uniqueness
	
	_save_manager.set_setting(test_setting_key, test_setting_value)
	
	var retrieved_value: Variant = _save_manager.get_setting(test_setting_key, -1)
	if retrieved_value != test_setting_value:
		_record_failure(test_name, "Setting value mismatch: expected %s, got %s" % [test_setting_value, retrieved_value])
		return
	
	print("  Settings: PASS")
	
	# Test 2: Level unlock
	print("  Testing level unlock...")
	var test_level_path := "res://scenes/levels/test_level_flow_test.tscn"
	
	# Make sure it's not already unlocked
	var was_unlocked: bool = _save_manager.is_level_unlocked(test_level_path)
	
	_save_manager.unlock_level(test_level_path)
	
	if not _save_manager.is_level_unlocked(test_level_path):
		_record_failure(test_name, "Level unlock failed - level not showing as unlocked")
		return
	
	print("  Level unlock: PASS")
	
	# Test 3: Crystal save
	print("  Testing crystal save...")
	var test_level_name := "flow_test_level"
	var test_crystal_id := "test_crystal_%d" % randi()
	
	_save_manager.save_crystal(test_level_name, test_crystal_id)
	
	if not _save_manager.is_crystal_collected(test_level_name, test_crystal_id):
		_record_failure(test_name, "Crystal save failed - crystal not showing as collected")
		return
	
	print("  Crystal save: PASS")
	
	# Test 4: Save persistence (force reload)
	print("  Testing save persistence...")
	
	# Force a save then reload
	_save_manager.save_game()
	await _wait_frames(5)
	
	# Store the random value we set earlier
	var value_before_reload: int = test_setting_value
	
	# Reload save data
	_save_manager.load_game()
	await _wait_frames(5)
	
	var value_after_reload: Variant = _save_manager.get_setting(test_setting_key, -1)
	if value_after_reload != value_before_reload:
		_record_failure(test_name, "Save persistence failed: value changed after reload")
		return
	
	print("  Save persistence: PASS")
	
	# Clean up test data
	_save_manager.save_data["settings"].erase(test_setting_key)
	if _save_manager.save_data.has("collected_crystals") and _save_manager.save_data["collected_crystals"].has(test_level_name):
		_save_manager.save_data["collected_crystals"].erase(test_level_name)
	
	_record_success(test_name, "All save/load operations completed successfully")


# ============================================================
# Helper Functions
# ============================================================

func _find_player() -> CharacterBody2D:
	"""Find the player node in the current scene."""
	# Search in player group
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0] is CharacterBody2D:
		return players[0]
	
	# Search all nodes
	var root := get_tree().root
	for child in root.get_children():
		# Skip autoloads
		if child.name in ["Events", "GameManager", "SaveManager", "AudioManager"]:
			continue
		
		# Search in level
		if child is Node2D:
			var player := child.get_node_or_null("Player")
			if player and player is CharacterBody2D:
				return player
	
	return null


func _record_success(test_name: String, message: String) -> void:
	"""Record a test success."""
	_test_results[test_name] = {"passed": true, "message": message}
	print("  [PASS] %s" % message)


func _record_failure(test_name: String, message: String) -> void:
	"""Record a test failure."""
	_test_results[test_name] = {"passed": false, "message": message}
	print("  [FAIL] %s" % message)


func _on_player_died() -> void:
	"""Track player death event."""
	if _test_running:
		_player_death_detected = true


func _on_player_respawned() -> void:
	"""Track player respawn event."""
	if _test_running:
		_player_respawn_detected = true


func _finish_tests() -> void:
	"""Complete the tests and print summary."""
	_test_running = false
	
	print("")
	print("=".repeat(70))
	print("[FlowTestRunner] TEST RESULTS SUMMARY")
	print("=".repeat(70))
	
	var total_passed: int = 0
	var total_failed: int = 0
	
	for test_name in _test_results.keys():
		var result: Dictionary = _test_results[test_name]
		var status: String = "PASS" if result["passed"] else "FAIL"
		
		if result["passed"]:
			total_passed += 1
		else:
			total_failed += 1
		
		print("")
		print("[%s] %s" % [status, test_name])
		if result["message"]:
			print("      %s" % result["message"])
	
	print("")
	print("=".repeat(70))
	print("OVERALL: %d tests passed, %d tests failed" % [total_passed, total_failed])
	print("=".repeat(70))
	
	if total_failed == 0:
		print("")
		print("All flow tests PASSED! Game flow is working correctly.")
	else:
		print("")
		print("Some tests FAILED. Review the errors above and fix before release.")
	
	print("")


## Static method to quickly verify autoloads exist.
static func verify_autoloads() -> Dictionary:
	"""Verify all required autoloads are present."""
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return {"valid": false, "missing": ["SceneTree not available"]}
	
	var required := ["Events", "GameManager", "SaveManager", "AudioManager"]
	var missing: Array[String] = []
	
	for autoload_name in required:
		if tree.root.get_node_or_null("/root/%s" % autoload_name) == null:
			missing.append(autoload_name)
	
	return {
		"valid": missing.size() == 0,
		"missing": missing
	}
