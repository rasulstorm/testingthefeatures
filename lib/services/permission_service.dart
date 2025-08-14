import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:firebase_messaging/firebase_messaging.dart';

class PermissionService {
  // поменяешь ключ, если надо заставить запрос заново у всех пользователей
  static const _askedFlagKey = 'asked_permissions_once_v220_b4';

  /// Запрашивает все нужные разрешения ровно один раз.
  static Future<void> requestAllOnce() async {
    if (!Platform.isIOS && !Platform.isAndroid) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_askedFlagKey) == true) return;

    // 1) Уведомления (FCM)
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } catch (_) {}

    // 2) Микрофон
    try {
      await Permission.microphone.request();
    } catch (_) {}

    // 3) Речь (iOS покажет системный диалог при инициализации)
    try {
      final s = stt.SpeechToText();
      await s.initialize();
    } catch (_) {}

    // 4) Камера / Фото (image_picker)
    try {
      await Permission.camera.request();
    } catch (_) {}
    try {
      await Permission.photos.request();
    } catch (_) {}

    // 5) Геолокация: сначала WhenInUse → затем попытка апгрейда до Always (iOS)
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied ||
          p == LocationPermission.deniedForever) {
        p = await Geolocator.requestPermission();
      }
      if (Platform.isIOS && p == LocationPermission.whileInUse) {
        final res = await Permission.locationAlways.request();
        if (!res.isGranted) {
          // при желании можно подсказать открыть Settings: await openAppSettings();
        }
      }
    } catch (_) {}

    await prefs.setBool(_askedFlagKey, true);
  }
}
