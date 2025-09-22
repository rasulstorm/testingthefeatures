import 'package:ISS/models/device_models.dart';

enum DeviceKind {
  light,
  plug,
  ac,
  curtains,
  speaker,
  tempSensor,
  humiditySensor,
  contactSensor,
  unknown,
}

extension DeviceKindDetect on BaseDevice {
  DeviceKind detectKind() {
    final raw = rawData;
    final t = (raw['type'] ?? raw['model'] ?? '').toString().toLowerCase();
    final m = (raw['manufacturer'] ?? '').toString().toLowerCase();
    final n =
        ((friendlyName.isNotEmpty ?? false) ? friendlyName : id)
            .toLowerCase();

    bool hasAny(Iterable<String> keys) =>
        keys.any((k) => t.contains(k) || n.contains(k) || m.contains(k));

    if (hasAny(['curtain', 'blind', 'shade', 'znclbl01lm'])) {
      return DeviceKind.curtains;
    }
    if (hasAny(['ac', 'air', 'climate', 'condition'])) return DeviceKind.ac;
    if (hasAny(['plug', 'socket', 'relay', 'розет'])) return DeviceKind.plug;
    if (hasAny(['light', 'lamp', 'bulb', 'свет', 'ламп'])) {
      return DeviceKind.light;
    }
    if (hasAny(['speaker', 'audio', 'music', 'homepod'])) {
      return DeviceKind.speaker;
    }
    if (hasAny(['temp', 'temperature', 'thermo'])) return DeviceKind.tempSensor;
    if (hasAny(['hum', 'humidity'])) return DeviceKind.humiditySensor;
    if (hasAny(['contact', 'door', 'window', 'reed'])) {
      return DeviceKind.contactSensor;
    }

    return DeviceKind.unknown;
  }
}
