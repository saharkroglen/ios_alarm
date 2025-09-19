import 'package:flutter/services.dart';

class SoundService {
  static const MethodChannel _channel = MethodChannel('com.ios_alarm.sound');

  /// Play a sound file from the iOS bundle
  static Future<bool> playSound(String soundName) async {
    try {
      final result = await _channel.invokeMethod('playSound', soundName);
      return result as bool? ?? false;
    } catch (e) {
      print('Error playing sound: $e');
      return false;
    }
  }

  /// Get list of available sound files in the iOS bundle
  static Future<List<String>> getAvailableSounds() async {
    try {
      final result = await _channel.invokeMethod('getAvailableSounds');
      return List<String>.from(result as List? ?? []);
    } catch (e) {
      print('Error getting available sounds: $e');
      return [];
    }
  }
}
