// lib/services/firebase_messaging_service.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ISS/main.dart'; // Для доступа к нашему глобальному navigatorKey
import 'package:ISS/core/network/dio_provider.dart'; // Для отправки токена

// Провайдер для легкого доступа к нашему сервису из любого места в приложении
final firebaseMessagingServiceProvider = Provider(
  (ref) => FirebaseMessagingService(),
);

// ВАЖНО: Эта функция должна быть верхнего уровня (top-level), вне любого класса.
// Она будет вызываться, когда приложение получит уведомление в фоновом режиме (полностью закрыто).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Убеждаемся, что Firebase инициализирован
  await Firebase.initializeApp();
  print("🔕 Обработка фонового уведомления: ${message.messageId}");
  print("   Заголовок: ${message.notification?.title}");
  print("   Тело: ${message.notification?.body}");
  print("   Данные: ${message.data}");
}

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Главный метод инициализации. Вызывается один раз при старте приложения (например, в MainScreen).
  Future<void> init() async {
    // 1. Запрашиваем у пользователя разрешение на показ уведомлений (критически важно для iOS и Android 13+)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('Статус разрешений на уведомления: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Пользователь предоставил разрешение на уведомления');

      // Если разрешение есть, настраиваем обработчики
      _setupListeners();

      // Теперь мы не просто выводим токен, а отправляем его на сервер при необходимости
      sendFcmTokenToServer();
    } else {
      print('❌ Пользователь отклонил разрешение на уведомления');
    }
  }

  // Настройка "слушателей" для разных состояний приложения
  void _setupListeners() {
    // 2. Обработчик для уведомлений, которые приходят, когда приложение ОТКРЫТО и на экране (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received:');
      print('   Message data: ${message.data}');

      if (message.notification != null) {
        print(
          '   Уведомление (Foreground): ${message.notification?.title} / ${message.notification?.body}',
        );
        // Здесь можно показать кастомный SnackBar, диалог или локальное уведомление,
        // так как система по умолчанию не показывает "шторку", когда приложение открыто.
      }
    });

    // 3. Обработчик НАЖАТИЯ на уведомление, когда приложение было свернуто (но не убито)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Пользователь нажал на уведомление из фона: ${message.messageId}');
      print('   Данные уведомления: ${message.data}');

      // Пример навигации при нажатии.
      final screen = message.data['screen'];
      if (navigatorKey.currentContext != null) {
        if (screen == 'profile') {
          GoRouter.of(navigatorKey.currentContext!).go('/profile');
        } else {
          // По умолчанию переходим на экран уведомлений
          GoRouter.of(navigatorKey.currentContext!).go('/notifications');
        }
      }
    });
  }

  // НОВЫЙ МЕТОД: Получение и отправка FCM токена на ваш бэкенд
  Future<void> sendFcmTokenToServer() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token == null) {
        print("🔥 Не удалось получить FCM токен.");
        return;
      }
      print("🔥 Ваш FCM токен: $token");

      // Отправляем токен на эндпоинт /user/notificationToken
      // Сервер ожидает параметр 'token' в URL
      await dio.post(
        '/user/notificationToken',
        queryParameters: {'token': token},
      );

      print("✅ FCM токен успешно отправлен на сервер.");
    } catch (e) {
      print("🔥 Ошибка при отправке FCM токена на сервер: $e");
    }
  }
}
