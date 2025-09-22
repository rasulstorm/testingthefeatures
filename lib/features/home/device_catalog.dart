import 'package:flutter/material.dart';
import 'package:ISS/models/device_models.dart';

/// Типы устройств, с которыми работаем
enum DeviceKind {
  light,
  switchPlug,
  curtain,
  thermostat,
  sensorTempHum,
  contactSensor,
  speaker,
  camera,
  unknown,
}

/// Визуальная тема карточки/экрана
class DeviceVisual {
  final String title;
  final String asset; // PNG/WebP/SVG c прозрачным фоном
  final Color start;
  final Color end;
  final IconData glyph;

  const DeviceVisual({
    required this.title,
    required this.asset,
    required this.start,
    required this.end,
    required this.glyph,
  });
}

/// Карта визуалов по типу
const Map<DeviceKind, DeviceVisual> kKindVisuals = {
  DeviceKind.light: DeviceVisual(
    title: 'Light',
    asset: 'assets/devices/light.png',
    start: Color(0xFF6C7A89),
    end: Color(0xFF213142),
    glyph: Icons.light_mode_rounded,
  ),
  DeviceKind.switchPlug: DeviceVisual(
    title: 'Outlet',
    asset: 'assets/devices/outlet.png',
    start: Color(0xFF6E7A86),
    end: Color(0xFF1E2B3A),
    glyph: Icons.power_rounded,
  ),
  DeviceKind.curtain: DeviceVisual(
    title: 'Curtains',
    asset: 'assets/devices/curtain.png',
    start: Color(0xFF697787),
    end: Color(0xFF1A2736),
    glyph: Icons.curtains_rounded,
  ),
  DeviceKind.thermostat: DeviceVisual(
    title: 'AC / Thermostat',
    asset: 'assets/devices/ac.png',
    start: Color(0xFF5E7185),
    end: Color(0xFF162231),
    glyph: Icons.ac_unit_rounded,
  ),
  DeviceKind.sensorTempHum: DeviceVisual(
    title: 'Temp/Humidity',
    asset: 'assets/devices/sensor_temp.png',
    start: Color(0xFF677583),
    end: Color(0xFF172332),
    glyph: Icons.thermostat_rounded,
  ),
  DeviceKind.contactSensor: DeviceVisual(
    title: 'Contact',
    asset: 'assets/devices/contact.png',
    start: Color(0xFF6A7785),
    end: Color(0xFF1B2634),
    glyph: Icons.sensor_window_rounded,
  ),
  DeviceKind.speaker: DeviceVisual(
    title: 'Speaker',
    asset: 'assets/devices/speaker.png',
    start: Color(0xFF687685),
    end: Color(0xFF1A2635),
    glyph: Icons.speaker_rounded,
  ),
  DeviceKind.camera: DeviceVisual(
    title: 'Camera',
    asset: 'assets/devices/camera.png',
    start: Color(0xFF647383),
    end: Color(0xFF162232),
    glyph: Icons.videocam_rounded,
  ),
  DeviceKind.unknown: DeviceVisual(
    title: 'Device',
    asset: 'assets/devices/unknown.png',
    start: Color(0xFF7A8794),
    end: Color(0xFF273647),
    glyph: Icons.device_unknown_rounded,
  ),
};

/// Хелпер: достаём строку поля из rawData безопасно
String _s(dynamic v) => (v ?? '').toString();

/// Хелпер: есть ли в rawData ключ
bool _has(BaseDevice d, String key) => d.rawData.containsKey(key);

/// Классификация устройства по сырым данным
DeviceKind classifyDevice(BaseDevice d) {
  final type = _s(d.rawData['type']).toLowerCase();
  final name = _s(d.friendlyName ?? d.id).toLowerCase();
  final mfg = _s(d.rawData['manufacturer']).toLowerCase();
  final keys = d.rawData.keys.map((e) => e.toString().toLowerCase()).toSet();

  // Шторы
  if (type.contains('curtain') ||
      type.contains('znclbl') ||
      keys.contains('position')) {
    return DeviceKind.curtain;
  }

  // Свет (признаки яркости/температуры/цвета)
  if (type.contains('light') ||
      name.contains('lamp') ||
      keys.contains('brightness') ||
      keys.contains('color_temp') ||
      keys.contains('color')) {
    return DeviceKind.light;
  }

  // Реле/розетка/выключатель (управляемое простым ON/OFF)
  final hasState = keys.contains('state');
  final controllable = d.rawData['controllable'] == true;
  if (type.contains('switch') ||
      type.contains('plug') ||
      type.contains('relay') ||
      name.contains('розетка') ||
      (hasState && controllable)) {
    return DeviceKind.switchPlug;
  }

  // Термостат/кондиционер
  if (type.contains('thermo') ||
      type.contains('ac') ||
      (keys.contains('temperature') &&
          (keys.contains('target_temperature') || keys.contains('mode')))) {
    return DeviceKind.thermostat;
  }

  // Сенсоры климата
  if (keys.contains('temperature') || keys.contains('humidity')) {
    return DeviceKind.sensorTempHum;
  }

  // Контактный (дверь/окно)
  if (type.contains('contact') ||
      type.contains('door') ||
      type.contains('window') ||
      keys.contains('contact')) {
    return DeviceKind.contactSensor;
  }

  // Камера
  if (type.contains('camera') ||
      mfg.contains('hikvision') ||
      mfg.contains('dahua')) {
    return DeviceKind.camera;
  }

  // Спикер
  if (type.contains('speaker') ||
      type.contains('music') ||
      mfg.contains('sonos') ||
      mfg.contains('homepod')) {
    return DeviceKind.speaker;
  }

  return DeviceKind.unknown;
}
