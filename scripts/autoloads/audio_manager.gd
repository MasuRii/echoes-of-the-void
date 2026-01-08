extends Node
## Centralized audio control for Echoes of the Void.
## Register as autoload "AudioManager" in Project Settings > Autoload.
## NOTE: Should be registered AFTER SaveManager autoload.
##
## Features:
## - Preloaded SFX caching for performance
## - Procedural audio fallback when .wav files are missing
## - Music crossfade support
## - Volume control with save/load persistence

# Preload the AudioFallback class for procedural sound generation
const AudioFallbackClass := preload("res://scripts/systems/audio_fallback.gd")

# Audio bus names
const BUS_MASTER: StringName = &"Master"
const BUS_MUSIC: StringName = &"Music"
const BUS_SFX: StringName = &"SFX"

# Preloaded SFX resources (add paths as sounds are created)
var _sfx_cache: Dictionary = {}

# Audio fallback system for procedural sound generation
var _audio_fallback: RefCounted = null

# Track which sounds are using fallback (for logging purposes)
var _fallback_sounds: Dictionary = {}

# Current music player reference
var _music_player: AudioStreamPlayer = null
var _music_tween: Tween = null

# Cached reference to SaveManager autoload
var _save_manager: Node = null


func _ready() -> void:
	# Run even when game is paused so audio can respond to pause/unpause
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Initialize the audio fallback system for procedural sounds
	_audio_fallback = AudioFallbackClass.new()
	
	# Create the music player node
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = BUS_MUSIC
	add_child(_music_player)
	
	# Get SaveManager reference
	_save_manager = get_node_or_null("/root/SaveManager")
	
	# Apply saved volume settings
	_apply_saved_settings()
	
	# Preload common SFX (with fallback for missing files)
	_preload_sfx()


func _apply_saved_settings() -> void:
	"""Apply volume settings from SaveManager."""
	if _save_manager == null:
		return
	
	var master_vol: float = _save_manager.get_setting("master_volume", 1.0)
	var music_vol: float = _save_manager.get_setting("music_volume", 0.8)
	var sfx_vol: float = _save_manager.get_setting("sfx_volume", 1.0)
	
	set_bus_volume(BUS_MASTER, master_vol)
	set_bus_volume(BUS_MUSIC, music_vol)
	set_bus_volume(BUS_SFX, sfx_vol)


func _preload_sfx() -> void:
	"""Preload common sound effects at startup."""
	# Define SFX to preload with their paths
	var sfx_paths: Dictionary = {
		# Player sounds
		"jump": "res://assets/audio/sfx/jump.wav",
		"double_jump": "res://assets/audio/sfx/double_jump.wav",
		"land": "res://assets/audio/sfx/land.wav",
		"wall_slide": "res://assets/audio/sfx/wall_slide.wav",
		"wall_jump": "res://assets/audio/sfx/wall_jump.wav",
		"death": "res://assets/audio/sfx/death.wav",
		"respawn": "res://assets/audio/sfx/respawn.wav",
		# Collectibles
		"shard_collect": "res://assets/audio/sfx/shard_collect.wav",
		"crystal_collect": "res://assets/audio/sfx/crystal_collect.wav",
		"checkpoint": "res://assets/audio/sfx/checkpoint.wav",
		# Enemies
		"enemy_death": "res://assets/audio/sfx/enemy_death.wav",
		# Environment
		"platform_crumble": "res://assets/audio/sfx/platform_crumble.wav",
		# UI
		"menu_select": "res://assets/audio/sfx/menu_select.wav",
		"menu_confirm": "res://assets/audio/sfx/menu_confirm.wav",
	}
	
	# Load each SFX if file exists (graceful failure for missing files)
	for sound_name in sfx_paths:
		var path: String = sfx_paths[sound_name]
		if ResourceLoader.exists(path):
			_sfx_cache[sound_name] = load(path)


# ============================================================
# SFX Playback
# ============================================================

func play_sfx(sound_name: String, volume_db: float = 0.0) -> void:
	"""Play a sound effect by name. Uses procedural fallback if file missing."""
	var stream: AudioStream = _get_sfx_stream(sound_name)
	if stream == null:
		# Only warn if fallback also failed (no definition exists)
		if OS.is_debug_build():
			push_warning("AudioManager: No SFX or fallback found for: %s" % sound_name)
		return
	
	# Create a one-shot player for this sound
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.bus = BUS_SFX
	add_child(player)
	player.play()
	
	# Auto-cleanup when finished
	player.finished.connect(player.queue_free)


func play_sfx_2d(sound_name: String, position: Vector2, volume_db: float = 0.0) -> AudioStreamPlayer2D:
	"""Play a positional sound effect. Uses procedural fallback if file missing."""
	var stream: AudioStream = _get_sfx_stream(sound_name)
	if stream == null:
		# Only warn if fallback also failed
		if OS.is_debug_build():
			push_warning("AudioManager: No SFX or fallback found for: %s" % sound_name)
		return null
	
	# Create a one-shot 2D player for this sound
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.volume_db = volume_db
	player.bus = BUS_SFX
	player.global_position = position
	add_child(player)
	player.play()
	
	# Auto-cleanup when finished
	player.finished.connect(player.queue_free)
	
	return player


func _get_sfx_stream(sound_name: String) -> AudioStream:
	"""Get an SFX stream from cache, load from file, or generate fallback."""
	# Check cache first
	if _sfx_cache.has(sound_name):
		return _sfx_cache[sound_name]
	
	# Try to load dynamically if not cached
	var possible_paths: Array[String] = [
		"res://assets/audio/sfx/%s.wav" % sound_name,
		"res://assets/audio/sfx/%s.ogg" % sound_name,
		"res://assets/audio/sfx/%s.mp3" % sound_name,
	]
	
	for path in possible_paths:
		if ResourceLoader.exists(path):
			var stream: AudioStream = load(path)
			_sfx_cache[sound_name] = stream
			return stream
	
	# File not found - use procedural fallback
	return _get_fallback_sound(sound_name)


func _get_fallback_sound(sound_name: String) -> AudioStream:
	"""Get or generate a procedural fallback sound when file is missing."""
	if _audio_fallback == null:
		return null
	
	# Log first time we use fallback for this sound
	if not _fallback_sounds.has(sound_name):
		_fallback_sounds[sound_name] = true
		if OS.is_debug_build():
			push_warning("AudioManager: Using procedural fallback for missing sound '%s'" % sound_name)
	
	# Get or generate the fallback sound
	var stream: AudioStream = _audio_fallback.get_sound(sound_name)
	
	# Cache it for future use
	if stream != null:
		_sfx_cache[sound_name] = stream
	
	return stream


# ============================================================
# Music Playback
# ============================================================

func play_music(track_name: String, fade_duration: float = 1.0) -> void:
	"""Play a music track with optional fade-in. Fades out current music first."""
	var stream: AudioStream = _get_music_stream(track_name)
	if stream == null:
		push_warning("AudioManager: Music track not found: %s" % track_name)
		return
	
	# If same track is already playing, do nothing
	if _music_player.stream == stream and _music_player.playing:
		return
	
	# Cancel any existing tween
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	
	# Fade out current music if playing
	if _music_player.playing and fade_duration > 0:
		_music_tween = create_tween()
		_music_tween.tween_property(_music_player, "volume_db", -80.0, fade_duration * 0.5)
		await _music_tween.finished
	
	# Switch to new track
	_music_player.stream = stream
	
	# Fade in new music
	if fade_duration > 0:
		_music_player.volume_db = -80.0
		_music_player.play()
		_music_tween = create_tween()
		_music_tween.tween_property(_music_player, "volume_db", 0.0, fade_duration * 0.5)
	else:
		_music_player.volume_db = 0.0
		_music_player.play()


func stop_music(fade_duration: float = 1.0) -> void:
	"""Stop the current music with optional fade-out."""
	if not _music_player.playing:
		return
	
	# Cancel any existing tween
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	
	if fade_duration > 0:
		_music_tween = create_tween()
		_music_tween.tween_property(_music_player, "volume_db", -80.0, fade_duration)
		await _music_tween.finished
		_music_player.stop()
	else:
		_music_player.stop()


func pause_music() -> void:
	"""Pause the current music."""
	_music_player.stream_paused = true


func resume_music() -> void:
	"""Resume paused music."""
	_music_player.stream_paused = false


func is_music_playing() -> bool:
	"""Check if music is currently playing."""
	return _music_player.playing and not _music_player.stream_paused


func _get_music_stream(track_name: String) -> AudioStream:
	"""Get a music stream by track name."""
	var possible_paths: Array[String] = [
		"res://assets/audio/music/%s.ogg" % track_name,
		"res://assets/audio/music/%s.mp3" % track_name,
		"res://assets/audio/music/%s.wav" % track_name,
	]
	
	for path in possible_paths:
		if ResourceLoader.exists(path):
			return load(path)
	
	return null


# ============================================================
# Volume Control
# ============================================================

func set_music_volume(value: float) -> void:
	"""Set music volume (0.0 to 1.0) and save to settings."""
	value = clampf(value, 0.0, 1.0)
	set_bus_volume(BUS_MUSIC, value)
	
	if _save_manager:
		_save_manager.set_setting("music_volume", value)


func set_sfx_volume(value: float) -> void:
	"""Set SFX volume (0.0 to 1.0) and save to settings."""
	value = clampf(value, 0.0, 1.0)
	set_bus_volume(BUS_SFX, value)
	
	if _save_manager:
		_save_manager.set_setting("sfx_volume", value)


func set_master_volume(value: float) -> void:
	"""Set master volume (0.0 to 1.0) and save to settings."""
	value = clampf(value, 0.0, 1.0)
	set_bus_volume(BUS_MASTER, value)
	
	if _save_manager:
		_save_manager.set_setting("master_volume", value)


func get_music_volume() -> float:
	"""Get current music volume (0.0 to 1.0)."""
	return get_bus_volume(BUS_MUSIC)


func get_sfx_volume() -> float:
	"""Get current SFX volume (0.0 to 1.0)."""
	return get_bus_volume(BUS_SFX)


func get_master_volume() -> float:
	"""Get current master volume (0.0 to 1.0)."""
	return get_bus_volume(BUS_MASTER)


func set_bus_volume(bus_name: StringName, linear_value: float) -> void:
	"""Set an audio bus volume using linear value (0.0 to 1.0)."""
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx < 0:
		push_warning("AudioManager: Audio bus not found: %s" % bus_name)
		return
	
	# Convert linear (0-1) to decibels
	var db: float
	if linear_value <= 0.0:
		db = -80.0  # Effectively muted
	else:
		db = linear_to_db(linear_value)
	
	AudioServer.set_bus_volume_db(bus_idx, db)


func get_bus_volume(bus_name: StringName) -> float:
	"""Get an audio bus volume as linear value (0.0 to 1.0)."""
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx < 0:
		return 1.0
	
	var db: float = AudioServer.get_bus_volume_db(bus_idx)
	if db <= -80.0:
		return 0.0
	
	return db_to_linear(db)


func set_bus_mute(bus_name: StringName, muted: bool) -> void:
	"""Mute or unmute an audio bus."""
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx < 0:
		push_warning("AudioManager: Audio bus not found: %s" % bus_name)
		return
	
	AudioServer.set_bus_mute(bus_idx, muted)


# ============================================================
# Fallback System Utilities
# ============================================================

func has_fallback_sound(sound_name: String) -> bool:
	"""Check if a procedural fallback exists for the given sound name."""
	if _audio_fallback == null:
		return false
	return _audio_fallback.has_sound(sound_name)


func is_using_fallback(sound_name: String) -> bool:
	"""Check if a sound is currently using a procedural fallback."""
	return _fallback_sounds.has(sound_name)


func get_fallback_sounds_in_use() -> Array:
	"""Get list of all sounds currently using fallback (for debugging)."""
	return _fallback_sounds.keys()


func clear_audio_cache() -> void:
	"""Clear the SFX cache and fallback cache (useful for hot-reloading)."""
	_sfx_cache.clear()
	_fallback_sounds.clear()
	if _audio_fallback != null:
		_audio_fallback.clear_cache()
