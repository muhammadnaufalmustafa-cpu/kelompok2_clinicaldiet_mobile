import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF10B981);
  static const Color primaryLight = Color(0xFFD1FAE5);
  static const Color primaryDark = Color(0xFF059669);
  static const Color background = Color(0xFFF4F6F8);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color protein = Color(0xFFF59E0B);
  static const Color fat = Color(0xFFEF4444);
  static const Color carb = Color(0xFF10B981);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color red = Color(0xFFEF4444);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: GoogleFonts.poppinsTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 16,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
