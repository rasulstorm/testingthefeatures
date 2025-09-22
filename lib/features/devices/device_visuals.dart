import 'package:flutter/material.dart';
import 'device_kinds.dart';

class DeviceVisuals {
  final IconData icon;
  final List<Color> gradient;
  final String? asset; // PNG/WebP/SVG с прозрачным фоном (не обязателен)
  const DeviceVisuals({required this.icon, required this.gradient, this.asset});
}

const _g1 = [Color(0xFF5E7385), Color(0xFF243241)];
const _g2 = [Color(0xFF6D5DF6), Color(0xFF4531B1)];
const _g3 = [Color(0xFF00B09B), Color(0xFF96C93D)];
const _g4 = [Color(0xFF1D976C), Color(0xFF2F80ED)];
const _g5 = [Color(0xFFEB5757), Color(0xFFF2994A)];
const _g6 = [Color(0xFF0F2027), Color(0xFF203A43)];
const _g7 = [Color(0xFF2C3E50), Color(0xFF4CA1AF)];

final Map<DeviceKind, DeviceVisuals> deviceVisuals = {
  DeviceKind.light: DeviceVisuals(
    icon: Icons.lightbulb_outline_rounded,
    gradient: _g2,
    // asset: 'assets/devices/light.png',
  ),
  DeviceKind.plug: DeviceVisuals(
    icon: Icons.power_outlined,
    gradient: _g3,
    // asset: 'assets/devices/plug.png',
  ),
  DeviceKind.ac: DeviceVisuals(
    icon: Icons.ac_unit_rounded,
    gradient: _g4,
    // asset: 'assets/devices/ac.png',
  ),
  DeviceKind.curtains: DeviceVisuals(
    icon: Icons.window_rounded,
    gradient: _g7,
    // asset: 'assets/devices/curtains.png',
  ),
  DeviceKind.speaker: DeviceVisuals(
    icon: Icons.speaker_rounded,
    gradient: _g6,
    // asset: 'assets/devices/speaker.png',
  ),
  DeviceKind.tempSensor: DeviceVisuals(
    icon: Icons.thermostat_rounded,
    gradient: _g1,
  ),
  DeviceKind.humiditySensor: DeviceVisuals(
    icon: Icons.water_drop_rounded,
    gradient: _g1,
  ),
  DeviceKind.contactSensor: DeviceVisuals(
    icon: Icons.sensors_rounded,
    gradient: _g1,
  ),
  DeviceKind.unknown: DeviceVisuals(
    icon: Icons.device_unknown_rounded,
    gradient: _g5,
  ),
};
