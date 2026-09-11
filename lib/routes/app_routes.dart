import 'package:flutter/material.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/history/history_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/ride/home/home_screen.dart';
import '../features/ride/ride_map/ride_map_screen.dart';
import '../core/widgets/shell_scaffold.dart';

class AppRoutes {
  AppRoutes._();

  static const String initial = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String ride = '/ride';

  static Map<String, WidgetBuilder> get routes => {
        login: (context) => const LoginScreen(),
        register: (context) => const RegisterScreen(),
        home: (context) => const AppShell(),
        ride: (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return RideMapScreen(
            rideId: args['rideId'] as String,
            inviteCode: args['inviteCode'] as String?,
            rideName: args['rideName'] as String?,
          );
        },
      };
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShellScaffold(
      pages: [
        HomeScreen(),
        HistoryScreen(),
        ProfileScreen(),
      ],
    );
  }
}
