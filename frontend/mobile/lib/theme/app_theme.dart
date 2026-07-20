import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.navy,
      scaffoldBackgroundColor: AppColors.white,
      colorScheme: const ColorScheme.light(
        primary: AppColors.navy,
        secondary: AppColors.amber,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.textPrimary,
        onError: AppColors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navy,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.white),
        titleTextStyle: AppTextStyles.screenTitle.copyWith(color: AppColors.white),
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.greeting,
        headlineMedium: AppTextStyles.screenTitle,
        titleLarge: AppTextStyles.sectionHeader,
        titleMedium: AppTextStyles.cardTitle,
        bodyLarge: AppTextStyles.bodyMain,
        bodyMedium: AppTextStyles.bodySecondary,
        labelSmall: AppTextStyles.badgeCaps,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.cardTitle,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.inputBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.inputBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.navy, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        hintStyle: AppTextStyles.bodySecondary.copyWith(color: AppColors.textSecondary),
        labelStyle: AppTextStyles.bodySecondary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.inputBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: AppColors.white, // Inverted: brand primary is white in dark mode
      scaffoldBackgroundColor: AppColors.navy, // Background is navy
      colorScheme: const ColorScheme.dark(
        primary: AppColors.white,
        secondary: AppColors.amber,
        surface: Color(0xFF162336), // Slightly lighter than navy
        error: AppColors.error,
        onPrimary: AppColors.navy,
        onSecondary: AppColors.navy,
        onSurface: AppColors.white,
        onError: AppColors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navy,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.white),
        titleTextStyle: AppTextStyles.screenTitle.copyWith(color: AppColors.white),
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.greeting.copyWith(color: AppColors.white),
        headlineMedium: AppTextStyles.screenTitle.copyWith(color: AppColors.white),
        titleLarge: AppTextStyles.sectionHeader.copyWith(color: AppColors.white),
        titleMedium: AppTextStyles.cardTitle.copyWith(color: AppColors.white),
        bodyLarge: AppTextStyles.bodyMain.copyWith(color: AppColors.white),
        bodyMedium: AppTextStyles.bodySecondary.copyWith(color: AppColors.inputBorder),
        labelSmall: AppTextStyles.badgeCaps.copyWith(color: AppColors.inputBorder),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.navy,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.cardTitle.copyWith(color: AppColors.navy),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF162336),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.textSecondary, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.textSecondary, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        hintStyle: AppTextStyles.bodySecondary.copyWith(color: AppColors.textSecondary),
        labelStyle: AppTextStyles.bodySecondary.copyWith(color: AppColors.inputBorder),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF162336),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.textSecondary, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
}

