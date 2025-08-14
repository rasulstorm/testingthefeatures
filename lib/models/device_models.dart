// lib/models/device_models.dart

// 1. Базовый класс с общими для всех устройств полями
abstract class BaseDevice {
  final String id;
  final String friendlyName;
  final String model;
  final String manufacturer;
  final int linkQuality;
  final int? battery;
  final Map<String, dynamic> rawData;

  BaseDevice({
    required this.id,
    required this.friendlyName,
    required this.model,
    required this.manufacturer,
    required this.linkQuality,
    required this.rawData,
    this.battery,
  });

  // Фабричный конструктор отсюда УДАЛЕН, так как он создавал ошибку компиляции.
}

// 2. Миксин для управляемых устройств (у них есть состояние)
mixin ControllableDevice {
  bool get isOn;
}

// --- Классы для Управляемых Устройств ---

class OnOffSwitchDevice extends BaseDevice with ControllableDevice {
  @override
  final bool isOn;
  final double? power;
  final double? voltage;
  final double? current;

  OnOffSwitchDevice({
    required super.id,
    required super.friendlyName,
    required super.model,
    required super.manufacturer,
    required super.linkQuality,
    required super.battery,
    required super.rawData,
    required this.isOn,
    this.power,
    this.voltage,
    this.current,
  });
}

class DimmableLightDevice extends BaseDevice with ControllableDevice {
  @override
  final bool isOn;
  final int brightness;

  DimmableLightDevice({
    required super.id,
    required super.friendlyName,
    required super.model,
    required super.manufacturer,
    required super.linkQuality,
    required super.battery,
    required super.rawData,
    required this.isOn,
    required this.brightness,
  });
}

// --- Классы для Сенсоров (Неуправляемые) ---

class MotionSensorDevice extends BaseDevice {
  final bool hasMotion; // occupancy
  final int? illuminance;

  MotionSensorDevice({
    required super.id,
    required super.friendlyName,
    required super.model,
    required super.manufacturer,
    required super.linkQuality,
    required super.battery,
    required super.rawData,
    required this.hasMotion,
    this.illuminance,
  });
}

class PresenceSensorDevice extends BaseDevice {
  final bool isPresent; // presence

  PresenceSensorDevice({
    required super.id,
    required super.friendlyName,
    required super.model,
    required super.manufacturer,
    required super.linkQuality,
    required super.battery,
    required super.rawData,
    required this.isPresent,
  });
}

class ContactSensorDevice extends BaseDevice {
  final bool isClosed; // contact: true - ЗАКРЫТО, false - ОТКРЫТО

  ContactSensorDevice({
    required super.id,
    required super.friendlyName,
    required super.model,
    required super.manufacturer,
    required super.linkQuality,
    required super.battery,
    required super.rawData,
    required this.isClosed,
  });
}

class TempHumiditySensorDevice extends BaseDevice {
  final double temperature;
  final double humidity;

  TempHumiditySensorDevice({
    required super.id,
    required super.friendlyName,
    required super.model,
    required super.manufacturer,
    required super.linkQuality,
    required super.battery,
    required super.rawData,
    required this.temperature,
    required this.humidity,
  });
}

class LeakSensorDevice extends BaseDevice {
  final bool hasLeak; // water_leak

  LeakSensorDevice({
    required super.id,
    required super.friendlyName,
    required super.model,
    required super.manufacturer,
    required super.linkQuality,
    required super.battery,
    required super.rawData,
    required this.hasLeak,
  });
}

// Заглушка для неизвестных устройств, чтобы приложение не падало
class UnknownDevice extends BaseDevice {
  UnknownDevice({
    required super.id,
    required super.friendlyName,
    required super.model,
    required super.manufacturer,
    required super.linkQuality,
    required super.battery,
    required super.rawData,
  });
}
