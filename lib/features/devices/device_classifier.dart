import 'device_types.dart';

class DeviceClassifier {
  static DeviceKind classify(Map<String, dynamic> j) {
    final model = (j['model'] ?? '').toString().toLowerCase();
    final manu = (j['manufacturer'] ?? '').toString().toLowerCase();

    bool has(String k) => j.containsKey(k);

    // curtains
    if (has('position') || model.contains('znclbl01lm')) {
      return DeviceKind.curtain;
    }

    // dimmer / light
    if (has('brightness') || model.contains('ms-105z')) {
      return DeviceKind.lightDimmable;
    }
    if (has('state') &&
        !has('brightness') &&
        !has('energy') &&
        !has('current')) {
      return DeviceKind.lightOnOff;
    }

    // relay / socket with power data
    if (has('energy') || has('current') || model.contains('ts000f_power')) {
      return DeviceKind.relay;
    }

    // sensors
    if (has('contact')) return DeviceKind.sensorContact;
    if (has('occupancy') &&
        !(manu.contains('tz3218') || model.contains('es1zz'))) {
      return DeviceKind.sensorMotion;
    }
    if (has('presence') ||
        manu.contains('_tz3218') ||
        model.contains('es1zz')) {
      return DeviceKind.sensorPresence;
    }
    if (has('water_leak')) return DeviceKind.sensorLeak;
    if (has('temperature') || has('humidity') || has('illuminance')) {
      return DeviceKind.sensorEnv;
    }
    if ((j['type'] ?? '').toString().toLowerCase().contains('vibration')) {
      return DeviceKind.sensorVibration;
    }

    return DeviceKind.generic;
  }
}
