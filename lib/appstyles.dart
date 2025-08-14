// lib/core/app_styles.dart
import 'package:flutter/material.dart';
import 'package:ISS/appcolor.dart'; // Make sure the path to appcolor.dart is correct

class AppStyles {
  // --- Text Styles ---

  // Headlines
  static TextStyle headline1(BuildContext context) => TextStyle(
    fontSize: 32, // Slightly increased for more prominence
    fontWeight: FontWeight.bold,
    color: AppColors.getTextColor(context),
  );

  static TextStyle headline2(BuildContext context) => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.getTextColor(context),
  );

  static TextStyle headline3(BuildContext context) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.getTextColor(context),
  );

  // Added headline4 for sub-sections or less prominent titles
  static TextStyle headline4(BuildContext context) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600, // Semi-bold
    color: AppColors.getTextColor(context),
  );

  // ДОБАВЛЕНО: headline5
  static TextStyle headline5(BuildContext context) => TextStyle(
    fontSize: 16, // Меньше, чем headline4, но все еще заметный
    fontWeight: FontWeight.w600, // Semi-bold
    color: AppColors.getTextColor(context),
  );

  // Body Text
  static TextStyle bodyText1(BuildContext context) =>
      TextStyle(fontSize: 16, color: AppColors.getTextColor(context));

  static TextStyle bodyText2(BuildContext context) =>
      TextStyle(fontSize: 14, color: AppColors.getSecondaryTextColor(context));

  // Caption/Small Text (e.g., timestamps, footnotes)
  static TextStyle caption(BuildContext context) =>
      TextStyle(fontSize: 12, color: AppColors.getLightGreyColor(context));

  // --- Button Styles ---

  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primaryAccent,
    foregroundColor:
        AppColors
            .textColorDark, // Text color on the primary button (assuming dark text on accent)
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 14,
    ), // Slightly increased vertical padding
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );

  // You might want a secondary button style as well, e.g., outlined or text-only
  static ButtonStyle textButtonStyle(BuildContext context) =>
      TextButton.styleFrom(
        foregroundColor: AppColors.primaryAccent, // Text color for text buttons
        textStyle: AppStyles.bodyText2(
          context,
        ).copyWith(fontWeight: FontWeight.w500),
      );

  static BoxDecoration cardDecoration(BuildContext context) => BoxDecoration(
    color: AppColors.getCardBackgroundColor(context),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: AppColors.getBorderGrayColor(context),
      width: 1.0,
    ),
    boxShadow: [
      BoxShadow(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.4) // Darker shadow for dark theme
                : Colors.grey.withOpacity(
                  0.2,
                ), // Lighter shadow for light theme
        blurRadius: 15,
        spreadRadius: 2,
        offset: const Offset(0, 8),
      ),
    ],
  );

  // Decoration for active elements (e.g., selected tabs, indicators)
  static BoxDecoration activeIndicatorDecoration(BuildContext context) =>
      BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAccent.withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          ),
        ],
      );
  static BorderRadius borderRadiusAll(double radius) {
    return BorderRadius.all(Radius.circular(radius));
  }
}
