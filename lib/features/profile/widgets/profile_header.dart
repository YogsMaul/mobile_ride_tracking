import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Profil',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.2,
            letterSpacing: -0.3,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Kelola akun dan preferensi kamu.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(fontSize: 11.5, height: 1.4, color: AppColors.muted),
        ),
      ],
    );
  }
}
