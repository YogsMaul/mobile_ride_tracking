import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/dio_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // Diambil sebelum await supaya tidak memakai BuildContext setelah async.
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioClientProvider).instance;
      final response = await dio.post(
        ApiConstants.registerEndpoint,
        data: {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        },
      );

      // Register balas 201 dengan `tokenResponse{access_token, user}`
      // (auth_handler.go:107-110). Tidak ada refresh_token.
      final token = readString(response.data, 'access_token');
      if (token == null || token.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content:
                Text('Registrasi gagal: server tidak mengirim access token.'),
          ),
        );
        return;
      }

      await _storage.write(key: 'access_token', value: token);
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Registrasi gagal: ${apiErrorMessage(e)}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                // Sesuai IsStrongPassword di backend/internal/middleware/validate.go:19.
                helperText: 'Min. 8 karakter, ada huruf besar, kecil, dan angka',
              ),
              obscureText: true,
              onSubmitted: (_) => _isLoading ? null : _register(),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _register,
                    child: const Text('Register'),
                  ),
          ],
        ),
      ),
    );
  }
}
