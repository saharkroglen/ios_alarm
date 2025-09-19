import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';

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

class CustomSnoozeScreen extends ConsumerStatefulWidget {
  const CustomSnoozeScreen({super.key, required this.reminderId});

  final String reminderId;

  @override
  ConsumerState<CustomSnoozeScreen> createState() => _CustomSnoozeScreenState();
}

class _CustomSnoozeScreenState extends ConsumerState<CustomSnoozeScreen> {
  int _selectedMinutes = 15;
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
  int _selectedTab = 0; // 0: Quick, 1: Hours, 2: Date/Time

  final List<int> _quickMinutes = [5, 10, 15, 30, 60, 120];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Snooze'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(onPressed: _saveSnooze, child: const Text('Save')),
        ],
      ),
      body: Column(
        children: [
          // Tab selector
          _buildTabSelector(),

          // Content based on selected tab
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTabButton('Quick', 0),
          _buildTabButton('Hours', 1),
          _buildTabButton('Date & Time', 2),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTab == index;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color:
                  isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildQuickMinutes();
      case 1:
        return _buildHoursPicker();
      case 2:
        return _buildDateTimePicker();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildQuickMinutes() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Options',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _quickMinutes.length,
              itemBuilder: (context, index) {
                final minutes = _quickMinutes[index];
                final isSelected =
                    _selectedTab == 0 && _selectedMinutes == minutes;

                return _buildQuickOption(minutes, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickOption(int minutes, bool isSelected) {
    final theme = Theme.of(context);
    String label;

    if (minutes < 60) {
      label = '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      label = '${hours}h';
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = 0;
          _selectedMinutes = minutes;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color:
              isSelected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border:
              isSelected
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : null,
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color:
                  isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHoursPicker() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Hours',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: CupertinoPicker(
              itemExtent: 50,
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedTab = 1;
                  _selectedMinutes = (index + 1) * 60; // 1 to 24 hours
                });
              },
              children: List.generate(24, (index) {
                final hours = index + 1;
                return Center(
                  child: Text(
                    '$hours hour${hours == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 18),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Date & Time',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: CupertinoDatePicker(
              initialDateTime: _selectedDateTime,
              onDateTimeChanged: (DateTime newDateTime) {
                setState(() {
                  _selectedTab = 2;
                  _selectedDateTime = newDateTime;
                });
              },
              use24hFormat: false,
              minimumDate: DateTime.now(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSnooze() async {
    try {
      final reminderNotifier = ref.read(reminderNotifierProvider.notifier);

      if (_selectedTab == 0 || _selectedTab == 1) {
        // Snooze by minutes
        await reminderNotifier.snoozeReminder(
          widget.reminderId,
          _selectedMinutes,
        );
      } else {
        // Snooze until specific date/time (rounded to nearest minute)
        await reminderNotifier.snoozeReminderUntil(
          widget.reminderId,
          roundToMinute(_selectedDateTime),
        );
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reminder snoozed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error snoozing reminder: $e')));
      }
    }
  }
}
