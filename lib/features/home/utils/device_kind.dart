enum DeviceKind {
  light,
  plug,
  switcher,
  curtain,
  lock,
  thermostat,
  tempSensor,
  humidSensor,
  motion,
  contact,
  illuminance,
  battery,
  unknown,
}

DeviceKind detectKind(Map raw) {
  final t = ((raw['type'] ?? raw['title'] ?? '') as String).toLowerCase();
  final name = ((raw['name'] ?? '') as String).toLowerCase();
  final m = ((raw['manufacturer'] ?? '') as String).toLowerCase();

  bool has(String x) => t.contains(x) || name.contains(x);

  if (has('zbsoft') || has('light') || has('bulb') || has('lamp')) {
    return DeviceKind.light;
  }
  if (has('plug') || has('socket') || has('outlet')) return DeviceKind.plug;
  if (has('switch')) return DeviceKind.switcher;
  if (has('curtain') || has('blind') || has('znclbl01lm')) {
    return DeviceKind.curtain;
  }
  if (has('lock')) return DeviceKind.lock;
  if (has('thermostat') || has('heater')) return DeviceKind.thermostat;
  if (has('temperature')) return DeviceKind.tempSensor;
  if (has('humidity')) return DeviceKind.humidSensor;
  if (has('motion') || has('occupancy')) return DeviceKind.motion;
  if (has('contact') || has('door') || has('window')) return DeviceKind.contact;
  if (has('illuminance') || has('lux')) return DeviceKind.illuminance;
  if (has('battery')) return DeviceKind.battery;

  if (m.contains('aqara') && has('znclbl01lm')) return DeviceKind.curtain;

  return DeviceKind.unknown;
}
