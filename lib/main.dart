import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/app_lifecycle.dart';
import 'features/auth/auth_state.dart';

void main() async {
  // Pastikan plugin (flutter_secure_storage) siap sebelum runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Container sementara untuk bootstrap auth — butuh ref untuk baca provider
  // tapi belum ada ProviderScope. Trik: bikin container sekali, ambil instance,
  // baru bungkus dengan ProviderScope.
  final container = ProviderContainer();
  final auth = container.read(authStateProvider);
  await auth.bootstrap();

  final lifecycle = AppLifecycleObserver(auth);
  WidgetsBinding.instance.addObserver(lifecycle);

  runApp(UncontrolledProviderScope(
    container: container,
    child: RideTrackingApp(lifecycle: lifecycle),
  ));
}
