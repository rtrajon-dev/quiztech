import 'package:flutter/material.dart';

import 'app_colors.dart';

/// App-wide [ThemeData]. Kept intentionally light: most quiz surfaces paint
/// their own gradient background, so the theme only sets shared defaults.
class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Ubuntu',
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );
  }
}
