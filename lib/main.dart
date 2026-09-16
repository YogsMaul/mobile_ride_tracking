import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/app_lifecycle.dart';
import 'features/auth/auth_state.dart';

void main() async {
  // Pastikan plugin (flutter_secure_storage) siap sebelum runApp.
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Bootstrap auth TIDAK di-await di sini — cukup baca instance singletonnya.
  // SplashScreen yang menjalankan auth.bootstrap() paralel dengan animasi
  // minimal-tampil, biar native splash -> Flutter splash zero-wait.
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
