import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 11.5,
                      height: 1.4,
                      color: AppColors.muted,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () =>
                AppToast.info(context, 'Pengaturan segera hadir.'),
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Icon(
                Icons.settings_outlined,
                color: AppColors.ink,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
