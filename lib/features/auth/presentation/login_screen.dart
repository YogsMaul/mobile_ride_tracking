import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/dio_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Diambil sebelum await supaya tidak memakai BuildContext setelah async.
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isLoading = true);
    try {
      // Pakai DioClient bersama supaya timeout dan interceptor-nya sama
      // dengan request lain, bukan bikin Dio baru tanpa konfigurasi.
      final dio = ref.read(dioClientProvider).instance;
      final response = await dio.post(
        ApiConstants.loginEndpoint,
        data: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        },
      );

      // Backend membalas `tokenResponse{access_token, user}`
      // (auth_handler.go:56-58) — tidak ada refresh_token. Menulis nilai null
      // ke secure storage justru menghapus key-nya, jadi jangan disimpan.
      final token = readString(response.data, 'access_token');
      if (token == null || token.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Login gagal: server tidak mengirim access token.'),
          ),
        );
        return;
      }

      await _storage.write(key: 'access_token', value: token);
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Login gagal: ${apiErrorMessage(e)}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              onSubmitted: (_) => _isLoading ? null : _login(),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: const Text('Belum punya akun? Register'),
            ),
          ],
        ),
      ),
    );
  }
}
