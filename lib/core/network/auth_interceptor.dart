import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  bool _isRefreshing = false;
  final List<Function(String)> _queuedRequests = [];

  AuthInterceptor(this.dio);

  Future<String?> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');
    if (refreshToken == null) return null;

    try {
      final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
      final response = await refreshDio.post('/account-management/refresh', data: {
        'refreshToken': refreshToken,
      });

      final data = response.data['data'];
      final newAccessToken = data['accessToken'] as String?;
      final newRefreshToken = data['refreshToken'] as String?;

      if (newAccessToken == null || newRefreshToken == null) {
        throw Exception('Неверный ответ от сервера');
      }

      await prefs.setString('accessToken', newAccessToken);
      await prefs.setString('refreshToken', newRefreshToken);

      return newAccessToken;
    } catch (e) {
      return null;
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token != null) {
      options.headers['Authorization'] = '$token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;

      final newToken = await _refreshToken();
      _isRefreshing = false;

      if (newToken != null) {
        final options = err.requestOptions;
        options.headers['Authorization'] = '$newToken';

        try {
          final response = await dio.fetch(options);
          for (final callback in _queuedRequests) {
            callback(newToken);
          }
          _queuedRequests.clear();

          return handler.resolve(response);
        } catch (e) {
          return handler.reject(err);
        }
      } else {
        _queuedRequests.clear(); 
        return handler.reject(err);
      }
    }
    if (err.response?.statusCode == 401 && _isRefreshing) {
      final completer = Completer<Response>();

      _queuedRequests.add((String newToken) async {
        try {
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = '$newToken';
          final retryResponse = await dio.fetch(retryOptions);
          completer.complete(retryResponse);
        } catch (e) {
          completer.completeError(e);
        }
      });

      try {
        final result = await completer.future;
        return handler.resolve(result);
      } catch (e) {
        return handler.reject(err);
      }
    }

    return handler.next(err);
  }
}
