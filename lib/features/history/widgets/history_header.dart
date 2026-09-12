import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';

class HistoryHeader extends StatelessWidget {
  const HistoryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Riwayat',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      letterSpacing: -0.3,
                      color: AppColors.ink,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                'Lihat perjalanan yang pernah kamu ikuti.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12.5,
                      height: 1.4,
                      color: AppColors.muted,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Material(
          color: AppColors.brandSoft,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () =>
                AppToast.info(context, 'Pencarian riwayat belum tersedia.'),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                Icons.search_rounded,
                color: AppColors.brand,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
