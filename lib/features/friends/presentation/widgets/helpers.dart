// lib/features/friends/presentation/widgets/helpers.dart
import 'dart:math';
import 'package:flutter/material.dart';

/// Инициалы по first/last или email
String initialsOf({String? firstName, String? lastName, String? email}) {
  String take(String s) => s.trim().isEmpty ? '' : s.trim()[0].toUpperCase();

  if ((firstName ?? '').trim().isNotEmpty ||
      (lastName ?? '').trim().isNotEmpty) {
    final a = take(firstName ?? '');
    final b = take(lastName ?? '');
    final res = (a + b).trim();
    if (res.isNotEmpty) return res;
  }
  if ((email ?? '').isNotEmpty) {
    final local = email!.split('@').first;
    if (local.isNotEmpty) {
      if (local.length == 1) return local[0].toUpperCase();
      return (local[0] + local[1]).toUpperCase();
    }
    return email[0].toUpperCase();
  }
  return '?';
}

/// Сидированный цвет для аватарки
Color avatarColorFromSeed(String seed, BuildContext context) {
  // стабильный цвет по хэшу
  final h = seed.hashCode;
  final rnd = Random(h);
  // лёгкая палитра с учётом темы
  final base = HSLColor.fromAHSL(
    1,
    rnd.nextDouble() * 360, // hue
    0.55 + rnd.nextDouble() * 0.15, // saturation
    Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.75, // lightness
  );
  return base.toColor();
}
