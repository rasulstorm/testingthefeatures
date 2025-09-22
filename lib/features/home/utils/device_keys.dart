import 'package:ISS/models/device_models.dart';

/// Единая логика выбора ключа для команд/WebSocket и поиска live-данных.
/// Приоритет: name/friendly (ieee) -> deviceId -> id
class DeviceKeys {
  static String commandKey(BaseDevice d) {
    String? pick(List<String?> values) {
      for (final value in values) {
        final trimmed = value?.trim();
        if (trimmed != null && trimmed.isNotEmpty) {
          return trimmed;
        }
      }
      return null;
    }

    final raw = d.rawData;
    final deviceMap = raw['device'] is Map<String, dynamic>
        ? raw['device'] as Map<String, dynamic>
        : null;

    final preferred = pick([
      raw['name'] as String?,
      raw['friendlyName'] as String?,
      deviceMap?['friendlyName'] as String?,
      raw['ieee_address'] as String?,
      raw['ieeeAddr'] as String?,
      deviceMap?['ieeeAddr'] as String?,
      d.friendlyName,
    ]);

    if (preferred != null) return preferred;

    final fallback = pick([
      raw['deviceId'] as String?,
      raw['id'] as String?,
      d.id,
    ]);

    return fallback ?? d.id;
  }

  /// Все возможные идентификаторы, которые может прислать сервер в live.
  static List<String> allKeys(BaseDevice d) {
    final raw = d.rawData;
    final deviceMap = raw['device'] is Map<String, dynamic>
        ? raw['device'] as Map<String, dynamic>
        : null;
    final s = <String>{};
    void add(String? v) {
      if (v != null && v.trim().isNotEmpty) s.add(v.trim());
    }

    add(d.id);
    add(d.friendlyName);
    add(raw['deviceId'] as String?);
    add(raw['name'] as String?);
    add(raw['friendlyName'] as String?);
    if (deviceMap != null) {
      add(deviceMap['friendlyName'] as String?);
      add(deviceMap['ieeeAddr'] as String?);
    }
    add(raw['ieee_address'] as String?); // на будущее
    add(raw['ieeeAddr'] as String?);
    return s.toList();
  }
}
