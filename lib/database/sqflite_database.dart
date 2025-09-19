import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/reminder.dart' as model;

class SqliteDatabase {
  static Database? _database;
  static const String _databaseName = 'ios_alarm.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _remindersTable = 'reminders';
  static const String _pendingNotificationsTable = 'pending_notifications';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create reminders table
    await db.execute('''
      CREATE TABLE $_remindersTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        notes TEXT,
        scheduled_at INTEGER NOT NULL,
        repeat_rule INTEGER NOT NULL,
        repeat_days_mask INTEGER,
        time_sensitive INTEGER NOT NULL DEFAULT 0,
        sound_name TEXT NOT NULL DEFAULT 'alarm_1.caf',
        snooze_presets TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create pending notifications table
    await db.execute('''
      CREATE TABLE $_pendingNotificationsTable (
        reminder_id TEXT NOT NULL,
        platform_request_id TEXT NOT NULL,
        fire_at INTEGER NOT NULL,
        PRIMARY KEY (reminder_id, platform_request_id)
      )
    ''');
  }

  // Reminders CRUD operations

  Future<List<model.Reminder>> getAllActiveReminders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _remindersTable,
      where: 'is_completed = ?',
      whereArgs: [0],
      orderBy: 'scheduled_at ASC',
    );

    return maps.map((map) => _reminderFromMap(map)).toList();
  }

  Future<model.Reminder?> getReminderById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _remindersTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _reminderFromMap(maps.first);
  }

  Future<void> insertReminder(model.Reminder reminder) async {
    final db = await database;
    await db.insert(
      _remindersTable,
      _reminderToMap(reminder),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateReminder(model.Reminder reminder) async {
    final db = await database;
    await db.update(
      _remindersTable,
      _reminderToMap(reminder),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<void> deleteReminder(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      // Delete reminder
      await txn.delete(_remindersTable, where: 'id = ?', whereArgs: [id]);
      // Delete associated pending notifications
      await txn.delete(
        _pendingNotificationsTable,
        where: 'reminder_id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> markReminderCompleted(String id) async {
    final db = await database;
    await db.update(
      _remindersTable,
      {'is_completed': 1, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Pending notifications operations

  Future<List<AppPendingNotification>> getPendingNotifications(
    String reminderId,
  ) async {
    final db = await database;
    // Get both the exact reminder ID and auto-snooze notifications for this reminder
    final List<Map<String, dynamic>> maps = await db.query(
      _pendingNotificationsTable,
      where: 'reminder_id = ? OR reminder_id LIKE ?',
      whereArgs: [reminderId, '${reminderId}_auto%'],
    );

    return maps
        .map(
          (map) => AppPendingNotification(
            reminderId: map['reminder_id'] as String,
            platformRequestId: map['platform_request_id'] as String,
            fireAt: DateTime.fromMillisecondsSinceEpoch(
              map['fire_at'] as int,
              isUtc: true,
            ),
          ),
        )
        .toList();
  }

  Future<void> insertPendingNotification(
    AppPendingNotification notification,
  ) async {
    final db = await database;
    await db.insert(_pendingNotificationsTable, {
      'reminder_id': notification.reminderId,
      'platform_request_id': notification.platformRequestId,
      'fire_at': notification.fireAt.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deletePendingNotifications(String reminderId) async {
    final db = await database;
    // Delete both the exact reminder ID and auto-snooze notifications for this reminder
    await db.delete(
      _pendingNotificationsTable,
      where: 'reminder_id = ? OR reminder_id LIKE ?',
      whereArgs: [reminderId, '${reminderId}_auto%'],
    );
  }

  Future<void> deletePendingNotification(
    String reminderId,
    String platformRequestId,
  ) async {
    final db = await database;
    await db.delete(
      _pendingNotificationsTable,
      where: 'reminder_id = ? AND platform_request_id = ?',
      whereArgs: [reminderId, platformRequestId],
    );
  }

  // Helper methods

  model.Reminder _reminderFromMap(Map<String, dynamic> map) {
    final snoozePresetsJson =
        jsonDecode(map['snooze_presets'] as String) as List;
    final snoozePresets =
        snoozePresetsJson
            .map(
              (json) =>
                  model.SnoozePreset.fromJson(json as Map<String, dynamic>),
            )
            .toList();

    return model.Reminder(
      id: map['id'] as String,
      title: map['title'] as String,
      notes: map['notes'] as String?,
      scheduledAt:
          DateTime.fromMillisecondsSinceEpoch(
            map['scheduled_at'] as int,
          ).toLocal(),
      repeatRule: model.RepeatRule.values[map['repeat_rule'] as int],
      repeatDaysMask: map['repeat_days_mask'] as int?,
      timeSensitive: (map['time_sensitive'] as int) == 1,
      soundName: map['sound_name'] as String,
      snoozePresets: snoozePresets,
      isCompleted: (map['is_completed'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> _reminderToMap(model.Reminder reminder) {
    final snoozePresetsJson = jsonEncode(
      reminder.snoozePresets.map((preset) => preset.toJson()).toList(),
    );

    return {
      'id': reminder.id,
      'title': reminder.title,
      'notes': reminder.notes,
      'scheduled_at': reminder.scheduledAt.toUtc().millisecondsSinceEpoch,
      'repeat_rule': reminder.repeatRule.index,
      'repeat_days_mask': reminder.repeatDaysMask,
      'time_sensitive': reminder.timeSensitive ? 1 : 0,
      'sound_name': reminder.soundName,
      'snooze_presets': snoozePresetsJson,
      'is_completed': reminder.isCompleted ? 1 : 0,
      'created_at': reminder.createdAt.millisecondsSinceEpoch,
      'updated_at': reminder.updatedAt.millisecondsSinceEpoch,
    };
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
