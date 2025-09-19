import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/reminder.dart' as model;
import '../providers/app_providers.dart';

class ReminderActionDialog extends ConsumerStatefulWidget {
  const ReminderActionDialog({
    super.key,
    required this.reminderId,
    this.isAutoSnooze = false,
    this.snoozeCount = 0,
  });

  final String reminderId;
  final bool isAutoSnooze;
  final int snoozeCount;

  @override
  ConsumerState<ReminderActionDialog> createState() =>
      _ReminderActionDialogState();
}

class _ReminderActionDialogState extends ConsumerState<ReminderActionDialog> {
  model.Reminder? _reminder;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminder();
  }

  Future<void> _loadReminder() async {
    try {
      final reminder = await ref
          .read(reminderNotifierProvider.notifier)
          .getReminderById(widget.reminderId);
      if (mounted) {
        setState(() {
          _reminder = reminder;
          _isLoading = false;
        });
      }
    } catch (e) {
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

    if (_reminder == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Reminder not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    widget.isAutoSnooze ? Icons.repeat : Icons.notifications,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.isAutoSnooze) ...[
                          Text(
                            'Auto-snoozed #${widget.snoozeCount}',
                            style: Theme.of(
                              context,
                            ).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          _reminder!.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (_reminder!.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _reminder!.notes!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Action buttons
              Text(
                'What would you like to do?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              // Snooze options
              _ActionButton(
                icon: Icons.snooze,
                label: 'Snooze 5 minutes',
                onPressed: () => _handleSnooze(5),
              ),
              const SizedBox(height: 8),
              _ActionButton(
                icon: Icons.access_time,
                label: 'Snooze 1 hour',
                onPressed: () => _handleSnooze(60),
              ),
              const SizedBox(height: 8),
              _ActionButton(
                icon: Icons.schedule,
                label: 'Snooze 3 hours',
                onPressed: () => _handleSnooze(180),
              ),
              const SizedBox(height: 8),
              _ActionButton(
                icon: Icons.wb_sunny,
                label: 'Tomorrow at 9:00 AM',
                onPressed: () => _handleTomorrowSnooze(),
              ),
              const SizedBox(height: 8),
              _ActionButton(
                icon: Icons.more_time,
                label: 'Custom snooze...',
                onPressed: () => _handleCustomSnooze(),
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Mark done button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _handleMarkDone,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Mark as Done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Cancel button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSnooze(int minutes) async {
    try {
      await ref
          .read(reminderNotifierProvider.notifier)
          .snoozeReminder(widget.reminderId, minutes);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Snoozed for $minutes minute${minutes == 1 ? '' : 's'}',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error snoozing reminder: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleTomorrowSnooze() async {
    final now = DateTime.now();
    final tomorrow9 = DateTime(now.year, now.month, now.day + 1, 9, 0);
    final minutes = tomorrow9.difference(now).inMinutes;
    await _handleSnooze(minutes);
  }

  Future<void> _handleCustomSnooze() async {
    context.pop();
    // Navigate to custom snooze screen
    context.push('/custom-snooze/${widget.reminderId}');
  }

  Future<void> _handleMarkDone() async {
    try {
      await ref
          .read(reminderNotifierProvider.notifier)
          .markReminderCompleted(widget.reminderId);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminder marked as done!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking reminder as done: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
