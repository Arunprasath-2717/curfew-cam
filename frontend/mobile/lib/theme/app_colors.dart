import 'package:flutter/material.dart';

class AppColors {
  // Brand colors
  static const Color navy = Color(0xFF0A1628);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  
  // Status colors
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color amber = Color(0xFFF59E0B);
  
  // Typography
  static const Color textPrimary = Color(0xFF191C1E);
  static const Color textSecondary = Color(0xFF45474C);
  static const Color white = Color(0xFFFFFFFF);
  
  // Input specific
  static const Color inputBorder = Color(0xFFCBD5E1);
  
  // Transparent variants
  static const Color transparent = Colors.transparent;

  // ── Visual Upgrade Tokens ──

  // Accent / Gradient
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color accentTeal = Color(0xFF14B8A6);

  // Gradient pairs
  static const List<Color> gradientNavy = [Color(0xFF0A1628), Color(0xFF1E3A5F)];
  static const List<Color> gradientSuccess = [Color(0xFF22C55E), Color(0xFF16A34A)];
  static const List<Color> gradientAmber = [Color(0xFFF59E0B), Color(0xFFD97706)];
  static const List<Color> gradientError = [Color(0xFFEF4444), Color(0xFFDC2626)];
  static const List<Color> gradientBlue = [Color(0xFF3B82F6), Color(0xFF6366F1)];

  // Card surface variants
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF1F5F9);
  static const Color darkSurface = Color(0xFF162336);

  // Status glow (subtle tinted backgrounds)
  static Color successGlow = const Color(0xFF22C55E).withOpacity(0.08);
  static Color errorGlow = const Color(0xFFEF4444).withOpacity(0.08);
  static Color amberGlow = const Color(0xFFF59E0B).withOpacity(0.08);
  static Color blueGlow = const Color(0xFF3B82F6).withOpacity(0.08);

  // Shimmer / skeleton
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF1F5F9);
}
