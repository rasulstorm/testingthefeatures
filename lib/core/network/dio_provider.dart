import 'package:dio/dio.dart';
import 'auth_service.dart';

final authService = AuthService();

late final Dio dio;

void setupDio() {
  dio = Dio(BaseOptions(
    baseUrl: 'https://cms.iss-control.kz:8443/api/v1',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await authService.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (err, handler) async {
      if (err.response?.statusCode == 401) {
        try {
          final newToken = await authService.refreshAccessToken();
          final requestOptions = err.requestOptions;
          requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final response = await dio.fetch(requestOptions);
          return handler.resolve(response);
        } catch (_) {
          await authService.clearTokens();
          return handler.next(err);
        }
      }
      return handler.next(err);
    },
  ));
}
