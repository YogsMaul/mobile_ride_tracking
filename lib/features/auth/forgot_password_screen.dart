import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/app_exception.dart';
import '../../core/network/repository/auth_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_toast.dart';
import 'widgets/password_strength_bar.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _pageController = PageController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKeyEmail = GlobalKey<FormState>();
  final _formKeyOtp = GlobalKey<FormState>();
  final _formKeyNewPassword = GlobalKey<FormState>();

  int _currentStep = 0; // 0: Email, 1: OTP, 2: Password Baru
  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String _newPassword = '';
  String? _devOtp;

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() => _currentStep++);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _requestOtp() async {
    if (!_formKeyEmail.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final otp = await repo.requestPasswordReset(
        email: _emailController.text.trim(),
      );
      _devOtp = otp;
      if (!mounted) return;
      AppToast.success(context, 'Kode OTP telah dikirim ke email kamu.');
      if (_devOtp != null && _devOtp!.isNotEmpty) {
        _otpController.text = _devOtp!;
      }
      _nextStep();
    } on AppException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    } catch (e) {
      if (mounted) AppToast.error(context, 'Gagal meminta OTP: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKeyOtp.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.verifyPasswordResetOtp(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
      );
      if (!mounted) return;
      AppToast.success(context, 'Kode OTP berhasil diverifikasi.');
      _nextStep();
    } on AppException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    } catch (e) {
      if (mounted) AppToast.error(context, 'Verifikasi gagal: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKeyNewPassword.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.resetPassword(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      AppToast.success(
        context,
        'Password berhasil direset. Silakan login kembali.',
        2200,
      );
      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted) Navigator.pop(context);
    } on AppException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    } catch (e) {
      if (mounted) AppToast.error(context, 'Reset password gagal: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isStrong(String pw) {
    if (pw.length < 8) return false;
    final hasUpper = pw.contains(RegExp(r'[A-Z]'));
    final hasLower = pw.contains(RegExp(r'[a-z]'));
    final hasDigit = pw.contains(RegExp(r'[0-9]'));
    return hasUpper && hasLower && hasDigit;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Bar
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (_currentStep > 0) {
                              setState(() => _currentStep--);
                              _pageController.animateToPage(
                                _currentStep,
                                duration: const Duration(milliseconds: 240),
                                curve: Curves.easeOutCubic,
                              );
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              side: const BorderSide(color: AppColors.line),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          'Lupa Password',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Step indicator
                    _StepIndicator(currentStep: _currentStep),
                    const SizedBox(height: AppSpacing.md),

                    // Card container
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: SizedBox(
                          height: 340,
                          child: PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _buildStepEmail(),
                              _buildStepOtp(),
                              _buildStepNewPassword(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: TextButton(
                        onPressed:
                            _isLoading ? null : () => Navigator.pop(context),
                        child: const Text('Kembali ke halaman Masuk'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepEmail() {
    return Form(
      key: _formKeyEmail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Kirim kode OTP',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Masukkan email akun kamu untuk menerima kode verifikasi 6 digit.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  height: 1.4,
                ),
          ),
          const Spacer(),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'nama@email.com',
              prefixIcon: Icon(Icons.alternate_email,
                  color: AppColors.muted, size: 20),
            ),
            validator: AppValidators.email,
            onFieldSubmitted: (_) => _isLoading ? null : _requestOtp(),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _isLoading ? null : _requestOtp,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Kirim Kode OTP'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepOtp() {
    return Form(
      key: _formKeyOtp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Verifikasi OTP',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kode dikirim ke ${_emailController.text}.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
          ),
          if (_devOtp != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3E2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCD39A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Mode dev: OTP kamu adalah $_devOtp',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7A4A04),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              letterSpacing: 8,
              fontWeight: FontWeight.w700,
            ),
            decoration: const InputDecoration(
              counterText: '',
              hintText: '••••••',
              labelText: 'Kode OTP',
            ),
            validator: (v) {
              if (v == null || v.trim().length != 6) {
                return 'Masukkan 6 digit kode OTP';
              }
              return null;
            },
            onFieldSubmitted: (_) => _isLoading ? null : _verifyOtp(),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _isLoading ? null : _verifyOtp,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Verifikasi'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepNewPassword() {
    return Form(
      key: _formKeyNewPassword,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Buat password baru',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            'Minimal 8 karakter: huruf besar, kecil, dan angka.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontSize: 11,
                ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscureNew,
            onChanged: (v) => setState(() => _newPassword = v),
            decoration: InputDecoration(
              labelText: 'Password baru',
              prefixIcon: const Icon(Icons.lock_outline,
                  color: AppColors.muted, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNew
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.muted,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            validator: (v) => AppValidators.password(v, minLength: 8),
          ),
          const SizedBox(height: 6),
          if (_newPassword.isNotEmpty)
            PasswordStrengthBar(isStrong: _isStrong(_newPassword)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: 'Konfirmasi password',
              prefixIcon: const Icon(Icons.lock_reset,
                  color: AppColors.muted, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.muted,
                  size: 18,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) {
              if (v != _newPasswordController.text) {
                return 'Konfirmasi password tidak cocok';
              }
              return null;
            },
          ),
          const Spacer(),
          FilledButton(
            onPressed: _isLoading ? null : _resetPassword,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Simpan Password Baru'),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < 3; i++) ...[
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i <= currentStep ? AppColors.brand : AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (i < 2) const SizedBox(width: 6),
        ],
      ],
    );
  }
}
