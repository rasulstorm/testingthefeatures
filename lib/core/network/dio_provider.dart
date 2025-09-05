import 'package:dio/dio.dart';
import 'package:ISS/core/network/auth_service.dart';
import 'package:ISS/core/network/auth_interceptor.dart';
import 'dart:developer' as dev;

class ServerUnavailableException implements Exception {
  final String message;
  ServerUnavailableException(this.message);
  @override
  String toString() => message;
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.type == DioExceptionType.badResponse &&
            (statusCode == 500 || statusCode == 502 || statusCode == 503))) {
      final customException = ServerUnavailableException(
        "Сервер временно недоступен. Попробуйте позже.",
      );
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: customException,
        ),
      );
    }
    return handler.next(err);
  }
}

class RetryInterceptor extends Interceptor {
  final Dio dio;
  RetryInterceptor(this.dio);

  @override
  Future onError(DioException err, ErrorInterceptorHandler handler) async {
    final retriable =
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError;

    if (!retriable) return super.onError(err, handler);

    for (var attempt = 1; attempt <= 2; attempt++) {
      await Future.delayed(Duration(milliseconds: 400 * attempt));
      try {
        final response = await dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (_) {}
    }
    return super.onError(err, handler);
  }
}

class DioConfig {
  static const String baseUrl = 'https://stage-app.iss-control.kz:443/api/v1';
}

final Dio dio = Dio(
  BaseOptions(
    baseUrl: DioConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ),
);

void setupDioInterceptors(AuthService authService) {
  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => dev.log(obj.toString()),
    ),
  );
  dio.interceptors.add(AuthInterceptor(dio, authService));
  dio.interceptors.add(ErrorInterceptor());
  dio.interceptors.add(RetryInterceptor(dio));
}
