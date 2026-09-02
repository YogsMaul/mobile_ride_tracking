import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/dio_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _createRide(BuildContext context, WidgetRef ref) async {
    // Messenger diambil sebelum await supaya tidak menyentuh BuildContext
    // setelah operasi async — pola yang diminta lint
    // `use_build_context_synchronously`.
    final messenger = ScaffoldMessenger.of(context);

    try {
      final dio = ref.read(dioClientProvider).instance;
      final response = await dio.post(ApiConstants.createRideEndpoint);

      // Backend membalas objek ride apa adanya (ride_handler.go:55), jadi
      // field-nya `id` dan `invite_code` — bukan `ride_id`.
      final rideId = readString(response.data, 'id');
      final inviteCode = readString(response.data, 'invite_code');

      if (rideId == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Server tidak mengirim id ride. Ride tidak dibuka.'),
          ),
        );
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            inviteCode == null
                ? 'Ride dibuat.'
                : 'Ride dibuat! Kode undangan: $inviteCode',
          ),
        ),
      );

      if (context.mounted) {
        Navigator.pushNamed(context, '/ride', arguments: {
          'rideId': rideId,
          'inviteCode': inviteCode,
        });
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal membuat ride: ${apiErrorMessage(e)}')),
      );
    }
  }

  Future<void> _showJoinDialog(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final codeController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Ride'),
        content: TextField(
          controller: codeController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Invite Code'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, codeController.text),
            child: const Text('Join'),
          ),
        ],
      ),
    );
    codeController.dispose();

    // Invite code dibaca backend sebagai UUID (ride_handler.go:102), jadi
    // spasi nyasar dari paste/keyboard harus dibuang dulu.
    final code = result?.trim() ?? '';
    if (code.isEmpty) return;

    try {
      final dio = ref.read(dioClientProvider).instance;
      final response = await dio.post(
        ApiConstants.joinRideEndpoint,
        data: {'invite_code': code},
      );

      final rideId = readString(response.data, 'id');
      if (rideId == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Server tidak mengirim id ride.')),
        );
        return;
      }

      if (context.mounted) {
        Navigator.pushNamed(context, '/ride', arguments: {
          'rideId': rideId,
          'inviteCode': readString(response.data, 'invite_code'),
        });
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal join ride: ${apiErrorMessage(e)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ride Tracking')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => _createRide(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Create Ride'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showJoinDialog(context, ref),
              icon: const Icon(Icons.login),
              label: const Text('Join Ride'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/history'),
              child: const Text('Ride History'),
            ),
          ],
        ),
      ),
    );
  }
}
