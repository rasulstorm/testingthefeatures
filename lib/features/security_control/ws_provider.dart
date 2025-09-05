// lib/features/security_control/ws_provider.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:ISS/core/network/auth_service.dart';

/// Состояние WebSocket: флаг подключения + карта live-данных по устройствам.
class WebSocketState {
  final bool isConnected;

  /// Live-состояния устройств по нормализованному ключу (lowercase+trim).
  final Map<String, Map<String, dynamic>> deviceData;

  const WebSocketState({required this.isConnected, required this.deviceData});

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

/// Класс-нотификатор для управления WS-соединением (legacy слой).
class WebSocketNotifier extends StateNotifier<WebSocketState> {
  final AuthService _authService;
  WebSocketNotifier(this._authService)
    : super(const WebSocketState(isConnected: false, deviceData: {}));

  WebSocketChannel? _channel;
  StreamSubscription? _listener;
  Timer? _reconnectTimer;
  Timer? _refreshTimer;

  // Хост WS
  final String _wsHost = 'stage-app.iss-control.kz';

  // Текущий hubId, с которым держим соединение
  String? _hubId;

  // ===== Helpers (нормализация ключей устройств) =====

  static String _normKey(String? s) => (s ?? '').trim().toLowerCase();

  /// Пытаемся извлечь ключ устройства из входящего сообщения.
  /// Берём первый из кандидатов, нормализуем.
  static String? _extractDeviceKey(Map<String, dynamic> data) {
    final candidates = <String?>[
      data['deviceId']?.toString(),
      data['deviceName']?.toString(),
      data['friendlyName']?.toString(),
      (data['device'] is Map ? (data['device']['ieeeAddr']?.toString()) : null),
      data['ieeeAddr']?.toString(),
      data['id']?.toString(),
    ];
    for (final raw in candidates) {
      final n = _normKey(raw);
      if (n.isNotEmpty) return n;
    }
    return null;
  }

  /// Если по переданному идентификатору уже есть live-данные — используем
  /// этот ключ, иначе — возвращаем нормализованную строку как есть.
  String _resolveDeviceKey(String userProvided) {
    final want = _normKey(userProvided);
    if (want.isEmpty) return want;
    if (state.deviceData.containsKey(want)) return want;

    final hit = state.deviceData.keys.firstWhere(
      (k) => _normKey(k) == want,
      orElse: () => '',
    );
    return hit.isNotEmpty ? hit : want;
  }

  // ===== Очередь SHARE подписок (по hubId) =====

  /// Очередь подписок, которые нужно отправить при подключении/реконнекте.
  final Map<String, Set<String>> _pendingShares = {}; // hubId -> {deviceKey}

  void _enqueueShare(String hubId, String normKey) {
    _pendingShares.putIfAbsent(hubId, () => <String>{}).add(normKey);
  }

  void _flushPendingShares() {
    if (!state.isConnected) return;
    _pendingShares.forEach((hubId, keys) {
      for (final key in keys) {
        final msg = jsonEncode({
          "type": "SHARE_DEVICE_DATA",
          "hubId": hubId,
          "details": {"deviceName": key},
        });
        _sendRaw(msg);
        dev.log('[LegacyWS] flushed SHARE hub=$hubId key=$key');
      }
    });
  }

  // ===== Жизненный цикл соединения =====

  /// Подключение к WS. Требует валидный hubId — он пойдёт в query.
  Future<void> connect(String hubId) async {
    if (state.isConnected) {
      dev.log('[LegacyWS] already connected');
      return;
    }
    if (hubId.isEmpty) {
      dev.log('[LegacyWS] hubId empty — abort');
      return;
    }
    _hubId = hubId;

    _reconnectTimer?.cancel();
    _refreshTimer?.cancel();

    try {
      String? token = await _authService.getAccessToken();
      if (token == null || token.isEmpty) {
        dev.log('[LegacyWS] no token, try refresh…');
        try {
          token = await _authService.refreshAccessToken();
          dev.log('[LegacyWS] token refreshed');
        } catch (e, st) {
          dev.log('[LegacyWS] refresh failed: $e\n$st');
          state = state.copyWith(isConnected: false);
          await _authService.clearTokens();
          return;
        }
      }
      if (token == null || token.isEmpty) {
        dev.log('[LegacyWS] still no token — abort');
        state = state.copyWith(isConnected: false);
        return;
      }

      // В query нужен "чистый" JWT без префикса Bearer
      final cleanToken =
          token.startsWith('Bearer ') ? token.substring(7) : token;

      final uri = Uri(
        scheme: 'wss',
        host: _wsHost,
        path: '/ws',
        queryParameters: {
          'token': cleanToken,
          'hubId': _hubId!, // <<< ОБЯЗАТЕЛЬНО
        },
      );
      dev.log('[LegacyWS] URI: $uri');

      _channel = WebSocketChannel.connect(uri);

      state = state.copyWith(isConnected: true);
      _scheduleTokenRefresh(cleanToken);

      // Сразу отправляем отложенные SHARE
      _flushPendingShares();

      _listener = _channel!.stream.listen(
        (message) {
          dev.log('[LegacyWS] RX: $message');
          _processWebSocketMessage(message);
        },
        onDone: () {
          dev.log('[LegacyWS] onDone -> reconnect in 5s');
          _cleanup();
          _reconnectTimer = Timer(const Duration(seconds: 5), () {
            if (_hubId != null) connect(_hubId!);
          });
        },
        onError: (error, st) {
          dev.log('[LegacyWS] onError: $error\n$st');
          _cleanup();
          _reconnectTimer = Timer(const Duration(seconds: 5), () {
            if (_hubId != null) connect(_hubId!);
          });
        },
        cancelOnError: true,
      );
    } catch (e) {
      dev.log('[LegacyWS] connect() failed: $e');
      _cleanup();
      _reconnectTimer = Timer(const Duration(seconds: 5), () {
        if (_hubId != null) connect(_hubId!);
      });
    }
  }

  void _cleanup() {
    state = state.copyWith(isConnected: false);
    _channel = null;
    _listener?.cancel();
    _refreshTimer?.cancel();
  }

  /// Плановый рефреш токена по exp (если это JWT), с буфером.
  Future<void> _scheduleTokenRefresh(String currentToken) async {
    _refreshTimer?.cancel();
    try {
      final parts = currentToken.split('.');
      if (parts.length != 3) {
        dev.log('[LegacyWS] invalid JWT, skip proactive refresh');
        return;
      }
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = payload['exp'] as int?;
      if (exp == null) return;

      final expiration = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();
      final delta = expiration.difference(now);
      const buffer = Duration(seconds: 60);

      if (delta > buffer) {
        final when = delta - buffer;
        dev.log('[LegacyWS] schedule token refresh in ${when.inSeconds}s');
        _refreshTimer = Timer(when, () async {
          dev.log('[LegacyWS] proactive token refresh…');
          try {
            await _authService.refreshAccessToken();
            final newToken = await _authService.getAccessToken();
            if (newToken != null) _scheduleTokenRefresh(newToken);
          } catch (e, st) {
            dev.log('[LegacyWS] proactive refresh failed: $e\n$st');
            await _authService.clearTokens();
          }
        });
      } else {
        dev.log('[LegacyWS] token expires soon, rely on reconnect');
      }
    } catch (e, st) {
      dev.log('[LegacyWS] schedule refresh error: $e\n$st');
    }
  }

  /// Ручное отключение.
  void disconnect() {
    dev.log('[LegacyWS] manual disconnect');
    _reconnectTimer?.cancel();
    _refreshTimer?.cancel();
    _listener?.cancel();
    _channel?.sink.close();
    _channel = null;
    state = state.copyWith(isConnected: false);
  }

  // ===== RX обработка =====

  void _processWebSocketMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message);

      // Ответы на команды
      if (data.containsKey('correlationId') &&
          (data.containsKey('success') || data.containsKey('message'))) {
        dev.log(
          '[LegacyWS] response corrId=${data['correlationId']} '
          'success=${data['success']} msg=${data['message']}',
        );
        return;
      }

      // Live-апдейт устройства
      final key = _extractDeviceKey(data);
      if (key != null) {
        final params =
            Map<String, dynamic>.from(data)
              ..remove('deviceId')
              ..remove('deviceName')
              ..remove('friendlyName')
              ..remove('ieeeAddr')
              ..remove('id')
              ..remove('correlationId')
              ..remove('type')
              ..remove('messageType');

        final prev = state.deviceData[key] ?? const <String, dynamic>{};
        final merged = {...prev, ...params};

        state = state.copyWith(deviceData: {...state.deviceData, key: merged});
        dev.log('[LegacyWS] live [$key] => $merged');
        return;
      }

      final type = data['messageType'] ?? data['type'];
      if (type != null) {
        dev.log('[LegacyWS] message type "$type" (no handler)');
      } else {
        dev.log('[LegacyWS] unknown message $message');
      }
    } catch (e, st) {
      dev.log('[LegacyWS] RX parse error: $e\n$st');
    }
  }

  // ===== TX helpers =====

  void _sendRaw(String json) {
    if (_channel != null && state.isConnected) {
      _channel!.sink.add(json);
    } else {
      dev.log('[LegacyWS] _sendRaw while disconnected (ignored)');
    }
  }

  /// Публичный API: подписаться на live-данные конкретного устройства (id/friendly/ieee).
  void sendShareDeviceData(String hubId, String deviceNameOrId) {
    final key = _normKey(deviceNameOrId);
    if (key.isEmpty) return;

    _enqueueShare(hubId, key);

    if (_channel != null && state.isConnected) {
      final msg = jsonEncode({
        "type": "SHARE_DEVICE_DATA",
        "hubId": hubId,
        "details": {"deviceName": key},
      });
      _sendRaw(msg);
      dev.log('[LegacyWS] SHARE sent hub=$hubId key=$key');
    } else {
      dev.log('[LegacyWS] queued SHARE hub=$hubId key=$key (flush on connect)');
    }
  }

  /// Отправить команду устройству.
  /// В details кладём deviceName (ключ), payload — как есть.
  void sendDeviceCommand(
    String hubId,
    String deviceIdentifier, // может быть ieeeAddr, friendlyName и т.д.
    Map<String, dynamic> commandPayload,
  ) {
    if (_channel == null || !state.isConnected) {
      dev.log(
        '[LegacyWS] not connected, skip DEVICE_COMMAND to "$deviceIdentifier"',
      );
      return;
    }

    final key = _resolveDeviceKey(deviceIdentifier);

    final msg = jsonEncode({
      "type": "DEVICE_COMMAND",
      "hubId": hubId,
      "details": {"deviceName": key, "payload": commandPayload},
    });

    _sendRaw(msg);
    dev.log(
      '[LegacyWS] DEVICE_COMMAND hub=$hubId key=$key payload=$commandPayload',
    );
  }

  /// Локально обновить состояние девайса (для мгновенного UI без ожидания ответа).
  void updateDeviceLocalState(
    String deviceNameOrId,
    Map<String, dynamic> newParameters,
  ) {
    final key = _resolveDeviceKey(deviceNameOrId);
    final updated = Map<String, Map<String, dynamic>>.from(state.deviceData);
    final current = Map<String, dynamic>.from(updated[key] ?? {});
    current.addAll(newParameters);
    updated[key] = current;
    state = state.copyWith(deviceData: updated);
    dev.log('[LegacyWS] local update [$key] => $newParameters');
  }

  @override
  void dispose() {
    dev.log('[LegacyWS] dispose');
    disconnect();
    super.dispose();
  }
}
