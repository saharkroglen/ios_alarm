# Audio Files Setup

## Current Status
The app currently has placeholder text files in `assets/sounds/`. For full functionality, you'll want to replace these with actual audio files.

## Supported Formats
- **CAF** (Core Audio Format) - Recommended for iOS
- **AIFF** (Audio Interchange File Format)
- **WAV** (as fallback)

## File Requirements
- **Duration**: ≤30 seconds (iOS notification sound limit)
- **Sample Rate**: 44.1kHz or 48kHz recommended
- **Bit Depth**: 16-bit or 24-bit
- **Channels**: Mono or Stereo

## Current Placeholder Files
- `alarm_1.caf` - Should be a traditional alarm sound
- `chime_1.aiff` - Should be a gentle chime sound  
- `bell_1.caf` - Should be a bell sound

## How to Add Real Audio Files

### Option 1: Use Online Converters
1. Find or create your audio files in WAV/MP3 format
2. Use online converters to convert to CAF format:
   - Audio Converter Online
   - CloudConvert
   - Zamzar

### Option 2: Use macOS Command Line (afconvert)
```bash
# Convert WAV to CAF
afconvert -f caff -d LEI16 input.wav output.caf

# Convert MP3 to CAF
afconvert -f caff -d LEI16 input.mp3 output.caf
```

### Option 3: Use Audio Editing Software
- **Audacity** (Free): Export as WAV, then use afconvert
- **Logic Pro** (Mac): Can export directly to CAF
- **GarageBand** (Mac): Export as AIFF

## Testing Audio Files
1. Replace the placeholder files in `assets/sounds/`
2. Rebuild the app: `flutter build ios`
3. Use the "Preview Sound" buttons in Settings
4. Test with the "Test Notification" feature

## Sound Design Tips
- **Alarm sounds**: Should be attention-grabbing but not jarring
- **Chime sounds**: Gentle, pleasant tones
- **Bell sounds**: Clear, resonant tones
- **Volume**: Moderate level - iOS will handle system volume
- **Fade in/out**: Add brief fades to avoid audio clicks

## Free Sound Resources
- **Freesound.org** - Creative Commons sounds
- **Zapsplat** - Free with registration
- **BBC Sound Effects** - Free for personal use
- **YouTube Audio Library** - Royalty-free sounds

## Note
The current app uses system alert sounds for preview functionality. Once you add real CAF/AIFF files, the app will play the actual notification sounds.
