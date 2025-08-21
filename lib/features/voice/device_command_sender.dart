import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// твои WS провайдеры
import 'package:ISS/features/security_control/ws_provider.dart'
    show webSocketNotifierProvider; // с sendDeviceCommand(deviceName)
import 'package:ISS/services/websocket_service.dart'
    show appWebSocketProvider; // с sendCommand(deviceId)

/// Унифицированный интерфейс
abstract class DeviceCommandSender {
  Future<void> setLight({
    required String hubId,
    required String deviceId,
    required bool on,
  });
}

/// Реализация через твои два WS-слоя.
/// Примечание по payload: оставил максимально простой и читаемый.
/// Если бек ожидает другой формат — подправь здесь один раз.
final deviceCommandSenderProvider = Provider<DeviceCommandSender>((ref) {
  return _WsDeviceCommandSender(ref);
});

class _WsDeviceCommandSender implements DeviceCommandSender {
  final Ref ref;
  _WsDeviceCommandSender(this.ref);

  Future<void> _ensureConnected() async {
    // 1) новый простой канал (appWebSocketProvider)
    final appWs = ref.read(appWebSocketProvider.notifier);
    if (!ref.read(appWebSocketProvider)) {
      await appWs.connect();
    }

    // 2) «старый» notifier (webSocketNotifierProvider)
    final legacyWs = ref.read(webSocketNotifierProvider.notifier);
    // у него нет явного статуса в state? — но есть connect()
    // вызовем безопасно: он сам проверит и ничего лишнего не сделает
    await legacyWs.connect();
  }

  @override
  Future<void> setLight({
    required String hubId,
    required String deviceId,
    required bool on,
  }) async {
    await _ensureConnected();

    // Универсальный payload. Если у бекэнда другой контракт —
    // меняешь тут в одном месте.
    final payload = {
      "type": "switch",
      "on": on, // true/false
      "value": on ? "ON" : "OFF",
      // можно добавить "source": "voice" для трекинга
    };

    // --- Пытаемся через оба канала ---

    // А) appWebSocketProvider — требует deviceId
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

    // Б) webSocketNotifierProvider — у него сигнатура с deviceIdentifier (часто «deviceName»)
    try {
      ref
          .read(webSocketNotifierProvider.notifier)
          .sendDeviceCommand(
            hubId,
            deviceId, // если у тебя тут реально нужен friendlyName — подставь его вместо deviceId
            payload,
          );
      debugPrint(
        '[Voice] sendDeviceCommand(legacyWS): hub=$hubId device=$deviceId $payload',
      );
    } catch (e) {
      debugPrint('[Voice] legacyWS sendDeviceCommand error: $e');
    }
  }
}
