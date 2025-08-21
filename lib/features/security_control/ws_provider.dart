import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:ISS/core/network/auth_service.dart';

class WebSocketState {
  final bool isConnected;
  final Map<String, Map<String, dynamic>> deviceData;

  WebSocketState({required this.isConnected, required this.deviceData});

  WebSocketState copyWith({
    bool? isConnected,
    Map<String, Map<String, dynamic>>? deviceData,
  }) {
    return WebSocketState(
      isConnected: isConnected ?? this.isConnected,
      deviceData: deviceData ?? this.deviceData,
    );
  }
}

final webSocketNotifierProvider =
    StateNotifierProvider<WebSocketNotifier, WebSocketState>((ref) {
      return WebSocketNotifier(AuthService());
    });

class WebSocketNotifier extends StateNotifier<WebSocketState> {
  final AuthService _authService;
  WebSocketNotifier(this._authService)
    : super(WebSocketState(isConnected: false, deviceData: {}));

  WebSocketChannel? _channel;
  StreamSubscription? _listener;
  Timer? _reconnectTimer; // Таймер для переподключения
  Timer? _refreshTimer; // Таймер для проактивного обновления токена

  final String _wsBaseUrl = 'wss://app.iss-control.kz'; // Базовый URL WebSocket

  Future<void> connect() async {
    // Если уже подключены или процесс подключения запущен, выходим
    if (state.isConnected) {
      // Проверяем только isConnected, так как _channel может быть null при разрыве
      dev.log('WebSocket: Already connected.');
      return;
    }

    _reconnectTimer
        ?.cancel(); // Отменяем любой существующий таймер переподключения
    _refreshTimer
        ?.cancel(); // Отменяем любой существующий таймер обновления токена

    try {
      String? token = await _authService.getAccessToken();

      // Если токен отсутствует или пустой, пытаемся его обновить
      if (token == null || token.isEmpty) {
        dev.log(
          'WebSocket: Access token not found or empty. Attempting to refresh token for WebSocket...',
        );
        try {
          token =
              await _authService
                  .refreshAccessToken(); // Пытаемся обновить токен
          dev.log(
            'WebSocket: Successfully refreshed token for WebSocket connection.',
          );
        } catch (e, st) {
          dev.log(
            'WebSocket: Failed to refresh token for WS connection: $e\n$st',
          );
          state = state.copyWith(isConnected: false);
          await _authService.clearTokens(); // Очищаем токены при неудаче
          return;
        }
      }

      if (token == null || token.isEmpty) {
        dev.log(
          'WebSocket: No valid token available after all attempts. Cannot connect.',
        );
        state = state.copyWith(isConnected: false);
        return;
      }

      // Токен из AuthService.getAccessToken() уже "чистый" (без "Bearer ").
      // Просто используем его напрямую.
      final uri = Uri.parse('$_wsBaseUrl/ws?token=$token');
      dev.log('WebSocket: Attempting to connect to $uri');

      _channel = WebSocketChannel.connect(uri);
      state = state.copyWith(
        isConnected: true,
      ); // Обновляем состояние: теперь подключено

      // Планируем проактивное обновление токена сразу после успешного подключения
      _scheduleTokenRefresh(token);

      _listener = _channel!.stream.listen(
        (message) {
          dev.log('WebSocket: Received message: $message');
          _processWebSocketMessage(message);
        },
        onDone: () {
          dev.log(
            'WebSocket: Connection done. Scheduling reconnect in 5 seconds...',
          );
          state = state.copyWith(
            isConnected: false,
          ); // Обновляем состояние: отключено
          _channel = null; // Очищаем канал
          _listener?.cancel(); // Отменяем слушателя
          _refreshTimer?.cancel(); // Отменяем таймер обновления при отключении
          _reconnectTimer = Timer(
            const Duration(seconds: 5),
            connect,
          ); // Планируем переподключение
        },
        onError: (error, stackTrace) {
          dev.log('WebSocket: Error: $error\nStackTrace: $stackTrace');
          state = state.copyWith(
            isConnected: false,
          ); // Обновляем состояние: отключено
          _channel = null; // Очищаем канал
          _listener?.cancel(); // Отменяем слушателя
          _refreshTimer?.cancel(); // Отменяем таймер обновления при ошибке

          // Если ошибка связана с токеном (401), попытаемся обновить
          if (error.toString().contains('401') ||
              error.toString().toLowerCase().contains('jwt expired') ||
              error.toString().contains(
                'WebSocketChannelException: WebSocket connection failed',
              )) {
            dev.log(
              'WebSocket: Token expired/invalid or connection failed. Attempting to refresh token before reconnect.',
            );
            // Вызываем connect(), который сам попытается обновить токен
            _reconnectTimer = Timer(const Duration(seconds: 5), connect);
          } else {
            // Для других ошибок просто переподключаемся
            dev.log('WebSocket: Other error. Reconnecting in 5 seconds...');
            _reconnectTimer = Timer(const Duration(seconds: 5), connect);
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      dev.log('WebSocket: Failed to connect: $e');
      state = state.copyWith(isConnected: false); // Обновляем состояние
      _channel = null;
      _listener?.cancel();
      _refreshTimer
          ?.cancel(); // Отменяем таймер обновления при ошибке подключения
      _reconnectTimer = Timer(
        const Duration(seconds: 5),
        connect,
      ); // Планируем переподключение даже при неудачной первой попытке
    }
  }

  Future<void> _scheduleTokenRefresh(String currentToken) async {
    _refreshTimer?.cancel(); // Отменяем любой существующий таймер обновления

    try {
      final parts = currentToken.split('.');
      if (parts.length != 3) {
        dev.log('WebSocket: Invalid JWT format. Cannot schedule refresh.');
        return;
      }

      // Декодируем payload JWT для получения 'exp'
      // base64Url.decode требует отбивки, поэтому base64Url.normalize
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = payload['exp'] as int?; // 'exp' в секундах

      if (exp == null) {
        dev.log(
          'WebSocket: JWT does not contain expiration time. Cannot schedule proactive refresh.',
        );
        return;
      }

      final expirationDateTime = DateTime.fromMillisecondsSinceEpoch(
        exp * 1000,
      );
      final now = DateTime.now();
      final durationUntilExpiration = expirationDateTime.difference(now);

      const refreshBuffer = Duration(
        seconds: 60,
      ); // Обновляем за 60 секунд до истечения

      if (durationUntilExpiration > refreshBuffer) {
        final refreshIn = durationUntilExpiration - refreshBuffer;
        dev.log(
          'WebSocket: Scheduling token refresh in ${refreshIn.inSeconds} seconds (at ${expirationDateTime.subtract(refreshBuffer)})',
        );
        _refreshTimer = Timer(refreshIn, () async {
          dev.log('WebSocket: Proactively refreshing token...');
          try {
            await _authService.refreshAccessToken();
            dev.log('WebSocket: Proactive token refresh successful.');
            // После обновления получаем новый токен и планируем следующее обновление для него
            final newToken = await _authService.getAccessToken();
            if (newToken != null) {
              _scheduleTokenRefresh(
                newToken,
              ); // Перепланируем для нового токена
            }
          } catch (e, st) {
            dev.log('WebSocket: Proactive token refresh failed: $e\n$st');
            // Если проактивное обновление не удалось, очищаем токены.
            await _authService.clearTokens();
          }
        });
      } else {
        dev.log(
          'WebSocket: Token already expired or expires too soon. Not scheduling proactive refresh, relying on reconnect logic.',
        );
      }
    } catch (e, st) {
      dev.log('WebSocket: Error scheduling token refresh: $e\n$st');
    }
  }

  void disconnect() {
    dev.log('WebSocket: Disconnecting...');
    _reconnectTimer?.cancel();
    _refreshTimer?.cancel();
    _listener?.cancel();
    _channel?.sink.close();
    _channel = null; // Очищаем канал при дисконнекте
    state = state.copyWith(isConnected: false); // Обновляем состояние
    dev.log('WebSocket: Disconnected.');
  }

  void _processWebSocketMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message);

      // Обработка ответов на команды или других служебных сообщений
      if (data.containsKey('correlationId') &&
          (data.containsKey('success') || data.containsKey('message'))) {
        dev.log(
          'WebSocket: Received response for correlationId ${data['correlationId']}: ${data['message'] ?? 'No message'}. Success: ${data['success']}',
        );
        return;
      }

      if (data.containsKey('deviceId')) {
        final String deviceIdFromWS = data['deviceId'];

        // Создаем новую карту параметров, исключая 'deviceId' и 'correlationId'
        final Map<String, dynamic> parameters =
            Map<String, dynamic>.from(data)
              ..remove('deviceId')
              ..remove('correlationId');

        // Обновляем состояние, создавая новую карту deviceData
        state = state.copyWith(
          deviceData: {...state.deviceData, deviceIdFromWS: parameters},
        );
        dev.log(
          'WebSocket: Updated state for device $deviceIdFromWS: $parameters',
        );
        return;
      }

      // Обработка других типов сообщений
      final String? messageType = data['messageType'] ?? data['type'];
      if (messageType != null) {
        if (messageType == 'COMMAND_RESPONSE') {
          dev.log('WebSocket: Received command response: $data');
        } else {
          dev.log(
            'WebSocket: Received a known message type "$messageType" but not handled: $message',
          );
        }
      } else {
        dev.log('WebSocket: Received unrecognized message format: $message');
      }
    } catch (e, st) {
      dev.log('WebSocket: Error processing message: $e\nStackTrace: $st');
    }
  }

  // Отправка запроса на получение данных по конкретному устройству
  void sendShareDeviceData(String hubId, String deviceName) {
    if (_channel != null && state.isConnected) {
      final message = jsonEncode({
        "type": "SHARE_DEVICE_DATA",
        "hubId": hubId,
        "details": {"deviceName": deviceName},
      });
      _channel!.sink.add(message);
      dev.log(
        'WebSocket: Отправлен SHARE_DEVICE_DATA запрос для hubId: $hubId, deviceName: $deviceName',
      );
    } else {
      dev.log(
        'WebSocket: Нет подключения. Невозможно отправить SHARE_DEVICE_DATA запрос для $deviceName.',
      );
    }
  }

  // Отправка команды управления устройством
  // Отправка команды управления устройством
  void sendDeviceCommand(
    String commandHubId, // hubId
    String deviceIdentifier, // Может быть friendlyName или deviceId
    Map<String, dynamic> commandPayload,
  ) {
    if (_channel != null && state.isConnected) {
      // Если имя пустое или это "unknown_friendly_name" — используем как идентификатор deviceId
      final safeDeviceId =
          (deviceIdentifier.isEmpty || deviceIdentifier.startsWith('unknown_'))
              ? _findDeviceId(deviceIdentifier)
              : deviceIdentifier;

      final message = jsonEncode({
        "type": "DEVICE_COMMAND",
        "hubId": commandHubId,
        "details": {"deviceName": safeDeviceId, "payload": commandPayload},
      });

      _channel!.sink.add(message);
      dev.log(
        'WebSocket: Sent DEVICE_COMMAND to hubId: $commandHubId, deviceName: $safeDeviceId with payload: $commandPayload',
      );
    } else {
      dev.log(
        'WebSocket: Not connected. Cannot send DEVICE_COMMAND to device ID: $deviceIdentifier',
      );
    }
  }

  // Вспомогательная функция — находит ID по имени, либо возвращает исходное
  String _findDeviceId(String maybeName) {
    // Ищем по карте state.deviceData
    final foundKey = state.deviceData.keys.firstWhere(
      (key) => key.isNotEmpty,
      orElse: () => maybeName,
    );
    return foundKey;
  }

  // Метод для локального обновления состояния устройства (для UI плавности)
  void updateDeviceLocalState(
    String deviceName,
    Map<String, dynamic> newParameters,
  ) {
    final Map<String, Map<String, dynamic>> updatedDeviceData =
        Map<String, Map<String, dynamic>>.from(state.deviceData);

    final Map<String, dynamic> currentDeviceParams = Map<String, dynamic>.from(
      updatedDeviceData[deviceName] ?? {},
    );
    currentDeviceParams.addAll(newParameters);

    updatedDeviceData[deviceName] = currentDeviceParams;

    state = state.copyWith(deviceData: updatedDeviceData);
    dev.log(
      'WebSocket: Locally updated state for device $deviceName: $newParameters',
    );
  }

  @override
  void dispose() {
    dev.log('WebSocket: Disposing notifier...');
    disconnect(); // Вызываем disconnect для правильного закрытия всех ресурсов
    super.dispose();
  }
}
