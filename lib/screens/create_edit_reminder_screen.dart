import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/reminder.dart' as model;
import '../providers/app_providers.dart';
import '../services/sound_service.dart';

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

class CreateEditReminderScreen extends ConsumerStatefulWidget {
  const CreateEditReminderScreen({super.key, this.reminderId});

  final String? reminderId;

  @override
  ConsumerState<CreateEditReminderScreen> createState() =>
      _CreateEditReminderScreenState();
}

class _CreateEditReminderScreenState
    extends ConsumerState<CreateEditReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _scheduledAt = DateTime.now();
  model.RepeatRule _repeatRule = model.RepeatRule.none;
  Set<int> _customWeekdays = {};
  bool _timeSensitive = false;
  String _soundName = model.kDefaultSound; // Will be updated in initState
  List<model.SnoozePreset> _snoozePresets = List.from(
    model.kDefaultSnoozePresets,
  );

  bool _isLoading = false;
  bool _isEditing = false;
  model.Reminder? _originalReminder;

  // Sound preview
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingSound = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.reminderId != null;
    if (_isEditing) {
      _loadReminder();
    } else {
      // For new reminders, use the user's selected default sound
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final defaultSound = ref.read(defaultSoundProvider);
        setState(() {
          _soundName = defaultSound;
        });
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadReminder() async {
    setState(() => _isLoading = true);

    try {
      final reminder = await ref
          .read(reminderNotifierProvider.notifier)
          .getReminderById(widget.reminderId!);

      if (reminder != null) {
        _originalReminder = reminder;
        _titleController.text = reminder.title;
        _notesController.text = reminder.notes ?? '';
        // Ensure scheduled time is not in the past for date picker
        _scheduledAt =
            reminder.scheduledAt.isBefore(DateTime.now())
                ? DateTime.now().add(const Duration(minutes: 1))
                : reminder.scheduledAt;
        _repeatRule = reminder.repeatRule;
        _customWeekdays = reminder.repeatWeekdays;
        _timeSensitive = reminder.timeSensitive;
        _soundName = reminder.soundName;
        _snoozePresets = List.from(reminder.snoozePresets);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading reminder: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Reminder' : 'New Reminder'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(onPressed: _saveReminder, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Title field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              maxLength: 120,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Notes field
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Date and time picker
            _buildDateTimePicker(),

            const SizedBox(height: 24),

            // Repeat options
            _buildRepeatOptions(),

            const SizedBox(height: 24),

            // Sound picker
            _buildSoundPicker(),

            const SizedBox(height: 24),

            // Time sensitive toggle
            _buildTimeSensitiveToggle(),

            const SizedBox(height: 24),

            // Snooze presets
            _buildSnoozePresets(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimePicker() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date & Time',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                initialDateTime:
                    _scheduledAt.isBefore(DateTime.now())
                        ? DateTime.now().add(const Duration(minutes: 1))
                        : _scheduledAt,
                onDateTimeChanged: (DateTime newDateTime) {
                  setState(() => _scheduledAt = newDateTime);
                },
                use24hFormat: false,
                minimumDate: DateTime.now(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepeatOptions() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Repeat',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            ...model.RepeatRule.values.map(
              (rule) => RadioListTile<model.RepeatRule>(
                title: Text(_getRepeatRuleDisplayName(rule)),
                value: rule,
                groupValue: _repeatRule,
                onChanged: (value) {
                  setState(() {
                    _repeatRule = value!;
                    if (value == model.RepeatRule.weekdays) {
                      _customWeekdays = {1, 2, 3, 4, 5}; // Mon-Fri
                    } else if (value != model.RepeatRule.custom) {
                      _customWeekdays = {};
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),

            if (_repeatRule == model.RepeatRule.custom) ...[
              const SizedBox(height: 16),
              Text('Select Days', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              _buildWeekdaySelector(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdaySelector() {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Wrap(
      spacing: 8,
      children: List.generate(7, (index) {
        final weekday = index + 1;
        final isSelected = _customWeekdays.contains(weekday);

        return FilterChip(
          label: Text(weekdays[index]),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _customWeekdays.add(weekday);
              } else {
                _customWeekdays.remove(weekday);
              }
            });
          },
        );
      }),
    );
  }

  Widget _buildSoundPicker() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sound',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            ...model.kAvailableSounds.map(
              (sound) => RadioListTile<String>(
                title: Text(_getSoundDisplayName(sound)),
                value: sound,
                groupValue: _soundName,
                secondary: IconButton(
                  icon: Icon(
                    _isPlayingSound ? Icons.stop : Icons.play_arrow,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  onPressed: () => _playSound(sound),
                  tooltip: _isPlayingSound ? 'Stop' : 'Preview',
                ),
                onChanged: (value) {
                  setState(() => _soundName = value!);
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSensitiveToggle() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time Sensitive',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bypass Focus and Silent mode',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _timeSensitive,
              onChanged: (value) {
                setState(() => _timeSensitive = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnoozePresets() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Snooze Options',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Choose which snooze options appear in notifications',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),

            const SizedBox(height: 16),

            ...model.kDefaultSnoozePresets.map((preset) {
              final isSelected = _snoozePresets.contains(preset);
              return CheckboxListTile(
                title: Text(preset.toString()),
                value: isSelected,
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      if (!_snoozePresets.contains(preset)) {
                        _snoozePresets.add(preset);
                      }
                    } else {
                      _snoozePresets.remove(preset);
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getRepeatRuleDisplayName(model.RepeatRule rule) {
    switch (rule) {
      case model.RepeatRule.none:
        return 'Never';
      case model.RepeatRule.daily:
        return 'Every Day';
      case model.RepeatRule.weekly:
        return 'Every Week';
      case model.RepeatRule.weekdays:
        return 'Weekdays (Mon-Fri)';
      case model.RepeatRule.custom:
        return 'Custom';
    }
  }

  String _getSoundDisplayName(String soundName) {
    switch (soundName) {
      case 'system_default':
        return 'System Default';
      case 'stars.caf':
        return 'Stars';
      case 'summer.caf':
        return 'Summer';
      case 'mistery.caf':
        return 'Mystery';
      // Legacy support
      case 'alarm_1.caf':
        return 'Summer'; // Redirect to new name
      case 'chime_1.caf':
      case 'chime_1.aiff':
        return 'Stars';
      case 'bell_1.caf':
        return 'Mystery';
      default:
        return soundName;
    }
  }

  Future<void> _playSound(String soundName) async {
    if (_isPlayingSound) {
      setState(() => _isPlayingSound = false);
      return;
    }

    try {
      setState(() => _isPlayingSound = true);

      // Try to play the custom sound from iOS bundle first
      final soundPlayed = await SoundService.playSound(soundName);

      if (!soundPlayed) {
        // Fallback to system sounds
        SystemSoundType soundType;
        switch (soundName) {
          case 'system_default':
            soundType = SystemSoundType.alert; // Default notification sound
            break;
          case 'stars.caf':
            soundType = SystemSoundType.click;
            break;
          case 'summer.caf':
            soundType = SystemSoundType.alert;
            break;
          case 'mistery.caf':
            soundType = SystemSoundType.alert;
            break;
          // Legacy support
          case 'alarm_1.caf':
            soundType = SystemSoundType.alert;
            break;
          case 'chime_1.caf':
            soundType = SystemSoundType.click;
            break;
          case 'bell_1.caf':
            soundType = SystemSoundType.alert;
            break;
          default:
            soundType = SystemSoundType.alert;
        }

        await SystemSound.play(soundType);
      }

      // Show feedback message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playing ${_getSoundDisplayName(soundName)}'),
            duration: const Duration(milliseconds: 800),
          ),
        );
      }

      // Reset state after a short delay
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() => _isPlayingSound = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPlayingSound = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not play sound: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_repeatRule == model.RepeatRule.custom && _customWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day for custom repeat'),
        ),
      );
      return;
    }

    if (_snoozePresets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one snooze option'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final reminder = model.Reminder(
        id: _isEditing ? _originalReminder!.id : const Uuid().v4(),
        title: _titleController.text.trim(),
        notes:
            _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
        scheduledAt: roundToMinute(_scheduledAt),
        repeatRule: _repeatRule,
        repeatDaysMask:
            _customWeekdays.isNotEmpty
                ? _customWeekdays.fold<int>(
                  0,
                  (mask, day) => mask | (1 << (day - 1)),
                )
                : null,
        timeSensitive: _timeSensitive,
        soundName: _soundName,
        snoozePresets: _snoozePresets,
        isCompleted: false,
        createdAt: _isEditing ? _originalReminder!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing) {
        await ref
            .read(reminderNotifierProvider.notifier)
            .updateReminder(reminder);
      } else {
        await ref
            .read(reminderNotifierProvider.notifier)
            .createReminder(reminder);
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving reminder: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
