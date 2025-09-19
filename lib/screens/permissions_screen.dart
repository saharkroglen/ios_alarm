import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/app_providers.dart';
import '../services/preferences_service.dart';

class PermissionsScreen extends ConsumerWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),

              // Icon
              Icon(
                Icons.notifications_active,
                size: 80,
                color: theme.colorScheme.primary,
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'Enable Notifications',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                'iOS Alarm needs notification permissions to deliver reminders even when your device is locked.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Features list
              _FeatureItem(
                icon: Icons.lock_clock,
                title: 'Lock Screen Notifications',
                description: 'Get reminded even when your phone is locked',
              ),

              const SizedBox(height: 16),

              _FeatureItem(
                icon: Icons.volume_up,
                title: 'Sound Alerts',
                description:
                    'Choose from custom sounds to never miss a reminder',
              ),

              const SizedBox(height: 16),

              _FeatureItem(
                icon: Icons.snooze,
                title: 'Quick Actions',
                description: 'Snooze or mark done directly from notifications',
              ),

              const Spacer(),

              // Enable button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _requestPermissions(context, ref),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Enable Notifications',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Skip button
              TextButton(
                onPressed: () => _skipPermissions(context),
                child: Text(
                  'Skip for now',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestPermissions(BuildContext context, WidgetRef ref) async {
    final notificationService = ref.read(notificationServiceProvider);

    try {
      // Check if we've already been denied before
      final wasAlreadyDenied =
          PreferencesService.arePermissionsPermanentlyDenied();

      if (wasAlreadyDenied) {
        // If already denied, go directly to settings
        if (context.mounted) {
          _showOpenSettingsDialog(context);
        }
        return;
      }

      await notificationService.requestPermissions();

      // Refresh permission status
      ref.invalidate(permissionStatusProvider);

      // Check if permissions were granted
      final hasPermissions = await notificationService.arePermissionsGranted();

      if (hasPermissions && context.mounted) {
        // Reset the permanently denied flag if permissions are now granted
        await PreferencesService.setPermissionsPermanentlyDenied(false);
        context.go('/');
      } else if (context.mounted) {
        // Mark as permanently denied since the system dialog won't show again
        await PreferencesService.setPermissionsPermanentlyDenied(true);
        _showOpenSettingsDialog(context);
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, e.toString());
      }
    }
  }

  void _skipPermissions(BuildContext context) {
    context.go('/');
  }

  void _showOpenSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Open Settings'),
            content: const Text(
              'To enable notifications, please go to Settings > Notifications > AlertFlow SK Pro and turn on "Allow Notifications".',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/');
                },
                child: const Text('Skip'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _openAppSettings();
                  if (context.mounted) {
                    context.go('/');
                  }
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
    );
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

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to request permissions: $error'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.onPrimaryContainer,
            size: 24,
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
