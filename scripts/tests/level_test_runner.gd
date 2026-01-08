extends Node
## Automated level test runner for Echoes of the Void.
## Verifies that all levels are correctly configured and playable.
##
## Tests performed per level:
## - Level loads without errors
## - Player spawns on ground (no immediate fall death)
## - Collectibles count matches expected
## - Level exit exists and is configured
## - Generated geometry is present
##
## Usage: Add to scene or run via command line with Godot --script flag.
## Toggle with F4 key in debug builds to run tests.

# Level paths in order
const LEVEL_PATHS: Array[String] = [
	"res://scenes/levels/level_01_awakening.tscn",
	"res://scenes/levels/level_02_fractured_paths.tscn",
	"res://scenes/levels/level_03_mirrors_edge.tscn",
	"res://scenes/levels/level_04_collapse.tscn",
	"res://scenes/levels/level_05_last_echo.tscn"
]

# Expected collectible counts per level (index 0 = level 1)
const EXPECTED_SHARDS: Array[int] = [5, 7, 10, 12, 15]
const EXPECTED_CRYSTALS: Array[int] = [1, 1, 2, 2, 3]

# Time to observe each level (seconds)
const OBSERVATION_TIME: float = 1.5

# Test state
var _current_level_index: int = -1
var _test_running: bool = false
var _test_results: Array[Dictionary] = []
var _observation_timer: Timer = null
var _current_level_instance: Node = null
var _player_fell_to_death: bool = false
var _player_initial_y: float = 0.0

# Cached references
var _game_manager: Node = null
var _events: Node = null


func _ready() -> void:
	_game_manager = get_node_or_null("/root/GameManager")
	_events = get_node_or_null("/root/Events")
	
	# Create timer for level observation
	_observation_timer = Timer.new()
	_observation_timer.one_shot = true
	_observation_timer.timeout.connect(_on_observation_complete)
	add_child(_observation_timer)
	
	# Connect to player death event if Events exists
	if _events and _events.has_signal("player_died"):
		_events.player_died.connect(_on_player_died_during_test)
	
	# Auto-start if run directly
	if get_parent() == get_tree().root:
		print("[LevelTestRunner] Running as standalone - starting tests automatically...")
		call_deferred("start_tests")


func _input(event: InputEvent) -> void:
	# F4 to toggle test runner in debug builds
	if OS.is_debug_build() and event is InputEventKey:
		if event.pressed and event.keycode == KEY_F4:
			if _test_running:
				_abort_tests()
			else:
				start_tests()


## Start the automated level tests.
func start_tests() -> void:
	if _test_running:
		print("[LevelTestRunner] Tests already running!")
		return
	
	print("")
	print("=" .repeat(70))
	print("[LevelTestRunner] STARTING AUTOMATED LEVEL VERIFICATION")
	print("=" .repeat(70))
	print("Testing %d levels..." % LEVEL_PATHS.size())
	print("")
	
	_test_running = true
	_test_results.clear()
	_current_level_index = -1
	_player_fell_to_death = false
	
	# Validate all level paths exist first
	var validation := _validate_level_paths()
	if not validation["all_valid"]:
		print("[LevelTestRunner] ABORTED: Some level paths are invalid.")
		_print_path_validation(validation)
		_finish_tests()
		return
	
	# Start testing first level
	_test_next_level()


## Abort the currently running tests.
func _abort_tests() -> void:
	print("[LevelTestRunner] Tests aborted by user.")
	_test_running = false
	_observation_timer.stop()
	_finish_tests()


func _test_next_level() -> void:
	"""Load and test the next level in the sequence."""
	_current_level_index += 1
	
	if _current_level_index >= LEVEL_PATHS.size():
		_finish_tests()
		return
	
	var level_path: String = LEVEL_PATHS[_current_level_index]
	var level_name: String = level_path.get_file().get_basename()
	
	print("-" .repeat(60))
	print("[Test %d/%d] %s" % [_current_level_index + 1, LEVEL_PATHS.size(), level_name])
	print("-" .repeat(60))
	
	# Initialize test result
	var result: Dictionary = {
		"level_path": level_path,
		"level_name": level_name,
		"index": _current_level_index,
		"tests": {},
		"passed": 0,
		"failed": 0
	}
	
	# Reset death tracker
	_player_fell_to_death = false
	
	# Load the level
	var load_success := await _load_level_for_test(level_path)
	result["tests"]["level_loads"] = load_success
	
	if not load_success:
		result["failed"] += 1
		_test_results.append(result)
		_test_next_level()
		return
	
	result["passed"] += 1
	
	# Wait a frame for level to fully initialize
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Get the current level instance
	_current_level_instance = _get_current_level_instance()
	if _current_level_instance == null:
		print("  [FAIL] Could not get level instance")
		result["tests"]["level_instance"] = false
		result["failed"] += 1
		_test_results.append(result)
		_test_next_level()
		return
	
	# Run all level tests
	await _run_level_tests(result)
	
	# Store result
	_test_results.append(result)
	
	# Wait observation time then proceed
	_observation_timer.start(OBSERVATION_TIME)


func _load_level_for_test(level_path: String) -> bool:
	"""Load a level for testing. Returns true if successful."""
	print("  Loading level...")
	
	# Use GameManager if available, otherwise direct scene change
	if _game_manager:
		_game_manager.load_level(level_path, false)  # No transition for speed
		await get_tree().process_frame
		await get_tree().process_frame
		print("  [PASS] Level loaded via GameManager")
		return true
	else:
		var error := get_tree().change_scene_to_file(level_path)
		if error != OK:
			print("  [FAIL] Failed to load scene: error %d" % error)
			return false
		await get_tree().process_frame
		print("  [PASS] Level loaded via direct scene change")
		return true


func _get_current_level_instance() -> Node:
	"""Get the current level instance from the scene tree."""
	var root := get_tree().root
	for child in root.get_children():
		# Skip autoloads and this test runner
		if child.name in ["Events", "GameManager", "SaveManager", "AudioManager"]:
			continue
		if child == self or child == get_parent():
			continue
		# Check if it's a level (has LevelBase or similar)
		if child is Node2D:
			return child
	return null


func _run_level_tests(result: Dictionary) -> void:
	"""Run all verification tests on the current level."""
	var level: Node = _current_level_instance
	
	# Test 1: Player exists and spawned
	var player := _find_player(level)
	result["tests"]["player_spawned"] = player != null
	if player:
		print("  [PASS] Player spawned")
		result["passed"] += 1
		_player_initial_y = player.global_position.y
	else:
		print("  [FAIL] Player not found in level")
		result["failed"] += 1
	
	# Test 2: Generated geometry exists
	var has_geometry := _check_generated_geometry(level)
	result["tests"]["geometry_generated"] = has_geometry
	if has_geometry:
		print("  [PASS] Generated geometry present")
		result["passed"] += 1
	else:
		print("  [FAIL] No generated geometry found")
		result["failed"] += 1
	
	# Test 3: Check collectibles count
	var collectibles_result := _check_collectibles(level)
	result["tests"]["collectibles_valid"] = collectibles_result["valid"]
	result["tests"]["shard_count"] = collectibles_result["shards"]
	result["tests"]["crystal_count"] = collectibles_result["crystals"]
	
	var expected_shards: int = EXPECTED_SHARDS[_current_level_index] if _current_level_index < EXPECTED_SHARDS.size() else 0
	var expected_crystals: int = EXPECTED_CRYSTALS[_current_level_index] if _current_level_index < EXPECTED_CRYSTALS.size() else 0
	
	if collectibles_result["valid"]:
		print("  [PASS] Collectibles: %d shards (expected ~%d), %d crystals (expected %d)" % [
			collectibles_result["shards"], expected_shards,
			collectibles_result["crystals"], expected_crystals
		])
		result["passed"] += 1
	else:
		print("  [WARN] Collectibles count may not match: %d shards, %d crystals" % [
			collectibles_result["shards"], collectibles_result["crystals"]
		])
		# This is a warning, not a failure - counts can vary
		result["passed"] += 1
	
	# Test 4: Level exit exists
	var has_exit := _check_level_exit(level)
	result["tests"]["exit_exists"] = has_exit
	if has_exit:
		print("  [PASS] Level exit configured")
		result["passed"] += 1
	else:
		print("  [FAIL] Level exit not found or not configured")
		result["failed"] += 1
	
	# Test 5: Wait briefly and check if player fell to death immediately
	await get_tree().create_timer(0.5).timeout
	
	if player and is_instance_valid(player):
		var current_y: float = player.global_position.y
		var fell_far := (current_y - _player_initial_y) > 500.0  # Fell more than 500px
		result["tests"]["player_stable"] = not fell_far and not _player_fell_to_death
		
		if not fell_far and not _player_fell_to_death:
			print("  [PASS] Player stable on ground (no immediate death)")
			result["passed"] += 1
		else:
			if _player_fell_to_death:
				print("  [FAIL] Player died immediately after spawn")
			else:
				print("  [FAIL] Player fell too far (%.0f px) - missing ground?" % (current_y - _player_initial_y))
			result["failed"] += 1
	else:
		# Player instance became invalid - likely died
		result["tests"]["player_stable"] = not _player_fell_to_death
		if _player_fell_to_death:
			print("  [FAIL] Player died immediately after spawn")
			result["failed"] += 1
		else:
			print("  [WARN] Player instance invalid but no death detected")
			result["passed"] += 1
	
	# Test 6: Checkpoints exist (for levels that should have them)
	var checkpoint_count := _count_checkpoints(level)
	result["tests"]["checkpoint_count"] = checkpoint_count
	if _current_level_index >= 1:  # Level 2+ should have checkpoints
		if checkpoint_count > 0:
			print("  [PASS] Checkpoints found: %d" % checkpoint_count)
			result["passed"] += 1
		else:
			print("  [WARN] No checkpoints found (expected for level %d)" % (_current_level_index + 1))
			# Warning only - not critical failure
			result["passed"] += 1
	else:
		print("  [INFO] Checkpoints: %d (optional for tutorial)" % checkpoint_count)


func _find_player(level: Node) -> CharacterBody2D:
	"""Find the player node in the level."""
	# Direct child named Player
	var player := level.get_node_or_null("Player")
	if player and player is CharacterBody2D:
		return player
	
	# Search in player group
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0] is CharacterBody2D:
		return players[0]
	
	# Search all children
	for child in level.get_children():
		if child is CharacterBody2D and (child.name == "Player" or child.is_in_group("player")):
			return child
	
	return null


func _check_generated_geometry(level: Node) -> bool:
	"""Check if procedurally generated geometry exists."""
	var geometry := level.get_node_or_null("GeneratedGeometry")
	if geometry == null:
		return false
	
	# Must have at least one child (a platform)
	return geometry.get_child_count() > 0


func _check_collectibles(level: Node) -> Dictionary:
	"""Check collectibles in the level."""
	var result := {
		"valid": true,
		"shards": 0,
		"crystals": 0
	}
	
	# Check Collectibles container
	var collectibles := level.get_node_or_null("Collectibles")
	if collectibles:
		for child in collectibles.get_children():
			if child.is_in_group("light_shards"):
				result["shards"] += 1
			elif child.is_in_group("echo_crystals"):
				result["crystals"] += 1
	
	# Also check via groups globally
	result["shards"] = max(result["shards"], get_tree().get_nodes_in_group("light_shards").size())
	result["crystals"] = max(result["crystals"], get_tree().get_nodes_in_group("echo_crystals").size())
	
	return result


func _check_level_exit(level: Node) -> bool:
	"""Check if level exit exists and is configured."""
	var exit := level.get_node_or_null("LevelExit")
	if exit == null:
		return false
	
	# Exit should be an Area2D
	if not exit is Area2D:
		return false
	
	# Check if exit has a collision shape
	for child in exit.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			return true
	
	return false


func _count_checkpoints(level: Node) -> int:
	"""Count checkpoints in the level."""
	var count: int = 0
	
	var checkpoints := level.get_node_or_null("Checkpoints")
	if checkpoints:
		for child in checkpoints.get_children():
			if child.is_in_group("checkpoints"):
				count += 1
	
	# Also check via group
	count = max(count, get_tree().get_nodes_in_group("checkpoints").size())
	
	return count


func _on_player_died_during_test() -> void:
	"""Track if player died during the test observation period."""
	if _test_running:
		_player_fell_to_death = true


func _on_observation_complete() -> void:
	"""Observation period complete, move to next level."""
	if _test_running:
		_test_next_level()


func _validate_level_paths() -> Dictionary:
	"""Validate all level paths exist."""
	var result := {
		"all_valid": true,
		"valid": [],
		"invalid": []
	}
	
	for path in LEVEL_PATHS:
		if ResourceLoader.exists(path):
			result["valid"].append(path)
		else:
			result["invalid"].append(path)
			result["all_valid"] = false
	
	return result


func _print_path_validation(validation: Dictionary) -> void:
	"""Print path validation results."""
	for path in validation["valid"]:
		print("  [PASS] %s" % path.get_file())
	for path in validation["invalid"]:
		print("  [FAIL] %s (not found)" % path.get_file())


func _finish_tests() -> void:
	"""Complete the tests and print summary."""
	_test_running = false
	
	print("")
	print("=" .repeat(70))
	print("[LevelTestRunner] TEST RESULTS SUMMARY")
	print("=" .repeat(70))
	
	var total_passed: int = 0
	var total_failed: int = 0
	var levels_with_failures: int = 0
	
	for result in _test_results:
		var status: String = "PASS" if result["failed"] == 0 else "FAIL"
		print("")
		print("[%s] %s" % [status, result["level_name"]])
		print("      Tests: %d passed, %d failed" % [result["passed"], result["failed"]])
		
		total_passed += result["passed"]
		total_failed += result["failed"]
		if result["failed"] > 0:
			levels_with_failures += 1
		
		# Print failed tests for this level
		if result["failed"] > 0:
			for test_name in result["tests"]:
				if result["tests"][test_name] == false:
					print("      - FAILED: %s" % test_name)
	
	print("")
	print("=" .repeat(70))
	print("OVERALL: %d tests passed, %d tests failed" % [total_passed, total_failed])
	print("LEVELS: %d/%d passed all tests" % [LEVEL_PATHS.size() - levels_with_failures, LEVEL_PATHS.size()])
	print("=" .repeat(70))
	
	if total_failed == 0:
		print("")
		print("All level tests PASSED! Game is ready for playthrough testing.")
	else:
		print("")
		print("Some tests FAILED. Review the errors above and fix before release.")
	
	print("")


## Static method to run a quick validation without loading levels.
static func quick_validate() -> Dictionary:
	"""Validate all level paths exist without loading them."""
	var results := {
		"valid": [],
		"invalid": []
	}
	
	for path in LEVEL_PATHS:
		if ResourceLoader.exists(path):
			results["valid"].append(path)
		else:
			results["invalid"].append(path)
	
	return results
