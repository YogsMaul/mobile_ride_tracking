import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_lifecycle.dart';
import 'core/network/dio_provider.dart';
import 'core/network/repository/auth_repository.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_toast.dart';
import 'features/auth/auth_state.dart';
import 'features/auth/idle_session_modal.dart';
import 'features/auth/login_screen.dart';
import 'routes/app_routes.dart';

/// Global navigator — dipakai buat akses context dari luar widget tree
/// (mis. callback onAuthError dari Dio interceptor).
final navigatorKey = GlobalKey<NavigatorState>();

class RideTrackingApp extends ConsumerStatefulWidget {
  const RideTrackingApp({super.key, required this.lifecycle});
  final AppLifecycleObserver lifecycle;

  @override
  ConsumerState<RideTrackingApp> createState() => _RideTrackingAppState();
}

class _RideTrackingAppState extends ConsumerState<RideTrackingApp> {
  @override
  void initState() {
    super.initState();
    final dio = ref.read(dioClientProvider);
    final auth = ref.read(authStateProvider);
    dio.onAuthExpired = auth.onLogout;
    dio.onAuthError = (message) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) AppToast.error(ctx, message);
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ride Tracking',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      navigatorKey: navigatorKey,
      initialRoute: AppRoutes.initial,
      routes: AppRoutes.routes,
      home: const _AuthGate(),
    );
  }
}

/// Wrapper yang merender halaman sesuai status auth. Sub-page (`/ride`,
/// `/register`) tetap pakai Navigator pushNamed biasa, push di atas
/// halaman aktif.
///
/// `ref.listen` di `build()` adalah cara idiomatic Riverpod untuk
/// `ChangeNotifierProvider` — Riverpod attach/detach listener ke
/// ChangeNotifier otomatis terhadap lifecycle widget ini. Karena
/// `AuthGate` tidak pernah ke-dispose (dia root dari `MaterialApp.home`),
/// listener tetap hidup selama aplikasi.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    debugPrint('[AuthGate] build status=${auth.status}');

    ref.listen<AuthState>(authStateProvider, (_, next) {
      if (next.status == AuthStatus.idleWarning && !auth.idleModalOpen) {
        auth.markIdleModalOpen();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => IdleSessionModal(
            repo: ref.read(authRepositoryProvider),
            auth: next,
          ),
        ).then((_) => auth.markIdleModalClosed());
      }
      // Tiap sesi login baru = fetch ulang /auth/me. FutureProvider
      // nge-cache hasil — tanpa ini, profil basi / null dari boot
      // sebelumnya nyangkut setelah login/re-login.
      if (next.status == AuthStatus.loggedIn) {
        ref.invalidate(userProfileProvider);
      }
    });

    switch (auth.status) {
      case AuthStatus.loggedIn:
        return const AppShell();
      case AuthStatus.loggedOut:
      case AuthStatus.idleWarning:
        return const LoginScreen();
    }
  }
}
