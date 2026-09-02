import 'package:flutter/material.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/ride/presentation/home_screen.dart';
import 'features/ride/presentation/ride_map_screen.dart';
import 'features/history/presentation/history_screen.dart';

class RideTrackingApp extends StatelessWidget {
  const RideTrackingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ride Tracking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/history': (context) => const HistoryScreen(),
        '/ride': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return RideMapScreen(
            rideId: args['rideId'] as String,
            inviteCode: args['inviteCode'] as String?,
          );
        },
      },
    );
  }
}
