import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class RideBottomBar extends StatelessWidget {
  const RideBottomBar({
    super.key,
    required this.riderCount,
    required this.isHost,
    required this.status,
    required this.isStarting,
    required this.onLeave,
    this.onStart,
  });

  final int riderCount;
  final bool isHost;
  final String status;
  final bool isStarting;
  final VoidCallback onLeave;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final isPlanned = status == 'planned';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: isPlanned
              ? _buildLobbyBar(context)
              : _buildActiveBar(context),
        ),
      ),
    );
  }

  Widget _buildLobbyBar(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Icons.hourglass_top,
                color: AppColors.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Lobby Ride',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          '$riderCount Peserta',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isHost
                        ? 'Kamu Room Master. Mulai saat semua siap!'
                        : 'Menunggu Room Master memulai perjalanan...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: isHost ? 'Batalkan Ride' : 'Keluar Room',
              icon: const Icon(Icons.exit_to_app, color: AppColors.warn),
              onPressed: isStarting ? null : onLeave,
            ),
          ],
        ),
        if (isHost) ...[
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            onPressed: isStarting ? null : onStart,
            icon: isStarting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.play_arrow, size: 20),
            label: Text(
              isStarting ? 'Memulai...' : 'Mulai Perjalanan',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActiveBar(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(Icons.group, color: AppColors.brand, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$riderCount rider online',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                riderCount <= 1
                    ? 'Kamu sendiri — undang teman via icon QR.'
                    : 'Posisi tersinkron via WebSocket.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.warn,
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
            ),
          ),
          onPressed: onLeave,
          child: Text(isHost ? 'Selesai' : 'Keluar'),
        ),
      ],
    );
  }
}
