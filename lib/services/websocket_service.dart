// lib/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/io.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appWebSocketProvider = StateNotifierProvider<AppWebSocketNotifier, bool>(
  (ref) => AppWebSocketNotifier(ref),
);

// (опционально) общий поток входящих сообщений
final webSocketMessagesProvider = StreamProvider<dynamic>((ref) {
  final notifier = ref.watch(appWebSocketProvider.notifier);
  return notifier.messagesStream;
});

class AppWebSocketNotifier extends StateNotifier<bool> {
  AppWebSocketNotifier(this._ref) : super(false);

  final Ref _ref;
  IOWebSocketChannel? _channel;
  final _messageController = StreamController<dynamic>.broadcast();
  Timer? _reconnectTimer;
  bool _shouldReconnect = true;
  String? _hubId;

  Stream<dynamic> get messagesStream => _messageController.stream;

  Future<void> connect({required String hubId}) async {
    if (state) {
      debugPrint('[AppWS] already connected, skip');
      return;
    }
    if (hubId.isEmpty) {
      debugPrint('[AppWS] hubId is empty — abort connect');
      return;
    }
    _hubId = hubId;

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    if (token == null || token.isEmpty) {
      debugPrint('[AppWS] accessToken not found');
      return;
    }
    if (token.startsWith('Bearer ')) token = token.substring(7);

    try {
      final uri = Uri(
        scheme: 'wss',
        host: 'stage-app.iss-control.kz',
        path: '/ws',
        queryParameters: {'token': token, 'hubId': _hubId!},
      );
      debugPrint('[AppWS] URI: $uri');

      _channel = IOWebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (message) {
          debugPrint('[AppWS] RX: $message');
          try {
            _messageController.add(jsonDecode(message));
          } catch (e) {
            debugPrint('[AppWS] JSON parse error: $e; msg=$message');
          }
        },
        onDone: () {
          state = false;
          debugPrint('[AppWS] closed. reconnect=$_shouldReconnect');
          if (_shouldReconnect) {
            _scheduleReconnect();
          } else {
            _messageController.close();
          }
        },
        onError: (error) {
          state = false;
          debugPrint('[AppWS] error: $error. reconnect=$_shouldReconnect');
          if (_shouldReconnect) {
            _scheduleReconnect();
          } else {
            _messageController.addError(error);
            _messageController.close();
          }
        },
        cancelOnError: true,
      );

      state = true;
      _reconnectTimer?.cancel();
      debugPrint('[AppWS] connected');
    } catch (e) {
      state = false;
      debugPrint('[AppWS] connect exception: $e');
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
      if (_shouldReconnect && _hubId != null && _hubId!.isNotEmpty) {
        debugPrint('[AppWS] reconnecting…');
        connect(hubId: _hubId!);
      }
    });
  }

  void sendCommand(
    String hubId,
    String deviceId,
    Map<String, dynamic> payload,
  ) {
    if (!state || _channel == null) {
      debugPrint('[AppWS] cannot send, socket not connected');
      return;
    }
    final command = {
      "type": "DEVICE_COMMAND",
      "hubId": hubId,
      "details": {"deviceId": deviceId, "payload": payload},
    };
    _channel!.sink.add(jsonEncode(command));
    debugPrint('[AppWS] TX DEVICE_COMMAND: $command');
  }

  void sendShareDeviceDataCommand(String hubId, String deviceId) {
    if (!state || _channel == null) {
      debugPrint('[AppWS] cannot share, socket not connected');
      return;
    }
    final command = {
      "type": "SHARE_DEVICE_DATA",
      "hubId": hubId,
      "details": {"deviceId": deviceId},
    };
    _channel!.sink.add(jsonEncode(command));
    debugPrint('[AppWS] TX SHARE_DEVICE_DATA: $command');
  }

  void disconnect() {
    debugPrint('[AppWS] manual disconnect');
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    state = false;
  }

  @override
  void dispose() {
    debugPrint('[AppWS] dispose');
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _messageController.close();
    super.dispose();
  }
}
