// lib/features/scenarios/presentation/icons_theme.dart
import 'package:flutter/material.dart';

class GradientSpec {
  final List<Color> colors;
  final Alignment begin;
  final Alignment end;
  const GradientSpec(this.colors, this.begin, this.end);
}

IconData templateIcon(String type) {
  switch (type.toUpperCase()) {
    case 'MOTION':
    case 'MOTION_SENSOR':
      return Icons.sensors;
    case 'PRESENCE':
    case 'PRESENCE_SENSOR':
      return Icons.person_pin_circle;
    case 'CONTACT':
    case 'CONTACT_SENSOR':
      return Icons.door_front_door;
    case 'ILLUMINANCE':
    case 'ILLUMINANCE_SENSOR':
      return Icons.wb_sunny_outlined;
    case 'TEMPERATURE':
    case 'TEMPERATURE_SENSOR':
      return Icons.device_thermostat;
    case 'HUMIDITY':
    case 'HUMIDITY_SENSOR':
      return Icons.water_drop;
    case 'LEAK':
    case 'LEAK_SENSOR':
      return Icons.water_damage;
    case 'SMOKE':
    case 'SMOKE_SENSOR':
      return Icons.smoking_rooms;
    case 'CO2':
    case 'CO2_SENSOR':
      return Icons.co2;
    case 'VIBRATION':
    case 'VIBRATION_SENSOR':
      return Icons.vibration;
    case 'BUTTON':
      return Icons.radio_button_checked;
    case 'SWITCH':
    case 'LIGHT':
    case 'LIGHT_SWITCH':
      return Icons.toggle_on;
    default:
      return Icons.auto_awesome;
  }
}

GradientSpec templateGradient(String type) {
  switch (type.toUpperCase()) {
    case 'MOTION':
    case 'MOTION_SENSOR':
      return const GradientSpec(
        [Colors.greenAccent, Colors.green],
        Alignment.topLeft,
        Alignment.bottomRight,
      );
    case 'CONTACT':
    case 'CONTACT_SENSOR':
      return const GradientSpec(
        [Colors.orangeAccent, Colors.deepOrange],
        Alignment.topRight,
        Alignment.bottomLeft,
      );
    case 'ILLUMINANCE':
    case 'ILLUMINANCE_SENSOR':
      return const GradientSpec(
        [Colors.amberAccent, Colors.orange],
        Alignment.topLeft,
        Alignment.bottomRight,
      );
    case 'TEMPERATURE':
    case 'TEMPERATURE_SENSOR':
      return const GradientSpec(
        [Colors.redAccent, Colors.red],
        Alignment.topLeft,
        Alignment.bottomRight,
      );
    case 'HUMIDITY':
    case 'HUMIDITY_SENSOR':
      return const GradientSpec(
        [Colors.lightBlueAccent, Colors.blue],
        Alignment.topRight,
        Alignment.bottomLeft,
      );
    case 'LEAK':
    case 'LEAK_SENSOR':
      return const GradientSpec(
        [Colors.cyanAccent, Colors.teal],
        Alignment.topLeft,
        Alignment.bottomRight,
      );
    case 'SMOKE':
    case 'SMOKE_SENSOR':
      return const GradientSpec(
        [Colors.grey, Colors.blueGrey],
        Alignment.topRight,
        Alignment.bottomLeft,
      );
    case 'CO2':
    case 'CO2_SENSOR':
      return const GradientSpec(
        [Colors.lightGreenAccent, Colors.green],
        Alignment.topLeft,
        Alignment.bottomRight,
      );
    case 'VIBRATION':
    case 'VIBRATION_SENSOR':
      return const GradientSpec(
        [Colors.purpleAccent, Colors.deepPurple],
        Alignment.topRight,
        Alignment.bottomLeft,
      );
    case 'BUTTON':
      return const GradientSpec(
        [Colors.indigoAccent, Colors.indigo],
        Alignment.topLeft,
        Alignment.bottomRight,
      );
    case 'SWITCH':
    case 'LIGHT':
    case 'LIGHT_SWITCH':
      return const GradientSpec(
        [Colors.tealAccent, Colors.teal],
        Alignment.topRight,
        Alignment.bottomLeft,
      );
    default:
      return const GradientSpec(
        [Colors.purpleAccent, Colors.deepPurple],
        Alignment.topLeft,
        Alignment.bottomRight,
      );
  }
}
