// lib/appstyles.dart
// --- FINAL CORRECTED VERSION ---

import 'package:flutter/material.dart';
import 'package:ISS/appcolor.dart'; // Make sure this path is correct for your project

class AppStyles {
  // ===========================================================================
  // Text Styles
  // ===========================================================================
  static TextStyle headline1(BuildContext context) => TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.getTextColor(context),
  );
  static TextStyle headline2(BuildContext context) => TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: AppColors.getTextColor(context),
  );
  static TextStyle headline3(BuildContext context) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.getTextColor(context),
  );
  static TextStyle headline4(BuildContext context) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.getTextColor(context),
  );
  static TextStyle headline5(BuildContext context) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.getTextColor(context),
  );
  static TextStyle bodyText1(BuildContext context) => TextStyle(
    fontSize: 16,
    color: AppColors.getTextColor(context),
    height: 1.5,
  );
  static TextStyle bodyText2(BuildContext context) => TextStyle(
    fontSize: 14,
    color: AppColors.getSecondaryTextColor(context),
    height: 1.4,
  );
  static TextStyle caption(BuildContext context) =>
      TextStyle(fontSize: 12, color: AppColors.getLightGreyColor(context));

  // ===========================================================================
  // Button Styles
  // ===========================================================================
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primaryAccent,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    elevation: 5,
    shadowColor: AppColors.primaryAccent.withOpacity(0.3),
  );

  static ButtonStyle textButtonStyle(BuildContext context) =>
      TextButton.styleFrom(
        foregroundColor: AppColors.primaryAccent,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      );

  // ===========================================================================
  // Decorations
  // ===========================================================================
  static BoxDecoration cardDecoration(BuildContext context) =>
      elevatedSurfaceDecoration(context);

  static BoxDecoration elevatedSurfaceDecoration(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);
    final base = AppColors.getGlassFillColor(context);
    final surface = isDark
        ? [base.withOpacity(0.72), base.withOpacity(0.45)]
        : [base.withOpacity(0.95), base.withOpacity(0.65)];
    final borderColor =
        isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.14);
    final shadowColor =
        isDark ? Colors.black.withOpacity(0.18) : Colors.black.withOpacity(0.08);

    return BoxDecoration(
      gradient: LinearGradient(
        colors: surface,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: borderColor, width: 1),
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          blurRadius: 14,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static BoxDecoration activeIndicatorDecoration(BuildContext context) =>
      BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAccent.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BorderRadius borderRadiusAll(double radius) =>
      BorderRadius.all(Radius.circular(radius));

  // ===========================================================================
  // NEW Glassmorphism & Input Helpers
  // ===========================================================================
  static BoxDecoration glassmorphicBoxDecoration(BuildContext context) =>
      BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.getGlassFillColor(context),
            AppColors.getGlassFillColor(context).withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.getGlassBorderColor(context),
          width: 1.5,
        ),
      );

  static InputDecoration inputDecoration({
    required BuildContext context,
    required String hintText,
    IconData? prefixIcon,
  }) => InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(color: AppColors.getSecondaryTextColor(context)),
    prefixIcon:
        prefixIcon != null
            ? Icon(
              prefixIcon,
              color: AppColors.getSecondaryTextColor(context),
              size: 20,
            )
            : null,
    filled: true,
    fillColor: AppColors.getGlassFillColor(context),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
  );
}
