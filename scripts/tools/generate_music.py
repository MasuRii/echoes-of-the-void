#!/usr/bin/env python3
"""
Generate placeholder music tracks for Echoes of the Void.
Creates simple looping WAV files using procedural synthesis.
These are atmospheric, minimalist tracks appropriate for a void-themed platformer.
"""

import struct
import math
import os
import random

# WAV file parameters
SAMPLE_RATE = 44100
CHANNELS = 2  # Stereo for music
BITS_PER_SAMPLE = 16


def write_wav_stereo(
    filename: str, left_samples: list[int], right_samples: list[int]
) -> None:
    """Write stereo 16-bit samples to a WAV file."""
    num_samples = len(left_samples)
    data_size = num_samples * (BITS_PER_SAMPLE // 8) * CHANNELS
    file_size = 36 + data_size

    with open(filename, "wb") as f:
        # RIFF header
        f.write(b"RIFF")
        f.write(struct.pack("<I", file_size))
        f.write(b"WAVE")

        # Format chunk
        f.write(b"fmt ")
        f.write(struct.pack("<I", 16))  # Chunk size
        f.write(struct.pack("<H", 1))  # PCM format
        f.write(struct.pack("<H", CHANNELS))
        f.write(struct.pack("<I", SAMPLE_RATE))
        f.write(struct.pack("<I", SAMPLE_RATE * CHANNELS * (BITS_PER_SAMPLE // 8)))
        f.write(struct.pack("<H", CHANNELS * (BITS_PER_SAMPLE // 8)))
        f.write(struct.pack("<H", BITS_PER_SAMPLE))

        # Data chunk
        f.write(b"data")
        f.write(struct.pack("<I", data_size))
        for i in range(num_samples):
            left = max(-32768, min(32767, left_samples[i]))
            right = max(-32768, min(32767, right_samples[i]))
            f.write(struct.pack("<h", left))
            f.write(struct.pack("<h", right))


def generate_sine(
    freq: float, duration: float, volume: float = 0.5, phase: float = 0.0
) -> list[int]:
    """Generate a sine wave."""
    samples = []
    num_samples = int(SAMPLE_RATE * duration)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        sample = int(math.sin(2 * math.pi * freq * t + phase) * 32767 * volume)
        samples.append(sample)
    return samples


def generate_triangle(freq: float, duration: float, volume: float = 0.5) -> list[int]:
    """Generate a triangle wave (softer than sine)."""
    samples = []
    num_samples = int(SAMPLE_RATE * duration)
    period = SAMPLE_RATE / freq
    for i in range(num_samples):
        pos = (i % period) / period
        if pos < 0.5:
            value = 4 * pos - 1
        else:
            value = 3 - 4 * pos
        sample = int(value * 32767 * volume)
        samples.append(sample)
    return samples


def apply_envelope(
    samples: list[int],
    attack: float = 0.1,
    decay: float = 0.1,
    sustain: float = 0.7,
    release: float = 0.2,
) -> list[int]:
    """Apply ADSR envelope to samples."""
    num_samples = len(samples)

    attack_samples = int(attack * SAMPLE_RATE)
    decay_samples = int(decay * SAMPLE_RATE)
    release_samples = int(release * SAMPLE_RATE)
    sustain_samples = max(
        0, num_samples - attack_samples - decay_samples - release_samples
    )

    result = []
    for i, sample in enumerate(samples):
        if i < attack_samples:
            envelope = i / attack_samples if attack_samples > 0 else 1.0
        elif i < attack_samples + decay_samples:
            progress = (
                (i - attack_samples) / decay_samples if decay_samples > 0 else 1.0
            )
            envelope = 1.0 - (1.0 - sustain) * progress
        elif i < attack_samples + decay_samples + sustain_samples:
            envelope = sustain
        else:
            progress = (
                (i - attack_samples - decay_samples - sustain_samples) / release_samples
                if release_samples > 0
                else 1.0
            )
            envelope = sustain * (1.0 - progress)

        result.append(int(sample * envelope))
    return result


def apply_fade(
    samples: list[int], fade_in: float = 0.5, fade_out: float = 0.5
) -> list[int]:
    """Apply simple fade in and fade out."""
    result = samples.copy()
    num_samples = len(result)

    fade_in_samples = int(fade_in * SAMPLE_RATE)
    fade_out_samples = int(fade_out * SAMPLE_RATE)

    for i in range(min(fade_in_samples, num_samples)):
        result[i] = int(result[i] * (i / fade_in_samples))

    for i in range(min(fade_out_samples, num_samples)):
        idx = num_samples - 1 - i
        result[idx] = int(result[idx] * (i / fade_out_samples))

    return result


def mix_samples(*sample_lists: list[int]) -> list[int]:
    """Mix multiple sample lists together."""
    max_len = max(len(s) for s in sample_lists) if sample_lists else 0
    result = [0] * max_len
    for samples in sample_lists:
        for i, sample in enumerate(samples):
            result[i] += sample
    # Normalize to prevent clipping
    max_val = max(abs(s) for s in result) if result else 1
    if max_val > 32767:
        result = [int(s * 32767 / max_val) for s in result]
    return result


def add_samples(base: list[int], overlay: list[int], offset: int = 0) -> list[int]:
    """Add overlay samples to base at a given offset."""
    result = base.copy()
    for i, sample in enumerate(overlay):
        idx = offset + i
        if 0 <= idx < len(result):
            result[idx] = max(-32768, min(32767, result[idx] + sample))
    return result


def generate_pad_chord(
    notes: list[float], duration: float, volume: float = 0.15
) -> list[int]:
    """Generate a soft pad chord with multiple notes."""
    layers = []
    for note in notes:
        # Use triangle wave for softer sound
        wave = generate_triangle(note, duration, volume / len(notes))
        layers.append(wave)

    mixed = mix_samples(*layers)
    return apply_envelope(mixed, attack=0.5, decay=0.2, sustain=0.6, release=0.5)


def generate_drone(base_freq: float, duration: float, volume: float = 0.1) -> list[int]:
    """Generate a low atmospheric drone."""
    # Multiple slightly detuned layers for richness
    layers = []
    for detune in [-2, 0, 2, 5]:
        freq = base_freq + detune * 0.1
        wave = generate_sine(freq, duration, volume * 0.3)
        layers.append(wave)

    # Add subtle harmonic
    harmonic = generate_sine(base_freq * 2, duration, volume * 0.1)
    layers.append(harmonic)

    return mix_samples(*layers)


def generate_shimmer(duration: float, volume: float = 0.05) -> list[int]:
    """Generate high-frequency shimmering ambience."""
    samples = [0] * int(SAMPLE_RATE * duration)

    # Random high-pitched tones fading in and out
    num_shimmers = int(duration * 2)  # 2 shimmers per second
    for _ in range(num_shimmers):
        freq = random.uniform(1500, 4000)
        start_time = random.uniform(0, duration - 0.5)
        shimmer_dur = random.uniform(0.3, 0.8)

        shimmer = generate_sine(freq, shimmer_dur, volume * random.uniform(0.3, 1.0))
        shimmer = apply_envelope(
            shimmer, attack=0.15, decay=0.1, sustain=0.4, release=0.2
        )

        offset = int(start_time * SAMPLE_RATE)
        samples = add_samples(samples, shimmer, offset)

    return samples


# ============================================================
# Music Track Generators
# ============================================================


def generate_main_menu() -> tuple[list[int], list[int]]:
    """
    Main menu music: Atmospheric, mysterious.
    Slow-evolving pads with ethereal textures.
    Duration: ~30 seconds (will loop)
    """
    duration = 30.0

    # Deep drone foundation (A1 = 55 Hz)
    drone = generate_drone(55.0, duration, volume=0.12)

    # Evolving pad chords (Am - Em - F - E progression, slow)
    pads = [0] * int(SAMPLE_RATE * duration)
    chord_duration = 7.5  # Each chord lasts 7.5 seconds

    # Chord frequencies (Am, Em, Fmaj, Emaj) - using lower octave for mystery
    chords = [
        [110, 131, 165],  # Am (A2, C3, E3)
        [82, 124, 165],  # Em (E2, B2, E3)
        [87, 110, 131],  # F (F2, A2, C3)
        [82, 104, 124],  # E (E2, G#2, B2)
    ]

    for i, chord in enumerate(chords):
        chord_samples = generate_pad_chord(chord, chord_duration, volume=0.18)
        offset = int(i * chord_duration * SAMPLE_RATE)
        pads = add_samples(pads, chord_samples, offset)

    # High shimmer layer
    shimmer = generate_shimmer(duration, volume=0.04)

    # Mix all layers
    left = mix_samples(drone, pads, shimmer)

    # Create stereo with slight variation
    # Slightly different shimmer for right channel
    shimmer_r = generate_shimmer(duration, volume=0.04)
    right = mix_samples(drone, pads, shimmer_r)

    # Apply fade
    left = apply_fade(left, fade_in=2.0, fade_out=2.0)
    right = apply_fade(right, fade_in=2.0, fade_out=2.0)

    return left, right


def generate_level_ambience() -> tuple[list[int], list[int]]:
    """
    Level ambience: Subtle, tense background.
    Minimal elements to not distract from gameplay.
    Duration: ~20 seconds (will loop)
    """
    duration = 20.0

    # Very low drone (almost sub-bass)
    drone = generate_drone(40.0, duration, volume=0.08)

    # Occasional distant tones
    tones = [0] * int(SAMPLE_RATE * duration)
    tone_times = [2.0, 6.5, 11.0, 15.5]
    tone_freqs = [220, 247, 196, 220]  # A3, B3, G3, A3

    for t, freq in zip(tone_times, tone_freqs):
        tone = generate_sine(freq, 2.0, 0.06)
        tone = apply_envelope(tone, attack=0.4, decay=0.3, sustain=0.3, release=0.6)
        offset = int(t * SAMPLE_RATE)
        tones = add_samples(tones, tone, offset)

    # Subtle high texture
    texture = generate_shimmer(duration, volume=0.02)

    # Mix
    left = mix_samples(drone, tones, texture)
    right = mix_samples(drone, tones, generate_shimmer(duration, volume=0.02))

    left = apply_fade(left, fade_in=1.0, fade_out=1.0)
    right = apply_fade(right, fade_in=1.0, fade_out=1.0)

    return left, right


def generate_level_intense() -> tuple[list[int], list[int]]:
    """
    Intense level music: For challenging sections.
    More rhythmic, driving energy.
    Duration: ~16 seconds (will loop)
    """
    duration = 16.0

    # Pulsing bass drone
    bass = [0] * int(SAMPLE_RATE * duration)
    pulse_interval = 0.5  # Pulse every 0.5 seconds
    num_pulses = int(duration / pulse_interval)

    for i in range(num_pulses):
        # Alternating bass notes
        freq = 55.0 if i % 4 < 2 else 65.0  # A1 and C2
        pulse = generate_sine(freq, 0.4, 0.2)
        pulse = apply_envelope(pulse, attack=0.02, decay=0.1, sustain=0.4, release=0.15)
        offset = int(i * pulse_interval * SAMPLE_RATE)
        bass = add_samples(bass, pulse, offset)

    # Tense high sustain
    high_drone = generate_triangle(440, duration, 0.06)  # A4
    high_drone = apply_fade(high_drone, fade_in=0.5, fade_out=0.5)

    # Rhythmic accent hits
    accents = [0] * int(SAMPLE_RATE * duration)
    accent_times = [0, 2, 4, 6, 8, 10, 12, 14]
    for t in accent_times:
        accent = generate_sine(330, 0.1, 0.15)
        accent = apply_envelope(
            accent, attack=0.01, decay=0.05, sustain=0.2, release=0.05
        )
        offset = int(t * SAMPLE_RATE)
        accents = add_samples(accents, accent, offset)

    left = mix_samples(bass, high_drone, accents)
    right = mix_samples(bass, high_drone, accents)

    left = apply_fade(left, fade_in=0.5, fade_out=0.5)
    right = apply_fade(right, fade_in=0.5, fade_out=0.5)

    return left, right


def generate_victory() -> tuple[list[int], list[int]]:
    """
    Victory jingle: Short, triumphant.
    Rising arpeggio with resolution.
    Duration: ~4 seconds
    """
    duration = 4.0

    samples = [0] * int(SAMPLE_RATE * duration)

    # Rising arpeggio (C major to resolution)
    notes = [
        (0.0, 523.25, 0.3),  # C5
        (0.2, 659.25, 0.3),  # E5
        (0.4, 783.99, 0.3),  # G5
        (0.6, 1046.50, 0.5),  # C6
        (1.2, 783.99, 0.8),  # G5 (held)
        (1.2, 1046.50, 0.8),  # C6 (held)
        (1.2, 1318.51, 1.5),  # E6 (held longest)
    ]

    for start, freq, dur in notes:
        note = generate_sine(freq, dur, 0.2)
        note = apply_envelope(note, attack=0.02, decay=0.1, sustain=0.6, release=0.2)
        offset = int(start * SAMPLE_RATE)
        samples = add_samples(samples, note, offset)

    # Add shimmer at the end
    shimmer = generate_shimmer(2.0, volume=0.08)
    samples = add_samples(samples, shimmer, int(1.5 * SAMPLE_RATE))

    left = apply_fade(samples, fade_in=0.0, fade_out=0.5)
    right = apply_fade(samples.copy(), fade_in=0.0, fade_out=0.5)

    return left, right


def generate_game_complete() -> tuple[list[int], list[int]]:
    """
    Game complete/ending theme: Peaceful, resolved.
    Gentle piano-like tones with warm chords.
    Duration: ~20 seconds
    """
    duration = 20.0

    # Base drone (warm)
    drone = generate_drone(65.0, duration, volume=0.08)  # C2

    # Peaceful chord progression
    pads = [0] * int(SAMPLE_RATE * duration)
    chord_duration = 5.0

    # C - Am - F - G progression (hopeful)
    chords = [
        [130.81, 164.81, 196.00],  # C (C3, E3, G3)
        [110.00, 130.81, 165.00],  # Am (A2, C3, E3)
        [87.31, 110.00, 130.81],  # F (F2, A2, C3)
        [98.00, 123.47, 146.83],  # G (G2, B2, D3)
    ]

    for i, chord in enumerate(chords):
        chord_samples = generate_pad_chord(chord, chord_duration, volume=0.15)
        offset = int(i * chord_duration * SAMPLE_RATE)
        pads = add_samples(pads, chord_samples, offset)

    # Gentle melody notes
    melody = [0] * int(SAMPLE_RATE * duration)
    melody_notes = [
        (1.0, 523.25, 1.0),  # C5
        (2.5, 587.33, 0.8),  # D5
        (4.0, 659.25, 1.5),  # E5
        (6.0, 523.25, 1.0),  # C5
        (8.0, 493.88, 0.8),  # B4
        (9.5, 523.25, 1.5),  # C5
        (12.0, 587.33, 1.0),  # D5
        (14.0, 659.25, 2.0),  # E5
        (17.0, 783.99, 2.5),  # G5 (final note)
    ]

    for start, freq, dur in melody_notes:
        note = generate_triangle(freq, dur, 0.12)
        note = apply_envelope(note, attack=0.1, decay=0.15, sustain=0.5, release=0.3)
        offset = int(start * SAMPLE_RATE)
        melody = add_samples(melody, note, offset)

    left = mix_samples(drone, pads, melody)
    right = mix_samples(drone, pads, melody)

    left = apply_fade(left, fade_in=1.0, fade_out=3.0)
    right = apply_fade(right, fade_in=1.0, fade_out=3.0)

    return left, right


def main():
    # Define output directory relative to this script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(os.path.dirname(script_dir))
    output_dir = os.path.join(project_root, "assets", "audio", "music")

    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)

    # Define all music tracks to generate
    tracks = {
        "main_menu.wav": generate_main_menu,
        "level_ambience.wav": generate_level_ambience,
        "level_intense.wav": generate_level_intense,
        "victory.wav": generate_victory,
        "game_complete.wav": generate_game_complete,
    }

    print(f"Generating {len(tracks)} music tracks...")

    for filename, generator in tracks.items():
        filepath = os.path.join(output_dir, filename)
        left, right = generator()
        write_wav_stereo(filepath, left, right)
        print(f"  Created: {filename}")

    print(f"\nAll music tracks generated in: {output_dir}")
    print(
        "\nNote: These are placeholder tracks. Replace with proper compositions for release."
    )


if __name__ == "__main__":
    main()
