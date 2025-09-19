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
      builder: (context, child) => NotificationListener(child: child),
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
        // Show the action dialog
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

    return child ?? const SizedBox.shrink();
  }
}

extension on IOSAlarmApp {
  GoRouter _createRouter(WidgetRef ref) {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/permissions',
          name: 'permissions',
          builder: (context, state) => const PermissionsScreen(),
        ),
        GoRoute(
          path: '/create',
          name: 'create',
          builder: (context, state) => const CreateEditReminderScreen(),
        ),
        GoRoute(
          path: '/edit/:id',
          name: 'edit',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return CreateEditReminderScreen(reminderId: id);
          },
        ),
        GoRoute(
          path: '/snooze',
          name: 'custom_snooze',
          builder: (context, state) {
            final reminderId = state.uri.queryParameters['rid'];
            if (reminderId == null) {
              return const HomeScreen();
            }
            return CustomSnoozeScreen(reminderId: reminderId);
          },
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
      redirect: (context, state) async {
        // For now, skip permission redirect to test the app
        return null;
      },
    );
  }
}
