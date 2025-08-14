import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // для debugPrint
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/io.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

final appWebSocketProvider = StateNotifierProvider<AppWebSocketNotifier, bool>(
  (ref) => AppWebSocketNotifier(ref),
);

// Этот провайдер будет предоставлять поток сырых WebSocket-сообщений
final webSocketMessagesProvider = StreamProvider<dynamic>((ref) {
  final notifier = ref.watch(appWebSocketProvider.notifier);
  return notifier.messagesStream; // Выставляем поток
});

class AppWebSocketNotifier extends StateNotifier<bool> {
  // Состояние теперь просто статус 'connected' (true/false)
  AppWebSocketNotifier(this._ref) : super(false);

  final Ref _ref;
  IOWebSocketChannel? _channel;
  final StreamController<dynamic> _messageController =
      StreamController.broadcast();
  Timer? _reconnectTimer;
  bool _shouldReconnect =
      true; // Флаг для управления автоматическими переподключениями

  Stream<dynamic> get messagesStream => _messageController.stream;

  Future<void> connect() async {
    if (state) {
      // Если уже подключено (state = true)
      debugPrint('[AppWebSocket] Уже подключено, пропускаем подключение.');
      return;
    }

    // Получаем токен из SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');

    if (token == null || token.isEmpty) {
      debugPrint(
        '[AppWebSocket] Токен доступа не найден. Невозможно подключиться.',
      );
      return;
    }

    // Предполагаем, что ваш токен не требует префикса "Bearer " для WebSocket
    if (token.startsWith('Bearer ')) {
      token = token.substring(7); // Удаляем префикс "Bearer ", если он есть
    }

    try {
      final url = 'wss://app.iss-control.kz/ws?token=$token';
      debugPrint('[AppWebSocket] Подключаемся к $url');

      _channel = IOWebSocketChannel.connect(Uri.parse(url));

      _channel!.stream.listen(
        (message) {
          debugPrint('[AppWebSocket] Получено сообщение: $message');
          try {
            _messageController.add(
              jsonDecode(message),
            ); // Добавляем сырые JSON-данные в поток
          } catch (e) {
            debugPrint(
              '[AppWebSocket] Ошибка парсинга JSON: $e, сообщение: $message',
            );
          }
        },
        onDone: () {
          state = false; // Обновляем статус подключения
          debugPrint(
            '[AppWebSocket] Соединение закрыто. _shouldReconnect: $_shouldReconnect',
          );
          if (_shouldReconnect) {
            _scheduleReconnect();
          } else {
            _messageController
                .close(); // Закрываем поток, если не переподключаемся
          }
        },
        onError: (error) {
          state = false; // Обновляем статус подключения
          debugPrint(
            '[AppWebSocket] Произошла ошибка: $error. _shouldReconnect: $_shouldReconnect',
          );
          if (_shouldReconnect) {
            _scheduleReconnect();
          } else {
            _messageController.addError(error); // Добавляем ошибку в поток
            _messageController.close();
          }
        },
      );

      state = true; // Обновляем статус подключения
      debugPrint('[AppWebSocket] Соединение установлено.');
      _reconnectTimer?.cancel(); // Отменяем любые ожидающие переподключения
    } catch (e) {
      state = false; // Обновляем статус подключения
      debugPrint(
        '[AppWebSocket] Исключение при подключении: $e. Планируем переподключение...',
      );
      if (_shouldReconnect) {
        _scheduleReconnect();
      } else {
        _messageController.addError(e);
        _messageController.close();
      }
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      debugPrint('[AppWebSocket] Попытка переподключения...');
      if (_shouldReconnect) {
        // Переподключаемся только если флаг true
        connect();
      }
    });
  }

  // Метод для отправки команд (устройство-специфичные)
  void sendCommand(
    String hubId,
    String deviceId,
    Map<String, dynamic> payload,
  ) {
    if (!state || _channel == null) {
      debugPrint(
        '[AppWebSocket] Невозможно отправить команду, сокет не подключен.',
      );
      return;
    }
    final command = {
      "type": "DEVICE_COMMAND",
      "hubId": hubId,
      "details": {"deviceId": deviceId, "payload": payload},
    };
    final jsonCommand = jsonEncode(command);
    debugPrint('[AppWebSocket] Отправка команды: $jsonCommand');
    _channel!.sink.add(jsonCommand);
  }

  // Метод для отправки команды SHARE_DEVICE_DATA
  void sendShareDeviceDataCommand(String hubId, String deviceId) {
    if (!state || _channel == null) {
      debugPrint(
        '[AppWebSocket] Невозможно отправить команду SHARE_DEVICE_DATA, сокет не подключен.',
      );
      return;
    }
    final command = {
      "type": "SHARE_DEVICE_DATA",
      "hubId": hubId,
      "details": {"deviceId": deviceId},
    };
    final jsonCommand = jsonEncode(command);
    debugPrint(
      '[AppWebSocket] Отправка команды SHARE_DEVICE_DATA: $jsonCommand',
    );
    _channel!.sink.add(jsonCommand);
  }

  @override
  void dispose() {
    debugPrint('[AppWebSocket] Закрытие соединения...');
    _shouldReconnect =
        false; // Предотвращаем дальнейшие автоматические переподключения
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _messageController.close();
    super.dispose();
  }
}
