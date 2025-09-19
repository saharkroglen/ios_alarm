#!/bin/bash

# Create CAF audio files for iOS alarm app
# This script creates simple tone-based sounds using macOS system tools

echo "Creating CAF audio files for iOS Alarm app..."

# Create assets/sounds directory
mkdir -p assets/sounds

# Remove old placeholder files
rm -f assets/sounds/*.caf assets/sounds/*.aiff

# Create temporary directory for intermediate files
mkdir -p temp_audio

echo "Generating audio files..."

# Create a simple alarm sound (800Hz + 1000Hz for 2 seconds)
cat > temp_audio/create_alarm.py << 'EOF'
import math
import wave
import struct

def create_tone(frequency, duration, sample_rate=44100):
    frames = []
    for i in range(int(duration * sample_rate)):
        # Create a dual-tone alarm sound
        wave_val1 = math.sin(2 * math.pi * frequency * i / sample_rate)
        wave_val2 = math.sin(2 * math.pi * (frequency * 1.25) * i / sample_rate)
        # Mix the tones and add some amplitude modulation
        amplitude = 0.3 * (1 + 0.5 * math.sin(2 * math.pi * 4 * i / sample_rate))
        wave_val = amplitude * (wave_val1 + wave_val2) / 2
        frames.append(struct.pack('<h', int(wave_val * 32767)))
    return frames

def create_wav(filename, frames, sample_rate=44100):
    with wave.open(filename, 'wb') as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)  # 16-bit
        wav_file.setframerate(sample_rate)
        wav_file.writeframes(b''.join(frames))

# Create alarm sound (800Hz + 1000Hz)
frames = create_tone(800, 2.0)
create_wav('temp_audio/alarm.wav', frames)

# Create chime sound (C major chord)
def create_chord_tone(frequencies, duration, sample_rate=44100):
    frames = []
    for i in range(int(duration * sample_rate)):
        wave_val = 0
        for freq in frequencies:
            wave_val += math.sin(2 * math.pi * freq * i / sample_rate)
        # Add envelope (fade in/out)
        envelope = 1.0
        fade_samples = int(0.1 * sample_rate)  # 0.1 second fade
        if i < fade_samples:
            envelope = i / fade_samples
        elif i > len(range(int(duration * sample_rate))) - fade_samples:
            envelope = (len(range(int(duration * sample_rate))) - i) / fade_samples
        
        wave_val = 0.2 * envelope * wave_val / len(frequencies)
        frames.append(struct.pack('<h', int(wave_val * 32767)))
    return frames

# Create chime sound (C major chord: C, E, G)
chime_frames = create_chord_tone([523.25, 659.25, 783.99], 1.5)
create_wav('temp_audio/chime.wav', chime_frames)

# Create bell sound (fundamental + harmonics)
def create_bell_tone(fundamental, duration, sample_rate=44100):
    frames = []
    harmonics = [1.0, 2.0, 3.0, 4.0, 5.0]  # Harmonic ratios
    amplitudes = [1.0, 0.5, 0.3, 0.2, 0.1]  # Harmonic amplitudes
    
    for i in range(int(duration * sample_rate)):
        wave_val = 0
        for h, amp in zip(harmonics, amplitudes):
            wave_val += amp * math.sin(2 * math.pi * fundamental * h * i / sample_rate)
        
        # Bell-like envelope (quick attack, slow decay)
        t = i / sample_rate
        envelope = math.exp(-t * 2)  # Exponential decay
        
        wave_val = 0.3 * envelope * wave_val / len(harmonics)
        frames.append(struct.pack('<h', int(wave_val * 32767)))
    return frames

# Create bell sound (440Hz with harmonics)
bell_frames = create_bell_tone(440, 2.5)
create_wav('temp_audio/bell.wav', bell_frames)

print("WAV files created successfully!")
EOF

# Run Python script to create WAV files
python3 temp_audio/create_alarm.py

# Convert WAV files to CAF format for iOS
echo "Converting to CAF format..."

# Convert alarm.wav to alarm_1.caf
afconvert -f caff -d LEI16 temp_audio/alarm.wav assets/sounds/alarm_1.caf
echo "Created alarm_1.caf"

# Convert chime.wav to chime_1.aiff (keeping as AIFF as specified)
afconvert -f AIFF -d LEI16 temp_audio/chime.wav assets/sounds/chime_1.aiff
echo "Created chime_1.aiff"

# Convert bell.wav to bell_1.caf
afconvert -f caff -d LEI16 temp_audio/bell.wav assets/sounds/bell_1.caf
echo "Created bell_1.caf"

# Clean up temporary files
rm -rf temp_audio

echo "✅ All CAF/AIFF audio files created successfully!"
echo "Files created:"
ls -la assets/sounds/

echo ""
echo "🎵 Audio files are now ready for use in the iOS app!"
echo "Each file contains a unique sound:"
echo "- alarm_1.caf: Dual-tone alarm sound"
echo "- chime_1.aiff: Pleasant C major chord"
echo "- bell_1.caf: Bell sound with harmonics"
