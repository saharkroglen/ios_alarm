import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../database/sqflite_database.dart';
import '../models/reminder.dart' as model;
import '../services/notification_service.dart';
import '../services/preferences_service.dart';
import '../services/scheduling_service.dart';

/// Helper function to round DateTime down to the nearest minute
/// Removes seconds and milliseconds: 18:56:30.123 -> 18:56:00.000
DateTime roundToMinute(DateTime dateTime) {
  return DateTime(
    dateTime.year,
    dateTime.month,
    dateTime.day,
    dateTime.hour,
    dateTime.minute,
  );
}

// Database provider
final databaseProvider = Provider<SqliteDatabase>((ref) {
  return SqliteDatabase();
});

/// Static helper function to handle notification rescheduling asynchronously
/// This allows the UI to respond immediately while heavy operations continue
void _handleNotificationReschedulingAsyncStatic(
  NotificationService notificationService,
  String reminderId,
  model.Reminder snoozedReminder,
) {
  // Run in background without blocking the UI
  Future.microtask(() async {
    try {
      print(
        '🔄 BACKGROUND: Starting notification cancellation for $reminderId...',
      );

      // Initialize the service if needed
      if (notificationService is IOSNotificationService) {
        await notificationService.init();
      }

      // Cancel all existing notifications (including auto-snooze)
      await notificationService.cancelReminderNotifications(reminderId);
      print('✅ BACKGROUND: All notifications cancelled for $reminderId');

      // Schedule new notification if not completed
      if (!snoozedReminder.isCompleted) {
        print('🔄 BACKGROUND: Scheduling new notification for $reminderId...');
        await notificationService.scheduleReminder(
          snoozedReminder,
          isTestNotification: false,
        );
        print('✅ BACKGROUND: New notification scheduled for $reminderId');
      }

      print(
        '🎉 BACKGROUND: Completed async notification rescheduling for $reminderId',
      );
    } catch (e, stackTrace) {
      print(
        '💥 BACKGROUND ERROR: Failed to reschedule notifications for $reminderId: $e',
      );
      print('Stack trace: $stackTrace');
    }
  });
}

/// Static helper function to handle mark done notification cancellation asynchronously
/// This allows the UI to respond immediately while cancellation happens in background
void _handleMarkDoneNotificationCancellationAsync(
  NotificationService notificationService,
  String reminderId,
) {
  // Run in background without blocking the UI
  Future.microtask(() async {
    try {
      print(
        '🔄 BACKGROUND: Starting notification cancellation for completed reminder $reminderId...',
      );

      // Initialize the service if needed
      if (notificationService is IOSNotificationService) {
        await notificationService.init();
      }

      // Cancel all existing notifications (including auto-snooze)
      await notificationService.cancelReminderNotifications(reminderId);
      print(
        '✅ BACKGROUND: All notifications cancelled for completed reminder $reminderId',
      );

      print(
        '🎉 BACKGROUND: Completed async mark done cancellation for $reminderId',
      );
    } catch (e, stackTrace) {
      print(
        '💥 BACKGROUND ERROR: Failed to cancel notifications for completed reminder $reminderId: $e',
      );
      print('Stack trace: $stackTrace');
    }
  });
}

// Notification service provider (without circular dependency)
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final database = ref.watch(databaseProvider);

  return IOSNotificationService(
    database: database,
    onNotificationTap: (reminderId, payload) async {
      // Handle notification tap - show action dialog
      final isAutoSnooze = payload?['isAutoSnooze'] as bool? ?? false;
      final snoozeCount = payload?['snoozeCount'] as int? ?? 0;

      // Set the current reminder for the action dialog
      ref.read(currentReminderActionProvider.notifier).state = {
        'reminderId': reminderId,
        'isAutoSnooze': isAutoSnooze,
        'snoozeCount': snoozeCount,
      };

      // Highlight the matching reminder for 5 seconds
      ref.read(highlightedReminderProvider.notifier).state = reminderId;

      // Auto-clear highlight after 5 seconds with fadeout
      Future.delayed(const Duration(seconds: 5), () {
        ref.read(highlightedReminderProvider.notifier).state = null;
      });

      print(
        'Notification tapped for reminder: $reminderId (autoSnooze: $isAutoSnooze, count: $snoozeCount) - highlighting reminder',
      );
    },
    onSnoozeAction: (reminderId, minutes) async {
      // Handle snooze action from notification buttons
      // We'll handle this directly with the database to avoid circular dependency
      print(
        '🔔 NOTIFICATION ACTION: Snooze $minutes minutes for reminder $reminderId',
      );

      try {
        print('📍 Step 1: Getting reminder from database...');
        final reminder = await database.getReminderById(reminderId);
        if (reminder == null) {
          print('❌ Reminder $reminderId not found in database!');
          return;
        }
        print('✅ Found reminder: ${reminder.title}');

        // Calculate new scheduled time (rounded to nearest minute)
        final newScheduledTime = roundToMinute(
          DateTime.now().add(Duration(minutes: minutes)),
        );
        print('📍 Step 2: New scheduled time: $newScheduledTime');

        final snoozedReminder = reminder.copyWith(
          scheduledAt: newScheduledTime,
          updatedAt: DateTime.now(),
        );

        // Update in database
        print('📍 Step 3: Updating reminder in database...');
        await database.updateReminder(snoozedReminder);
        print('✅ Database updated');

        // Cancel all notifications (including auto-snooze) and reschedule asynchronously
        print('📍 Step 4: Starting async notification management...');
        final tempNotificationService = IOSNotificationService(
          database: database,
          onNotificationTap: (_, __) {},
          onSnoozeAction: (_, __) {},
          onMarkDone: (_) {},
        );

        // Don't await these operations - let them run in background
        _handleNotificationReschedulingAsyncStatic(
          tempNotificationService,
          reminderId,
          snoozedReminder,
        );
        print(
          '✅ Async notification management started (continuing in background)',
        );

        // User sees immediate response while background work continues

        print(
          '🎉 SUCCESSFULLY snoozed reminder $reminderId for $minutes minutes',
        );
      } catch (e, stackTrace) {
        print('💥 CRITICAL ERROR snoozing reminder $reminderId: $e');
        print('Stack trace: $stackTrace');
      }
    },
    onMarkDone: (reminderId) async {
      // Handle mark done action from notification buttons
      // We'll handle this directly with the database to avoid circular dependency
      print('✅ NOTIFICATION ACTION: Mark done for reminder $reminderId');

      try {
        print('📍 Step 1: Getting reminder from database...');
        final reminder = await database.getReminderById(reminderId);
        if (reminder == null) {
          print('❌ Reminder $reminderId not found in database!');
          return;
        }
        print('✅ Found reminder: ${reminder.title}');

        // Check if this is a repeating reminder (daily, weekly, etc.)
        if (reminder.hasRepeat) {
          print(
            '🔄 This is a repeating reminder - rescheduling to next occurrence',
          );

          // Import scheduling service to calculate next occurrence
          final nextOccurrence = SchedulingService.calculateNextOccurrence(
            reminder,
          );
          print('📍 Step 2: Next occurrence calculated: $nextOccurrence');

          final rescheduledReminder = reminder.copyWith(
            scheduledAt: nextOccurrence,
            updatedAt: DateTime.now(),
            // Don't mark as completed - just reschedule to next occurrence
          );

          // Update in database
          print(
            '📍 Step 3: Updating reminder with next occurrence in database...',
          );
          await database.updateReminder(rescheduledReminder);
          print('✅ Database updated - reminder rescheduled to next occurrence');

          // Use the same mechanism as snooze to cancel all notifications (including auto-snooze) and reschedule
          print(
            '📍 Step 4: Starting async notification rescheduling (same as snooze)...',
          );
          final tempNotificationService = IOSNotificationService(
            database: database,
            onNotificationTap: (_, __) {},
            onSnoozeAction: (_, __) {},
            onMarkDone: (_) {},
          );

          // Use the same rescheduling mechanism as snooze - this properly cancels auto-snooze
          _handleNotificationReschedulingAsyncStatic(
            tempNotificationService,
            reminderId,
            rescheduledReminder,
          );
          print(
            '✅ Async notification rescheduling started (continuing in background)',
          );

          print(
            '🎉 SUCCESSFULLY rescheduled repeating reminder $reminderId to next occurrence',
          );
        } else {
          print('📍 This is a one-time reminder - marking as completed');

          final completedReminder = reminder.copyWith(
            isCompleted: true,
            updatedAt: DateTime.now(),
          );

          // Update in database
          print('📍 Step 2: Marking reminder as completed in database...');
          await database.updateReminder(completedReminder);
          print('✅ Database updated - reminder marked as done');

          // Cancel all notifications asynchronously
          print('📍 Step 3: Starting async notification cancellation...');
          final tempNotificationService = IOSNotificationService(
            database: database,
            onNotificationTap: (_, __) {},
            onSnoozeAction: (_, __) {},
            onMarkDone: (_) {},
          );

          // Don't await - let cancellation happen in background
          _handleMarkDoneNotificationCancellationAsync(
            tempNotificationService,
            reminderId,
          );
          print(
            '✅ Async notification cancellation started (continuing in background)',
          );

          print('🎉 SUCCESSFULLY marked one-time reminder $reminderId as done');
        }
      } catch (e, stackTrace) {
        print('💥 CRITICAL ERROR marking reminder $reminderId as done: $e');
        print('Stack trace: $stackTrace');
      }
    },
  );
});

// Reminders state notifier
class RemindersNotifier
    extends StateNotifier<AsyncValue<List<model.Reminder>>> {
  RemindersNotifier(this._database, this._notificationService)
    : super(const AsyncValue.loading()) {
    _loadReminders();
  }

  final SqliteDatabase _database;
  final NotificationService _notificationService;
  final _uuid = const Uuid();

  Future<void> _loadReminders() async {
    try {
      final reminders = await _database.getAllActiveReminders();
      state = AsyncValue.data(reminders);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createReminder(model.Reminder reminder) async {
    try {
      // Create reminder with new ID if not provided
      final newReminder = reminder.copyWith(
        id: reminder.id.isEmpty ? _uuid.v4() : reminder.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Insert into database
      await _database.insertReminder(newReminder);

      // Schedule notification
      if (!newReminder.isCompleted &&
          newReminder.scheduledAt.isAfter(DateTime.now())) {
        await _notificationService.scheduleReminder(
          newReminder,
          isTestNotification: false,
        );
      }

      // Reload reminders
      await _loadReminders();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateReminder(model.Reminder reminder) async {
    try {
      final updatedReminder = reminder.copyWith(updatedAt: DateTime.now());

      // Update in database
      await _database.updateReminder(updatedReminder);

      // Reschedule notification
      await _notificationService.cancelReminderNotifications(reminder.id);
      if (!updatedReminder.isCompleted &&
          updatedReminder.scheduledAt.isAfter(DateTime.now())) {
        await _notificationService.scheduleReminder(
          updatedReminder,
          isTestNotification: false,
        );
      }

      // Reload reminders
      await _loadReminders();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteReminder(String id) async {
    try {
      // Cancel notifications
      await _notificationService.cancelReminderNotifications(id);

      // Delete from database
      await _database.deleteReminder(id);

      // Reload reminders
      await _loadReminders();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> snoozeReminderUntil(String id, DateTime scheduledTime) async {
    try {
      // Get the reminder
      final reminder = await _database.getReminderById(id);
      if (reminder == null) return;

      // Update reminder with new scheduled time
      final snoozedReminder = reminder.copyWith(
        scheduledAt: scheduledTime,
        updatedAt: DateTime.now(),
      );

      await updateReminder(snoozedReminder);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> handleNotificationTap(
    String reminderId,
    Map<String, dynamic>? payload,
  ) async {
    // This will be implemented to handle deep links and navigation
    // For now, just mark as handled
    print('Notification tapped for reminder: $reminderId');
  }

  Future<void> rescheduleAllReminders() async {
    try {
      final reminders = await _database.getAllActiveReminders();
      await _notificationService.rescheduleAllReminders(reminders);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<model.Reminder?> getReminderById(String id) async {
    return await _database.getReminderById(id);
  }

  /// Handle notification rescheduling asynchronously in the background
  /// This allows the UI to respond immediately while heavy operations continue
  void _handleNotificationReschedulingAsync(
    NotificationService notificationService,
    String reminderId,
    model.Reminder snoozedReminder,
  ) {
    // Run in background without blocking the UI
    Future.microtask(() async {
      try {
        print(
          '🔄 BACKGROUND: Starting notification cancellation for $reminderId...',
        );

        // Initialize the service if needed
        if (notificationService is IOSNotificationService) {
          await notificationService.init();
        }

        // Cancel all existing notifications (including auto-snooze)
        await notificationService.cancelReminderNotifications(reminderId);
        print('✅ BACKGROUND: All notifications cancelled for $reminderId');

        // Schedule new notification if not completed
        if (!snoozedReminder.isCompleted) {
          print(
            '🔄 BACKGROUND: Scheduling new notification for $reminderId...',
          );
          await notificationService.scheduleReminder(
            snoozedReminder,
            isTestNotification: false,
          );
          print('✅ BACKGROUND: New notification scheduled for $reminderId');
        }

        print(
          '🎉 BACKGROUND: Completed async notification rescheduling for $reminderId',
        );
      } catch (e, stackTrace) {
        print(
          '💥 BACKGROUND ERROR: Failed to reschedule notifications for $reminderId: $e',
        );
        print('Stack trace: $stackTrace');
      }
    });
  }

  Future<void> snoozeReminder(String reminderId, int minutes) async {
    try {
      final reminder = await _database.getReminderById(reminderId);
      if (reminder == null) return;

      // Calculate new scheduled time (rounded to nearest minute)
      final newScheduledTime = roundToMinute(
        DateTime.now().add(Duration(minutes: minutes)),
      );

      final snoozedReminder = reminder.copyWith(
        scheduledAt: newScheduledTime,
        updatedAt: DateTime.now(),
      );

      // Update in database
      await _database.updateReminder(snoozedReminder);

      // Reschedule notification asynchronously (not a test notification)
      print('📍 Starting async notification rescheduling...');
      _handleNotificationReschedulingAsync(
        _notificationService,
        reminderId,
        snoozedReminder,
      );
      print(
        '✅ Async notification rescheduling started (continuing in background)',
      );

      // Reload reminders
      await _loadReminders();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> markReminderCompleted(String reminderId) async {
    try {
      print('✅ IN-APP ACTION: Mark done for reminder $reminderId');

      final reminder = await _database.getReminderById(reminderId);
      if (reminder == null) return;

      // Check if this is a repeating reminder (daily, weekly, etc.)
      if (reminder.hasRepeat) {
        print(
          '🔄 This is a repeating reminder - rescheduling to next occurrence',
        );

        // Calculate next occurrence
        final nextOccurrence = SchedulingService.calculateNextOccurrence(
          reminder,
        );
        print('📍 Next occurrence calculated: $nextOccurrence');

        final rescheduledReminder = reminder.copyWith(
          scheduledAt: nextOccurrence,
          updatedAt: DateTime.now(),
          // Don't mark as completed - just reschedule to next occurrence
        );

        // Update in database immediately for instant UI update
        await _database.updateReminder(rescheduledReminder);
        print('✅ Database updated - reminder rescheduled to next occurrence');

        // Reload reminders immediately so UI updates
        await _loadReminders();
        print('✅ UI updated with rescheduled reminder');

        // Use the same rescheduling mechanism as snooze - this properly cancels auto-snooze
        print(
          '📍 Starting async notification rescheduling (same as snooze)...',
        );
        _handleNotificationReschedulingAsyncStatic(
          _notificationService,
          reminderId,
          rescheduledReminder,
        );
        print(
          '✅ Async notification rescheduling started (continuing in background)',
        );

        print(
          '🎉 SUCCESSFULLY rescheduled repeating reminder $reminderId to next occurrence',
        );
      } else {
        print('📍 This is a one-time reminder - marking as completed');

        final completedReminder = reminder.copyWith(
          isCompleted: true,
          updatedAt: DateTime.now(),
        );

        // Update in database immediately for instant UI update
        await _database.updateReminder(completedReminder);
        print('✅ Database updated - reminder marked as done');

        // Reload reminders immediately so UI updates
        await _loadReminders();
        print('✅ UI updated with completed reminder');

        // Cancel notifications asynchronously in background
        print('📍 Starting async notification cancellation...');
        _handleMarkDoneNotificationCancellationAsync(
          _notificationService,
          reminderId,
        );
        print(
          '✅ Async notification cancellation started (continuing in background)',
        );

        print('🎉 SUCCESSFULLY marked one-time reminder $reminderId as done');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Reminders provider
final reminderNotifierProvider =
    StateNotifierProvider<RemindersNotifier, AsyncValue<List<model.Reminder>>>((
      ref,
    ) {
      final database = ref.watch(databaseProvider);
      final notificationService = ref.watch(notificationServiceProvider);
      return RemindersNotifier(database, notificationService);
    });

// Permission status provider
final permissionStatusProvider = FutureProvider<bool>((ref) async {
  final notificationService = ref.watch(notificationServiceProvider);
  await notificationService.init();
  return await notificationService.arePermissionsGranted();
});

// App initialization provider
final appInitProvider = FutureProvider<void>((ref) async {
  final notificationService = ref.watch(notificationServiceProvider);
  await notificationService.init();
});

// Current editing reminder provider (for create/edit screen)
final currentReminderProvider = StateProvider<model.Reminder?>((ref) => null);

// Snooze sheet provider (for custom snooze)
final snoozeSheetProvider = StateProvider<String?>((ref) => null);

// Current reminder action provider (for notification tap dialog)
final currentReminderActionProvider = StateProvider<Map<String, dynamic>?>(
  (ref) => null,
);

// Highlighted reminder provider (for notification tap highlighting)
final highlightedReminderProvider = StateProvider<String?>((ref) => null);

// Persistent default sound provider
class DefaultSoundNotifier extends StateNotifier<String> {
  DefaultSoundNotifier() : super(model.kDefaultSound) {
    _loadDefaultSound();
  }

  Future<void> _loadDefaultSound() async {
    await PreferencesService.init();
    final savedSound = PreferencesService.getDefaultSound();
    state = savedSound;
  }

  Future<void> setDefaultSound(String soundName) async {
    await PreferencesService.setDefaultSound(soundName);
    state = soundName;
  }
}

// Settings providers
final defaultSoundProvider =
    StateNotifierProvider<DefaultSoundNotifier, String>(
      (ref) => DefaultSoundNotifier(),
    );
final defaultSnoozePresetsProvider = StateProvider<List<model.SnoozePreset>>(
  (ref) => model.kDefaultSnoozePresets,
);

// Navigation state
final currentRouteProvider = StateProvider<String>((ref) => '/');

// Helper provider to get reminders grouped by day
final groupedRemindersProvider = Provider<Map<String, List<model.Reminder>>>((
  ref,
) {
  final remindersAsync = ref.watch(reminderNotifierProvider);

  return remindersAsync.when(
    data: (reminders) => _groupRemindersByDay(reminders),
    loading: () => {},
    error: (_, __) => {},
  );
});

Map<String, List<model.Reminder>> _groupRemindersByDay(
  List<model.Reminder> reminders,
) {
  final Map<String, List<model.Reminder>> grouped = {};
  final now = DateTime.now();

  for (final reminder in reminders) {
    final scheduledDate = reminder.scheduledAt;
    final difference = scheduledDate.difference(now).inDays;

    String key;
    if (difference == 0) {
      key = 'Today';
    } else if (difference == 1) {
      key = 'Tomorrow';
    } else if (difference < 7) {
      key = 'This Week';
    } else {
      key = 'Later';
    }

    grouped.putIfAbsent(key, () => []).add(reminder);
  }

  // Sort reminders within each group by scheduled time
  for (final group in grouped.values) {
    group.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  return grouped;
}
