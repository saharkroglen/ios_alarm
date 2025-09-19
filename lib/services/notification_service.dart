import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import '../models/reminder.dart' as model;
import '../database/sqflite_database.dart';

/// Notification action identifiers
class NotificationActions {
  static const String snooze5 = 'SNOOZE_5';
  static const String snooze60 = 'SNOOZE_60';
  static const String snooze180 = 'SNOOZE_180';
  static const String snoozeTmrw9 = 'SNOOZE_TMRW_9';
  static const String snoozeCustom = 'SNOOZE_CUSTOM';
  static const String markDone = 'MARK_DONE';
}

/// Notification category identifier
const String kAlarmCategory = 'ALARM_CATEGORY';

/// Custom snooze deep link scheme
const String kCustomSnoozeScheme = 'nx2u.scheduler';

/// Notification service interface
abstract class NotificationService {
  Future<void> init();
  Future<void> requestPermissions();
  Future<bool> arePermissionsGranted();
  Future<void> registerCategories();
  Future<void> scheduleReminder(
    model.Reminder reminder, {
    bool isTestNotification = false,
  });
  Future<void> cancelReminderNotifications(String reminderId);
  Future<void> handleNotificationAction(
    String actionId,
    String reminderId, {
    Map<String, dynamic>? payload,
  });
  Future<void> rescheduleAllReminders(List<model.Reminder> reminders);
}

/// iOS-specific notification service implementation
class IOSNotificationService implements NotificationService {
  IOSNotificationService({
    required this.database,
    required this.onNotificationTap,
    required this.onSnoozeAction,
    required this.onMarkDone,
  });

  final SqliteDatabase database;
  final Function(String reminderId, Map<String, dynamic>? payload)
  onNotificationTap;
  final Function(String reminderId, int minutes) onSnoozeAction;
  final Function(String reminderId) onMarkDone;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final Uuid _uuid = const Uuid();

  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    // Create notification categories first
    final List<DarwinNotificationAction> actions = [
      DarwinNotificationAction.plain(
        NotificationActions.snooze5,
        'Snooze 5m',
        options: <DarwinNotificationActionOption>{
          DarwinNotificationActionOption.foreground,
        },
      ),
      DarwinNotificationAction.plain(
        NotificationActions.snooze60,
        'Snooze 1h',
        options: <DarwinNotificationActionOption>{
          DarwinNotificationActionOption.foreground,
        },
      ),
      DarwinNotificationAction.plain(
        NotificationActions.snooze180,
        'Snooze 3h',
        options: <DarwinNotificationActionOption>{
          DarwinNotificationActionOption.foreground,
        },
      ),
      DarwinNotificationAction.plain(
        NotificationActions.snoozeTmrw9,
        'Tomorrow 09:00',
        options: <DarwinNotificationActionOption>{
          DarwinNotificationActionOption.foreground,
        },
      ),
      DarwinNotificationAction.plain(
        NotificationActions.snoozeCustom,
        'Custom…',
        options: <DarwinNotificationActionOption>{
          DarwinNotificationActionOption.foreground,
        },
      ),
      DarwinNotificationAction.plain(
        NotificationActions.markDone,
        'Done',
        options: <DarwinNotificationActionOption>{
          DarwinNotificationActionOption.foreground,
        },
      ),
    ];

    final DarwinNotificationCategory category = DarwinNotificationCategory(
      kAlarmCategory,
      actions: actions,
      options: <DarwinNotificationCategoryOption>{
        DarwinNotificationCategoryOption.allowInCarPlay,
        DarwinNotificationCategoryOption.allowAnnouncement,
      },
    );

    // iOS initialization settings with categories
    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          onDidReceiveLocalNotification: null, // Deprecated for iOS 10+
          notificationCategories: [category], // Register categories here!
        );

    final InitializationSettings initSettings = InitializationSettings(
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    _initialized = true;

    if (kDebugMode) {
      print('NotificationService initialized with categories');
    }
  }

  @override
  Future<void> requestPermissions() async {
    final iosPlugin =
        _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();

    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: true, // Enable critical alerts for extended display duration
      );
    }
  }

  @override
  Future<bool> arePermissionsGranted() async {
    final iosPlugin =
        _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();

    if (iosPlugin != null) {
      final permissions = await iosPlugin.checkPermissions();
      return permissions?.isEnabled ?? false;
    }
    return false;
  }

  @override
  Future<void> registerCategories() async {
    // Categories are now registered during initialization
    // This method is kept for interface compliance
    if (kDebugMode) {
      print('Categories already registered during init');
    }
  }

  /// Build notification details based on reminder sound
  DarwinNotificationDetails _buildNotificationDetails(
    model.Reminder reminder, {
    bool isMain = true,
  }) {
    switch (reminder.soundName) {
      case 'system_default':
        return DarwinNotificationDetails(
          categoryIdentifier: kAlarmCategory,
          sound: null, // null uses system default sound
          interruptionLevel: InterruptionLevel.timeSensitive,
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          badgeNumber: 1,
        );
      case 'stars.caf':
        return DarwinNotificationDetails(
          categoryIdentifier: kAlarmCategory,
          sound: 'stars.caf',
          interruptionLevel: InterruptionLevel.timeSensitive,
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          badgeNumber: 2,
        );
      case 'summer.caf':
        return DarwinNotificationDetails(
          categoryIdentifier: kAlarmCategory,
          sound: 'summer.caf',
          interruptionLevel: InterruptionLevel.timeSensitive,
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          badgeNumber: 3,
        );
      case 'mistery.caf':
        return DarwinNotificationDetails(
          categoryIdentifier: kAlarmCategory,
          sound: 'mistery.caf',
          interruptionLevel: InterruptionLevel.timeSensitive,
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          badgeNumber: 4,
        );
      // Legacy support for old names
      case 'chime_1.caf':
        return DarwinNotificationDetails(
          categoryIdentifier: kAlarmCategory,
          sound: 'stars.caf', // Redirect to new name
          interruptionLevel: InterruptionLevel.timeSensitive,
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          badgeNumber: 1,
        );
      case 'bell_1.caf':
        return DarwinNotificationDetails(
          categoryIdentifier: kAlarmCategory,
          sound: 'mistery.caf', // Redirect to new name
          interruptionLevel: InterruptionLevel.timeSensitive,
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          badgeNumber: 3,
        );
      case 'alarm_1.caf':
        return DarwinNotificationDetails(
          categoryIdentifier: kAlarmCategory,
          sound: 'summer.caf', // Redirect to new name
          interruptionLevel: InterruptionLevel.timeSensitive,
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          badgeNumber: 2,
        );
      default:
        return DarwinNotificationDetails(
          categoryIdentifier: kAlarmCategory,
          sound: null, // Default to system sound
          interruptionLevel: InterruptionLevel.active,
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          badgeNumber: 1,
        );
    }
  }

  @override
  Future<void> scheduleReminder(
    model.Reminder reminder, {
    bool isTestNotification = false,
  }) async {
    if (!_initialized) await init();

    // Cancel any existing notifications for this reminder
    await cancelReminderNotifications(reminder.id);

    // Generate unique platform request ID
    final requestId = _uuid.v4();
    final requestIdHash = requestId.hashCode.abs();

    // Convert local scheduled time to UTC for timezone calculations
    final scheduledUtc = reminder.scheduledAt.toUtc();
    final scheduledTz = tz.TZDateTime.from(reminder.scheduledAt, tz.local);

    // Create notification details
    final DarwinNotificationDetails iosDetails = _buildNotificationDetails(
      reminder,
      isMain: true,
    );
    final NotificationDetails notificationDetails = NotificationDetails(
      iOS: iosDetails,
    );

    // Create payload with reminder data
    final payload = jsonEncode({
      'reminderId': reminder.id,
      'title': reminder.title,
      'notes': reminder.notes,
      'scheduledAt': reminder.scheduledAt.millisecondsSinceEpoch,
      'isTestNotification': isTestNotification,
    });

    try {
      if (kDebugMode) {
        print('Scheduling notification:');
        print('  ID: $requestIdHash');
        print('  Title: ${reminder.title}');
        print('  Scheduled for: $scheduledTz');
        print('  Sound: ${reminder.soundName}');
        print('  Category: $kAlarmCategory');
      }

      // Schedule the notification
      await _notifications.zonedSchedule(
        requestIdHash,
        reminder.title,
        reminder.notes?.isNotEmpty == true
            ? reminder.notes!
            : 'Tap Snooze to delay or Done to complete',
        scheduledTz,
        notificationDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      // Store pending notification in database
      final pendingNotification = AppPendingNotification(
        reminderId: reminder.id,
        platformRequestId: requestId,
        fireAt: scheduledUtc,
      );
      await database.insertPendingNotification(pendingNotification);

      if (kDebugMode) {
        print(
          '✅ Successfully scheduled notification for reminder ${reminder.id}',
        );

        // Verify the notification was scheduled
        final pendingNotifications =
            await _notifications.pendingNotificationRequests();
        final ourNotification =
            pendingNotifications
                .where((n) => n.id == requestIdHash)
                .firstOrNull;
        if (ourNotification != null) {
          print('✅ Confirmed: Notification is in pending list');
        } else {
          print('❌ Warning: Notification not found in pending list');
        }
      }

      // Schedule auto-snooze repeating notification 1 minute after the original
      // Skip auto-snooze for test notifications
      if (!isTestNotification) {
        final autoSnoozeTime = reminder.scheduledAt.add(
          const Duration(minutes: 1),
        );
        if (autoSnoozeTime.isAfter(DateTime.now())) {
          // Schedule auto-snooze asynchronously to not block the main notification
          if (kDebugMode) {
            print(
              '🔄 Starting async auto-snooze scheduling for ${reminder.id}...',
            );
          }
          _scheduleRepeatingAutoSnoozeAsync(reminder);
        }
      } else {
        if (kDebugMode) {
          print('⏭️ Skipping auto-snooze for test notification');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error scheduling notification: $e');
        print('Stack trace: ${StackTrace.current}');
      }
      rethrow;
    }
  }

  /// Schedule multiple individual auto-snooze notifications asynchronously
  void _scheduleRepeatingAutoSnoozeAsync(model.Reminder reminder) {
    // Run in background without blocking the main notification scheduling
    Future.microtask(() async {
      await _scheduleRepeatingAutoSnooze(reminder);
    });
  }

  /// Schedule multiple individual auto-snooze notifications (easier to cancel than repeating)
  Future<void> _scheduleRepeatingAutoSnooze(model.Reminder reminder) async {
    if (!_initialized) await init();

    if (kDebugMode) {
      print(
        '🔄 Scheduling individual auto-snooze notifications for reminder ${reminder.id}',
      );
    }

    // Create notification details for auto-snooze (more urgent styling)
    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      categoryIdentifier: kAlarmCategory,
      sound: reminder.soundName,
      interruptionLevel: InterruptionLevel.critical, // Critical stays longer
      presentAlert: true,
      presentBadge: true,
      presentSound: true, // Use built-in sound for longer banner duration
      badgeNumber: 2, // Different badge to show it's auto-snooze
      // subtitle: '🔄 Auto-snooze - Action needed!',
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      iOS: iosDetails,
    );

    // Schedule multiple individual auto-snooze notifications instead of using periodicallyShow
    // This makes them much easier to cancel individually
    final now = DateTime.now();
    final originalTime = reminder.scheduledAt;

    // Prepare all auto-snooze notifications for parallel scheduling
    final autoSnoozeSchedulingTasks = <Future<Map<String, dynamic>>>[];

    // Create scheduling tasks for the next 30 minutes (30 individual notifications)
    for (int i = 1; i <= 30; i++) {
      final autoSnoozeTime = originalTime.add(Duration(minutes: i));

      // Only schedule if it's in the future
      if (autoSnoozeTime.isAfter(now)) {
        final autoSnoozeId = '${reminder.id}_auto_$i';
        final requestId = _uuid.v4();
        final requestIdHash = requestId.hashCode.abs();

        // Create payload with auto-snooze info
        final payload = jsonEncode({
          'reminderId': reminder.id,
          'title': reminder.title,
          'notes': reminder.notes,
          'scheduledAt': reminder.scheduledAt.millisecondsSinceEpoch,
          'isAutoSnooze': true,
          'autoSnoozeCount': i,
        });

        // Add parallel scheduling task
        autoSnoozeSchedulingTasks.add(
          _scheduleIndividualAutoSnooze(
            requestIdHash,
            autoSnoozeId,
            requestId,
            reminder,
            autoSnoozeTime,
            notificationDetails,
            payload,
            i,
          ),
        );
      }
    }

    // Execute all auto-snooze scheduling in parallel
    if (autoSnoozeSchedulingTasks.isNotEmpty) {
      if (kDebugMode) {
        print(
          '🚀 BACKGROUND: Scheduling ${autoSnoozeSchedulingTasks.length} auto-snooze notifications in parallel...',
        );
      }

      final results = await Future.wait(
        autoSnoozeSchedulingTasks,
        eagerError: false, // Continue even if some fail
      );

      // Batch logging for better performance and readability
      if (kDebugMode) {
        final successful = results.where((r) => r['success'] == true).length;
        final failed = results.where((r) => r['success'] == false).length;

        print(
          '✅ BACKGROUND: Parallel scheduled $successful auto-snooze notifications for ${reminder.id}',
        );
        if (failed > 0) {
          print(
            '⚠️ BACKGROUND: $failed auto-snooze notifications failed to schedule',
          );
          // Only log first few failures to avoid spam
          final failures = results.where((r) => r['success'] == false).take(3);
          for (final failure in failures) {
            print(
              '  ❌ Auto-snooze #${failure['snoozeNumber']}: ${failure['error']}',
            );
          }
          if (failed > 3) {
            print('  ... and ${failed - 3} more failures');
          }
        }
      }
    } else {
      if (kDebugMode) {
        print(
          '⏭️ BACKGROUND: No auto-snooze notifications to schedule (all times in past)',
        );
      }
    }
  }

  /// Helper method to schedule individual auto-snooze notification
  Future<Map<String, dynamic>> _scheduleIndividualAutoSnooze(
    int requestIdHash,
    String autoSnoozeId,
    String requestId,
    model.Reminder reminder,
    DateTime autoSnoozeTime,
    NotificationDetails notificationDetails,
    String payload,
    int snoozeNumber,
  ) async {
    try {
      // Schedule individual auto-snooze notification
      await _notifications.zonedSchedule(
        requestIdHash,
        '${reminder.title} (Auto-snooze #$snoozeNumber)',
        'This reminder needs your attention! Tap to take action.',
        tz.TZDateTime.from(autoSnoozeTime, tz.local),
        notificationDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        // DO NOT use matchDateTimeComponents for auto-snooze - they should fire only once
        // matchDateTimeComponents: DateTimeComponents.time, // This causes daily repeats!
      );

      // Store auto-snooze notification in database
      final pendingNotification = AppPendingNotification(
        reminderId: autoSnoozeId,
        platformRequestId: requestId,
        fireAt: autoSnoozeTime.toUtc(),
      );
      await database.insertPendingNotification(pendingNotification);

      // Return success result for batch logging
      return {
        'success': true,
        'snoozeNumber': snoozeNumber,
        'time': autoSnoozeTime.toString(),
        'id': requestIdHash,
      };
    } catch (e) {
      // Return error result for batch logging
      return {
        'success': false,
        'snoozeNumber': snoozeNumber,
        'error': e.toString(),
        'id': requestIdHash,
      };
    }
  }

  @override
  Future<void> cancelReminderNotifications(String reminderId) async {
    if (kDebugMode) {
      print('🚫 CANCELLING all notifications for reminder: $reminderId');
    }

    // Get all pending notifications for this reminder
    final pendingNotifications = await database.getPendingNotifications(
      reminderId,
    );

    if (kDebugMode) {
      print(
        'Found ${pendingNotifications.length} pending notifications in database:',
      );
      for (final notification in pendingNotifications) {
        print(
          '  - ${notification.reminderId} (${notification.platformRequestId})',
        );
      }
    }

    // Get all platform pending notifications to see what's actually scheduled
    final allPlatformPending =
        await _notifications.pendingNotificationRequests();
    if (kDebugMode) {
      print(
        'Platform has ${allPlatformPending.length} total pending notifications',
      );
    }

    // Cancel each notification from our database
    for (final notification in pendingNotifications) {
      final requestIdHash = notification.platformRequestId.hashCode.abs();
      await _notifications.cancel(requestIdHash);

      if (kDebugMode) {
        print(
          '  ✅ Cancelled notification ID: $requestIdHash for ${notification.reminderId}',
        );
      }
    }

    // CRITICAL: For repeating notifications (auto-snooze), we need to use cancelAll
    // if regular cancel doesn't work for periodicallyShow
    final autoSnoozeNotifications =
        pendingNotifications
            .where((n) => n.reminderId.contains('_auto'))
            .toList();

    if (autoSnoozeNotifications.isNotEmpty) {
      if (kDebugMode) {
        print(
          '🔄 Found ${autoSnoozeNotifications.length} auto-snooze notifications - using parallel aggressive cancellation',
        );
      }

      // Cancel all auto-snooze notifications in parallel for speed
      final parallelCancellations =
          autoSnoozeNotifications.map((autoSnooze) async {
            final requestIdHash = autoSnooze.platformRequestId.hashCode.abs();

            try {
              // Method 1: Regular cancel
              await _notifications.cancel(requestIdHash);

              // Method 2: Wait a bit and try again
              await Future.delayed(const Duration(milliseconds: 100));
              await _notifications.cancel(requestIdHash);

              // Return success result for batch logging
              return {
                'success': true,
                'id': requestIdHash,
                'reminderId': autoSnooze.reminderId,
              };
            } catch (e) {
              // Return error result for batch logging
              return {
                'success': false,
                'id': requestIdHash,
                'reminderId': autoSnooze.reminderId,
                'error': e.toString(),
              };
            }
          }).toList();

      // Wait for all cancellations to complete in parallel
      final cancellationResults = await Future.wait(parallelCancellations);

      // Batch logging for better performance and readability
      if (kDebugMode) {
        final successful =
            cancellationResults.where((r) => r['success'] == true).length;
        final failed =
            cancellationResults.where((r) => r['success'] == false).length;

        print(
          '✅ BACKGROUND: Parallel double-cancelled $successful auto-snooze notifications',
        );
        if (failed > 0) {
          print('⚠️ BACKGROUND: $failed auto-snooze cancellations failed');
          // Only log first few failures to avoid spam
          final failures = cancellationResults
              .where((r) => r['success'] == false)
              .take(3);
          for (final failure in failures) {
            print(
              '  ❌ Failed to cancel ${failure['reminderId']}: ${failure['error']}',
            );
          }
          if (failed > 3) {
            print('  ... and ${failed - 3} more cancellation failures');
          }
        }
      }
    }

    // Verify cancellation worked
    if (kDebugMode) {
      await Future.delayed(
        const Duration(milliseconds: 200),
      ); // Wait for cancellation to process
      final remainingPending =
          await _notifications.pendingNotificationRequests();
      final stillPendingForThisReminder =
          remainingPending
              .where(
                (n) => pendingNotifications.any(
                  (pending) => pending.platformRequestId.hashCode.abs() == n.id,
                ),
              )
              .toList();

      if (stillPendingForThisReminder.isNotEmpty) {
        print(
          '⚠️ WARNING: ${stillPendingForThisReminder.length} notifications still pending after cancellation!',
        );
        for (final remaining in stillPendingForThisReminder) {
          print('  - STILL PENDING: ${remaining.id} - "${remaining.title}"');
          // Nuclear option: try to cancel again
          await _notifications.cancel(remaining.id);
        }
      } else {
        print('✅ All notifications successfully cancelled from platform');
      }
    }

    // Also cancel any iOS-side scheduled auto-snooze tasks
    try {
      const platform = MethodChannel('com.ios_alarm.sound');
      await platform.invokeMethod('cancelAutoSnooze', reminderId);
      if (kDebugMode) {
        print('✅ Cancelled iOS auto-snooze tasks for reminder $reminderId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not cancel iOS auto-snooze tasks: $e');
      }
    }

    // Remove from database
    await database.deletePendingNotifications(reminderId);

    if (kDebugMode) {
      print('✅ COMPLETED cancellation for reminder $reminderId');
    }
  }

  @override
  Future<void> rescheduleAllReminders(List<model.Reminder> reminders) async {
    if (kDebugMode) {
      print('Rescheduling ${reminders.length} reminders');
    }

    for (final reminder in reminders) {
      if (!reminder.isCompleted &&
          reminder.scheduledAt.isAfter(DateTime.now())) {
        await scheduleReminder(reminder, isTestNotification: false);
      }
    }
  }

  @override
  Future<void> handleNotificationAction(
    String actionId,
    String reminderId, {
    Map<String, dynamic>? payload,
  }) async {
    if (kDebugMode) {
      print(
        '🎯 HANDLING NOTIFICATION ACTION: $actionId for reminder: $reminderId',
      );
      print('   Payload: $payload');
    }

    try {
      switch (actionId) {
        case NotificationActions.snooze5:
          if (kDebugMode) print('   → Executing snooze 5 minutes');
          await onSnoozeAction(reminderId, 5);
          break;
        case NotificationActions.snooze60:
          if (kDebugMode) print('   → Executing snooze 60 minutes');
          await onSnoozeAction(reminderId, 60);
          break;
        case NotificationActions.snooze180:
          if (kDebugMode) print('   → Executing snooze 180 minutes');
          await onSnoozeAction(reminderId, 180);
          break;
        case NotificationActions.snoozeTmrw9:
          // Calculate minutes until tomorrow 9:00 AM
          final now = DateTime.now();
          final tomorrow9 = DateTime(now.year, now.month, now.day + 1, 9, 0);
          final minutesUntilTomorrow9 = tomorrow9.difference(now).inMinutes;
          if (kDebugMode)
            print(
              '   → Executing snooze until tomorrow 9AM ($minutesUntilTomorrow9 minutes)',
            );
          await onSnoozeAction(reminderId, minutesUntilTomorrow9);
          break;
        case NotificationActions.snoozeCustom:
          // This will trigger deep link to custom snooze screen
          // The deep link handler will call onNotificationTap
          if (kDebugMode)
            print('   → Executing custom snooze (opening dialog)');
          await onNotificationTap(reminderId, payload);
          break;
        case NotificationActions.markDone:
          if (kDebugMode) print('   → Executing mark done');
          await onMarkDone(reminderId);
          break;
        default:
          if (kDebugMode) {
            print('❌ Unknown notification action: $actionId');
          }
      }

      if (kDebugMode) {
        print('✅ COMPLETED notification action: $actionId');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('💥 ERROR handling notification action $actionId: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  // Handle notification tap (foreground)
  Future<void> _onNotificationResponse(NotificationResponse response) async {
    if (kDebugMode) {
      print('📱 NOTIFICATION RESPONSE RECEIVED:');
      print('   Action ID: ${response.actionId}');
      print('   Notification ID: ${response.id}');
      print('   Input: ${response.input}');
      print('   Payload: ${response.payload}');
    }

    final payload = response.payload;
    if (payload != null) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        final reminderId = data['reminderId'] as String;

        if (kDebugMode) {
          print('   Reminder ID: $reminderId');
        }

        if (response.actionId != null) {
          if (kDebugMode) {
            print('   → Routing to handleNotificationAction');
          }
          await handleNotificationAction(
            response.actionId!,
            reminderId,
            payload: data,
          );
        } else {
          if (kDebugMode) {
            print('   → Routing to onNotificationTap');
          }
          await onNotificationTap(reminderId, data);
        }

        if (kDebugMode) {
          print('✅ NOTIFICATION RESPONSE HANDLED SUCCESSFULLY');
        }
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print('💥 ERROR handling notification response: $e');
          print('Stack trace: $stackTrace');
        }
      }
    } else {
      if (kDebugMode) {
        print('⚠️ Notification response has no payload');
      }
    }
  }
}

/// Create deep link URL for custom snooze
String createCustomSnoozeDeepLink(String reminderId) {
  return '$kCustomSnoozeScheme://snooze?rid=$reminderId';
}
