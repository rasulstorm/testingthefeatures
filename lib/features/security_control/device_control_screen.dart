import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/io.dart';

final webSocketProvider =
    StateNotifierProvider<WebSocketNotifier, Map<String, dynamic>>(
      (ref) => WebSocketNotifier(),
    );

class WebSocketNotifier extends StateNotifier<Map<String, dynamic>> {
  WebSocketNotifier() : super({});

  late IOWebSocketChannel _channel;
  bool _connected = false;
  bool get connected => _connected;

  Timer? _reconnectTimer;

  Future<void> connect(
    String hubId,
    String deviceName, {
    required String token,
  }) async {
    if (_connected) {
      print('[WS] Already connected, skipping connect.');
      return;
    }

    try {
      final url = 'wss://app.iss-control.kz/ws?token=$token';
      print('[WS] Connecting to $url for deviceName=$deviceName');

      _channel = IOWebSocketChannel.connect(Uri.parse(url));

      _channel.stream.listen(
        (message) {
          print('[WS] Received message: $message');
          final data = jsonDecode(message);
          if (data['type'] == 'DEVICE_STATE_UPDATE' &&
              data['deviceId'] == deviceName) {
            state = Map<String, dynamic>.from(data['payload'] ?? {});
            print('[WS] State updated for deviceName=$deviceName: ${state}');
          } else {
            print('[WS] Message ignored for deviceName=$deviceName');
          }
        },
        onDone: () {
          _connected = false;
          print('[WS] Connection closed. Scheduling reconnect...');
          _scheduleReconnect(hubId, deviceName, token);
        },
        onError: (error) {
          _connected = false;
          print('[WS] Connection error: $error. Scheduling reconnect...');
          _scheduleReconnect(hubId, deviceName, token);
        },
      );

      _connected = true;
      print('[WS] Connected successfully for deviceName=$deviceName');
    } catch (e) {
      _connected = false;
      print('[WS] Connection failed: $e. Scheduling reconnect...');
      _scheduleReconnect(hubId, deviceName, token);
    }
  }

  void _scheduleReconnect(String hubId, String deviceName, String token) {
    _reconnectTimer?.cancel();
    print('[WS] Scheduling reconnect in 5 seconds for deviceName=$deviceName');
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      print('[WS] Attempting reconnect for deviceName=$deviceName');
      connect(hubId, deviceName, token: token);
    });
  }

  void sendCommand(
    String hubId,
    String deviceName,
    Map<String, dynamic> payload,
  ) {
    if (!_connected) {
      print('[WS] Cannot send command, WebSocket not connected.');
      return;
    }
    final command = {
      "type": "DEVICE_COMMAND",
      "hubId": hubId,
      "details": {"deviceId": deviceName, "payload": payload},
    };
    final jsonCommand = jsonEncode(command);
    print('[WS] Sending command: $jsonCommand');
    _channel.sink.add(jsonCommand);
  }

  @override
  void dispose() {
    print(
      '[WS] Disposing WebSocketNotifier, cancelling timers and closing connection.',
    );
    _reconnectTimer?.cancel();
    _channel.sink.close();
    super.dispose();
  }
}
