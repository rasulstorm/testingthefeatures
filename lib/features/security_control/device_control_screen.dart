// lib/features/device_state/websocket_device_provider.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/io.dart';

/// Хранит актуальное состояние одного устройства
final webSocketProvider =
    StateNotifierProvider<WebSocketNotifier, Map<String, dynamic>>(
      (ref) => WebSocketNotifier(),
    );

class WebSocketNotifier extends StateNotifier<Map<String, dynamic>> {
  WebSocketNotifier() : super({});

  IOWebSocketChannel? _channel;
  bool _connected = false;
  bool get connected => _connected;

  Timer? _reconnectTimer;

  String? _hubId;
  String? _deviceKey; // то, чем ты фильтруешь входящие (id / friendly)
  String? _token; // JWT без Bearer

  /// Подключение к WS.
  /// ВАЖНО: теперь **в URL добавляем hubId**.
  ///
  /// Прежняя сигнатура сохранена, чтобы не ломать вызовы:
  /// connect(hubId, deviceId, token: token)
  Future<void> connect(
    String hubId,
    String deviceName, {
    required String token,
  }) async {
    if (_connected) {
      debugPrint('[DeviceWS] Already connected, skip');
      return;
    }

    _hubId = hubId;
    _deviceKey = deviceName.trim();
    _token = token.startsWith('Bearer ') ? token.substring(7) : token;

    try {
      final uri = Uri(
        scheme: 'wss',
        host: 'stage-app.iss-control.kz',
        path: '/ws',
        queryParameters: {
          'token': _token!,
          'hubId': _hubId!, // <<< КРИТИЧЕСКОЕ ДОБАВЛЕНИЕ
        },
      );
      debugPrint('[DeviceWS] URI: $uri');

      _channel = IOWebSocketChannel.connect(uri);

      // Сразу подписываемся на конкретное устройство,
      // если бэкенд шлёт данные только после SHARE.
      _sendShareIfPossible();

      _channel!.stream.listen(
        (message) {
          debugPrint('[DeviceWS] RX: $message');
          try {
            final data = jsonDecode(message);
            // Подстрахуемся по типу и по ключам устройства
            final typ = data['type'] ?? data['messageType'];
            final devId = (data['deviceId'] ?? data['deviceName'])?.toString();

            if (typ == 'DEVICE_STATE_UPDATE' && devId != null) {
              if (_deviceKeyMatches(devId)) {
                state = Map<String, dynamic>.from(data['payload'] ?? {});
                debugPrint('[DeviceWS] State updated for $_deviceKey: $state');
              } else {
                debugPrint(
                  '[DeviceWS] Ignored message for $devId (want $_deviceKey)',
                );
              }
            }
          } catch (e) {
            debugPrint('[DeviceWS] JSON parse error: $e');
          }
        },
        onDone: () {
          _connected = false;
          debugPrint('[DeviceWS] Closed. Reconnect in 5s');
          _scheduleReconnect();
        },
        onError: (error) {
          _connected = false;
          debugPrint('[DeviceWS] Error: $error. Reconnect in 5s');
          _scheduleReconnect();
        },
        cancelOnError: true,
      );

      _connected = true;
      debugPrint('[DeviceWS] Connected for device=$_deviceKey');
    } catch (e) {
      _connected = false;
      debugPrint('[DeviceWS] Connect failed: $e. Reconnect in 5s');
      _scheduleReconnect();
    }
  }

  bool _deviceKeyMatches(String incoming) {
    if (_deviceKey == null || _deviceKey!.isEmpty) return false;
    final a = _deviceKey!.trim().toLowerCase();
    final b = incoming.trim().toLowerCase();
    return a == b;
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    // Переиспользуем сохранённые параметры
    if (_hubId == null || _token == null || _deviceKey == null) return;

    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      debugPrint('[DeviceWS] Reconnecting…');
      connect(_hubId!, _deviceKey!, token: _token!);
    });
  }

  /// Отправка SHARE на сервер (если сокет уже поднят)
  void _sendShareIfPossible() {
    if (_channel == null || !_connected) return;
    if (_hubId == null || _deviceKey == null) return;

    final msg = jsonEncode({
      'type': 'SHARE_DEVICE_DATA',
      'hubId': _hubId!,
      'details': {'deviceName': _deviceKey!},
    });
    _channel!.sink.add(msg);
    debugPrint('[DeviceWS] TX SHARE_DEVICE_DATA hub=$_hubId key=$_deviceKey');
  }

  /// Команда конкретному устройству (опционально; можно не юзать)
  void sendCommand(
    String hubId,
    String deviceKey,
    Map<String, dynamic> payload,
  ) {
    if (!_connected || _channel == null) {
      debugPrint('[DeviceWS] Cannot send command, WS not connected');
      return;
    }
    final msg = jsonEncode({
      'type': 'DEVICE_COMMAND',
      'hubId': hubId,
      'details': {
        // серверная сторона ожидает deviceName (ieee)
        'deviceName': deviceKey,
        'payload': payload,
      },
    });
    _channel!.sink.add(msg);
    debugPrint('[DeviceWS] TX DEVICE_COMMAND: $msg');
  }

  @override
  void dispose() {
    debugPrint('[DeviceWS] dispose');
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
