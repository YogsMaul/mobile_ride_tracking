import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/illustrations.dart';

/// Tab Riwayat di bottom nav. Backend belum punya endpoint
/// list-my-rides — empty state jujur, ilustrasi + copy yang kasih
/// konteks (apa yang bakal muncul di sini nanti, bukan fabricated
/// data).
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xxl),
              const Center(child: HistoryIllustration()),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Riwayat belum tersedia',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Begitu backend punya endpoint list-my-rides, daftar '
                'perjalanan sebelumnya — jarak, kecepatan, dan rute — '
                'akan nongol di sini.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                      height: 1.5,
                    ),
              ),
              const Spacer(),
              Text(
                'v1.0 · Ride Tracking',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              // Ruang aman biar footer tak tertutup navbar floating.
              const SizedBox(height: 108),
            ],
          ),
        ),
      ),
    );
  }
}
