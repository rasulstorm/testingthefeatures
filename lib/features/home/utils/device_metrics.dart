class Metric {
  final String label; // 28.1°
  final String name; // Temp
  Metric(this.label, this.name);
}

List<Metric> extractMetrics(Map raw) {
  final r = <Metric>[];

  num? n(dynamic v) => v is num ? v : num.tryParse('$v');
  String f(num? v) =>
      v == null
          ? '-'
          : (v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1));

  final temp = n(raw['temperature'] ?? raw['device_temperature']);
  if (temp != null) r.add(Metric('${f(temp)}°', 'Temp'));

  final hum = n(raw['humidity']);
  if (hum != null) r.add(Metric('${f(hum)}%', 'Humid'));

  final lux = n(raw['illuminance'] ?? raw['lux']);
  if (lux != null) r.add(Metric('${f(lux)} lx', 'Light'));

  final batt = n(raw['battery']);
  if (batt != null) r.add(Metric('${f(batt)}%', 'Battery'));

  final pos = n(raw['position']);
  if (pos != null) r.add(Metric('${f(pos)}%', 'Pos'));

  return r;
}
