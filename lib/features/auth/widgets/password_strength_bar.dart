import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class PasswordStrengthBar extends StatelessWidget {
  const PasswordStrengthBar({super.key, required this.isStrong});
  final bool isStrong;

  @override
  Widget build(BuildContext context) {
    final color = isStrong ? AppColors.brand : AppColors.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: isStrong ? color : AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          isStrong
              ? 'Password kuat (huruf besar, kecil, angka)'
              : 'Gunakan kombinasi huruf besar, kecil, dan angka',
          style: TextStyle(
            color: isStrong ? AppColors.brand : AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
