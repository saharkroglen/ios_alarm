import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder.dart' as model;

/// Service for managing app preferences using SharedPreferences
class PreferencesService {
  static const String _defaultSoundKey = 'default_sound';

  static SharedPreferences? _prefs;

  /// Initialize the preferences service
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get the current default sound, fallback to kDefaultSound if not set
  static String getDefaultSound() {
    if (_prefs == null) {
      return model.kDefaultSound;
    }
    return _prefs!.getString(_defaultSoundKey) ?? model.kDefaultSound;
  }

  /// Set the default sound
  static Future<void> setDefaultSound(String soundName) async {
    if (_prefs == null) {
      await init();
    }
    await _prefs!.setString(_defaultSoundKey, soundName);
  }

  /// Check if a default sound has been explicitly set by the user
  static bool hasCustomDefaultSound() {
    if (_prefs == null) {
      return false;
    }
    return _prefs!.containsKey(_defaultSoundKey);
  }
}
