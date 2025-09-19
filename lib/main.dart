import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'providers/app_providers.dart';
import 'screens/home_screen.dart';
import 'screens/create_edit_reminder_screen.dart';
import 'screens/custom_snooze_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/permissions_screen.dart';
import 'screens/reminder_action_dialog.dart';
import 'services/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone data
  tz.initializeTimeZones();

  runApp(const ProviderScope(child: IOSAlarmApp()));
}

class IOSAlarmApp extends ConsumerWidget {
  const IOSAlarmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = _createRouter(ref);

    return MaterialApp.router(
      title: 'iOS Alarm',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class NotificationListener extends ConsumerWidget {
  const NotificationListener({super.key, required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for notification tap actions
    ref.listen<Map<String, dynamic>?>(currentReminderActionProvider, (
      previous,
      next,
    ) {
      if (next != null) {
        // Navigate to home screen to show the highlighted reminder
        context.go('/');

        // Show the action dialog after a brief delay to allow navigation
        Future.delayed(const Duration(milliseconds: 100), () {
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder:
                  (context) => ReminderActionDialog(
                    reminderId: next['reminderId'] as String,
                    isAutoSnooze: next['isAutoSnooze'] as bool? ?? false,
                    snoozeCount: next['snoozeCount'] as int? ?? 0,
                  ),
            ).then((_) {
              // Clear the action state after dialog closes
              ref.read(currentReminderActionProvider.notifier).state = null;
            });
          }
        });
      }
    });

    return child ?? const SizedBox.shrink();
  }
}

extension on IOSAlarmApp {
  GoRouter _createRouter(WidgetRef ref) {
    return GoRouter(
      initialLocation: '/',
      routes: [
        // Special route for notification dialog
        GoRoute(
          path: '/notification-action',
          name: 'notification-action',
          builder: (context, state) {
            final reminderId = state.uri.queryParameters['reminderId'];
            final isAutoSnooze =
                state.uri.queryParameters['isAutoSnooze'] == 'true';
            final snoozeCount =
                int.tryParse(state.uri.queryParameters['snoozeCount'] ?? '0') ??
                0;

            if (reminderId == null) {
              return NotificationListener(child: const HomeScreen());
            }

            return NotificationListener(
              child: ReminderActionDialog(
                reminderId: reminderId,
                isAutoSnooze: isAutoSnooze,
                snoozeCount: snoozeCount,
              ),
            );
          },
        ),
        GoRoute(
          path: '/',
          name: 'home',
          builder:
              (context, state) =>
                  NotificationListener(child: const HomeScreen()),
        ),
        GoRoute(
          path: '/permissions',
          name: 'permissions',
          builder:
              (context, state) =>
                  NotificationListener(child: const PermissionsScreen()),
        ),
        GoRoute(
          path: '/create',
          name: 'create',
          builder:
              (context, state) =>
                  NotificationListener(child: const CreateEditReminderScreen()),
        ),
        GoRoute(
          path: '/edit/:id',
          name: 'edit',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return NotificationListener(
              child: CreateEditReminderScreen(reminderId: id),
            );
          },
        ),
        GoRoute(
          path: '/snooze',
          name: 'custom_snooze',
          builder: (context, state) {
            final reminderId = state.uri.queryParameters['rid'];
            if (reminderId == null) {
              return NotificationListener(child: const HomeScreen());
            }
            return NotificationListener(
              child: CustomSnoozeScreen(reminderId: reminderId),
            );
          },
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder:
              (context, state) =>
                  NotificationListener(child: const SettingsScreen()),
        ),
      ],
      redirect: (context, state) async {
        // Initialize preferences service
        await PreferencesService.init();

        // Check if this is the first time and we need to prompt for permissions
        final hasPrompted = PreferencesService.hasPromptedForPermissions();

        // If we haven't prompted before and we're not already on the permissions screen
        if (!hasPrompted && state.uri.path != '/permissions') {
          // Mark as prompted to avoid loops
          await PreferencesService.setHasPromptedForPermissions(true);
          return '/permissions';
        }

        return null;
      },
    );
  }
}
