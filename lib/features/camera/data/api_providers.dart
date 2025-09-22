import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cameras_api.dart';
import '../utils/hls_probe.dart';

/// Базовый URL для live-сервиса камер
/// при необходимости подменяй через override в ProviderScope
final camerasBaseProvider = Provider<String>((ref) {
  return 'https://stage-app.iss-control.kz:443/live/api/v1';
});

/// Отдельный Dio под камеры (чтобы не конфликтовать с остальным DI)
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  return dio;
});

/// Пробник HLS (проверка доступности .m3u8/.ts)
final hlsProbeProvider = Provider<HlsProbe>((ref) {
  return HlsProbe(ref.read(dioProvider));
});

/// Сам API обёртка
final camerasApiProvider = Provider<CamerasApi>((ref) {
  final dio = ref.read(dioProvider);
  final base = ref.read(camerasBaseProvider);
  return CamerasApi(dio, camerasBase: base);
});
