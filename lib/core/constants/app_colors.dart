import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF090B10);
  static const Color backgroundSecondary = Color(0xFF0F141F);
  static const Color surface = Color(0xFF161D2E);

  // Glassmorphic Surfaces
  static final Color glassSurface = const Color(0xFF1E2638).withOpacity(0.45);
  static final Color glassSurfaceHighlight = const Color(0xFF2B364E).withOpacity(0.55);
  static final Color glassBorder = Colors.white.withOpacity(0.12);
  static final Color glassBorderActive = const Color(0xFF00F2FE).withOpacity(0.4);

  // Brand & Accent Gradients
  static const Color primary = Color(0xFF00F2FE); // Vibrant Cyan
  static const Color primaryDark = Color(0xFF4FACFE);
  static const Color secondary = Color(0xFF9D4EDD); // Electric Violet
  static const Color accent = Color(0xFF00F5D4); // Neon Emerald
  static const Color error = Color(0xFFFF4B72); // Soft Red
  static const Color warning = Color(0xFFFFB703); // Golden Amber
  static const Color success = Color(0xFF06D6A0); // Bright Green

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient violetGradient = LinearGradient(
    colors: [Color(0xFF9D4EDD), Color(0xFF5A189A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00F5D4), Color(0xFF00B4D8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF090B10), Color(0xFF0F1424), Color(0xFF090B10)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textAccent = Color(0xFF38BDF8);
}
