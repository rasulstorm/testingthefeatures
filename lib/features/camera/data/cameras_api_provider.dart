// lib/features/camera/data/cameras_api_provider.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cameras_api.dart';

/// Базовый URL на прод/стейдж — подставь свой при необходимости.
final camerasBaseProvider = Provider<String>((_) {
  return 'https://stage-app.iss-control.kz:443/live/api/v1';
});

/// Локальный Dio под камеры (не конфликтует с другими, если они есть)
final camerasDioProvider = Provider<Dio>((_) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ),
  );
});

/// Провайдер API камер
final camerasApiProvider = Provider<CamerasApi>((ref) {
  final dio = ref.read(camerasDioProvider);
  final base = ref.read(camerasBaseProvider);
  return CamerasApi(dio, camerasBase: base);
});
