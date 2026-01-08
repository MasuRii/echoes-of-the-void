class_name PerformanceProfiler
extends CanvasLayer

## Performance profiling and monitoring tool.
## Displays frame time, FPS, particle count, memory usage, and performance statistics.
## Toggle visibility with F6 key in debug builds, reset stats with Shift+F6.
##
## Usage: Add as child of any scene, or instantiate via code.
## Automatically tracks performance metrics when visible.

# Visual constants
const PANEL_BG_COLOR: Color = Color(0.0, 0.0, 0.0, 0.85)
const PANEL_BORDER_COLOR: Color = Color(1.0, 1.0, 1.0, 0.6)
const TEXT_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)
const GOOD_COLOR: Color = Color(0.0, 1.0, 0.0, 1.0)  # Green - good performance
const WARN_COLOR: Color = Color(1.0, 1.0, 0.0, 1.0)  # Yellow - warning
const BAD_COLOR: Color = Color(1.0, 0.0, 0.0, 1.0)  # Red - poor performance
const HEADER_COLOR: Color = Color(0.0, 1.0, 1.0, 1.0)  # Cyan headers

# Target thresholds
const TARGET_FPS: float = 60.0
const TARGET_FRAME_TIME_MS: float = 16.67  # 1000 / 60
const WARN_FRAME_TIME_MS: float = 20.0  # ~50 FPS
const BAD_FRAME_TIME_MS: float = 33.33  # ~30 FPS

# Particle count thresholds
const WARN_PARTICLE_COUNT: int = 1000
const BAD_PARTICLE_COUNT: int = 5000

# Memory thresholds (in MB)
const WARN_MEMORY_MB: float = 256.0
const BAD_MEMORY_MB: float = 512.0

# Sample sizes for averaging
const FRAME_SAMPLE_COUNT: int = 60
const HISTORY_SIZE: int = 120  # 2 seconds at 60 FPS

# Profiling state
var _debug_visible: bool = false
var _profiling_active: bool = false

# Frame time tracking
var _frame_times: PackedFloat64Array = []
var _frame_time_history: PackedFloat64Array = []
var _min_frame_time: float = INF
var _max_frame_time: float = 0.0
var _total_frame_time: float = 0.0
var _frame_count: int = 0

# FPS tracking
var _fps_history: PackedFloat64Array = []
var _current_fps: float = 0.0
var _min_fps: float = INF
var _max_fps: float = 0.0
var _avg_fps: float = 0.0

# Particle tracking
var _total_particles: int = 0
var _active_particle_systems: int = 0
var _max_particles_seen: int = 0

# Memory tracking
var _static_memory_mb: float = 0.0
var _peak_static_memory_mb: float = 0.0

# Physics tracking
var _physics_time_ms: float = 0.0
var _collision_objects: int = 0

# Session stats
var _session_start_time: int = 0
var _total_frames_profiled: int = 0
var _frames_below_target: int = 0
var _worst_frame_time: float = 0.0

# UI nodes
var _panel: PanelContainer
var _label: RichTextLabel


func _ready() -> void:
	# Set layer to render above game
	layer = 100
	
	# Create UI
	_create_ui()
	
	# Start hidden unless in debug mode
	_debug_visible = false
	_panel.visible = false
	
	# Initialize session
	_session_start_time = Time.get_ticks_msec()
	
	print("PerformanceProfiler: Ready (F6 to toggle, Shift+F6 to reset)")


func _create_ui() -> void:
	"""Create the profiler UI panel."""
	# Create panel container
	_panel = PanelContainer.new()
	_panel.name = "ProfilerPanel"
	
	# Style the panel
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG_COLOR
	style.border_color = PANEL_BORDER_COLOR
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	_panel.add_theme_stylebox_override("panel", style)
	
	# Position in top-right corner
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 0.0
	_panel.anchor_bottom = 0.0
	_panel.offset_left = -320
	_panel.offset_right = -10
	_panel.offset_top = 10
	
	# Create rich text label for formatted output
	_label = RichTextLabel.new()
	_label.name = "ProfilerLabel"
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.custom_minimum_size = Vector2(300, 200)
	_label.scroll_active = false
	
	_panel.add_child(_label)
	add_child(_panel)


func _process(delta: float) -> void:
	# Handle input
	_handle_input()
	
	if not _debug_visible:
		return
	
	# Track performance
	_track_frame_time(delta)
	_track_particles()
	_track_memory()
	_track_physics()
	
	# Update display
	_update_display()


func _handle_input() -> void:
	"""Handle profiler toggle input."""
	if Input.is_action_just_pressed("ui_text_caret_document_end"):
		# This won't work, need raw input
		pass


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F6:
			if event.shift_pressed:
				# Shift+F6: Reset statistics
				_reset_statistics()
			else:
				# F6: Toggle visibility
				_toggle_visibility()
			get_viewport().set_input_as_handled()


func _toggle_visibility() -> void:
	"""Toggle profiler visibility."""
	_debug_visible = not _debug_visible
	_panel.visible = _debug_visible
	_profiling_active = _debug_visible
	
	if _debug_visible:
		print("PerformanceProfiler: ENABLED (Shift+F6 to reset stats)")
	else:
		print("PerformanceProfiler: DISABLED")


func _reset_statistics() -> void:
	"""Reset all tracked statistics."""
	_frame_times.clear()
	_frame_time_history.clear()
	_fps_history.clear()
	
	_min_frame_time = INF
	_max_frame_time = 0.0
	_total_frame_time = 0.0
	_frame_count = 0
	
	_min_fps = INF
	_max_fps = 0.0
	_avg_fps = 0.0
	
	_max_particles_seen = 0
	_peak_static_memory_mb = 0.0
	
	_session_start_time = Time.get_ticks_msec()
	_total_frames_profiled = 0
	_frames_below_target = 0
	_worst_frame_time = 0.0
	
	print("PerformanceProfiler: Statistics reset")


func _track_frame_time(delta: float) -> void:
	"""Track frame time and FPS."""
	var frame_time_ms := delta * 1000.0
	
	# Update running stats
	_frame_count += 1
	_total_frames_profiled += 1
	_total_frame_time += frame_time_ms
	
	# Track min/max
	if frame_time_ms < _min_frame_time:
		_min_frame_time = frame_time_ms
	if frame_time_ms > _max_frame_time:
		_max_frame_time = frame_time_ms
	if frame_time_ms > _worst_frame_time:
		_worst_frame_time = frame_time_ms
	
	# Track frames below target
	if frame_time_ms > TARGET_FRAME_TIME_MS:
		_frames_below_target += 1
	
	# Add to sample buffer
	_frame_times.append(frame_time_ms)
	if _frame_times.size() > FRAME_SAMPLE_COUNT:
		_frame_times.remove_at(0)
	
	# Add to history for graph
	_frame_time_history.append(frame_time_ms)
	if _frame_time_history.size() > HISTORY_SIZE:
		_frame_time_history.remove_at(0)
	
	# Calculate FPS
	_current_fps = 1.0 / delta if delta > 0 else 0.0
	
	# Track FPS history
	_fps_history.append(_current_fps)
	if _fps_history.size() > FRAME_SAMPLE_COUNT:
		_fps_history.remove_at(0)
	
	# Calculate FPS stats
	if _fps_history.size() > 0:
		var total: float = 0.0
		var local_min: float = INF
		var local_max: float = 0.0
		for fps in _fps_history:
			total += fps
			if fps < local_min:
				local_min = fps
			if fps > local_max:
				local_max = fps
		_avg_fps = total / _fps_history.size()
		_min_fps = local_min
		_max_fps = local_max


func _track_particles() -> void:
	"""Count active particles in the scene."""
	_total_particles = 0
	_active_particle_systems = 0
	
	# Find all particle systems in the scene tree
	var particles := _find_all_particles(get_tree().current_scene)
	
	for particle_system in particles:
		_active_particle_systems += 1
		if particle_system is GPUParticles2D:
			# GPUParticles2D amount is the max, not current
			# We estimate based on emitting state
			if particle_system.emitting:
				_total_particles += particle_system.amount
		elif particle_system is CPUParticles2D:
			if particle_system.emitting:
				_total_particles += particle_system.amount
	
	# Track peak
	if _total_particles > _max_particles_seen:
		_max_particles_seen = _total_particles


func _find_all_particles(node: Node) -> Array:
	"""Recursively find all particle systems."""
	var result: Array = []
	
	if node == null:
		return result
	
	if node is GPUParticles2D or node is CPUParticles2D:
		result.append(node)
	
	for child in node.get_children():
		result.append_array(_find_all_particles(child))
	
	return result


func _track_memory() -> void:
	"""Track memory usage."""
	_static_memory_mb = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	
	if _static_memory_mb > _peak_static_memory_mb:
		_peak_static_memory_mb = _static_memory_mb


func _track_physics() -> void:
	"""Track physics performance."""
	_physics_time_ms = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	_collision_objects = int(Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS))


func _update_display() -> void:
	"""Update the profiler display."""
	var text := ""
	
	# Header
	text += "[color=#00FFFF][b]PERFORMANCE PROFILER (F6)[/b][/color]\n"
	text += "[color=#888888]Shift+F6 to reset stats[/color]\n\n"
	
	# Frame Time section
	text += "[color=#00FFFF]═══ FRAME TIME ═══[/color]\n"
	var avg_frame_time := _total_frame_time / _frame_count if _frame_count > 0 else 0.0
	
	# Current frame time with color coding
	var current_ft := _frame_time_history[-1] if _frame_time_history.size() > 0 else 0.0
	var ft_color := _get_frame_time_color(current_ft)
	text += "Current: [color=%s]%.2f ms[/color]\n" % [ft_color, current_ft]
	
	# Min/Avg/Max
	text += "Min: [color=#00FF00]%.2f ms[/color]  " % _min_frame_time if _min_frame_time != INF else "Min: --- ms  "
	text += "Avg: %.2f ms  " % avg_frame_time
	text += "Max: [color=%s]%.2f ms[/color]\n" % [_get_frame_time_color(_max_frame_time), _max_frame_time]
	text += "\n"
	
	# FPS section
	text += "[color=#00FFFF]═══ FPS ═══[/color]\n"
	var fps_color := _get_fps_color(_current_fps)
	text += "Current: [color=%s]%.1f FPS[/color]\n" % [fps_color, _current_fps]
	text += "Min: [color=%s]%.1f[/color]  " % [_get_fps_color(_min_fps), _min_fps] if _min_fps != INF else "Min: ---  "
	text += "Avg: %.1f  " % _avg_fps
	text += "Max: [color=#00FF00]%.1f[/color]\n" % _max_fps
	
	# Target indicator
	var target_met := _current_fps >= TARGET_FPS
	var target_text := "TARGET: %d FPS " % int(TARGET_FPS)
	target_text += "[color=#00FF00]✓ MET[/color]" if target_met else "[color=#FF0000]✗ MISSED[/color]"
	text += target_text + "\n\n"
	
	# Particles section
	text += "[color=#00FFFF]═══ PARTICLES ═══[/color]\n"
	var particle_color := _get_particle_color(_total_particles)
	text += "Active: [color=%s]%d[/color]  " % [particle_color, _total_particles]
	text += "Systems: %d  " % _active_particle_systems
	text += "Peak: %d\n\n" % _max_particles_seen
	
	# Memory section
	text += "[color=#00FFFF]═══ MEMORY ═══[/color]\n"
	var memory_color := _get_memory_color(_static_memory_mb)
	text += "Static: [color=%s]%.1f MB[/color]  " % [memory_color, _static_memory_mb]
	text += "Peak: %.1f MB\n\n" % _peak_static_memory_mb
	
	# Physics section
	text += "[color=#00FFFF]═══ PHYSICS ═══[/color]\n"
	text += "Physics Time: %.2f ms  " % _physics_time_ms
	text += "Objects: %d\n\n" % _collision_objects
	
	# Session stats
	text += "[color=#00FFFF]═══ SESSION ═══[/color]\n"
	var session_time_sec := (Time.get_ticks_msec() - _session_start_time) / 1000.0
	text += "Runtime: %.1f sec  Frames: %d\n" % [session_time_sec, _total_frames_profiled]
	
	# Calculate percentage of frames meeting target
	var frames_at_target := _total_frames_profiled - _frames_below_target
	var target_percentage := (float(frames_at_target) / _total_frames_profiled * 100.0) if _total_frames_profiled > 0 else 100.0
	var perc_color := "#00FF00" if target_percentage >= 95.0 else ("#FFFF00" if target_percentage >= 80.0 else "#FF0000")
	text += "At Target: [color=%s]%.1f%%[/color]  " % [perc_color, target_percentage]
	text += "Worst: %.2f ms\n" % _worst_frame_time
	
	_label.text = text


func _get_frame_time_color(frame_time_ms: float) -> String:
	"""Get color string for frame time value."""
	if frame_time_ms <= TARGET_FRAME_TIME_MS:
		return "#00FF00"  # Good (green)
	elif frame_time_ms <= WARN_FRAME_TIME_MS:
		return "#FFFF00"  # Warning (yellow)
	else:
		return "#FF0000"  # Bad (red)


func _get_fps_color(fps: float) -> String:
	"""Get color string for FPS value."""
	if fps >= TARGET_FPS:
		return "#00FF00"  # Good (green)
	elif fps >= 45.0:
		return "#FFFF00"  # Warning (yellow)
	else:
		return "#FF0000"  # Bad (red)


func _get_particle_color(count: int) -> String:
	"""Get color string for particle count."""
	if count < WARN_PARTICLE_COUNT:
		return "#00FF00"  # Good
	elif count < BAD_PARTICLE_COUNT:
		return "#FFFF00"  # Warning
	else:
		return "#FF0000"  # Bad


func _get_memory_color(memory_mb: float) -> String:
	"""Get color string for memory usage."""
	if memory_mb < WARN_MEMORY_MB:
		return "#00FF00"  # Good
	elif memory_mb < BAD_MEMORY_MB:
		return "#FFFF00"  # Warning
	else:
		return "#FF0000"  # Bad


## Get performance summary for external use.
func get_performance_summary() -> Dictionary:
	var avg_frame_time := _total_frame_time / _frame_count if _frame_count > 0 else 0.0
	var frames_at_target := _total_frames_profiled - _frames_below_target
	var target_percentage := (float(frames_at_target) / _total_frames_profiled * 100.0) if _total_frames_profiled > 0 else 100.0
	
	return {
		"current_fps": _current_fps,
		"avg_fps": _avg_fps,
		"min_fps": _min_fps if _min_fps != INF else 0.0,
		"max_fps": _max_fps,
		"avg_frame_time_ms": avg_frame_time,
		"min_frame_time_ms": _min_frame_time if _min_frame_time != INF else 0.0,
		"max_frame_time_ms": _max_frame_time,
		"worst_frame_time_ms": _worst_frame_time,
		"total_particles": _total_particles,
		"max_particles": _max_particles_seen,
		"particle_systems": _active_particle_systems,
		"static_memory_mb": _static_memory_mb,
		"peak_memory_mb": _peak_static_memory_mb,
		"physics_time_ms": _physics_time_ms,
		"collision_objects": _collision_objects,
		"total_frames": _total_frames_profiled,
		"frames_at_target_percent": target_percentage,
		"session_time_sec": (Time.get_ticks_msec() - _session_start_time) / 1000.0,
		"meets_60fps_target": _current_fps >= TARGET_FPS
	}


## Print performance summary to console.
func print_summary() -> void:
	var summary := get_performance_summary()
	print("\n=== PERFORMANCE SUMMARY ===")
	print("FPS: %.1f avg (%.1f - %.1f range)" % [summary.avg_fps, summary.min_fps, summary.max_fps])
	print("Frame Time: %.2f ms avg (%.2f - %.2f range)" % [summary.avg_frame_time_ms, summary.min_frame_time_ms, summary.max_frame_time_ms])
	print("Particles: %d active, %d peak (%d systems)" % [summary.total_particles, summary.max_particles, summary.particle_systems])
	print("Memory: %.1f MB static, %.1f MB peak" % [summary.static_memory_mb, summary.peak_memory_mb])
	print("Physics: %.2f ms, %d objects" % [summary.physics_time_ms, summary.collision_objects])
	print("Session: %d frames over %.1f sec" % [summary.total_frames, summary.session_time_sec])
	print("Target Met: %.1f%% of frames at %d FPS" % [summary.frames_at_target_percent, int(TARGET_FPS)])
	print("60 FPS Target: %s" % ("PASSING" if summary.meets_60fps_target else "FAILING"))
	print("===========================\n")


## Check if performance is acceptable (meets 60 FPS target).
func is_performance_acceptable() -> bool:
	var summary := get_performance_summary()
	return summary.frames_at_target_percent >= 95.0


## Force enable profiling (for automated tests).
func enable_profiling() -> void:
	_debug_visible = true
	_panel.visible = true
	_profiling_active = true


## Force disable profiling.
func disable_profiling() -> void:
	_debug_visible = false
	_panel.visible = false
	_profiling_active = false
