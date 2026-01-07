#!/usr/bin/env python3
"""
Generate placeholder sound effects for Echoes of the Void.
Creates simple WAV files using procedural synthesis.
"""

import struct
import math
import os
import random

# WAV file parameters
SAMPLE_RATE = 44100
CHANNELS = 1
BITS_PER_SAMPLE = 16


def write_wav(filename: str, samples: list[int]) -> None:
    """Write a list of 16-bit samples to a WAV file."""
    num_samples = len(samples)
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
        for sample in samples:
            f.write(struct.pack("<h", max(-32768, min(32767, sample))))


def generate_sine(freq: float, duration: float, volume: float = 0.5) -> list[int]:
    """Generate a sine wave."""
    samples = []
    num_samples = int(SAMPLE_RATE * duration)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        sample = int(math.sin(2 * math.pi * freq * t) * 32767 * volume)
        samples.append(sample)
    return samples


def apply_envelope(
    samples: list[int],
    attack: float = 0.01,
    decay: float = 0.1,
    sustain: float = 0.5,
    release: float = 0.2,
) -> list[int]:
    """Apply ADSR envelope to samples."""
    num_samples = len(samples)
    total_duration = num_samples / SAMPLE_RATE

    attack_samples = int(attack * SAMPLE_RATE)
    decay_samples = int(decay * SAMPLE_RATE)
    release_samples = int(release * SAMPLE_RATE)
    sustain_samples = num_samples - attack_samples - decay_samples - release_samples

    result = []
    for i, sample in enumerate(samples):
        if i < attack_samples:
            # Attack phase
            envelope = i / attack_samples if attack_samples > 0 else 1.0
        elif i < attack_samples + decay_samples:
            # Decay phase
            progress = (
                (i - attack_samples) / decay_samples if decay_samples > 0 else 1.0
            )
            envelope = 1.0 - (1.0 - sustain) * progress
        elif i < attack_samples + decay_samples + sustain_samples:
            # Sustain phase
            envelope = sustain
        else:
            # Release phase
            progress = (
                (i - attack_samples - decay_samples - sustain_samples) / release_samples
                if release_samples > 0
                else 1.0
            )
            envelope = sustain * (1.0 - progress)

        result.append(int(sample * envelope))
    return result


def generate_noise(duration: float, volume: float = 0.3) -> list[int]:
    """Generate white noise."""
    samples = []
    num_samples = int(SAMPLE_RATE * duration)
    for _ in range(num_samples):
        sample = int((random.random() * 2 - 1) * 32767 * volume)
        samples.append(sample)
    return samples


def generate_sweep(
    start_freq: float, end_freq: float, duration: float, volume: float = 0.5
) -> list[int]:
    """Generate a frequency sweep."""
    samples = []
    num_samples = int(SAMPLE_RATE * duration)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        progress = i / num_samples
        freq = start_freq + (end_freq - start_freq) * progress
        sample = int(math.sin(2 * math.pi * freq * t) * 32767 * volume)
        samples.append(sample)
    return samples


def mix_samples(*sample_lists: list[int]) -> list[int]:
    """Mix multiple sample lists together."""
    max_len = max(len(s) for s in sample_lists)
    result = [0] * max_len
    for samples in sample_lists:
        for i, sample in enumerate(samples):
            result[i] += sample
    # Normalize to prevent clipping
    max_val = max(abs(s) for s in result) if result else 1
    if max_val > 32767:
        result = [int(s * 32767 / max_val) for s in result]
    return result


# Sound generation functions


def generate_jump():
    """Whoosh sound for jump."""
    sweep = generate_sweep(200, 600, 0.15, 0.3)
    noise = generate_noise(0.1, 0.1)
    mixed = mix_samples(sweep, noise)
    return apply_envelope(mixed, attack=0.01, decay=0.05, sustain=0.2, release=0.1)


def generate_double_jump():
    """Echo/reverb jump sound."""
    sweep1 = generate_sweep(300, 800, 0.12, 0.4)
    sweep2 = generate_sweep(500, 1000, 0.12, 0.3)
    # Add reverb-like effect with delayed quieter sweep
    delay = [0] * int(SAMPLE_RATE * 0.05)
    sweep2_delayed = delay + [int(s * 0.5) for s in sweep1]
    mixed = mix_samples(sweep1, sweep2, sweep2_delayed)
    return apply_envelope(mixed, attack=0.005, decay=0.05, sustain=0.3, release=0.15)


def generate_land():
    """Soft thud for landing."""
    noise = generate_noise(0.1, 0.4)
    low_freq = generate_sine(80, 0.1, 0.3)
    mixed = mix_samples(noise, low_freq)
    return apply_envelope(mixed, attack=0.002, decay=0.08, sustain=0.1, release=0.02)


def generate_wall_slide():
    """Friction/scrape looping sound."""
    noise = generate_noise(0.5, 0.2)
    # Filter to make it more scratchy
    filtered = []
    prev = 0
    for sample in noise:
        filtered_sample = int(sample * 0.3 + prev * 0.7)
        filtered.append(filtered_sample)
        prev = filtered_sample
    return apply_envelope(filtered, attack=0.05, decay=0.1, sustain=0.8, release=0.05)


def generate_wall_jump():
    """Kick-off sound."""
    sweep = generate_sweep(150, 500, 0.1, 0.4)
    thud = generate_sine(100, 0.05, 0.4)
    mixed = mix_samples(sweep, thud)
    return apply_envelope(mixed, attack=0.005, decay=0.05, sustain=0.2, release=0.05)


def generate_footstep():
    """Subtle footstep sound."""
    noise = generate_noise(0.05, 0.15)
    thud = generate_sine(120, 0.03, 0.2)
    mixed = mix_samples(noise, thud)
    return apply_envelope(mixed, attack=0.002, decay=0.03, sustain=0.1, release=0.02)


def generate_death():
    """Dissolve/shatter sound."""
    noise = generate_noise(0.4, 0.5)
    sweep_down = generate_sweep(800, 100, 0.4, 0.3)
    mixed = mix_samples(noise, sweep_down)
    return apply_envelope(mixed, attack=0.01, decay=0.3, sustain=0.1, release=0.1)


def generate_respawn():
    """Reformation sound."""
    sweep_up = generate_sweep(200, 1200, 0.3, 0.3)
    chime = generate_sine(880, 0.3, 0.2)
    chime2 = generate_sine(1320, 0.25, 0.15)
    mixed = mix_samples(sweep_up, chime, chime2)
    return apply_envelope(mixed, attack=0.1, decay=0.1, sustain=0.3, release=0.1)


def generate_shard_collect():
    """Light chime for shard collection."""
    chime1 = generate_sine(1047, 0.15, 0.3)  # C6
    chime2 = generate_sine(1319, 0.12, 0.25)  # E6
    delay = [0] * int(SAMPLE_RATE * 0.03)
    chime2_delayed = delay + chime2
    mixed = mix_samples(chime1, chime2_delayed)
    return apply_envelope(mixed, attack=0.005, decay=0.05, sustain=0.3, release=0.1)


def generate_crystal_collect():
    """Grand chime/chord for crystal collection."""
    # C major chord
    c5 = generate_sine(523, 0.5, 0.25)
    e5 = generate_sine(659, 0.45, 0.2)
    g5 = generate_sine(784, 0.4, 0.2)
    c6 = generate_sine(1047, 0.35, 0.15)
    sweep = generate_sweep(400, 1600, 0.3, 0.2)
    mixed = mix_samples(c5, e5, g5, c6, sweep)
    return apply_envelope(mixed, attack=0.01, decay=0.15, sustain=0.4, release=0.2)


def generate_checkpoint():
    """Activation tone for checkpoint."""
    tone1 = generate_sine(440, 0.2, 0.3)  # A4
    delay = [0] * int(SAMPLE_RATE * 0.1)
    tone2 = delay + list(generate_sine(660, 0.2, 0.3))  # E5
    mixed = mix_samples(tone1, tone2)
    return apply_envelope(mixed, attack=0.02, decay=0.1, sustain=0.3, release=0.15)


def generate_enemy_death():
    """Shadow disperse sound."""
    noise = generate_noise(0.25, 0.4)
    sweep = generate_sweep(400, 80, 0.25, 0.3)
    mixed = mix_samples(noise, sweep)
    return apply_envelope(mixed, attack=0.01, decay=0.15, sustain=0.1, release=0.05)


def generate_platform_crumble():
    """Stone breaking sound."""
    noise = generate_noise(0.3, 0.5)
    rumble = generate_sine(60, 0.3, 0.4)
    crack1 = generate_noise(0.05, 0.6)
    mixed = mix_samples(noise, rumble, crack1)
    return apply_envelope(mixed, attack=0.005, decay=0.2, sustain=0.15, release=0.1)


def generate_menu_select():
    """UI blip for selection."""
    blip = generate_sine(660, 0.05, 0.3)
    return apply_envelope(blip, attack=0.002, decay=0.02, sustain=0.2, release=0.02)


def generate_menu_confirm():
    """UI confirm sound."""
    tone1 = generate_sine(523, 0.08, 0.3)  # C5
    delay = [0] * int(SAMPLE_RATE * 0.04)
    tone2 = delay + list(generate_sine(784, 0.08, 0.3))  # G5
    mixed = mix_samples(tone1, tone2)
    return apply_envelope(mixed, attack=0.005, decay=0.03, sustain=0.3, release=0.05)


def main():
    # Define output directory relative to this script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(os.path.dirname(script_dir))
    output_dir = os.path.join(project_root, "assets", "audio", "sfx")

    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)

    # Define all sounds to generate
    sounds = {
        "jump.wav": generate_jump,
        "double_jump.wav": generate_double_jump,
        "land.wav": generate_land,
        "wall_slide.wav": generate_wall_slide,
        "wall_jump.wav": generate_wall_jump,
        "footstep_01.wav": generate_footstep,
        "footstep_02.wav": generate_footstep,  # Slight variation from random
        "death.wav": generate_death,
        "respawn.wav": generate_respawn,
        "shard_collect.wav": generate_shard_collect,
        "crystal_collect.wav": generate_crystal_collect,
        "checkpoint.wav": generate_checkpoint,
        "enemy_death.wav": generate_enemy_death,
        "platform_crumble.wav": generate_platform_crumble,
        "menu_select.wav": generate_menu_select,
        "menu_confirm.wav": generate_menu_confirm,
    }

    print(f"Generating {len(sounds)} sound effects...")

    for filename, generator in sounds.items():
        filepath = os.path.join(output_dir, filename)
        samples = generator()
        write_wav(filepath, samples)
        print(f"  Created: {filename}")

    print(f"\nAll sound effects generated in: {output_dir}")


if __name__ == "__main__":
    main()
