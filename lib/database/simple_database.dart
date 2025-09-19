import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/reminder.dart' as model;

part 'simple_database.g.dart';

/// Reminders table definition using simple types
class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 120)();
  TextColumn get notes => text().nullable()();
  IntColumn get scheduledAt => integer()(); // UTC milliseconds
  IntColumn get repeatRule => integer()(); // Store as int
  IntColumn get repeatDaysMask => integer().nullable()();
  BoolColumn get timeSensitive =>
      boolean().withDefault(const Constant(false))();
  TextColumn get soundName =>
      text().withDefault(const Constant('alarm_1.caf'))();
  TextColumn get snoozePresets => text()(); // JSON array
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()(); // UTC milliseconds
  IntColumn get updatedAt => integer()(); // UTC milliseconds

  @override
  Set<Column> get primaryKey => {id};
}

/// Pending notifications table
class PendingNotifications extends Table {
  TextColumn get reminderId => text()();
  TextColumn get platformRequestId => text()();
  IntColumn get fireAt => integer()(); // UTC milliseconds

  @override
  Set<Column> get primaryKey => {reminderId, platformRequestId};
}

/// Database implementation
@DriftDatabase(tables: [Reminders, PendingNotifications])
class SimpleAppDatabase extends _$SimpleAppDatabase {
  SimpleAppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Reminders CRUD operations

  /// Get all non-completed reminders ordered by scheduled time
  Future<List<model.Reminder>> getAllActiveReminders() async {
    final query =
        select(reminders)
          ..where((r) => r.isCompleted.equals(false))
          ..orderBy([(r) => OrderingTerm.asc(r.scheduledAt)]);

    final rows = await query.get();
    return rows.map((row) => _reminderFromRow(row)).toList();
  }

  /// Get a reminder by ID
  Future<model.Reminder?> getReminderById(String id) async {
    final query = select(reminders)..where((r) => r.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _reminderFromRow(row) : null;
  }

  /// Insert a new reminder
  Future<void> insertReminder(model.Reminder reminder) async {
    await into(reminders).insert(_reminderToCompanion(reminder));
  }

  /// Update an existing reminder
  Future<void> updateReminder(model.Reminder reminder) async {
    await (update(reminders)..where(
      (r) => r.id.equals(reminder.id),
    )).write(_reminderToCompanion(reminder));
  }

  /// Delete a reminder
  Future<void> deleteReminder(String id) async {
    await (delete(reminders)..where((r) => r.id.equals(id))).go();
    // Also delete associated pending notifications
    await (delete(pendingNotifications)
      ..where((p) => p.reminderId.equals(id))).go();
  }

  /// Mark reminder as completed
  Future<void> markReminderCompleted(String id) async {
    await (update(reminders)..where((r) => r.id.equals(id))).write(
      RemindersCompanion(
        isCompleted: const Value(true),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  // Pending notifications operations

  /// Get all pending notifications for a reminder
  Future<List<AppPendingNotification>> getPendingNotifications(
    String reminderId,
  ) async {
    final query = select(pendingNotifications)
      ..where((p) => p.reminderId.equals(reminderId));
    final rows = await query.get();
    return rows
        .map(
          (row) => AppPendingNotification(
            reminderId: row.reminderId,
            platformRequestId: row.platformRequestId,
            fireAt: DateTime.fromMillisecondsSinceEpoch(
              row.fireAt,
              isUtc: true,
            ),
          ),
        )
        .toList();
  }

  /// Insert a pending notification
  Future<void> insertPendingNotification(
    AppPendingNotification notification,
  ) async {
    await into(pendingNotifications).insert(
      PendingNotificationsCompanion(
        reminderId: Value(notification.reminderId),
        platformRequestId: Value(notification.platformRequestId),
        fireAt: Value(notification.fireAt.millisecondsSinceEpoch),
      ),
    );
  }

  /// Delete pending notifications for a reminder
  Future<void> deletePendingNotifications(String reminderId) async {
    await (delete(pendingNotifications)
      ..where((p) => p.reminderId.equals(reminderId))).go();
  }

  /// Delete a specific pending notification
  Future<void> deletePendingNotification(
    String reminderId,
    String platformRequestId,
  ) async {
    await (delete(pendingNotifications)..where(
      (p) =>
          p.reminderId.equals(reminderId) &
          p.platformRequestId.equals(platformRequestId),
    )).go();
  }

  // Helper methods

  model.Reminder _reminderFromRow(Reminder row) {
    final snoozePresetsJson = jsonDecode(row.snoozePresets) as List;
    final snoozePresets =
        snoozePresetsJson
            .map(
              (json) =>
                  model.SnoozePreset.fromJson(json as Map<String, dynamic>),
            )
            .toList();

    return model.Reminder(
      id: row.id,
      title: row.title,
      notes: row.notes,
      scheduledAt:
          DateTime.fromMillisecondsSinceEpoch(row.scheduledAt).toLocal(),
      repeatRule: model.RepeatRule.values[row.repeatRule],
      repeatDaysMask: row.repeatDaysMask,
      timeSensitive: row.timeSensitive,
      soundName: row.soundName,
      snoozePresets: snoozePresets,
      isCompleted: row.isCompleted,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  RemindersCompanion _reminderToCompanion(model.Reminder reminder) {
    final snoozePresetsJson = jsonEncode(
      reminder.snoozePresets.map((preset) => preset.toJson()).toList(),
    );

    return RemindersCompanion(
      id: Value(reminder.id),
      title: Value(reminder.title),
      notes: Value(reminder.notes),
      scheduledAt: Value(reminder.scheduledAt.toUtc().millisecondsSinceEpoch),
      repeatRule: Value(reminder.repeatRule.index),
      repeatDaysMask: Value(reminder.repeatDaysMask),
      timeSensitive: Value(reminder.timeSensitive),
      soundName: Value(reminder.soundName),
      snoozePresets: Value(snoozePresetsJson),
      isCompleted: Value(reminder.isCompleted),
      createdAt: Value(reminder.createdAt.millisecondsSinceEpoch),
      updatedAt: Value(reminder.updatedAt.millisecondsSinceEpoch),
    );
  }
}

/// Model for pending notifications
class AppPendingNotification {
  const AppPendingNotification({
    required this.reminderId,
    required this.platformRequestId,
    required this.fireAt,
  });

  final String reminderId;
  final String platformRequestId;
  final DateTime fireAt;
}

/// Database connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'ios_alarm_simple.db'));
    return SqfliteQueryExecutor.inDatabaseFolder(
      path: file.path,
      logStatements: true,
    );
  });
}
