// lib/core/network/dio_provider.dart
import 'package:dio/dio.dart';
import 'auth_interceptor.dart';

late final Dio dio;

void setupDio() {
  dio = Dio(BaseOptions(
    baseUrl: 'https://cms.iss-control.kz:8443/api/v1',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  dio.interceptors.add(AuthInterceptor(dio));
}
