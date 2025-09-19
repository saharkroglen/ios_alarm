// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, model.Reminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  @override
  late final GeneratedColumn<int> scheduledAt = GeneratedColumn<int>(
    'scheduled_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<model.RepeatRule, int>
  repeatRule = GeneratedColumn<int>(
    'repeat_rule',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<model.RepeatRule>($RemindersTable.$converterrepeatRule);
  static const VerificationMeta _repeatDaysMaskMeta = const VerificationMeta(
    'repeatDaysMask',
  );
  @override
  late final GeneratedColumn<int> repeatDaysMask = GeneratedColumn<int>(
    'repeat_days_mask',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeSensitiveMeta = const VerificationMeta(
    'timeSensitive',
  );
  @override
  late final GeneratedColumn<bool> timeSensitive = GeneratedColumn<bool>(
    'time_sensitive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("time_sensitive" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _soundNameMeta = const VerificationMeta(
    'soundName',
  );
  @override
  late final GeneratedColumn<String> soundName = GeneratedColumn<String>(
    'sound_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('alarm_1.caf'),
  );
  static const VerificationMeta _snoozePresetsMeta = const VerificationMeta(
    'snoozePresets',
  );
  @override
  late final GeneratedColumn<String> snoozePresets = GeneratedColumn<String>(
    'snooze_presets',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    notes,
    scheduledAt,
    repeatRule,
    repeatDaysMask,
    timeSensitive,
    soundName,
    snoozePresets,
    isCompleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<model.Reminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
        _scheduledAtMeta,
        scheduledAt.isAcceptableOrUnknown(
          data['scheduled_at']!,
          _scheduledAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledAtMeta);
    }
    if (data.containsKey('repeat_days_mask')) {
      context.handle(
        _repeatDaysMaskMeta,
        repeatDaysMask.isAcceptableOrUnknown(
          data['repeat_days_mask']!,
          _repeatDaysMaskMeta,
        ),
      );
    }
    if (data.containsKey('time_sensitive')) {
      context.handle(
        _timeSensitiveMeta,
        timeSensitive.isAcceptableOrUnknown(
          data['time_sensitive']!,
          _timeSensitiveMeta,
        ),
      );
    }
    if (data.containsKey('sound_name')) {
      context.handle(
        _soundNameMeta,
        soundName.isAcceptableOrUnknown(data['sound_name']!, _soundNameMeta),
      );
    }
    if (data.containsKey('snooze_presets')) {
      context.handle(
        _snoozePresetsMeta,
        snoozePresets.isAcceptableOrUnknown(
          data['snooze_presets']!,
          _snoozePresetsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_snoozePresetsMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  model.Reminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reminder(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      title:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}title'],
          )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      scheduledAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}scheduled_at'],
          )!,
      repeatRule: $RemindersTable.$converterrepeatRule.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}repeat_rule'],
        )!,
      ),
      repeatDaysMask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repeat_days_mask'],
      ),
      timeSensitive:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}time_sensitive'],
          )!,
      soundName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}sound_name'],
          )!,
      snoozePresets:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}snooze_presets'],
          )!,
      isCompleted:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_completed'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<model.RepeatRule, int, int> $converterrepeatRule =
      const EnumIndexConverter<model.RepeatRule>(model.RepeatRule.values);
}

class Reminder extends DataClass implements Insertable<model.Reminder> {
  final String id;
  final String title;
  final String? notes;
  final int scheduledAt;
  final model.RepeatRule repeatRule;
  final int? repeatDaysMask;
  final bool timeSensitive;
  final String soundName;
  final String snoozePresets;
  final bool isCompleted;
  final int createdAt;
  final int updatedAt;
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
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['scheduled_at'] = Variable<int>(scheduledAt);
    {
      map['repeat_rule'] = Variable<int>(
        $RemindersTable.$converterrepeatRule.toSql(repeatRule),
      );
    }
    if (!nullToAbsent || repeatDaysMask != null) {
      map['repeat_days_mask'] = Variable<int>(repeatDaysMask);
    }
    map['time_sensitive'] = Variable<bool>(timeSensitive);
    map['sound_name'] = Variable<String>(soundName);
    map['snooze_presets'] = Variable<String>(snoozePresets);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      title: Value(title),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      scheduledAt: Value(scheduledAt),
      repeatRule: Value(repeatRule),
      repeatDaysMask:
          repeatDaysMask == null && nullToAbsent
              ? const Value.absent()
              : Value(repeatDaysMask),
      timeSensitive: Value(timeSensitive),
      soundName: Value(soundName),
      snoozePresets: Value(snoozePresets),
      isCompleted: Value(isCompleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Reminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reminder(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      notes: serializer.fromJson<String?>(json['notes']),
      scheduledAt: serializer.fromJson<int>(json['scheduledAt']),
      repeatRule: $RemindersTable.$converterrepeatRule.fromJson(
        serializer.fromJson<int>(json['repeatRule']),
      ),
      repeatDaysMask: serializer.fromJson<int?>(json['repeatDaysMask']),
      timeSensitive: serializer.fromJson<bool>(json['timeSensitive']),
      soundName: serializer.fromJson<String>(json['soundName']),
      snoozePresets: serializer.fromJson<String>(json['snoozePresets']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'notes': serializer.toJson<String?>(notes),
      'scheduledAt': serializer.toJson<int>(scheduledAt),
      'repeatRule': serializer.toJson<int>(
        $RemindersTable.$converterrepeatRule.toJson(repeatRule),
      ),
      'repeatDaysMask': serializer.toJson<int?>(repeatDaysMask),
      'timeSensitive': serializer.toJson<bool>(timeSensitive),
      'soundName': serializer.toJson<String>(soundName),
      'snoozePresets': serializer.toJson<String>(snoozePresets),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Reminder copyWith({
    String? id,
    String? title,
    Value<String?> notes = const Value.absent(),
    int? scheduledAt,
    model.RepeatRule? repeatRule,
    Value<int?> repeatDaysMask = const Value.absent(),
    bool? timeSensitive,
    String? soundName,
    String? snoozePresets,
    bool? isCompleted,
    int? createdAt,
    int? updatedAt,
  }) => Reminder(
    id: id ?? this.id,
    title: title ?? this.title,
    notes: notes.present ? notes.value : this.notes,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    repeatRule: repeatRule ?? this.repeatRule,
    repeatDaysMask:
        repeatDaysMask.present ? repeatDaysMask.value : this.repeatDaysMask,
    timeSensitive: timeSensitive ?? this.timeSensitive,
    soundName: soundName ?? this.soundName,
    snoozePresets: snoozePresets ?? this.snoozePresets,
    isCompleted: isCompleted ?? this.isCompleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Reminder copyWithCompanion(RemindersCompanion data) {
    return Reminder(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      notes: data.notes.present ? data.notes.value : this.notes,
      scheduledAt:
          data.scheduledAt.present ? data.scheduledAt.value : this.scheduledAt,
      repeatRule:
          data.repeatRule.present ? data.repeatRule.value : this.repeatRule,
      repeatDaysMask:
          data.repeatDaysMask.present
              ? data.repeatDaysMask.value
              : this.repeatDaysMask,
      timeSensitive:
          data.timeSensitive.present
              ? data.timeSensitive.value
              : this.timeSensitive,
      soundName: data.soundName.present ? data.soundName.value : this.soundName,
      snoozePresets:
          data.snoozePresets.present
              ? data.snoozePresets.value
              : this.snoozePresets,
      isCompleted:
          data.isCompleted.present ? data.isCompleted.value : this.isCompleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reminder(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('repeatDaysMask: $repeatDaysMask, ')
          ..write('timeSensitive: $timeSensitive, ')
          ..write('soundName: $soundName, ')
          ..write('snoozePresets: $snoozePresets, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    notes,
    scheduledAt,
    repeatRule,
    repeatDaysMask,
    timeSensitive,
    soundName,
    snoozePresets,
    isCompleted,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reminder &&
          other.id == this.id &&
          other.title == this.title &&
          other.notes == this.notes &&
          other.scheduledAt == this.scheduledAt &&
          other.repeatRule == this.repeatRule &&
          other.repeatDaysMask == this.repeatDaysMask &&
          other.timeSensitive == this.timeSensitive &&
          other.soundName == this.soundName &&
          other.snoozePresets == this.snoozePresets &&
          other.isCompleted == this.isCompleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RemindersCompanion extends UpdateCompanion<model.Reminder> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> notes;
  final Value<int> scheduledAt;
  final Value<model.RepeatRule> repeatRule;
  final Value<int?> repeatDaysMask;
  final Value<bool> timeSensitive;
  final Value<String> soundName;
  final Value<String> snoozePresets;
  final Value<bool> isCompleted;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.repeatDaysMask = const Value.absent(),
    this.timeSensitive = const Value.absent(),
    this.soundName = const Value.absent(),
    this.snoozePresets = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemindersCompanion.insert({
    required String id,
    required String title,
    this.notes = const Value.absent(),
    required int scheduledAt,
    required model.RepeatRule repeatRule,
    this.repeatDaysMask = const Value.absent(),
    this.timeSensitive = const Value.absent(),
    this.soundName = const Value.absent(),
    required String snoozePresets,
    this.isCompleted = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       scheduledAt = Value(scheduledAt),
       repeatRule = Value(repeatRule),
       snoozePresets = Value(snoozePresets),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<model.Reminder> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? notes,
    Expression<int>? scheduledAt,
    Expression<int>? repeatRule,
    Expression<int>? repeatDaysMask,
    Expression<bool>? timeSensitive,
    Expression<String>? soundName,
    Expression<String>? snoozePresets,
    Expression<bool>? isCompleted,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (repeatRule != null) 'repeat_rule': repeatRule,
      if (repeatDaysMask != null) 'repeat_days_mask': repeatDaysMask,
      if (timeSensitive != null) 'time_sensitive': timeSensitive,
      if (soundName != null) 'sound_name': soundName,
      if (snoozePresets != null) 'snooze_presets': snoozePresets,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemindersCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? notes,
    Value<int>? scheduledAt,
    Value<model.RepeatRule>? repeatRule,
    Value<int?>? repeatDaysMask,
    Value<bool>? timeSensitive,
    Value<String>? soundName,
    Value<String>? snoozePresets,
    Value<bool>? isCompleted,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return RemindersCompanion(
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
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<int>(scheduledAt.value);
    }
    if (repeatRule.present) {
      map['repeat_rule'] = Variable<int>(
        $RemindersTable.$converterrepeatRule.toSql(repeatRule.value),
      );
    }
    if (repeatDaysMask.present) {
      map['repeat_days_mask'] = Variable<int>(repeatDaysMask.value);
    }
    if (timeSensitive.present) {
      map['time_sensitive'] = Variable<bool>(timeSensitive.value);
    }
    if (soundName.present) {
      map['sound_name'] = Variable<String>(soundName.value);
    }
    if (snoozePresets.present) {
      map['snooze_presets'] = Variable<String>(snoozePresets.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('repeatDaysMask: $repeatDaysMask, ')
          ..write('timeSensitive: $timeSensitive, ')
          ..write('soundName: $soundName, ')
          ..write('snoozePresets: $snoozePresets, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingNotificationsTable extends PendingNotifications
    with TableInfo<$PendingNotificationsTable, PendingNotification> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingNotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _reminderIdMeta = const VerificationMeta(
    'reminderId',
  );
  @override
  late final GeneratedColumn<String> reminderId = GeneratedColumn<String>(
    'reminder_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _platformRequestIdMeta = const VerificationMeta(
    'platformRequestId',
  );
  @override
  late final GeneratedColumn<String> platformRequestId =
      GeneratedColumn<String>(
        'platform_request_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _fireAtMeta = const VerificationMeta('fireAt');
  @override
  late final GeneratedColumn<int> fireAt = GeneratedColumn<int>(
    'fire_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [reminderId, platformRequestId, fireAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_notifications';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingNotification> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('reminder_id')) {
      context.handle(
        _reminderIdMeta,
        reminderId.isAcceptableOrUnknown(data['reminder_id']!, _reminderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_reminderIdMeta);
    }
    if (data.containsKey('platform_request_id')) {
      context.handle(
        _platformRequestIdMeta,
        platformRequestId.isAcceptableOrUnknown(
          data['platform_request_id']!,
          _platformRequestIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_platformRequestIdMeta);
    }
    if (data.containsKey('fire_at')) {
      context.handle(
        _fireAtMeta,
        fireAt.isAcceptableOrUnknown(data['fire_at']!, _fireAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fireAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {reminderId, platformRequestId};
  @override
  PendingNotification map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingNotification(
      reminderId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}reminder_id'],
          )!,
      platformRequestId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}platform_request_id'],
          )!,
      fireAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}fire_at'],
          )!,
    );
  }

  @override
  $PendingNotificationsTable createAlias(String alias) {
    return $PendingNotificationsTable(attachedDatabase, alias);
  }
}

class PendingNotification extends DataClass
    implements Insertable<PendingNotification> {
  final String reminderId;
  final String platformRequestId;
  final int fireAt;
  const PendingNotification({
    required this.reminderId,
    required this.platformRequestId,
    required this.fireAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['reminder_id'] = Variable<String>(reminderId);
    map['platform_request_id'] = Variable<String>(platformRequestId);
    map['fire_at'] = Variable<int>(fireAt);
    return map;
  }

  PendingNotificationsCompanion toCompanion(bool nullToAbsent) {
    return PendingNotificationsCompanion(
      reminderId: Value(reminderId),
      platformRequestId: Value(platformRequestId),
      fireAt: Value(fireAt),
    );
  }

  factory PendingNotification.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingNotification(
      reminderId: serializer.fromJson<String>(json['reminderId']),
      platformRequestId: serializer.fromJson<String>(json['platformRequestId']),
      fireAt: serializer.fromJson<int>(json['fireAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'reminderId': serializer.toJson<String>(reminderId),
      'platformRequestId': serializer.toJson<String>(platformRequestId),
      'fireAt': serializer.toJson<int>(fireAt),
    };
  }

  PendingNotification copyWith({
    String? reminderId,
    String? platformRequestId,
    int? fireAt,
  }) => PendingNotification(
    reminderId: reminderId ?? this.reminderId,
    platformRequestId: platformRequestId ?? this.platformRequestId,
    fireAt: fireAt ?? this.fireAt,
  );
  PendingNotification copyWithCompanion(PendingNotificationsCompanion data) {
    return PendingNotification(
      reminderId:
          data.reminderId.present ? data.reminderId.value : this.reminderId,
      platformRequestId:
          data.platformRequestId.present
              ? data.platformRequestId.value
              : this.platformRequestId,
      fireAt: data.fireAt.present ? data.fireAt.value : this.fireAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingNotification(')
          ..write('reminderId: $reminderId, ')
          ..write('platformRequestId: $platformRequestId, ')
          ..write('fireAt: $fireAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(reminderId, platformRequestId, fireAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingNotification &&
          other.reminderId == this.reminderId &&
          other.platformRequestId == this.platformRequestId &&
          other.fireAt == this.fireAt);
}

class PendingNotificationsCompanion
    extends UpdateCompanion<PendingNotification> {
  final Value<String> reminderId;
  final Value<String> platformRequestId;
  final Value<int> fireAt;
  final Value<int> rowid;
  const PendingNotificationsCompanion({
    this.reminderId = const Value.absent(),
    this.platformRequestId = const Value.absent(),
    this.fireAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingNotificationsCompanion.insert({
    required String reminderId,
    required String platformRequestId,
    required int fireAt,
    this.rowid = const Value.absent(),
  }) : reminderId = Value(reminderId),
       platformRequestId = Value(platformRequestId),
       fireAt = Value(fireAt);
  static Insertable<PendingNotification> custom({
    Expression<String>? reminderId,
    Expression<String>? platformRequestId,
    Expression<int>? fireAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (reminderId != null) 'reminder_id': reminderId,
      if (platformRequestId != null) 'platform_request_id': platformRequestId,
      if (fireAt != null) 'fire_at': fireAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingNotificationsCompanion copyWith({
    Value<String>? reminderId,
    Value<String>? platformRequestId,
    Value<int>? fireAt,
    Value<int>? rowid,
  }) {
    return PendingNotificationsCompanion(
      reminderId: reminderId ?? this.reminderId,
      platformRequestId: platformRequestId ?? this.platformRequestId,
      fireAt: fireAt ?? this.fireAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (reminderId.present) {
      map['reminder_id'] = Variable<String>(reminderId.value);
    }
    if (platformRequestId.present) {
      map['platform_request_id'] = Variable<String>(platformRequestId.value);
    }
    if (fireAt.present) {
      map['fire_at'] = Variable<int>(fireAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingNotificationsCompanion(')
          ..write('reminderId: $reminderId, ')
          ..write('platformRequestId: $platformRequestId, ')
          ..write('fireAt: $fireAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $PendingNotificationsTable pendingNotifications =
      $PendingNotificationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    reminders,
    pendingNotifications,
  ];
}

typedef $$RemindersTableCreateCompanionBuilder =
    RemindersCompanion Function({
      required String id,
      required String title,
      Value<String?> notes,
      required int scheduledAt,
      required model.RepeatRule repeatRule,
      Value<int?> repeatDaysMask,
      Value<bool> timeSensitive,
      Value<String> soundName,
      required String snoozePresets,
      Value<bool> isCompleted,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$RemindersTableUpdateCompanionBuilder =
    RemindersCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> notes,
      Value<int> scheduledAt,
      Value<model.RepeatRule> repeatRule,
      Value<int?> repeatDaysMask,
      Value<bool> timeSensitive,
      Value<String> soundName,
      Value<String> snoozePresets,
      Value<bool> isCompleted,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<model.RepeatRule, model.RepeatRule, int>
  get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get repeatDaysMask => $composableBuilder(
    column: $table.repeatDaysMask,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get timeSensitive => $composableBuilder(
    column: $table.timeSensitive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get soundName => $composableBuilder(
    column: $table.soundName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snoozePresets => $composableBuilder(
    column: $table.snoozePresets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repeatDaysMask => $composableBuilder(
    column: $table.repeatDaysMask,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get timeSensitive => $composableBuilder(
    column: $table.timeSensitive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get soundName => $composableBuilder(
    column: $table.soundName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snoozePresets => $composableBuilder(
    column: $table.snoozePresets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<model.RepeatRule, int> get repeatRule =>
      $composableBuilder(
        column: $table.repeatRule,
        builder: (column) => column,
      );

  GeneratedColumn<int> get repeatDaysMask => $composableBuilder(
    column: $table.repeatDaysMask,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get timeSensitive => $composableBuilder(
    column: $table.timeSensitive,
    builder: (column) => column,
  );

  GeneratedColumn<String> get soundName =>
      $composableBuilder(column: $table.soundName, builder: (column) => column);

  GeneratedColumn<String> get snoozePresets => $composableBuilder(
    column: $table.snoozePresets,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          model.Reminder,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (
            model.Reminder,
            BaseReferences<_$AppDatabase, $RemindersTable, model.Reminder>,
          ),
          model.Reminder,
          PrefetchHooks Function()
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> scheduledAt = const Value.absent(),
                Value<model.RepeatRule> repeatRule = const Value.absent(),
                Value<int?> repeatDaysMask = const Value.absent(),
                Value<bool> timeSensitive = const Value.absent(),
                Value<String> soundName = const Value.absent(),
                Value<String> snoozePresets = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                title: title,
                notes: notes,
                scheduledAt: scheduledAt,
                repeatRule: repeatRule,
                repeatDaysMask: repeatDaysMask,
                timeSensitive: timeSensitive,
                soundName: soundName,
                snoozePresets: snoozePresets,
                isCompleted: isCompleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> notes = const Value.absent(),
                required int scheduledAt,
                required model.RepeatRule repeatRule,
                Value<int?> repeatDaysMask = const Value.absent(),
                Value<bool> timeSensitive = const Value.absent(),
                Value<String> soundName = const Value.absent(),
                required String snoozePresets,
                Value<bool> isCompleted = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion.insert(
                id: id,
                title: title,
                notes: notes,
                scheduledAt: scheduledAt,
                repeatRule: repeatRule,
                repeatDaysMask: repeatDaysMask,
                timeSensitive: timeSensitive,
                soundName: soundName,
                snoozePresets: snoozePresets,
                isCompleted: isCompleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      model.Reminder,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (
        model.Reminder,
        BaseReferences<_$AppDatabase, $RemindersTable, model.Reminder>,
      ),
      model.Reminder,
      PrefetchHooks Function()
    >;
typedef $$PendingNotificationsTableCreateCompanionBuilder =
    PendingNotificationsCompanion Function({
      required String reminderId,
      required String platformRequestId,
      required int fireAt,
      Value<int> rowid,
    });
typedef $$PendingNotificationsTableUpdateCompanionBuilder =
    PendingNotificationsCompanion Function({
      Value<String> reminderId,
      Value<String> platformRequestId,
      Value<int> fireAt,
      Value<int> rowid,
    });

class $$PendingNotificationsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingNotificationsTable> {
  $$PendingNotificationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get reminderId => $composableBuilder(
    column: $table.reminderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get platformRequestId => $composableBuilder(
    column: $table.platformRequestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fireAt => $composableBuilder(
    column: $table.fireAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingNotificationsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingNotificationsTable> {
  $$PendingNotificationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get reminderId => $composableBuilder(
    column: $table.reminderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get platformRequestId => $composableBuilder(
    column: $table.platformRequestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fireAt => $composableBuilder(
    column: $table.fireAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingNotificationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingNotificationsTable> {
  $$PendingNotificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get reminderId => $composableBuilder(
    column: $table.reminderId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get platformRequestId => $composableBuilder(
    column: $table.platformRequestId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fireAt =>
      $composableBuilder(column: $table.fireAt, builder: (column) => column);
}

class $$PendingNotificationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingNotificationsTable,
          PendingNotification,
          $$PendingNotificationsTableFilterComposer,
          $$PendingNotificationsTableOrderingComposer,
          $$PendingNotificationsTableAnnotationComposer,
          $$PendingNotificationsTableCreateCompanionBuilder,
          $$PendingNotificationsTableUpdateCompanionBuilder,
          (
            PendingNotification,
            BaseReferences<
              _$AppDatabase,
              $PendingNotificationsTable,
              PendingNotification
            >,
          ),
          PendingNotification,
          PrefetchHooks Function()
        > {
  $$PendingNotificationsTableTableManager(
    _$AppDatabase db,
    $PendingNotificationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$PendingNotificationsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$PendingNotificationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$PendingNotificationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> reminderId = const Value.absent(),
                Value<String> platformRequestId = const Value.absent(),
                Value<int> fireAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingNotificationsCompanion(
                reminderId: reminderId,
                platformRequestId: platformRequestId,
                fireAt: fireAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String reminderId,
                required String platformRequestId,
                required int fireAt,
                Value<int> rowid = const Value.absent(),
              }) => PendingNotificationsCompanion.insert(
                reminderId: reminderId,
                platformRequestId: platformRequestId,
                fireAt: fireAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingNotificationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingNotificationsTable,
      PendingNotification,
      $$PendingNotificationsTableFilterComposer,
      $$PendingNotificationsTableOrderingComposer,
      $$PendingNotificationsTableAnnotationComposer,
      $$PendingNotificationsTableCreateCompanionBuilder,
      $$PendingNotificationsTableUpdateCompanionBuilder,
      (
        PendingNotification,
        BaseReferences<
          _$AppDatabase,
          $PendingNotificationsTable,
          PendingNotification
        >,
      ),
      PendingNotification,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$PendingNotificationsTableTableManager get pendingNotifications =>
      $$PendingNotificationsTableTableManager(_db, _db.pendingNotifications);
}
