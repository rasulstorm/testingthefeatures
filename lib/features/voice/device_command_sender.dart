import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// legacy WS (security_control/ws_provider.dart)
import 'package:ISS/features/security_control/ws_provider.dart'
    show webSocketNotifierProvider;

// app-wide WS (services/websocket_service.dart)
import 'package:ISS/services/websocket_service.dart' show appWebSocketProvider;

abstract class DeviceCommandSender {
  Future<void> setLight({
    required String hubId,
    required String deviceId,
    required bool on,
  });
}

final deviceCommandSenderProvider = Provider<DeviceCommandSender>((ref) {
  return _WsDeviceCommandSender(ref);
});

class _WsDeviceCommandSender implements DeviceCommandSender {
  final Ref ref;
  _WsDeviceCommandSender(this.ref);

  Future<void> _ensureConnected(String hubId) async {
    // app WS (bool state = connected)
    final appWsNotifier = ref.read(appWebSocketProvider.notifier);
    final appWsConnected = ref.read(appWebSocketProvider);
    if (!appWsConnected) {
      await appWsNotifier.connect(hubId: hubId);
    }

    // legacy WS (connect(hubId) как позиционный)
    final legacyWs = ref.read(webSocketNotifierProvider.notifier);
    await legacyWs.connect(hubId);
  }

  @override
  Future<void> setLight({
    required String hubId,
    required String deviceId,
    required bool on,
  }) async {
    await _ensureConnected(hubId);

    final payload = {"type": "switch", "on": on, "value": on ? "ON" : "OFF"};

    // Пытаемся через app WS
    try {
      ref
          .read(appWebSocketProvider.notifier)
          .sendCommand(hubId, deviceId, payload);
      debugPrint(
        '[Voice] sendCommand(appWS): hub=$hubId device=$deviceId $payload',
      );
    } catch (e) {
      debugPrint('[Voice] appWS sendCommand error: $e');
    }

    // Дублируем через legacy WS (на всякий случай)
    try {
      ref
          .read(webSocketNotifierProvider.notifier)
          .sendDeviceCommand(hubId, deviceId, payload);
      debugPrint(
        '[Voice] sendDeviceCommand(legacyWS): hub=$hubId device=$deviceId $payload',
      );
    } catch (e) {
      debugPrint('[Voice] legacyWS sendDeviceCommand error: $e');
    }
  }
}
