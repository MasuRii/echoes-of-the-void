extends Node
## Automated level transition test script.
## Tests that all level transitions work correctly without errors.
## Run this script to auto-walk through all levels.
##
## Usage: Add to scene or run via command line with Godot --script flag.

# Level paths in order
const LEVEL_PATHS: Array[String] = [
	"res://scenes/levels/level_01_awakening.tscn",
	"res://scenes/levels/level_02_fractured_paths.tscn",
	"res://scenes/levels/level_03_mirrors_edge.tscn",
	"res://scenes/levels/level_04_collapse.tscn",
	"res://scenes/levels/level_05_last_echo.tscn"
]

# Time to wait on each level before transitioning (seconds)
const TIME_PER_LEVEL: float = 2.0

# Test state
var _current_level_index: int = -1
var _test_running: bool = false
var _test_results: Array[Dictionary] = []
var _level_timer: Timer = null

# Cached references
var _game_manager: Node = null


func _ready() -> void:
	_game_manager = get_node_or_null("/root/GameManager")
	
	# Create timer for level transitions
	_level_timer = Timer.new()
	_level_timer.one_shot = true
	_level_timer.timeout.connect(_on_level_timer_timeout)
	add_child(_level_timer)
	
	# Start test automatically
	print("[TransitionTest] Starting automated level transition test...")
	_start_test()


func _start_test() -> void:
	"""Begin the automated transition test."""
	_test_running = true
	_test_results.clear()
	_current_level_index = -1
	
	# Validate all level paths exist first
	print("[TransitionTest] Validating level paths...")
	var all_exist: bool = true
	for path in LEVEL_PATHS:
		if ResourceLoader.exists(path):
			print("  [PASS] %s exists" % path)
		else:
			print("  [FAIL] %s does not exist!" % path)
			all_exist = false
	
	if not all_exist:
		print("[TransitionTest] ABORTED: Some level paths are invalid.")
		_finish_test()
		return
	
	# Start with first level
	_next_level()


func _next_level() -> void:
	"""Load the next level in the test sequence."""
	_current_level_index += 1
	
	if _current_level_index >= LEVEL_PATHS.size():
		# All levels tested
		_finish_test()
		return
	
	var level_path: String = LEVEL_PATHS[_current_level_index]
	print("[TransitionTest] Loading level %d/%d: %s" % [
		_current_level_index + 1, 
		LEVEL_PATHS.size(), 
		level_path.get_file()
	])
	
	var result: Dictionary = {
		"level": level_path,
		"index": _current_level_index,
		"loaded": false,
		"error": ""
	}
	
	# Load level via GameManager if available
	if _game_manager:
		_game_manager.load_level(level_path, false)  # No fade for faster testing
	else:
		var error := get_tree().change_scene_to_file(level_path)
		if error != OK:
			result["error"] = "Failed to load scene: error %d" % error
			_test_results.append(result)
			print("  [FAIL] %s" % result["error"])
			_next_level()
			return
	
	# Wait for level to load then check
	await get_tree().process_frame
	await get_tree().process_frame
	
	result["loaded"] = true
	_test_results.append(result)
	print("  [PASS] Level loaded successfully")
	
	# Start timer for next level
	_level_timer.start(TIME_PER_LEVEL)


func _on_level_timer_timeout() -> void:
	"""Timer expired, move to next level."""
	if _test_running:
		_next_level()


func _finish_test() -> void:
	"""Complete the test and print summary."""
	_test_running = false
	
	print("")
	print("=" .repeat(60))
	print("[TransitionTest] TEST COMPLETE")
	print("=" .repeat(60))
	
	var passed: int = 0
	var failed: int = 0
	
	for result in _test_results:
		if result["loaded"]:
			passed += 1
			print("[PASS] %s" % result["level"].get_file())
		else:
			failed += 1
			print("[FAIL] %s - %s" % [result["level"].get_file(), result["error"]])
	
	print("")
	print("Results: %d passed, %d failed out of %d levels" % [passed, failed, LEVEL_PATHS.size()])
	
	if failed == 0:
		print("All level transitions working correctly!")
	else:
		print("Some levels failed to load. Check errors above.")
	
	print("=" .repeat(60))


func _input(event: InputEvent) -> void:
	"""Allow manual control during test."""
	if event.is_action_pressed("ui_cancel"):
		# Escape to abort test
		print("[TransitionTest] Test aborted by user.")
		_test_running = false
		_level_timer.stop()
	elif event.is_action_pressed("ui_accept"):
		# Skip to next level immediately
		if _test_running:
			_level_timer.stop()
			_next_level()


## Run a quick validation without loading levels.
static func validate_level_paths() -> Dictionary:
	"""Validate all level paths exist without loading them."""
	var results: Dictionary = {
		"valid": [],
		"invalid": []
	}
	
	for path in LEVEL_PATHS:
		if ResourceLoader.exists(path):
			results["valid"].append(path)
		else:
			results["invalid"].append(path)
	
	return results
