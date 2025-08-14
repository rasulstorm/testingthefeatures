// /appcolor.dart
import 'package:flutter/material.dart';

class AppColors {
  // Основной фон приложения (очень темный, почти черный)
  static const Color backgroundDark = Color(
    0xFF121212,
  ); // Deep charcoal / almost black
  static const Color backgroundLight = Color(
    0xFFF0F2F5,
  ); // Light grey/off-white

  static const Color cardBackgroundDark = Color(0xFF1F1F1F); // Dark grey
  static const Color cardBackgroundLight = Colors.white;

  // Акцентный цвет (холодный синий для интерактивных элементов)
  static const Color primaryAccent = Color(
    0xFF00BFFF,
  ); // Deep Sky Blue - яркий, но не кричащий
  // Вторичный акцентный цвет (может быть светло-зеленый или мятный для     успеха/доп.индикаторов)
  static const Color secondaryAccent = Color(
    0xFF00E676,
  ); // Emerald Green - для статусов
  // Цвет текста
  static const Color textColorDark = Colors.white;
  static const Color secondaryTextColorDark = Colors.white70;
  static const Color lightGreyDark = Colors.white54;
  static const Color borderGrayDark = Color(0xFF424242); // Для рамок

  static const Color textColorLight = Colors.black87;
  static const Color secondaryTextColorLight = Colors.black54;
  static const Color lightGreyLight = Colors.grey;
  static const Color borderGrayLight = Color(
    0xFFE0E0E0,
  ); // Для рамок в светлой теме

  // Цвета для индикаторов состояния
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);

  // Градиенты для фона / элементов (более холодные тона)
  static const Gradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF00BFFF),
      Color(0xFF1E90FF),
    ], // От Deep Sky Blue к Dodger Blue
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient cardGradientDark = LinearGradient(
    colors: [
      Color(0xFF2F2F2F),
      Color(0xFF1F1F1F),
    ], // От более светлого серого к более темному
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient cardGradientLight = LinearGradient(
    colors: [Color(0xFFFBFBFB), Color(0xFFF0F0F0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Методы для получения цвета в зависимости от темы
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? backgroundDark
        : backgroundLight;
  }

  static Color getCardBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? cardBackgroundDark
        : cardBackgroundLight;
  }

  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textColorDark
        : textColorLight;
  }

  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? secondaryTextColorDark
        : secondaryTextColorLight;
  }

  static Color getLightGreyColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? lightGreyDark
        : lightGreyLight;
  }

  static Color getBorderGrayColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? borderGrayDark
        : borderGrayLight;
  }

  static Gradient getCardGradient(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? cardGradientDark
        : cardGradientLight;
  }
}
