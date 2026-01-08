class_name AudioFallback
extends RefCounted
## Procedural audio generation fallback for when audio files are missing.
## Generates simple beep/tone sounds programmatically using AudioStreamGenerator.
##
## This system ensures the game remains playable with audio feedback
## even when .wav files are not found. Each sound type has a unique
## procedural signature to maintain audio clarity and recognition.

# Common audio generation parameters
const SAMPLE_RATE: float = 44100.0
const DEFAULT_VOLUME: float = 0.3

## Sound type definitions for procedural generation
## Each entry defines: frequency, duration, wave_type, and optional envelope/modulation
const SOUND_DEFINITIONS: Dictionary = {
	# Player movement sounds
	"jump": {
		"frequency": 440.0,
		"duration": 0.12,
		"wave_type": "sine",
		"pitch_sweep": 1.5,  # Frequency multiplier at end
		"attack": 0.01,
		"decay": 0.11,
	},
	"double_jump": {
		"frequency": 660.0,
		"duration": 0.15,
		"wave_type": "sine",
		"pitch_sweep": 1.8,
		"attack": 0.01,
		"decay": 0.14,
	},
	"land": {
		"frequency": 120.0,
		"duration": 0.08,
		"wave_type": "noise_filtered",
		"attack": 0.005,
		"decay": 0.075,
	},
	"wall_slide": {
		"frequency": 200.0,
		"duration": 0.3,
		"wave_type": "noise_filtered",
		"attack": 0.05,
		"decay": 0.05,
		"loop": true,
	},
	"wall_jump": {
		"frequency": 550.0,
		"duration": 0.1,
		"wave_type": "triangle",
		"pitch_sweep": 1.3,
		"attack": 0.01,
		"decay": 0.09,
	},
	
	# Player state sounds
	"death": {
		"frequency": 300.0,
		"duration": 0.5,
		"wave_type": "sine",
		"pitch_sweep": 0.3,  # Pitch goes down
		"attack": 0.02,
		"decay": 0.48,
	},
	"respawn": {
		"frequency": 300.0,
		"duration": 0.4,
		"wave_type": "sine",
		"pitch_sweep": 2.0,  # Pitch rises
		"attack": 0.05,
		"decay": 0.35,
	},
	
	# Collectible sounds
	"shard_collect": {
		"frequency": 880.0,
		"duration": 0.15,
		"wave_type": "sine",
		"pitch_sweep": 1.2,
		"attack": 0.01,
		"decay": 0.14,
	},
	"crystal_collect": {
		"frequency": 523.25,  # C5
		"duration": 0.6,
		"wave_type": "sine",
		"chord": [1.0, 1.26, 1.5],  # Major chord ratios
		"attack": 0.02,
		"decay": 0.58,
	},
	"checkpoint": {
		"frequency": 440.0,
		"duration": 0.3,
		"wave_type": "sine",
		"chord": [1.0, 1.5],  # Fifth interval
		"attack": 0.02,
		"decay": 0.28,
	},
	
	# Environment sounds
	"enemy_death": {
		"frequency": 180.0,
		"duration": 0.25,
		"wave_type": "noise_filtered",
		"pitch_sweep": 0.5,
		"attack": 0.01,
		"decay": 0.24,
	},
	"platform_crumble": {
		"frequency": 150.0,
		"duration": 0.35,
		"wave_type": "noise_filtered",
		"pitch_sweep": 0.4,
		"attack": 0.02,
		"decay": 0.33,
	},
	
	# Phase platform sounds
	"phase_in": {
		"frequency": 600.0,
		"duration": 0.15,
		"wave_type": "sine",
		"pitch_sweep": 1.3,
		"attack": 0.02,
		"decay": 0.13,
	},
	"phase_out": {
		"frequency": 500.0,
		"duration": 0.15,
		"wave_type": "sine",
		"pitch_sweep": 0.7,
		"attack": 0.02,
		"decay": 0.13,
	},
	
	# UI sounds
	"menu_select": {
		"frequency": 700.0,
		"duration": 0.05,
		"wave_type": "square_soft",
		"attack": 0.005,
		"decay": 0.045,
	},
	"menu_confirm": {
		"frequency": 880.0,
		"duration": 0.12,
		"wave_type": "sine",
		"pitch_sweep": 1.2,
		"attack": 0.01,
		"decay": 0.11,
	},
	
	# Footstep sounds
	"footstep_01": {
		"frequency": 100.0,
		"duration": 0.04,
		"wave_type": "noise_filtered",
		"attack": 0.005,
		"decay": 0.035,
	},
	"footstep_02": {
		"frequency": 110.0,
		"duration": 0.04,
		"wave_type": "noise_filtered",
		"attack": 0.005,
		"decay": 0.035,
	},
}

# Cached generated streams for reuse
var _cache: Dictionary = {}

# Random number generator for noise
var _rng: RandomNumberGenerator


func _init() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()


## Check if a sound definition exists
func has_sound(sound_name: String) -> bool:
	return SOUND_DEFINITIONS.has(sound_name)


## Generate or retrieve a cached procedural sound
func get_sound(sound_name: String) -> AudioStream:
	# Return cached version if available
	if _cache.has(sound_name):
		return _cache[sound_name]
	
	# Check if we have a definition for this sound
	if not SOUND_DEFINITIONS.has(sound_name):
		push_warning("AudioFallback: No definition for sound '%s', using default beep" % sound_name)
		return _generate_default_beep()
	
	# Generate the sound based on definition
	var definition: Dictionary = SOUND_DEFINITIONS[sound_name]
	var stream: AudioStream = _generate_sound(definition)
	
	# Cache for future use
	_cache[sound_name] = stream
	
	return stream


## Generate a default fallback beep for unknown sounds
func _generate_default_beep() -> AudioStreamWAV:
	var definition: Dictionary = {
		"frequency": 440.0,
		"duration": 0.1,
		"wave_type": "sine",
		"attack": 0.01,
		"decay": 0.09,
	}
	return _generate_sound(definition)


## Generate a sound based on a definition dictionary
func _generate_sound(definition: Dictionary) -> AudioStreamWAV:
	var frequency: float = definition.get("frequency", 440.0)
	var duration: float = definition.get("duration", 0.1)
	var wave_type: String = definition.get("wave_type", "sine")
	var pitch_sweep: float = definition.get("pitch_sweep", 1.0)
	var attack: float = definition.get("attack", 0.01)
	var decay: float = definition.get("decay", duration - attack)
	var chord: Array = definition.get("chord", [])
	
	var sample_count: int = int(duration * SAMPLE_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count * 2)  # 16-bit audio = 2 bytes per sample
	
	for i in range(sample_count):
		var t: float = float(i) / SAMPLE_RATE
		var normalized_t: float = float(i) / float(sample_count)
		
		# Calculate current frequency with pitch sweep
		var current_freq: float = frequency * lerpf(1.0, pitch_sweep, normalized_t)
		
		# Generate waveform sample
		var sample: float = 0.0
		
		if chord.size() > 0:
			# Generate chord (multiple frequencies)
			for ratio in chord:
				sample += _generate_wave_sample(t, current_freq * ratio, wave_type)
			sample /= chord.size()
		else:
			sample = _generate_wave_sample(t, current_freq, wave_type)
		
		# Apply envelope
		var envelope: float = _calculate_envelope(t, duration, attack, decay)
		sample *= envelope * DEFAULT_VOLUME
		
		# Convert to 16-bit signed integer
		var sample_int: int = clampi(int(sample * 32767.0), -32768, 32767)
		
		# Write to byte array (little-endian)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	# Create AudioStreamWAV
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(SAMPLE_RATE)
	stream.stereo = false
	stream.data = data
	
	return stream


## Generate a single wave sample at time t for given frequency
func _generate_wave_sample(t: float, frequency: float, wave_type: String) -> float:
	var phase: float = t * frequency * TAU
	
	match wave_type:
		"sine":
			return sin(phase)
		"square":
			return 1.0 if sin(phase) > 0 else -1.0
		"square_soft":
			# Softened square wave (less harsh harmonics)
			var square: float = 1.0 if sin(phase) > 0 else -1.0
			return square * 0.7 + sin(phase) * 0.3
		"triangle":
			# Triangle wave
			var normalized: float = fmod(t * frequency, 1.0)
			if normalized < 0.5:
				return normalized * 4.0 - 1.0
			else:
				return 3.0 - normalized * 4.0
		"sawtooth":
			var normalized: float = fmod(t * frequency, 1.0)
			return normalized * 2.0 - 1.0
		"noise_filtered":
			# Filtered noise (more of a rumble/thump)
			var noise: float = _rng.randf_range(-1.0, 1.0)
			# Simple low-pass by mixing with sine
			return noise * 0.4 + sin(phase * 0.5) * 0.6
		_:
			return sin(phase)


## Calculate amplitude envelope (attack-sustain-decay)
func _calculate_envelope(t: float, duration: float, attack: float, decay_time: float) -> float:
	if t < attack:
		# Attack phase - ramp up
		return t / attack
	elif t > duration - decay_time:
		# Decay phase - ramp down
		var decay_progress: float = (t - (duration - decay_time)) / decay_time
		return 1.0 - decay_progress
	else:
		# Sustain phase
		return 1.0


## Clear the cache to free memory
func clear_cache() -> void:
	_cache.clear()


## Pregenerate all defined sounds into cache
func pregenerate_all() -> void:
	for sound_name in SOUND_DEFINITIONS.keys():
		if not _cache.has(sound_name):
			var _stream: AudioStream = get_sound(sound_name)
