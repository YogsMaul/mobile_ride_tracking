import 'package:flutter/material.dart';

import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/history/history_screen.dart';
import '../features/history/ride_detail_screen.dart';
import '../features/history/ride_history_item.dart';
import '../features/profile/profile_screen.dart';
import '../features/ride/home/home_screen.dart';
import '../features/ride/home/scan_qr_screen.dart';
import '../features/ride/ride_map/ride_map_screen.dart';
import '../core/widgets/shell_scaffold.dart';

class AppRoutes {
  AppRoutes._();

  static const String initial = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String scanQr = '/scan-qr';
  static const String ride = '/ride';
  static const String rideDetail = '/ride-detail';

  static Map<String, WidgetBuilder> get routes => {
        login: (context) => const LoginScreen(),
        register: (context) => const RegisterScreen(),
        forgotPassword: (context) => const ForgotPasswordScreen(),
        home: (context) => const AppShell(),
        scanQr: (context) => const ScanQrScreen(),
        rideDetail: (context) {
          final item = ModalRoute.of(context)!.settings.arguments as RideHistoryItem;
          return RideDetailScreen(item: item);
        },
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
