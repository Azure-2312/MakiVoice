import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.accent,
      surface: AppColors.surface,
      background: AppColors.background,
      secondary: AppColors.accentDim,
    ),
    scaffoldBackgroundColor: AppColors.background,
    cardColor: AppColors.surface,
    dialogBackgroundColor: AppColors.surface,
    fontFamily: 'Roboto',
  );
}
