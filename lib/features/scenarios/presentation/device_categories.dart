// lib/features/scenarios/presentation/device_categories.dart
import 'package:flutter/material.dart';

class DeviceCategoryDef {
  final String apiName; // строгое имя для /device/category/{apiName}
  final String label; // подпись в UI
  final IconData icon;
  const DeviceCategoryDef(this.apiName, this.label, this.icon);
}

// Полный список из бэка:
const allServerCategories = <String>{
  'MOTION_SENSOR',
  'CONTACT_SENSOR',
  'TEMPERATURE_SENSOR',
  'HUMIDITY_SENSOR',
  'ILLUMINANCE_SENSOR',
  'LEAK_SENSOR',
  'SMOKE_SENSOR',
  'CO2_SENSOR',
  'VIBRATION_SENSOR',
  'BUTTON',
  'PRESENCE_SENSOR',
  'LIGHT_SWITCH',
};

// Алиасы → нормализованные имена (кейс инсенситив)
String normalizeCategory(String input) {
  switch (input.toUpperCase()) {
    case 'SWITCH':
    case 'LIGHT':
    case 'RELAY':
    case 'SMART_PLUG':
    case 'PLUG':
      return 'LIGHT_SWITCH';
    case 'MOTION':
      return 'MOTION_SENSOR';
    case 'CONTACT':
      return 'CONTACT_SENSOR';
    case 'TEMPERATURE':
      return 'TEMPERATURE_SENSOR';
    case 'HUMIDITY':
      return 'HUMIDITY_SENSOR';
    case 'ILLUMINANCE':
      return 'ILLUMINANCE_SENSOR';
    case 'LEAK':
      return 'LEAK_SENSOR';
    case 'SMOKE':
      return 'SMOKE_SENSOR';
    case 'CO2':
      return 'CO2_SENSOR';
    case 'PRESENCE':
      return 'PRESENCE_SENSOR';
    default:
      return input.toUpperCase();
  }
}

// Сенсорные категории (для Триггеров)
const sensorCategories = <DeviceCategoryDef>[
  DeviceCategoryDef('MOTION_SENSOR', 'Движение', Icons.sensors),
  DeviceCategoryDef('PRESENCE_SENSOR', 'Присутствие', Icons.person_pin_circle),
  DeviceCategoryDef('CONTACT_SENSOR', 'Открытие', Icons.door_front_door),
  DeviceCategoryDef(
    'ILLUMINANCE_SENSOR',
    'Освещённость',
    Icons.wb_sunny_outlined,
  ),
  DeviceCategoryDef(
    'TEMPERATURE_SENSOR',
    'Температура',
    Icons.device_thermostat,
  ),
  DeviceCategoryDef('HUMIDITY_SENSOR', 'Влажность', Icons.water_drop),
  DeviceCategoryDef('LEAK_SENSOR', 'Протечка', Icons.water_damage),
  DeviceCategoryDef('SMOKE_SENSOR', 'Дым', Icons.smoking_rooms),
  DeviceCategoryDef('CO2_SENSOR', 'CO₂', Icons.co2),
  DeviceCategoryDef('VIBRATION_SENSOR', 'Вибрация', Icons.vibration),
  DeviceCategoryDef('BUTTON', 'Кнопка', Icons.radio_button_checked),
];

// Категории для Действий (то, чем реально управляем):
const actionCategories = <DeviceCategoryDef>[
  DeviceCategoryDef(
    'LIGHT_SWITCH',
    'Переключатели/свет/реле/розетки',
    Icons.toggle_on,
  ),
];
