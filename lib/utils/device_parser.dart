import 'package:ISS/models/device_models.dart';

class DeviceParser {
  static BaseDevice parse(Map<String, dynamic> json) {
    // --- УЛУЧШЕННАЯ ЛОГИКА ИМЕН И ID ---
    // friendlyName - это всегда физический ID устройства (Zigbee ID)
    final String friendlyName =
        json['name'] ??
        json['device']?['friendlyName'] ??
        json['deviceId'] ??
        json['id'] ??
        'unknown_friendly_name';
    // id - это всегда UUID из нашей базы данных
    final String id = json['id'] ?? friendlyName;

    // Используем 'parameters' если есть, иначе - сам json
    final params = json['parameters'] as Map<String, dynamic>? ?? json;

    final String model = params['model'] ?? 'Unknown Model';
    final String manufacturer =
        params['manufacturer'] ?? 'Unknown Manufacturer';
    final int linkQuality = (params['linkquality'] as num?)?.toInt() ?? 0;
    final int? battery = (params['battery'] as num?)?.toInt();

    if (params.containsKey('water_leak')) {
      return LeakSensorDevice(
        id: id,
        friendlyName: friendlyName,
        model: model,
        manufacturer: manufacturer,
        linkQuality: linkQuality,
        battery: battery,
        rawData: json,
        hasLeak: params['water_leak'] ?? false,
      );
    }
    if (params.containsKey('temperature') && params.containsKey('humidity')) {
      return TempHumiditySensorDevice(
        id: id,
        friendlyName: friendlyName,
        model: model,
        manufacturer: manufacturer,
        linkQuality: linkQuality,
        battery: battery,
        rawData: json,
        temperature: (params['temperature'] as num).toDouble(),
        humidity: (params['humidity'] as num).toDouble(),
      );
    }
    if (params.containsKey('contact')) {
      return ContactSensorDevice(
        id: id,
        friendlyName: friendlyName,
        model: model,
        manufacturer: manufacturer,
        linkQuality: linkQuality,
        battery: battery,
        rawData: json,
        isClosed: params['contact'] ?? true,
      );
    }
    if (params.containsKey('presence')) {
      return PresenceSensorDevice(
        id: id,
        friendlyName: friendlyName,
        model: model,
        manufacturer: manufacturer,
        linkQuality: linkQuality,
        battery: battery,
        rawData: json,
        isPresent: params['presence'] ?? false,
      );
    }
    if (params.containsKey('occupancy')) {
      return MotionSensorDevice(
        id: id,
        friendlyName: friendlyName,
        model: model,
        manufacturer: manufacturer,
        linkQuality: linkQuality,
        battery: battery,
        rawData: json,
        hasMotion: params['occupancy'] ?? false,
        illuminance: (params['illuminance'] as num?)?.toInt(),
      );
    }
    if (params.containsKey('brightness')) {
      return DimmableLightDevice(
        id: id,
        friendlyName: friendlyName,
        model: model,
        manufacturer: manufacturer,
        linkQuality: linkQuality,
        battery: battery,
        rawData: json,
        isOn: params['state'] == 'ON',
        brightness: (params['brightness'] as num?)?.toInt() ?? 0,
      );
    }
    if (params.containsKey('state') &&
        (params.containsKey('power') || params.containsKey('current'))) {
      return OnOffSwitchDevice(
        id: id,
        friendlyName: friendlyName,
        model: model,
        manufacturer: manufacturer,
        linkQuality: linkQuality,
        battery: battery,
        rawData: json,
        isOn: params['state'] == 'ON',
        power: (params['power'] as num?)?.toDouble(),
        voltage: (params['voltage'] as num?)?.toDouble(),
        current: (params['current'] as num?)?.toDouble(),
      );
    }
    if (params.containsKey('state')) {
      return OnOffSwitchDevice(
        id: id,
        friendlyName: friendlyName,
        model: model,
        manufacturer: manufacturer,
        linkQuality: linkQuality,
        battery: battery,
        rawData: json,
        isOn: params['state'] == 'ON',
      );
    }

    return UnknownDevice(
      id: id,
      friendlyName: friendlyName,
      model: model,
      manufacturer: manufacturer,
      linkQuality: linkQuality,
      battery: battery,
      rawData: json,
    );
  }
}
