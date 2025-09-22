import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class WeatherInfo {
  const WeatherInfo({
    required this.locationName,
    this.temperature,
    this.humidity,
    this.description,
    this.weatherCode,
  });

  final String locationName;
  final double? temperature;
  final double? humidity;
  final String? description;
  final int? weatherCode;
}

class WeatherCodeMapper {
  static const Map<int, String> _descriptions = {
    0: 'Ясно',
    1: 'Преимущественно ясно',
    2: 'Переменная облачность',
    3: 'Пасмурно',
    45: 'Туман',
    48: 'Туман с изморозью',
    51: 'Слабая морось',
    53: 'Умеренная морось',
    55: 'Сильная морось',
    61: 'Слабый дождь',
    63: 'Умеренный дождь',
    65: 'Сильный дождь',
    66: 'Ледяной дождь',
    67: 'Сильный ледяной дождь',
    71: 'Слабый снег',
    73: 'Умеренный снег',
    75: 'Сильный снег',
    77: 'Снежные зерна',
    80: 'Кратковременный дождь',
    81: 'Умеренный ливень',
    82: 'Сильный ливень',
    85: 'Кратковременный снег',
    86: 'Сильный снегопад',
    95: 'Гроза',
    96: 'Гроза с градом',
    99: 'Сильная гроза с градом',
  };

  static String? descriptionFor(int? code) =>
      code != null ? _descriptions[code] : null;
}

class WeatherService {
  WeatherService({Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));

  final Dio _dio;

  Future<WeatherInfo?> fetchWeatherByCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final weatherResp = await _dio.get(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'current': 'temperature_2m,relativehumidity_2m,weather_code',
        },
      );

      final current = weatherResp.data is Map
          ? weatherResp.data['current'] as Map<String, dynamic>?
          : null;

      final temp = (current?['temperature_2m'] as num?)?.toDouble();
      final humidity = (current?['relativehumidity_2m'] as num?)?.toDouble();
      final code = current?['weather_code'] as int?;

      String? locationName;
      try {
        final reverseResp = await _dio.get(
          'https://geocoding-api.open-meteo.com/v1/reverse',
          queryParameters: {
            'latitude': latitude,
            'longitude': longitude,
            'language': 'ru',
            'count': 1,
          },
        );
        final results = reverseResp.data is Map
            ? (reverseResp.data['results'] as List?)
            : null;
        if (results != null && results.isNotEmpty) {
          final first = results.first as Map<String, dynamic>;
          locationName =
              [first['name'], first['country']]
                  .whereType<String>()
                  .where((s) => s.trim().isNotEmpty)
                  .join(', ');
        }
      } catch (e) {
        debugPrint('[WeatherService] reverse geocode error: $e');
      }

      return WeatherInfo(
        locationName: locationName ?? 'Текущая локация',
        temperature: temp,
        humidity: humidity,
        weatherCode: code,
        description: WeatherCodeMapper.descriptionFor(code),
      );
    } catch (e, st) {
      debugPrint('[WeatherService] coord fetch error: $e\n$st');
      return null;
    }
  }

  Future<WeatherInfo?> fetchWeatherByQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;

    try {
      final geoResp = await _dio.get(
        'https://geocoding-api.open-meteo.com/v1/search',
        queryParameters: {
          'name': trimmed,
          'count': 1,
          'language': 'ru',
          'format': 'json',
        },
      );

      final results = geoResp.data is Map
          ? (geoResp.data['results'] as List?)
          : null;
      if (results == null || results.isEmpty) {
        return null;
      }

      final first = results.first as Map<String, dynamic>;
      final lat = (first['latitude'] as num?)?.toDouble();
      final lon = (first['longitude'] as num?)?.toDouble();
      if (lat == null || lon == null) return null;

      final locationName =
          [first['name'], first['country']]
              .whereType<String>()
              .where((s) => s.trim().isNotEmpty)
              .join(', ');

      final weatherResp = await _dio.get(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
          'current': 'temperature_2m,relativehumidity_2m,weather_code',
        },
      );

      final current = weatherResp.data is Map
          ? weatherResp.data['current'] as Map<String, dynamic>?
          : null;

      final temp = (current?['temperature_2m'] as num?)?.toDouble();
      final humidity = (current?['relativehumidity_2m'] as num?)?.toDouble();
      final code = current?['weather_code'] as int?;

      return WeatherInfo(
        locationName: locationName.isNotEmpty ? locationName : trimmed,
        temperature: temp,
        humidity: humidity,
        weatherCode: code,
        description: WeatherCodeMapper.descriptionFor(code),
      );
    } catch (e, st) {
      debugPrint('[WeatherService] fetch error: $e\n$st');
      return null;
    }
  }
}
