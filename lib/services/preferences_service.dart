import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder.dart' as model;

/// Service for managing app preferences using SharedPreferences
class PreferencesService {
  static const String _defaultSoundKey = 'default_sound';
  static const String _hasPromptedPermissionsKey = 'has_prompted_permissions';
  static const String _permissionsDismissedKey = 'permissions_dismissed';
  static const String _permissionsPermanentlyDeniedKey =
      'permissions_permanently_denied';

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

  /// Check if we have prompted for permissions before
  static bool hasPromptedForPermissions() {
    if (_prefs == null) {
      return false;
    }
    return _prefs!.getBool(_hasPromptedPermissionsKey) ?? false;
  }

  /// Mark that we have prompted for permissions
  static Future<void> setHasPromptedForPermissions(bool hasPrompted) async {
    if (_prefs == null) {
      await init();
    }
    await _prefs!.setBool(_hasPromptedPermissionsKey, hasPrompted);
  }

  /// Check if user has dismissed the permission banner
  static bool hasPermissionsDismissed() {
    if (_prefs == null) {
      return false;
    }
    return _prefs!.getBool(_permissionsDismissedKey) ?? false;
  }

  /// Set whether user has dismissed the permission banner
  static Future<void> setPermissionsDismissed(bool dismissed) async {
    if (_prefs == null) {
      await init();
    }
    await _prefs!.setBool(_permissionsDismissedKey, dismissed);
  }

  /// Check if permissions have been permanently denied (user chose "Don't Allow")
  static bool arePermissionsPermanentlyDenied() {
    if (_prefs == null) {
      return false;
    }
    return _prefs!.getBool(_permissionsPermanentlyDeniedKey) ?? false;
  }

  /// Set whether permissions have been permanently denied
  static Future<void> setPermissionsPermanentlyDenied(bool denied) async {
    if (_prefs == null) {
      await init();
    }
    await _prefs!.setBool(_permissionsPermanentlyDeniedKey, denied);
  }
}
