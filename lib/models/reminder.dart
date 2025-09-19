/// Enum for repeat rules
enum RepeatRule {
  none,
  daily,
  weekly,
  weekdays, // Monday to Friday
  custom, // Custom weekdays using bitmask
}

/// Snooze preset options
sealed class SnoozePreset {
  const SnoozePreset();

  /// Convert to JSON representation
  Map<String, dynamic> toJson();

  /// Create from JSON
  static SnoozePreset fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'minutes':
        return MinutesPreset(json['minutes'] as int);
      case 'tomorrow':
        return TomorrowAtPreset(
          hour: json['hour'] as int,
          minute: json['minute'] as int,
        );
      default:
        throw ArgumentError('Unknown snooze preset type: ${json['type']}');
    }
  }
}

class MinutesPreset extends SnoozePreset {
  const MinutesPreset(this.minutes);

  final int minutes;

  @override
  Map<String, dynamic> toJson() => {'type': 'minutes', 'minutes': minutes};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MinutesPreset &&
          runtimeType == other.runtimeType &&
          minutes == other.minutes;

  @override
  int get hashCode => minutes.hashCode;

  @override
  String toString() => '${minutes}m';
}

class TomorrowAtPreset extends SnoozePreset {
  const TomorrowAtPreset({required this.hour, required this.minute});

  final int hour;
  final int minute;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'tomorrow',
    'hour': hour,
    'minute': minute,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TomorrowAtPreset &&
          runtimeType == other.runtimeType &&
          hour == other.hour &&
          minute == other.minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() =>
      'Tomorrow ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// Domain model for a reminder
class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    this.notes,
    required this.scheduledAt,
    required this.repeatRule,
    this.repeatDaysMask,
    required this.timeSensitive,
    required this.soundName,
    required this.snoozePresets,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? notes;
  final DateTime scheduledAt; // Next occurrence in local time
  final RepeatRule repeatRule;
  final int? repeatDaysMask; // Bitmask for weekdays (1=Mon, 2=Tue, 4=Wed, etc.)
  final bool timeSensitive;
  final String soundName; // Asset filename
  final List<SnoozePreset> snoozePresets;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Create a copy with updated fields
  Reminder copyWith({
    String? id,
    String? title,
    String? notes,
    DateTime? scheduledAt,
    RepeatRule? repeatRule,
    int? repeatDaysMask,
    bool? timeSensitive,
    String? soundName,
    List<SnoozePreset>? snoozePresets,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      repeatRule: repeatRule ?? this.repeatRule,
      repeatDaysMask: repeatDaysMask ?? this.repeatDaysMask,
      timeSensitive: timeSensitive ?? this.timeSensitive,
      soundName: soundName ?? this.soundName,
      snoozePresets: snoozePresets ?? this.snoozePresets,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if this reminder repeats
  bool get hasRepeat => repeatRule != RepeatRule.none;

  /// Get weekdays for weekly/custom repeat (1=Mon, 2=Tue, etc.)
  Set<int> get repeatWeekdays {
    if (repeatRule == RepeatRule.weekdays) {
      return {1, 2, 3, 4, 5}; // Mon-Fri
    }
    if (repeatRule == RepeatRule.custom && repeatDaysMask != null) {
      final Set<int> days = {};
      for (int i = 1; i <= 7; i++) {
        if ((repeatDaysMask! & (1 << (i - 1))) != 0) {
          days.add(i);
        }
      }
      return days;
    }
    return {};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reminder && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Reminder(id: $id, title: $title, scheduledAt: $scheduledAt)';
}

/// Default snooze presets
const List<SnoozePreset> kDefaultSnoozePresets = [
  MinutesPreset(5),
  MinutesPreset(60),
  MinutesPreset(180),
  TomorrowAtPreset(hour: 9, minute: 0),
];

/// Available sound files (to be placed in assets/sounds/)
const List<String> kAvailableSounds = [
  'system_default', // System default notification sound
  'stars.caf',
  'summer.caf',
  'mistery.caf',
];

/// Default sound (system default for first launch)
const String kDefaultSound = 'system_default';
