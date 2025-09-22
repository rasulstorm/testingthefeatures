// lib/features/devices/widgets/device_catalog.dart
import 'package:ISS/models/device_models.dart';
import 'package:ISS/features/home/utils/device_keys.dart';

/// Унифицированный вид устройства для UI (карточки/деталка).
class DeviceCardVm {
  final String deviceId; // строго 0x…
  final String title;
  final String roomName;
  final DeviceUiKind kind;
  final String asset; // путь к PNG для карточек/деталок
  final int? linkquality; // 0..255
  final bool disconnected; // true => связь потеряна
  final Map<String, dynamic> extra; // произвольные поля под деталку
  final String? manufacturer;
  final String? model;
  final String? friendlyName;

  const DeviceCardVm({
    required this.deviceId,
    required this.title,
    required this.roomName,
    required this.kind,
    required this.asset,
    this.linkquality,
    this.disconnected = false,
    this.extra = const {},
    this.manufacturer,
    this.model,
    this.friendlyName,
  });
}

/// Набор "UI-типов" (не зависит от бекенда).
enum DeviceUiKind {
  lightDimmer,
  curtain,
  sensorMotion,
  sensorContact,
  sensorLeak,
  sensorVibration,
  climate, // temp/hum/illuminance
  relay,
  unknown,
}

/// Построение каталога карточек из реальных устройств + live WS карты.
List<DeviceCardVm> buildDeviceCatalog({
  required List<BaseDevice> devices,
  required Map<String, Map<String, dynamic>> liveById,
}) {
  return devices.map((d) {
    final live = _findLiveFor(d, liveById);
    final kind = _inferKind(d);
    final visual = _visualFor(kind);

    // Заголовок/комната
    final title = _titleOf(d);
    final room = _roomOf(d);

    // Связь/сигнал
    final int? lq =
        (live?['linkquality'] as num?)?.toInt() ??
        (d.rawData['linkquality'] as num?)?.toInt();
    final bool disconnected =
        live == null
            ? false
            : (live['connected'] == false) ||
                (live['availability'] == 'offline');

    // Доп. поля по типам (для деталок)
    final extra = <String, dynamic>{};
    switch (kind) {
      case DeviceUiKind.lightDimmer:
        extra['on'] = live?['state'] == 'ON' || d.rawData['state'] == 'ON';
        extra['brightness'] =
            (live?['brightness'] as num?)?.toInt() ??
            (d.rawData['brightness'] as num?)?.toInt();
        extra['hue'] = (live?['hue'] as num?)?.toDouble();
        extra['saturation'] = (live?['saturation'] as num?)?.toDouble();
        extra['color_temp'] =
            (live?['color_temp_kelvin'] as num?)?.toDouble() ??
            (live?['color_temp'] as num?)?.toDouble() ??
            (d.rawData['color_temp'] as num?)?.toDouble();
        extra['power'] =
            (live?['power'] as num?)?.toDouble() ??
            (d.rawData['power'] as num?)?.toDouble();
        extra['light_type'] =
            (live?['light_type'] ?? d.rawData['light_type'])?.toString();
        break;

      case DeviceUiKind.curtain:
        extra['position'] =
            (live?['position'] as num?)?.toInt() ??
            (d.rawData['position'] as num?)?.toInt();
        extra['state'] = (live?['state'] ?? d.rawData['state'])?.toString();
        extra['motor_state'] =
            (live?['motor_state'] ?? d.rawData['motor_state'])?.toString();
        break;

      case DeviceUiKind.climate:
        extra['temperature'] =
            (live?['temperature'] as num?)?.toDouble() ??
            (d.rawData['temperature'] as num?)?.toDouble();
        extra['humidity'] =
            (live?['humidity'] as num?)?.toDouble() ??
            (d.rawData['humidity'] as num?)?.toDouble();
        extra['illuminance'] =
            (live?['illuminance_lux'] as num?)?.toDouble() ??
            (live?['illuminance'] as num?)?.toDouble() ??
            (d.rawData['illuminance'] as num?)?.toDouble();
        extra['pressure'] =
            (live?['pressure'] as num?)?.toDouble() ??
            (d.rawData['pressure'] as num?)?.toDouble();
        extra['device_temperature'] =
            (live?['device_temperature'] as num?)?.toDouble() ??
            (d.rawData['device_temperature'] as num?)?.toDouble();
        break;

      case DeviceUiKind.sensorMotion:
        final occupancy = live?['occupancy'] ?? d.rawData['occupancy'];
        if (occupancy is bool) extra['occupied'] = occupancy;
        final presence = live?['presence'] ?? d.rawData['presence'];
        if (presence is bool) extra['presence'] = presence;
        extra['illuminance'] =
            (live?['illuminance'] as num?)?.toDouble() ??
            (d.rawData['illuminance'] as num?)?.toDouble();
        extra['status'] =
            (live?['status'] ??
                    live?['action'] ??
                    d.rawData['status'] ??
                    d.rawData['action'])
                ?.toString();
        break;

      case DeviceUiKind.sensorContact:
        final contact = live?['contact'] ?? d.rawData['contact'];
        if (contact is bool) extra['contact'] = contact;
        final tamper = live?['tamper'] ?? d.rawData['tamper'];
        if (tamper is bool) extra['tamper'] = tamper;
        extra['status'] =
            (live?['status'] ??
                    live?['action'] ??
                    d.rawData['status'] ??
                    d.rawData['action'])
                ?.toString();
        break;

      case DeviceUiKind.sensorLeak:
        final leak =
            live?['water_leak'] ?? live?['leak'] ?? d.rawData['water_leak'];
        if (leak is bool) extra['water_leak'] = leak;
        final leakAlarm = live?['alarm'] ?? d.rawData['alarm'];
        if (leakAlarm is bool) extra['leak_alarm'] = leakAlarm;
        extra['status'] =
            (live?['status'] ??
                    live?['action'] ??
                    d.rawData['status'] ??
                    d.rawData['action'])
                ?.toString();
        break;

      case DeviceUiKind.sensorVibration:
        final vibration = live?['vibration'] ?? d.rawData['vibration'];
        if (vibration is bool) extra['vibration'] = vibration;
        final action = (live?['action'] ?? d.rawData['action'])?.toString();
        if (action != null) extra['action'] = action;
        extra['status'] =
            (live?['status'] ??
                    live?['action'] ??
                    d.rawData['status'] ??
                    d.rawData['action'])
                ?.toString();
        break;

      case DeviceUiKind.relay:
        final state = (live?['state'] ?? d.rawData['state'])?.toString();
        if (state != null) extra['state'] = state;
        extra['on'] = (state ?? '').toUpperCase() == 'ON';
        extra['power'] =
            (live?['power'] as num?)?.toDouble() ??
            (d.rawData['power'] as num?)?.toDouble();
        extra['voltage'] =
            (live?['voltage'] as num?)?.toDouble() ??
            (d.rawData['voltage'] as num?)?.toDouble();
        extra['current'] =
            (live?['current'] as num?)?.toDouble() ??
            (d.rawData['current'] as num?)?.toDouble();
        extra['energy'] =
            (live?['energy'] as num?)?.toDouble() ??
            (d.rawData['energy'] as num?)?.toDouble();
        break;

      case DeviceUiKind.unknown:
        final state = (live?['state'] ?? d.rawData['state'])?.toString();
        if (state != null) extra['state'] = state;
        break;
    }

    final battery =
        (live?['battery'] as num?) ?? (d.rawData['battery'] as num?);
    if (battery != null) {
      extra['battery'] = battery.toDouble();
    }
    final voltage =
        (live?['voltage'] as num?) ?? (d.rawData['voltage'] as num?);
    if (voltage != null) {
      extra['voltage'] = voltage.toDouble();
    }

    extra['category'] = (d.rawData['deviceCategory'] ?? '').toString();

    final commandKey = DeviceKeys.commandKey(d);

    return DeviceCardVm(
      deviceId: commandKey,
      title: title,
      roomName: room,
      kind: kind,
      asset: _resolveAsset(d, kind, visual),
      linkquality: lq,
      disconnected: disconnected,
      extra: extra,
      manufacturer: d.manufacturer,
      model: d.model,
      friendlyName: d.friendlyName,
    );
  }).toList();
}

// ───────────────────────────────── helpers ───────────────────────────────────

Map<String, dynamic>? _findLiveFor(
  BaseDevice d,
  Map<String, Map<String, dynamic>> live,
) {
  for (final k in DeviceKeys.allKeys(d)) {
    final v = live[k];
    if (v != null) return v;
  }
  return null;
}

String _titleOf(BaseDevice d) {
  final t = d.rawData['title'];
  final friendly = d.friendlyName;
  final name = d.rawData['name'];
  final type = d.rawData['type'];

  if (t is String && t.trim().isNotEmpty) return t.trim();
  if (friendly.trim().isNotEmpty) return _beautifyDeviceName(friendly.trim());
  if (name is String && name.trim().isNotEmpty) {
    return _beautifyDeviceName(name.trim());
  }

  final parsedType = _extractTypeName(type?.toString());
  if (parsedType != null && parsedType.isNotEmpty) {
    return parsedType;
  }

  final modelName = _modelFallback(d.model);
  if (modelName != null) return modelName;

  return d.id;
}

String _roomOf(BaseDevice d) {
  final room = d.rawData['room'];
  if (room is Map) {
    final n = room['name'];
    if (n is String) return n;
  }
  final r = d.rawData['roomName'];
  if (r is String) return r;
  return '';
}

DeviceUiKind _inferKind(BaseDevice d) {
  final model = d.model.toLowerCase();
  final mfr = d.manufacturer.toLowerCase();
  final title = _titleOf(d).toLowerCase();
  final name = (d.rawData['name']?.toString() ?? '').toLowerCase();
  final type = (d.rawData['type']?.toString() ?? '').toLowerCase();
  final category =
      (d.rawData['deviceCategory']?.toString() ?? '').toLowerCase();

  bool any(String s) =>
      model.contains(s) ||
      name.contains(s) ||
      title.contains(s) ||
      type.contains(s) ||
      mfr.contains(s);

  if (category.isNotEmpty) {
    if (category.contains('curtain') || category.contains('blind')) {
      return DeviceUiKind.curtain;
    }
    if (category.contains('bulb') || category.contains('light')) {
      return DeviceUiKind.lightDimmer;
    }
    if (category.contains('switch') || category.contains('plug')) {
      return DeviceUiKind.relay;
    }
    if (category.contains('motion') || category.contains('presence')) {
      return DeviceUiKind.sensorMotion;
    }
    if (category.contains('contact') ||
        category.contains('door') ||
        category.contains('window')) {
      return DeviceUiKind.sensorContact;
    }
    if (category.contains('leak') ||
        category.contains('water') ||
        category.contains('flood')) {
      return DeviceUiKind.sensorLeak;
    }
    if (category.contains('vibration') || category.contains('tilt')) {
      return DeviceUiKind.sensorVibration;
    }
    if (category.contains('temp') ||
        category.contains('climate') ||
        category.contains('humidity') ||
        category.contains('weather')) {
      return DeviceUiKind.climate;
    }
  }

  if (any('curtain') || any('blind') || any('cover')) {
    return DeviceUiKind.curtain;
  }
  if (any('switch') || any('relay') || any('socket') || any('plug')) {
    return DeviceUiKind.relay;
  }
  if (any('vibration')) return DeviceUiKind.sensorVibration;
  if (any('leak') || any('water') || any('flood')) {
    return DeviceUiKind.sensorLeak;
  }
  if (any('smoke') || any('gas')) {
    return DeviceUiKind.sensorLeak;
  }
  if (any('contact') || any('window') || any('door') || any('lock')) {
    return DeviceUiKind.sensorContact;
  }
  if (any('motion') || any('occupancy') || any('movement') || any('presence')) {
    return DeviceUiKind.sensorMotion;
  }
  if (any('thermo') ||
      any('temp') ||
      any('humid') ||
      any('climate') ||
      any('env') ||
      any('weather')) {
    return DeviceUiKind.climate;
  }
  if (any('light') || any('lamp') || any('dimmer') || any('bulb')) {
    return DeviceUiKind.lightDimmer;
  }
  return DeviceUiKind.unknown;
}

class _DeviceVisual {
  final String asset;
  const _DeviceVisual(this.asset);
}

String? _extractTypeName(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final match = RegExp(r'\(([^)]+)\)').firstMatch(trimmed);
  if (match != null) {
    final inside = match.group(1);
    if (inside != null && inside.trim().isNotEmpty) {
      return _beautifyDeviceName(inside.trim());
    }
  }

  if (trimmed.contains(' ')) {
    return _beautifyDeviceName(trimmed);
  }

  return null;
}

String _beautifyDeviceName(String input) {
  final cleaned =
      input
          .replaceAll(RegExp(r'[_]+'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
  if (cleaned.isEmpty) return input;

  // Если строка похожа на код устройства (все буквы в верхнем регистре и цифры)
  final looksLikeCode = RegExp(
    r'^[A-Z0-9\-]+$',
  ).hasMatch(cleaned.replaceAll(' ', ''));
  if (looksLikeCode) return cleaned.toUpperCase();

  final words = cleaned.split(' ');
  final capitalised = words
      .map(
        (w) =>
            w.isEmpty
                ? w
                : '${w[0].toUpperCase()}${w.length > 1 ? w.substring(1).toLowerCase() : ''}',
      )
      .join(' ');
  return capitalised;
}

String? _modelFallback(String model) {
  final trimmed = model.trim();
  if (trimmed.isEmpty) return null;
  if (RegExp(r'^[A-Za-z0-9\-_.]+$').hasMatch(trimmed)) {
    return trimmed.toUpperCase();
  }
  return _beautifyDeviceName(trimmed);
}

_DeviceVisual _visualFor(DeviceUiKind kind) {
  switch (kind) {
    case DeviceUiKind.lightDimmer:
      return const _DeviceVisual('assets/devices/lamp.png');
    case DeviceUiKind.curtain:
      return const _DeviceVisual('assets/devices/curtain.png');
    case DeviceUiKind.sensorMotion:
      return const _DeviceVisual('assets/devices/movement.png');
    case DeviceUiKind.sensorContact:
      return const _DeviceVisual('assets/devices/door.png');
    case DeviceUiKind.sensorLeak:
      return const _DeviceVisual('assets/devices/leak.png');
    case DeviceUiKind.sensorVibration:
      return const _DeviceVisual('assets/devices/vibration.png');
    case DeviceUiKind.climate:
      return const _DeviceVisual('assets/devices/env.png');
    case DeviceUiKind.relay:
      return const _DeviceVisual('assets/devices/relay.png');
    case DeviceUiKind.unknown:
      return const _DeviceVisual('assets/devices/generic.png');
  }
}

String _resolveAsset(BaseDevice d, DeviceUiKind kind, _DeviceVisual fallback) {
  final model = d.model.toLowerCase();
  final title = _titleOf(d).toLowerCase();
  final name = (d.rawData['name']?.toString() ?? '').toLowerCase();

  switch (kind) {
    case DeviceUiKind.sensorMotion:
      if (model.contains('presence') ||
          title.contains('presence') ||
          name.contains('presence')) {
        return 'assets/devices/presence.png';
      }
      return fallback.asset;
    case DeviceUiKind.sensorContact:
      return 'assets/devices/door.png';
    case DeviceUiKind.sensorLeak:
      return 'assets/devices/leak.png';
    case DeviceUiKind.sensorVibration:
      return 'assets/devices/vibration.png';
    case DeviceUiKind.climate:
      return 'assets/devices/env.png';
    case DeviceUiKind.curtain:
      return 'assets/devices/curtain.png';
    case DeviceUiKind.lightDimmer:
      return 'assets/devices/lamp.png';
    case DeviceUiKind.relay:
      if (model.contains('plug') || title.contains('розетка')) {
        return 'assets/devices/relay.png';
      }
      return 'assets/devices/relay.png';
    case DeviceUiKind.unknown:
      return fallback.asset;
  }
}
