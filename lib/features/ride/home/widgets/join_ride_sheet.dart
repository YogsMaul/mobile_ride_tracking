import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../scan_qr_screen.dart';

class JoinRideSheet extends StatefulWidget {
  const JoinRideSheet({super.key});

  @override
  State<JoinRideSheet> createState() => _JoinRideSheetState();
}

class _JoinRideSheetState extends State<JoinRideSheet> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _openScanner() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScanQrScreen()),
    );
    if (code != null && code.isNotEmpty && mounted) {
      // Langsung tutup sheet dan kembalikan kode yang didapat dari scan
      Navigator.pop(context, code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Gabung ride',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Scan QR host atau masukkan kode 8 karakter.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                    fontSize: 13,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Tombol Scan QR mencolok
            OutlinedButton.icon(
              onPressed: _openScanner,
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.brandSoft,
                side: const BorderSide(color: AppColors.brand, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.qr_code_scanner_rounded,
                  color: AppColors.brand, size: 22),
              label: const Text(
                'Scan QR Code Teman',
                style: TextStyle(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'atau ketik kode',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11.5,
                        ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            TextField(
              controller: _codeController,
              autofocus: false,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Kode undangan',
                hintText: 'Contoh: A1B2C3D4',
                prefixIcon: const Icon(Icons.tag_rounded,
                    color: AppColors.muted, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner,
                      color: AppColors.brand, size: 20),
                  tooltip: 'Scan QR',
                  onPressed: _openScanner,
                ),
              ),
              onSubmitted: (v) => Navigator.pop(context, v),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.pop(context, _codeController.text),
                    child: const Text('Gabung'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
