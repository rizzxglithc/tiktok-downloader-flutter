import 'package:flutter/material.dart';

class AppColors {
  // Pure Monochrome Dark Palette
  static const Color background = Color(0xFF000000);
  static const Color backgroundSecondary = Color(0xFF09090B);
  static const Color backgroundElevated = Color(0xFF121214);

  // Surfaces & Glass Cards
  static const Color surface = Color(0xFF141416);
  static const Color surfaceElevated = Color(0xFF1C1C1F);
  static const Color surfaceHover = Color(0xFF26262B);

  // Borders & Dividers
  static const Color border = Color(0xFF27272A);
  static const Color borderLight = Color(0xFF3F3F46);

  // High-Contrast Primary & Accents (Black & White)
  static const Color primary = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFF000000);
  
  static const Color secondary = Color(0xFFE4E4E7);
  static const Color onSecondary = Color(0xFF09090B);

  // Monochromatic Glass Overlay
  static final Color glassFill = const Color(0xFFFFFFFF).withOpacity(0.04);
  static final Color glassBorder = const Color(0xFFFFFFFF).withOpacity(0.10);
  static final Color glassFillActive = const Color(0xFFFFFFFF).withOpacity(0.08);

  // Typography
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);
  static const Color textDisabled = Color(0xFF52525B);

  // Semantic
  static const Color success = Color(0xFFE4E4E7);
  static const Color error = Color(0xFFF87171);
  static const Color warning = Color(0xFFFBBF24);

  // Gradients (Monochrome Silver/White/Dark)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFD4D4D8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF18181B), Color(0xFF09090B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static final LinearGradient glassGradient = LinearGradient(
    colors: [
      const Color(0xFFFFFFFF).withOpacity(0.07),
      const Color(0xFFFFFFFF).withOpacity(0.02),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
