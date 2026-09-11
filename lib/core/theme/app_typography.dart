import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  static TextTheme light() {
    return const TextTheme(
      displaySmall: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        letterSpacing: -0.5,
        height: 1.15,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        letterSpacing: -0.3,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        letterSpacing: -0.1,
      ),
      bodyLarge: TextStyle(fontSize: 15, color: AppColors.ink, height: 1.4),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.ink, height: 1.45),
      bodySmall: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        letterSpacing: 0.1,
      ),
    );
  }
}
