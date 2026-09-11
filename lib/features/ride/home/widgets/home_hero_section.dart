import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class HomeHeroSection extends StatelessWidget {
  const HomeHeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 55,
              child: Text(
                'Jalan\nlebih seru\nbersama.',
                style: textTheme.displaySmall?.copyWith(
                  fontSize: 23,
                  fontWeight: FontWeight.w600,
                  height: 1.22,
                  letterSpacing: -0.4,
                  color: AppColors.brandDark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 45,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Text(
                    'Jarak bukan penghalang\nuntuk tetap bersama.',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                      fontSize: 10.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Pantau perjalanan konvoi\nsecara real-time.',
          style: textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            height: 1.45,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: 36,
          height: 3.5,
          decoration: BoxDecoration(
            color: AppColors.brand,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih aksi',
          style: textTheme.headlineMedium?.copyWith(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            height: 1.3,
            letterSpacing: -0.2,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Mulai perjalanan baru atau gabung dengan teman.',
          style: textTheme.bodyMedium?.copyWith(
            fontSize: 12.5,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}
