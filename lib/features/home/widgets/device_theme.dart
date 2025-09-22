import 'package:flutter/material.dart';
import 'package:ISS/models/device_models.dart';

/// Какой это тип — влияет на карточку и на контролы в шторке
enum DeviceKind {
  light,
  plug,
  curtain,
  contact,
  motion,
  climate,
  leak,
  smoke,
  lock,
  camera,
  unknown,
}

class DeviceMetric {
  final String label; // "28.1°"
  final IconData icon; // Icons.thermostat_outlined
  final String? hint; // "temp"
  const DeviceMetric({required this.label, required this.icon, this.hint});
}

class DeviceThemeData {
  final DeviceKind kind;
  final String displayType;
  final IconData icon;
  final List<Color> gradient;
  final bool controllable;
  final String? stateText;
  final List<DeviceMetric> metrics;

  const DeviceThemeData({
    required this.kind,
    required this.displayType,
    required this.icon,
    required this.gradient,
    required this.controllable,
    required this.metrics,
    this.stateText,
  });
}

// -------- безопасные геттеры ----------
T? _get<T>(Map<String, dynamic> m, String k) {
  final v = m[k];
  if (v is T) return v;
  return null;
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.replaceAll(',', '.'));
  return null;
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

bool? _toBool(dynamic v) {
  if (v is bool) return v;
  if (v is String) {
    final s = v.toLowerCase();
    if (s == 'true' || s == '1' || s == 'on') return true;
    if (s == 'false' || s == '0' || s == 'off') return false;
  }
  return null;
}

// ---------- inference ----------
DeviceThemeData inferDeviceTheme(BaseDevice d, BuildContext context) {
  final rd = d.rawData;
  final type = (_get<String>(rd, 'type') ?? '').toLowerCase();
  final manu = (_get<String>(rd, 'manufacturer') ?? '').toLowerCase();

  final stateStr = _get<String>(rd, 'state');
  final isControllable = _get<bool>(rd, 'controllable') ?? false;

  final temp = _toDouble(rd['temperature'] ?? rd['device_temperature']);
  final hum = _toDouble(rd['humidity']);
  final illum = _toInt(rd['illuminance']);
  final battery = _toInt(rd['battery']);
  final position = _toInt(rd['position']);
  final motion = _toBool(rd['occupancy']) ?? _toBool(rd['motion']);
  final leak = _toBool(rd['water_leak']) ?? _toBool(rd['leak']);
  final smoke = _toBool(rd['smoke']);
  final lockOpen =
      (rd['lock_state'] ?? rd['door_lock'])?.toString().toLowerCase();

  bool isCurtain =
      type.contains('curtain') || type.contains('znclbl') || position != null;
  bool isPlugOrRelay =
      type.contains('plug') ||
      type.contains('socket') ||
      type.contains('relay') ||
      ((stateStr == 'ON' || stateStr == 'OFF') && isControllable);
  bool isLight =
      type.contains('light') ||
      type.contains('bulb') ||
      (type.contains('led') && isControllable);
  bool isContact =
      type.contains('contact') ||
      type.contains('window') ||
      type.contains('door') ||
      (stateStr == 'OPEN' || stateStr == 'CLOSE');
  bool isMotion = type.contains('motion') || motion == true;
  bool isEnv = temp != null || hum != null || illum != null;
  bool isLeak = type.contains('leak') || leak == true;
  bool isSmoke = type.contains('smoke') || smoke == true;
  bool isLock =
      type.contains('lock') || lockOpen == 'unlock' || lockOpen == 'open';
  bool isCamera = type.contains('camera') || type.contains('cam');

  // палитры
  const gSunset = [Color(0xFFFAD961), Color(0xFFF76B1C)];
  const gGreen = [Color(0xFF11998E), Color(0xFF38EF7D)];
  const gBlue = [Color(0xFF56CCF2), Color(0xFF2F80ED)];
  const gPurple = [Color(0xFFB06AB3), Color(0xFF4568DC)];
  const gSea = [Color(0xFF00C9FF), Color(0xFF92FE9D)];
  const gSteel = [Color(0xFFBDC3C7), Color(0xFF2C3E50)];
  const gOrange = [Color(0xFFFFA17F), Color(0xFFFFE29F)];
  const gRed = [Color(0xFFFF512F), Color(0xFFF09819)];

  if (isCurtain) {
    return DeviceThemeData(
      kind: DeviceKind.curtain,
      displayType: 'Шторы',
      icon: Icons.curtains_outlined,
      gradient: gPurple,
      controllable: isControllable,
      stateText: position != null ? '$position%' : stateStr,
      metrics: [
        if (illum != null)
          DeviceMetric(
            label: '$illum lx',
            icon: Icons.wb_sunny_outlined,
            hint: 'lux',
          ),
        if (battery != null)
          DeviceMetric(
            label: '$battery%',
            icon: Icons.battery_6_bar,
            hint: 'bat',
          ),
      ],
    );
  }

  if (isLight) {
    return DeviceThemeData(
      kind: DeviceKind.light,
      displayType: 'Освещение',
      icon: Icons.lightbulb_outline,
      gradient: gSunset,
      controllable: true,
      stateText: (stateStr == null) ? null : (stateStr == 'ON' ? 'ON' : 'OFF'),
      metrics: [
        if (illum != null)
          DeviceMetric(label: '$illum lx', icon: Icons.wb_sunny_outlined),
        if (battery != null)
          DeviceMetric(label: '$battery%', icon: Icons.battery_6_bar),
      ],
    );
  }

  if (isPlugOrRelay) {
    return DeviceThemeData(
      kind: DeviceKind.plug,
      displayType: 'Розетка/Реле',
      icon: Icons.power_outlined,
      gradient: gGreen,
      controllable: true,
      stateText: (stateStr == null) ? null : (stateStr == 'ON' ? 'ON' : 'OFF'),
      metrics: [
        if (battery != null)
          DeviceMetric(label: '$battery%', icon: Icons.battery_6_bar),
      ],
    );
  }

  if (isContact) {
    return DeviceThemeData(
      kind: DeviceKind.contact,
      displayType: 'Датчик двери/окна',
      icon: Icons.sensor_door_outlined,
      gradient: gBlue,
      controllable: false,
      stateText:
          (stateStr == null) ? null : (stateStr == 'OPEN' ? 'OPEN' : 'CLOSE'),
      metrics: [
        if (temp != null)
          DeviceMetric(
            label: '${temp.toStringAsFixed(1)}°',
            icon: Icons.thermostat_outlined,
            hint: 'temp',
          ),
        if (battery != null)
          DeviceMetric(
            label: '$battery%',
            icon: Icons.battery_6_bar,
            hint: 'bat',
          ),
      ],
    );
  }

  if (isMotion) {
    return DeviceThemeData(
      kind: DeviceKind.motion,
      displayType: 'Датчик движения',
      icon: Icons.sensors_outlined,
      gradient: gPurple,
      controllable: false,
      stateText: motion == true ? 'MOTION' : 'IDLE',
      metrics: [
        if (illum != null)
          DeviceMetric(label: '$illum lx', icon: Icons.wb_sunny_outlined),
        if (battery != null)
          DeviceMetric(label: '$battery%', icon: Icons.battery_6_bar),
      ],
    );
  }

  if (isLeak) {
    return DeviceThemeData(
      kind: DeviceKind.leak,
      displayType: 'Датчик протечки',
      icon: Icons.water_damage_outlined,
      gradient: gSea,
      controllable: false,
      stateText: leak == true ? 'ALERT' : 'OK',
      metrics: [
        if (battery != null)
          DeviceMetric(label: '$battery%', icon: Icons.battery_6_bar),
      ],
    );
  }

  if (isSmoke) {
    return DeviceThemeData(
      kind: DeviceKind.smoke,
      displayType: 'Датчик дыма',
      icon: Icons.smoke_free_outlined,
      gradient: gRed,
      controllable: false,
      stateText: smoke == true ? 'ALERT' : 'OK',
      metrics: [
        if (battery != null)
          DeviceMetric(label: '$battery%', icon: Icons.battery_6_bar),
      ],
    );
  }

  if (isLock) {
    return DeviceThemeData(
      kind: DeviceKind.lock,
      displayType: 'Замок',
      icon: Icons.lock_outline,
      gradient: gSteel,
      controllable: true,
      stateText:
          (lockOpen == 'unlock' || lockOpen == 'open') ? 'UNLOCK' : 'LOCK',
      metrics: [
        if (battery != null)
          DeviceMetric(label: '$battery%', icon: Icons.battery_6_bar),
      ],
    );
  }

  if (isCamera) {
    return DeviceThemeData(
      kind: DeviceKind.camera,
      displayType: 'Камера',
      icon: Icons.videocam_outlined,
      gradient: gSteel,
      controllable: false,
      stateText: 'ONLINE',
      metrics: const [],
    );
  }

  if (isEnv) {
    return DeviceThemeData(
      kind: DeviceKind.climate,
      displayType: 'Климат',
      icon: Icons.device_thermostat,
      gradient: gSea,
      controllable: false,
      stateText: null,
      metrics: [
        if (temp != null)
          DeviceMetric(
            label: '${temp.toStringAsFixed(1)}°',
            icon: Icons.thermostat_outlined,
            hint: 'temp',
          ),
        if (hum != null)
          DeviceMetric(
            label: '${hum.toStringAsFixed(0)}%',
            icon: Icons.water_drop_outlined,
            hint: 'hum',
          ),
        if (illum != null)
          DeviceMetric(
            label: '$illum lx',
            icon: Icons.wb_sunny_outlined,
            hint: 'lux',
          ),
        if (battery != null)
          DeviceMetric(
            label: '$battery%',
            icon: Icons.battery_6_bar,
            hint: 'bat',
          ),
      ],
    );
  }

  return DeviceThemeData(
    kind: DeviceKind.unknown,
    displayType: manu.isNotEmpty ? manu : 'Устройство',
    icon: Icons.device_unknown_outlined,
    gradient: gSteel,
    controllable: isControllable,
    stateText: stateStr,
    metrics: [
      if (battery != null)
        DeviceMetric(
          label: '$battery%',
          icon: Icons.battery_6_bar,
          hint: 'bat',
        ),
    ],
  );
}

/// Имя
String deviceTitle(BaseDevice d) {
  final fn = d.friendlyName;
  if (fn.trim().isNotEmpty) return fn.trim();
  final title = d.rawData['title'] as String?;
  final name = d.rawData['name'] as String?;
  return (title ?? name ?? d.id);
}

/// Подзаголовок
String deviceSubtitle(BaseDevice d) {
  final type = d.rawData['type'] as String?;
  if (type != null && type.trim().isNotEmpty) return type;
  final manu = d.rawData['manufacturer'] as String?;
  return manu ?? '';
}
