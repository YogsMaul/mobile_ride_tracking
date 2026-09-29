import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'config/app_environment.dart';
import 'core/app_lifecycle.dart';
import 'core/constants/api_constants.dart';
import 'features/auth/auth_state.dart';

void main() async {
  await bootstrapApp();
}

Future<void> bootstrapApp([AppEnvironmentConfig? environmentConfig]) async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  final flavor = appFlavor;
  final resolvedEnv =
      environmentConfig ?? AppEnvironmentConfig.fromFlavor(flavor);

  ApiConstants.environmentConfig = resolvedEnv;

  final container = ProviderContainer();
  final auth = container.read(authStateProvider);

  final lifecycle = AppLifecycleObserver(auth);
  WidgetsBinding.instance.addObserver(lifecycle);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: RideTrackingApp(lifecycle: lifecycle),
    ),
  );
}
