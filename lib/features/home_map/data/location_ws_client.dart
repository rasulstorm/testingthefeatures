import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:ISS/core/network/auth_service.dart';
import 'package:ISS/features/friends/domain/friends_models.dart';
import 'package:ISS/core/network/dio_provider.dart'
    show DioConfig, ServerUnavailableException;

class LocationWsClient {
  LocationWsClient({required AuthService authService, Uri? endpoint})
    : _authService = authService,
      _endpoint = endpoint ?? _buildDefaultEndpoint();

  final AuthService _authService;
  final Uri _endpoint;

  final _friendsController =
      StreamController<List<FriendCoordinate>>.broadcast();
  final _statusController = StreamController<bool>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Stream<List<FriendCoordinate>> get friendsStream => _friendsController.stream;
  Stream<bool> get statusStream => _statusController.stream;

  double? _lastLatitude;
  double? _lastLongitude;
  Duration _backoff = const Duration(seconds: 1);

  Future<void> connect() async {
    if (_isConnected) return;
    _reconnectTimer?.cancel();

    try {
      final token = await _obtainToken();
      if (token == null) {
        throw ServerUnavailableException('friends_error_unauthorized');
      }

      final uri = _endpoint.replace(
        queryParameters: {..._endpoint.queryParameters, 'token': token},
      );

      debugPrint('[LocationWs] connecting to $uri');
      _channel = IOWebSocketChannel.connect(
        uri,
        pingInterval: const Duration(seconds: 30),
      );

      _subscription = _channel!.stream.listen(
        (event) => _handleMessage(event),
        onDone: _handleDisconnect,
        onError:
            (error, stack) => _handleDisconnect(error: error, stack: stack),
        cancelOnError: true,
      );

      _setConnected(true);
      _backoff = const Duration(seconds: 1);
      _startHeartbeat();
      _sendLastLocation();
    } catch (e, stack) {
      debugPrint('[LocationWs] connect failed: $e\n$stack');
      _scheduleReconnect();
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _setConnected(false, notifyEvenIfSame: true);
  }

  void dispose() {
    disconnect();
    _friendsController.close();
    _statusController.close();
  }

  void updateSelfLocation(double latitude, double longitude) {
    _lastLatitude = latitude;
    _lastLongitude = longitude;
    _sendLastLocation();
  }

  Future<String?> _obtainToken() async {
    String? token = await _authService.getAccessToken();
    if (token == null || token.isEmpty) {
      token = await _authService.refreshAccessToken();
    }
    if (token == null || token.isEmpty) return null;
    return token.startsWith('Bearer ') ? token.substring(7) : token;
  }

  void _handleMessage(dynamic event) {
    try {
      if (event is! String) return;
      final decoded = jsonDecode(event);
      if (decoded is List) {
        final result =
            decoded
                .whereType<Map<String, dynamic>>()
                .map((e) => FriendCoordinate.fromJson(e))
                .toList();
        _friendsController.add(result);
      }
    } catch (e, stack) {
      debugPrint('[LocationWs] failed to parse message: $e\n$stack');
    }
  }

  void _handleDisconnect({Object? error, StackTrace? stack}) {
    debugPrint('[LocationWs] disconnected: $error');
    _setConnected(false, notifyEvenIfSame: true);
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    _heartbeatTimer?.cancel();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null) return;
    _setConnected(false, notifyEvenIfSame: true);
    _reconnectTimer = Timer(_backoff, () {
      _reconnectTimer = null;
      connect();
    });
    final nextSeconds = (_backoff.inSeconds * 2).clamp(1, 30);
    _backoff = Duration(
      seconds: nextSeconds is int ? nextSeconds : nextSeconds.toInt(),
    );
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendLastLocation();
    });
  }

  void _sendLastLocation() {
    if (!_isConnected || _channel == null) return;
    if (_lastLatitude == null || _lastLongitude == null) return;
    final payload = jsonEncode({
      'latitude': _lastLatitude,
      'longitude': _lastLongitude,
    });
    try {
      _channel!.sink.add(payload);
    } catch (e, stack) {
      debugPrint('[LocationWs] send error: $e\n$stack');
    }
  }

  void _setConnected(bool value, {bool notifyEvenIfSame = false}) {
    if (_isConnected == value && !notifyEvenIfSame) return;
    _isConnected = value;
    if (!_statusController.isClosed) {
      _statusController.add(_isConnected);
    }
  }

  static Uri _buildDefaultEndpoint() {
    final base = Uri.parse(DioConfig.baseUrl);
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';
    return Uri(
      scheme: scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: '/ws/location',
    );
  }
}
