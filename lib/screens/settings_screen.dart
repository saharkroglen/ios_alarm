import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/reminder.dart' as model;
import '../providers/app_providers.dart';
import '../services/sound_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingSound = false;
  bool _isSendingTestNotification = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultSound = ref.watch(defaultSoundProvider);
    final defaultSnoozePresets = ref.watch(defaultSnoozePresetsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Notification Settings Section
          _buildSectionHeader(context, 'Notifications'),

          _buildPermissionsTile(context, ref),

          _buildTimeSensitiveInfoTile(context),

          ListTile(
            leading: const Icon(Icons.notification_add),
            title: const Text('Test Notification'),
            subtitle: const Text('Send a sample reminder notification'),
            trailing:
                _isSendingTestNotification
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.send),
            onTap: _isSendingTestNotification ? null : _sendTestNotification,
          ),

          const Divider(),

          // Default Settings Section
          _buildSectionHeader(context, 'Defaults'),

          ListTile(
            leading: const Icon(Icons.volume_up),
            title: const Text('Default Sound'),
            subtitle: Text(_getSoundDisplayName(defaultSound)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _isPlayingSound ? Icons.stop : Icons.play_arrow,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => _playSound(defaultSound),
                  tooltip: _isPlayingSound ? 'Stop' : 'Preview Sound',
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _showSoundPicker(context, ref, defaultSound),
          ),

          ListTile(
            leading: const Icon(Icons.snooze),
            title: const Text('Default Snooze Options'),
            subtitle: Text('${defaultSnoozePresets.length} options selected'),
            onTap:
                () => _showSnoozePresetsPicker(
                  context,
                  ref,
                  defaultSnoozePresets,
                ),
          ),

          const Divider(),

          // App Information Section
          _buildSectionHeader(context, 'About'),

          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),

          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            onTap: () => _showHelpDialog(context),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPermissionsTile(BuildContext context, WidgetRef ref) {
    final permissionsAsync = ref.watch(permissionStatusProvider);

    return permissionsAsync.when(
      data:
          (hasPermissions) => ListTile(
            leading: Icon(
              hasPermissions ? Icons.check_circle : Icons.error,
              color:
                  hasPermissions
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
            ),
            title: const Text('Notification Permissions'),
            subtitle: Text(
              hasPermissions ? 'Enabled' : 'Tap to enable notifications',
            ),
            onTap:
                hasPermissions ? null : () => _requestPermissions(context, ref),
          ),
      loading:
          () => const ListTile(
            leading: CircularProgressIndicator(),
            title: Text('Notification Permissions'),
            subtitle: Text('Checking...'),
          ),
      error:
          (_, __) => ListTile(
            leading: Icon(
              Icons.error,
              color: Theme.of(context).colorScheme.error,
            ),
            title: const Text('Notification Permissions'),
            subtitle: const Text('Error checking permissions'),
            onTap: () => _requestPermissions(context, ref),
          ),
    );
  }

  Widget _buildTimeSensitiveInfoTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.priority_high),
      title: const Text('Time Sensitive Notifications'),
      subtitle: const Text('Bypass Focus and Silent mode'),
      trailing: const Icon(Icons.info_outline),
      onTap: () => _showTimeSensitiveInfo(context),
    );
  }

  Future<void> _requestPermissions(BuildContext context, WidgetRef ref) async {
    final notificationService = ref.read(notificationServiceProvider);

    try {
      await notificationService.requestPermissions();
      ref.invalidate(permissionStatusProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error requesting permissions: $e')),
        );
      }
    }
  }

  void _showSoundPicker(
    BuildContext context,
    WidgetRef ref,
    String currentSound,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Default Sound'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  model.kAvailableSounds
                      .map(
                        (sound) => RadioListTile<String>(
                          title: Text(_getSoundDisplayName(sound)),
                          value: sound,
                          groupValue: currentSound,
                          secondary: IconButton(
                            icon: const Icon(Icons.play_arrow, size: 20),
                            onPressed: () => _playSound(sound),
                            tooltip: 'Preview',
                          ),
                          onChanged: (value) {
                            if (value != null) {
                              ref
                                  .read(defaultSoundProvider.notifier)
                                  .setDefaultSound(value);
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      )
                      .toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  void _showSnoozePresetsPicker(
    BuildContext context,
    WidgetRef ref,
    List<model.SnoozePreset> currentPresets,
  ) {
    final selectedPresets = Set<model.SnoozePreset>.from(currentPresets);

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Default Snooze Options'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        model.kDefaultSnoozePresets.map((preset) {
                          final isSelected = selectedPresets.contains(preset);
                          return CheckboxListTile(
                            title: Text(preset.toString()),
                            value: isSelected,
                            onChanged: (selected) {
                              setState(() {
                                if (selected == true) {
                                  selectedPresets.add(preset);
                                } else {
                                  selectedPresets.remove(preset);
                                }
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          );
                        }).toList(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed:
                          selectedPresets.isEmpty
                              ? null
                              : () {
                                ref
                                    .read(defaultSnoozePresetsProvider.notifier)
                                    .state = selectedPresets.toList();
                                Navigator.of(context).pop();
                              },
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showTimeSensitiveInfo(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Time Sensitive Notifications'),
            content: const Text(
              'Time Sensitive notifications can bypass Focus modes and Silent mode. '
              'They are designed for urgent reminders that you don\'t want to miss.\n\n'
              'You can enable this on a per-reminder basis when creating or editing reminders.\n\n'
              'Note: The user can disable Time Sensitive notifications in iOS Settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it'),
              ),
            ],
          ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Help & Support'),
            content: const Text(
              'iOS Alarm is a local-only reminder app with the following features:\n\n'
              '• Lock-screen notifications with sound\n'
              '• Quick snooze actions (5m, 1h, 3h, Tomorrow 9AM)\n'
              '• Custom snooze with date/time picker\n'
              '• Repeat options (daily, weekly, weekdays, custom)\n'
              '• Time Sensitive notifications\n'
              '• Custom sound selection\n\n'
              'All data is stored locally on your device. No cloud sync or accounts required.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
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

  Future<void> _sendTestNotification() async {
    setState(() => _isSendingTestNotification = true);

    try {
      final notificationService = ref.read(notificationServiceProvider);
      final defaultSound = ref.read(defaultSoundProvider);

      // Create a test reminder
      final testReminder = model.Reminder(
        id: 'test_notification_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Test Notification',
        notes:
            'This is a sample reminder notification with all available actions.',
        scheduledAt: DateTime.now().add(
          const Duration(seconds: 2),
        ), // Test notifications can keep seconds for immediate testing
        repeatRule: model.RepeatRule.none,
        timeSensitive: false,
        soundName: defaultSound,
        snoozePresets: model.kDefaultSnoozePresets,
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Schedule the test notification (without auto-snooze)
      await notificationService.scheduleReminder(
        testReminder,
        isTestNotification: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notification will appear in 2 seconds!'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending test notification: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingTestNotification = false);
      }
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
        return 'Stars';
      case 'bell_1.caf':
        return 'Mystery';
      default:
        return soundName;
    }
  }
}
