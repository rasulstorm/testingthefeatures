// lib/appColor.dart
// --- FINAL CORRECTED VERSION (with glassGradient & getPrimaryTextColor) ---

import 'package:flutter/material.dart';

class AppColors {
  // ===========================================================================
  // Core Palette (Scandinavian Inspired)
  // ===========================================================================
  static const Color primaryAccent = Color(0xFF4A90E2);
  static const Color secondaryAccent = Color(0xFF50E3C2);

  // Light Theme
  static const Color backgroundLight = Color(0xFFF7F9FC);
  static const Color cardBackgroundLight = Colors.white;
  static const Color textColorLight = Color(0xFF1B1B1B);
  static const Color secondaryTextColorLight = Color(0xFF6E717A);
  static const Color lightGreyLight = Color(0xFFAAB0B9);
  static const Color borderGrayLight = Color(0xFFE8EAF0);

  // Dark Theme
  static const Color backgroundDark = Color(0xFF161B22);
  static const Color cardBackgroundDark = Color(0xFF21262D);
  static const Color textColorDark = Color(0xFFE6EDF3);
  static const Color secondaryTextColorDark = Color(0xFF8B949E);
  static const Color lightGreyDark = Color(0xFF6E717A);
  static const Color borderGrayDark = Color(0xFF30363D);

  // Semantic Colors
  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFDC3545);

  // ===========================================================================
  // Gradients
  // ===========================================================================
  static const Gradient primaryGradient = LinearGradient(
    colors: [primaryAccent, Color(0xFF50E3C2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient cardGradientDark = LinearGradient(
    colors: [Color(0xFF2A2F37), Color(0xFF21262D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient cardGradientLight = LinearGradient(
    colors: [Colors.white, Color(0xFFFDFEFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===========================================================================
  // Theme-aware Helper Methods
  // ===========================================================================
  static bool isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color getBackgroundColor(BuildContext context) =>
      isDarkMode(context) ? backgroundDark : backgroundLight;

  static Color getCardBackgroundColor(BuildContext context) =>
      isDarkMode(context) ? cardBackgroundDark : cardBackgroundLight;

  /// Base text color
  static Color getTextColor(BuildContext context) =>
      isDarkMode(context) ? textColorDark : textColorLight;

  /// Alias used by widgets (fix for missing method)
  static Color getPrimaryTextColor(BuildContext context) =>
      getTextColor(context);

  static Color getSecondaryTextColor(BuildContext context) =>
      isDarkMode(context) ? secondaryTextColorDark : secondaryTextColorLight;

  static Color getLightGreyColor(BuildContext context) =>
      isDarkMode(context) ? lightGreyDark : lightGreyLight;

  static Color getBorderGrayColor(BuildContext context) =>
      isDarkMode(context) ? borderGrayDark : borderGrayLight;

  static Gradient getCardGradient(BuildContext context) =>
      isDarkMode(context) ? cardGradientDark : cardGradientLight;

  // Glassmorphism Helpers
  static Color getGlassFillColor(BuildContext context) =>
      isDarkMode(context)
          ? Colors.white.withOpacity(0.08)
          : Colors.white.withOpacity(0.6);

  static Color getGlassBorderColor(BuildContext context) =>
      isDarkMode(context)
          ? Colors.white.withOpacity(0.15)
          : Colors.white.withOpacity(0.3);

  // Subtle glass gradient for cards
  static Gradient glassGradient(BuildContext context) => LinearGradient(
    colors: [
      getGlassFillColor(context),
      getGlassFillColor(context).withOpacity(0.30),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
