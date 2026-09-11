import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../core/error/app_exception.dart';
import '../../core/network/repository/auth_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import './auth_state.dart';


class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscure = true;
  bool _success = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = scaffoldMessengerKey.currentState ??
        ScaffoldMessenger.of(context);

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _success = true);
      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Login berhasil.')),
            ],
          ),
          duration: Duration(milliseconds: 1200),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 1200));
      ref.read(authStateProvider).onLoginSuccess();
    } on AppException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(e.message)),
            ],
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text('Terjadi kesalahan: $e')),
            ],
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keyboard di-handle manual (resizeToAvoidBottomInset false): bg
    // image gak pernah terdorong/resize. Card naik via AnimatedPadding
    // yang ngikutin viewInsets — di Android inset berubah per-frame
    // selama keyboard muncul, di iOS lompat sekali lalu animasi
    // inter polasi. Hasilnya card "naik" mulus, background tetap diam.
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4EC),
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/backgroud_login.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.xl),
                        // Brand header di area kosong atas.
                        Column(
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                color: AppColors.brand,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.brand
                                        .withValues(alpha: 0.28),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.route,
                                  color: Colors.white, size: 42),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'Ride Tracking',
                              style:
                                  Theme.of(context).textTheme.displaySmall,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Pantau perjalanan konvoi\nsecara real-time.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.muted),
                            ),
                          ],
                        ),
                        // Scene rider pegunungan di antara header & card.
                        const Spacer(),
                        AnimatedPadding(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.only(
                            left: AppSpacing.lg,
                            right: AppSpacing.lg,
                            bottom: viewInsets.bottom,
                          ),
                          child: ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxWidth: 420),
                            child: Card(
                              elevation: 8,
                              shadowColor:
                                  Colors.black.withValues(alpha: 0.12),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.xl),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Masuk ke akun',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Lanjutkan perjalanan bersama komunitas.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppColors.muted,
                                            ),
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      TextFormField(
                                        controller: _emailController,
                                        decoration: const InputDecoration(
                                          labelText: 'Email',
                                          hintText: 'nama@email.com',
                                          prefixIcon: Icon(
                                              Icons.alternate_email,
                                              color: AppColors.muted,
                                              size: 20),
                                        ),
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction:
                                            TextInputAction.next,
                                        autofillHints: const [
                                          AutofillHints.email
                                        ],
                                        validator: AppValidators.email,
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: _obscure,
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [
                                          AutofillHints.password
                                        ],
                                        onFieldSubmitted: (_) =>
                                            _isLoading ? null : _login(),
                                        decoration: InputDecoration(
                                          labelText: 'Password',
                                          hintText: 'Masukkan password',
                                          prefixIcon: const Icon(
                                              Icons.lock_outline,
                                              color: AppColors.muted,
                                              size: 20),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscure
                                                  ? Icons
                                                      .visibility_outlined
                                                  : Icons
                                                      .visibility_off_outlined,
                                              color: AppColors.muted,
                                              size: 20,
                                            ),
                                            onPressed: () => setState(
                                                () => _obscure = !_obscure),
                                          ),
                                        ),
                                        validator: (v) => AppValidators.requiredField(v, 'Password'),
                                      ),
                                      const SizedBox(
                                          height: AppSpacing.xl),
                                      FilledButton(
                                        onPressed: (_isLoading || _success)
                                            ? null
                                            : _login,
                                        style: FilledButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppRadius.lg,
                                            ),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.4,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : _success
                                                ? const Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(Icons.check,
                                                          color: Colors.white,
                                                          size: 18),
                                                      SizedBox(width: 8),
                                                      Text('Berhasil'),
                                                    ],
                                                  )
                                                : const Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text('Masuk'),
                                                      Icon(Icons.arrow_forward,
                                                          color: Colors.white,
                                                          size: 20),
                                                    ],
                                                  ),
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      // Divider "atau"
                                      Row(
                                        children: [
                                          const Expanded(
                                            child: Divider(),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal:
                                                    AppSpacing.md),
                                            child: Text(
                                              'atau',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ),
                                          const Expanded(
                                            child: Divider(),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Belum punya akun?',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: AppColors.muted,
                                                ),
                                          ),
                                          TextButton(
                                            onPressed: _isLoading
                                                ? null
                                                : () => Navigator.pushNamed(
                                                    context, '/register'),
                                            child:
                                                const Text('Daftar akun baru'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
