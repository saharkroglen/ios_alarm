import 'package:timezone/timezone.dart' as tz;
import '../models/reminder.dart';

/// Service for computing next occurrence times for reminders
class SchedulingService {
  /// Calculate the next occurrence time for a reminder
  static DateTime calculateNextOccurrence(
    Reminder reminder, {
    DateTime? fromTime,
  }) {
    final from = fromTime ?? DateTime.now();

    switch (reminder.repeatRule) {
      case RepeatRule.none:
        return reminder.scheduledAt;

      case RepeatRule.daily:
        return _calculateNextDaily(reminder.scheduledAt, from);

      case RepeatRule.weekly:
        return _calculateNextWeekly(reminder.scheduledAt, from);

      case RepeatRule.weekdays:
        return _calculateNextWeekdays(reminder.scheduledAt, from);

      case RepeatRule.custom:
        return _calculateNextCustom(
          reminder.scheduledAt,
          from,
          reminder.repeatWeekdays,
        );
    }
  }

  /// Calculate next occurrence for daily repeat
  static DateTime _calculateNextDaily(DateTime originalTime, DateTime from) {
    final originalLocal = originalTime.toLocal();
    final fromLocal = from.toLocal();

    // Start with today at the original time
    DateTime next = DateTime(
      fromLocal.year,
      fromLocal.month,
      fromLocal.day,
      originalLocal.hour,
      originalLocal.minute,
      originalLocal.second,
    );

    // If the time has already passed today, move to tomorrow
    if (next.isBefore(fromLocal) || next.isAtSameMomentAs(fromLocal)) {
      next = next.add(const Duration(days: 1));
    }

    return next;
  }

  /// Calculate next occurrence for weekly repeat
  static DateTime _calculateNextWeekly(DateTime originalTime, DateTime from) {
    final originalLocal = originalTime.toLocal();
    final fromLocal = from.toLocal();

    // Calculate days until next occurrence of the same weekday
    final originalWeekday = originalLocal.weekday;
    final currentWeekday = fromLocal.weekday;

    int daysToAdd;
    if (originalWeekday > currentWeekday) {
      daysToAdd = originalWeekday - currentWeekday;
    } else if (originalWeekday < currentWeekday) {
      daysToAdd = 7 - (currentWeekday - originalWeekday);
    } else {
      // Same weekday
      final todayAtTime = DateTime(
        fromLocal.year,
        fromLocal.month,
        fromLocal.day,
        originalLocal.hour,
        originalLocal.minute,
        originalLocal.second,
      );

      if (todayAtTime.isAfter(fromLocal)) {
        return todayAtTime;
      } else {
        daysToAdd = 7; // Next week
      }
    }

    return DateTime(
      fromLocal.year,
      fromLocal.month,
      fromLocal.day + daysToAdd,
      originalLocal.hour,
      originalLocal.minute,
      originalLocal.second,
    );
  }

  /// Calculate next occurrence for weekdays (Monday-Friday)
  static DateTime _calculateNextWeekdays(DateTime originalTime, DateTime from) {
    final weekdays = {1, 2, 3, 4, 5}; // Monday to Friday
    return _calculateNextCustom(originalTime, from, weekdays);
  }

  /// Calculate next occurrence for custom weekdays
  static DateTime _calculateNextCustom(
    DateTime originalTime,
    DateTime from,
    Set<int> weekdays,
  ) {
    if (weekdays.isEmpty) {
      return originalTime; // Fallback to original time
    }

    final originalLocal = originalTime.toLocal();
    final fromLocal = from.toLocal();

    // Check today first
    if (weekdays.contains(fromLocal.weekday)) {
      final todayAtTime = DateTime(
        fromLocal.year,
        fromLocal.month,
        fromLocal.day,
        originalLocal.hour,
        originalLocal.minute,
        originalLocal.second,
      );

      if (todayAtTime.isAfter(fromLocal)) {
        return todayAtTime;
      }
    }

    // Find next valid weekday
    for (int i = 1; i <= 7; i++) {
      final nextDate = fromLocal.add(Duration(days: i));
      if (weekdays.contains(nextDate.weekday)) {
        return DateTime(
          nextDate.year,
          nextDate.month,
          nextDate.day,
          originalLocal.hour,
          originalLocal.minute,
          originalLocal.second,
        );
      }
    }

    // Fallback (should never reach here with valid weekdays)
    return originalTime;
  }

  /// Calculate snooze time from current time
  static DateTime calculateSnoozeTime(int minutes) {
    return DateTime.now().add(Duration(minutes: minutes));
  }

  /// Calculate "tomorrow at specified time" snooze
  static DateTime calculateTomorrowAt(int hour, int minute) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, hour, minute);
    return tomorrow;
  }

  /// Handle timezone changes and DST transitions
  static DateTime adjustForTimezone(DateTime localTime) {
    // Convert to TZ datetime to handle DST properly
    final tz.Location location = tz.local;
    final tzDateTime = tz.TZDateTime.from(localTime, location);
    return tzDateTime;
  }

  /// Check if a reminder should fire now (within tolerance)
  static bool shouldFireNow(
    DateTime scheduledTime, {
    Duration tolerance = const Duration(minutes: 1),
  }) {
    final now = DateTime.now();
    final difference = scheduledTime.difference(now).abs();
    return difference <= tolerance;
  }

  /// Get human-readable description of next occurrence
  static String getNextOccurrenceDescription(Reminder reminder) {
    final next = calculateNextOccurrence(reminder);
    final now = DateTime.now();
    final difference = next.difference(now);

    if (difference.inDays > 7) {
      return 'in ${difference.inDays} days';
    } else if (difference.inDays > 0) {
      return 'in ${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      return 'in ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inMinutes > 0) {
      return 'in ${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'now';
    }
  }

  /// Get repeat rule description
  static String getRepeatDescription(RepeatRule rule, Set<int> weekdays) {
    switch (rule) {
      case RepeatRule.none:
        return 'Once';
      case RepeatRule.daily:
        return 'Daily';
      case RepeatRule.weekly:
        return 'Weekly';
      case RepeatRule.weekdays:
        return 'Weekdays';
      case RepeatRule.custom:
        if (weekdays.isEmpty) return 'Custom';
        final dayNames = weekdays.map(_weekdayName).join(', ');
        return 'Custom ($dayNames)';
    }
  }

  static String _weekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }
}
