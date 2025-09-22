import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// legacy WS (security_control/ws_provider.dart)
import 'package:ISS/features/security_control/ws_provider.dart'
    show webSocketNotifierProvider;
import 'package:ISS/services/device_command_service.dart';

/// Унифицированный интерфейс отправки команд устройствам.
abstract class DeviceCommandSender {
  Future<void> setLight({
    required String hubId,
    required String deviceId, // <- используем ID устройства
    required bool on,
  });
}

/// Провайдер отправителя команд (через наш legacy WS + HTTP командный сервис).
final deviceCommandSenderProvider = Provider<DeviceCommandSender>((ref) {
  return _WsDeviceCommandSender(ref);
});

class _WsDeviceCommandSender implements DeviceCommandSender {
  final Ref ref;
  _WsDeviceCommandSender(this.ref);

  Future<void> _ensureConnected(String hubId) async {
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

    try {
      final legacyWs = ref.read(webSocketNotifierProvider.notifier);

      // локально мгновенно обновляем UI по ключу устройства
      legacyWs.updateDeviceLocalState(deviceId, {'state': on ? 'ON' : 'OFF'});

      // отправляем команду через HTTP-слой (по deviceName)
      await ref
          .read(deviceCommandServiceProvider)
          .sendCommand(
            hubId: hubId,
            deviceName: deviceId, // <- backend ждёт deviceName
            payload: payload,
          );

      debugPrint('[Voice] HTTP DEVICE_COMMAND hub=$hubId deviceName=$deviceId');
    } on DeviceCommandException catch (e) {
      debugPrint('[Voice] sendCommand error: $e');
      rethrow;
    }
  }
}
