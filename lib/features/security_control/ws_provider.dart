import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // для debugPrint
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/io.dart';

final webSocketProvider = StateNotifierProvider<WebSocketNotifier, Map<String, dynamic>>(
  (ref) => WebSocketNotifier(),
);

class WebSocketNotifier extends StateNotifier<Map<String, dynamic>> {
  WebSocketNotifier() : super({});

  late IOWebSocketChannel _channel;
  bool _connected = false;
  bool get connected => _connected;

  Timer? _reconnectTimer;

  Future<void> connect(String hubId, String deviceName, {required String token}) async {
    if (_connected) {
      debugPrint('[WebSocket] Already connected, skipping connect.');
      return;
    }

    try {
      final url = 'wss://cms.iss-control.kz:8443/ws?token=$token';
      debugPrint('[WebSocket] Connecting to $url');

      _channel = IOWebSocketChannel.connect(Uri.parse(url));

      _channel.stream.listen(
        (message) {
          debugPrint('[WebSocket] Received message: $message');
          final data = jsonDecode(message);
          if (data['type'] == 'DEVICE_STATE_UPDATE' && data['deviceId'] == deviceName) {
            debugPrint('[WebSocket] Updating state for deviceName: $deviceName');
            state = Map<String, dynamic>.from(data['payload'] ?? {});
          } else {
            debugPrint('[WebSocket] Message ignored, deviceId mismatch or different type.');
          }
        },
        onDone: () {
          _connected = false;
          debugPrint('[WebSocket] Connection closed. Scheduling reconnect...');
          _scheduleReconnect(hubId, deviceName, token);
        },
        onError: (error) {
          _connected = false;
          debugPrint('[WebSocket] Error occurred: $error. Scheduling reconnect...');
          _scheduleReconnect(hubId, deviceName, token);
        },
      );

      _connected = true;
      debugPrint('[WebSocket] Connection established.');
    } catch (e) {
      _connected = false;
      debugPrint('[WebSocket] Exception during connect: $e. Scheduling reconnect...');
      _scheduleReconnect(hubId, deviceName, token);
    }
  }

  void _scheduleReconnect(String hubId, String deviceName, String token) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      debugPrint('[WebSocket] Attempting reconnect...');
      connect(hubId, deviceName, token: token);
    });
  }

  void sendCommand(String hubId, String deviceName, Map<String, dynamic> payload) {
    if (!_connected) {
      debugPrint('[WebSocket] Cannot send command, socket is not connected.');
      return;
    }
    final command = {
      "type": "DEVICE_COMMAND",
      "hubId": hubId,
      "details": {
        "deviceId": deviceName,
        "payload": payload,
      },
    };
    final jsonCommand = jsonEncode(command);
    debugPrint('[WebSocket] Sending command: $jsonCommand');
    _channel.sink.add(jsonCommand);
  }

  @override
  void dispose() {
    debugPrint('[WebSocket] Disposing connection...');
    _reconnectTimer?.cancel();
    _channel.sink.close();
    super.dispose();
  }
}
