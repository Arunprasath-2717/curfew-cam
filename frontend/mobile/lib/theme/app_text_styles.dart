import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Greeting (32px, Bold)
  static TextStyle get greeting => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.02,
      );

  // Screen Title (24px, SemiBold)
  static TextStyle get screenTitle => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // Section Header (20px, SemiBold)
  static TextStyle get sectionHeader => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // Card Title (18px, SemiBold)
  static TextStyle get cardTitle => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // Body Main (16px, Regular)
  static TextStyle get bodyMain => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  // Body Secondary (14px, Regular)
  static TextStyle get bodySecondary => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  // Badge Caps (12px, SemiBold, Uppercase)
  static TextStyle get badgeCaps => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 12 * 0.05, // 0.05em
        color: AppColors.textPrimary,
      );
}
