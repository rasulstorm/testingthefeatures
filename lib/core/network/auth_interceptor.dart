// lib/core/network/auth_interceptor.dart
import 'package:dio/dio.dart';
import 'dart:async';
import 'package:ISS/core/network/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:ISS/main.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  final AuthService _authService;
  bool _isRefreshing = false;
  final List<RequestOptions> _queuedRequests = [];
  final List<Completer<Response>> _completers = [];

  AuthInterceptor(this.dio, this._authService);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.path.contains('/account-management/refresh')) {
      return handler.next(options);
    }

    final token = await _authService.getAccessToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Проверяем, является ли ошибка 401 Unauthorized и не является ли это запросом на refresh
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/account-management/refresh')) {
      // Если токен истек и мы уже не обновляем
      if (!_isRefreshing) {
        _isRefreshing = true;
        String? newToken;
        try {
          newToken =
              await _authService.refreshAccessToken(); // Попытка обновить токен
        } catch (e) {
          // Если refresh не удался (например, refresh token тоже истек)
          _isRefreshing = false;
          _clearQueueAndRedirect(
            err,
            handler,
          ); // Очищаем очередь и перенаправляем
          return; // Выходим
        }

        if (newToken != null) {
          // Если новый токен получен успешно, выполняем все запросы из очереди
          for (int i = 0; i < _queuedRequests.length; i++) {
            final requestOptions = _queuedRequests[i];
            final completer = _completers[i];
            requestOptions.headers['Authorization'] = 'Bearer $newToken';
            try {
              final response = await dio.fetch(requestOptions);
              completer.complete(response);
            } on DioException catch (e) {
              completer.completeError(e);
            }
          }
          _queuedRequests.clear();
          _completers.clear();

          // Повторяем изначальный запрос, который вызвал 401
          final originalRequestOptions = err.requestOptions;
          originalRequestOptions.headers['Authorization'] = 'Bearer $newToken';
          try {
            final response = await dio.fetch(originalRequestOptions);
            _isRefreshing = false; // Сбрасываем флаг после успешного повтора
            return handler.resolve(response);
          } on DioException catch (e) {
            _isRefreshing = false; // Сбрасываем флаг
            _clearQueueAndRedirect(
              e,
              handler,
            ); // Если повторный запрос также провалился
            return;
          }
        } else {
          // Если newToken null (не удалось обновить токен, но исключения не было)
          _clearQueueAndRedirect(
            err,
            handler,
          ); // Очищаем очередь и перенаправляем
          return;
        }
      } else {
        // Если токен истек, но уже идет процесс обновления, ставим запрос в очередь
        final completer = Completer<Response>();
        _queuedRequests.add(err.requestOptions);
        _completers.add(completer);

        try {
          final result = await completer.future;
          return handler.resolve(result);
        } on DioException catch (e) {
          return handler.reject(
            e,
          ); // Отклоняем запрос, если он провалился из очереди
        }
      }
    }

    // Для всех остальных ошибок
    return handler.next(err);
  }

  // Вспомогательный метод для очистки очереди и перенаправления на логин
  void _clearQueueAndRedirect(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    for (final completer in _completers) {
      if (!completer.isCompleted) {
        completer.completeError(err); // Завершаем ожидающие запросы с ошибкой
      }
    }
    _queuedRequests.clear();
    _completers.clear();
    _isRefreshing = false; // Убедимся, что флаг сброшен

    // Перенаправляем на экран логина
    if (navigatorKey.currentContext != null) {
      GoRouter.of(navigatorKey.currentContext!).go('/login');
    }
    handler.reject(err); // Отклоняем оригинальный запрос
  }
}
