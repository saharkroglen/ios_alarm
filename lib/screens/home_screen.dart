import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/reminder.dart' as model;
import '../providers/app_providers.dart';
import '../services/scheduling_service.dart';
import '../services/preferences_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize notification service
    ref.watch(appInitProvider);

    final remindersAsync = ref.watch(reminderNotifierProvider);
    final groupedReminders = ref.watch(groupedRemindersProvider);
    final permissionStatus = ref.watch(permissionStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Permission alert banner
          permissionStatus.when(
            data: (hasPermissions) {
              if (!hasPermissions &&
                  !PreferencesService.hasPermissionsDismissed()) {
                return _buildPermissionBanner(context, ref);
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Main content
          Expanded(
            child: remindersAsync.when(
              data: (reminders) {
                if (reminders.isEmpty) {
                  return _buildEmptyState(context);
                }
                return _buildRemindersList(context, ref, groupedReminders);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading reminders',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed:
                              () => ref.refresh(reminderNotifierProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPermissionBanner(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPermanentlyDenied =
        PreferencesService.arePermissionsPermanentlyDenied();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_off,
                color: theme.colorScheme.onErrorContainer,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Notifications Disabled',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _dismissPermissionBanner(ref),
                icon: Icon(
                  Icons.close,
                  color: theme.colorScheme.onErrorContainer,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isPermanentlyDenied
                ? 'Your reminders won\'t work without notification permissions. Go to Settings to enable them.'
                : 'Your reminders won\'t work without notification permissions. Enable them to receive alerts.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed:
                    isPermanentlyDenied
                        ? () => _openAppSettings()
                        : () => _requestPermissions(context, ref),
                icon: Icon(
                  isPermanentlyDenied ? Icons.settings : Icons.notifications,
                  size: 16,
                ),
                label: Text(
                  isPermanentlyDenied
                      ? 'Open Settings'
                      : 'Enable Notifications',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => context.push('/permissions'),
                child: Text(
                  'Learn More',
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermissions(BuildContext context, WidgetRef ref) async {
    final notificationService = ref.read(notificationServiceProvider);

    try {
      await notificationService.requestPermissions();
      // Refresh permission status
      ref.invalidate(permissionStatusProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting permissions: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _dismissPermissionBanner(WidgetRef ref) async {
    await PreferencesService.setPermissionsDismissed(true);
    // Force a rebuild to hide the banner
    ref.invalidate(permissionStatusProvider);
  }

  Future<void> _openAppSettings() async {
    const url = 'app-settings:';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      // Fallback to general settings
      const settingsUrl = 'App-Prefs:';
      if (await canLaunchUrl(Uri.parse(settingsUrl))) {
        await launchUrl(Uri.parse(settingsUrl));
      }
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 80, color: theme.colorScheme.outline),

            const SizedBox(height: 24),

            Text(
              'No Reminders Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Tap the + button to create your first reminder',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersList(
    BuildContext context,
    WidgetRef ref,
    Map<String, List<model.Reminder>> groupedReminders,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh reminders list
        ref.read(reminderNotifierProvider.notifier);
      },
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          for (final entry in groupedReminders.entries) ...[
            _buildSectionHeader(context, entry.key),
            const SizedBox(height: 8),
            ...entry.value.map(
              (reminder) => _buildReminderCard(context, ref, reminder),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildReminderCard(
    BuildContext context,
    WidgetRef ref,
    model.Reminder reminder,
  ) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () => context.push('/edit/${reminder.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        if (reminder.notes?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            reminder.notes!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.7,
                              ),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (reminder.timeSensitive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Time Sensitive',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateFormat.format(reminder.scheduledAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),

                  const Spacer(),

                  if (reminder.hasRepeat) ...[
                    Icon(
                      Icons.repeat,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      SchedulingService.getRepeatDescription(
                        reminder.repeatRule,
                        reminder.repeatWeekdays,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  // Quick snooze button
                  TextButton.icon(
                    onPressed:
                        () => _showQuickSnoozeSheet(context, ref, reminder),
                    icon: const Icon(Icons.snooze, size: 16),
                    label: const Text('Snooze'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Mark done button
                  TextButton.icon(
                    onPressed: () => _markDone(ref, reminder.id),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Done'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),

                  const Spacer(),

                  // Delete button
                  IconButton(
                    onPressed: () => _confirmDelete(context, ref, reminder),
                    icon: const Icon(Icons.delete_outline),
                    iconSize: 20,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickSnoozeSheet(
    BuildContext context,
    WidgetRef ref,
    model.Reminder reminder,
  ) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => _QuickSnoozeSheet(
            reminder: reminder,
            onSnooze: (minutes) {
              Navigator.of(context).pop();
              ref
                  .read(reminderNotifierProvider.notifier)
                  .snoozeReminder(reminder.id, minutes);
            },
            onCustomSnooze: () {
              Navigator.of(context).pop();
              context.push('/snooze?rid=${reminder.id}');
            },
          ),
    );
  }

  void _markDone(WidgetRef ref, String reminderId) {
    ref
        .read(reminderNotifierProvider.notifier)
        .markReminderCompleted(reminderId);
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    model.Reminder reminder,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Reminder'),
            content: Text(
              'Are you sure you want to delete "${reminder.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref
                      .read(reminderNotifierProvider.notifier)
                      .deleteReminder(reminder.id);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}

class _QuickSnoozeSheet extends StatelessWidget {
  const _QuickSnoozeSheet({
    required this.reminder,
    required this.onSnooze,
    required this.onCustomSnooze,
  });

  final model.Reminder reminder;
  final Function(int minutes) onSnooze;
  final VoidCallback onCustomSnooze;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Snooze Reminder',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            reminder.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),

          const SizedBox(height: 24),

          // Quick snooze options
          _SnoozeOption(title: '5 minutes', onTap: () => onSnooze(5)),

          _SnoozeOption(title: '1 hour', onTap: () => onSnooze(60)),

          _SnoozeOption(title: '3 hours', onTap: () => onSnooze(180)),

          _SnoozeOption(
            title: 'Tomorrow 9:00 AM',
            onTap: () {
              final now = DateTime.now();
              final tomorrow9 = DateTime(
                now.year,
                now.month,
                now.day + 1,
                9,
                0,
              );
              final minutes = tomorrow9.difference(now).inMinutes;
              onSnooze(minutes);
            },
          ),

          const Divider(),

          _SnoozeOption(
            title: 'Custom...',
            icon: Icons.edit_calendar,
            onTap: onCustomSnooze,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SnoozeOption extends StatelessWidget {
  const _SnoozeOption({
    required this.title,
    required this.onTap,
    this.icon = Icons.snooze,
  });

  final String title;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
