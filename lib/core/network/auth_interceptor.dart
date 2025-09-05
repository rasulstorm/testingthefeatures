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

  static const _kRetry401Key = '__retried401';

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
    final is401 = err.response?.statusCode == 401;
    final isRefreshCall = err.requestOptions.path.contains(
      '/account-management/refresh',
    );

    if (is401 && !isRefreshCall) {
      // prevent per-request infinite loops
      if (err.requestOptions.extra[_kRetry401Key] == true) {
        _clearQueueAndRedirect(err, handler);
        return;
      }

      // If not currently refreshing, start it
      if (!_isRefreshing) {
        _isRefreshing = true;
        String? newToken;
        try {
          newToken = await _authService.refreshAccessToken();
        } catch (_) {
          _isRefreshing = false;
          _clearQueueAndRedirect(err, handler);
          return;
        }

        if (newToken != null && newToken.isNotEmpty) {
          // drain queued
          for (int i = 0; i < _queuedRequests.length; i++) {
            final req = _queuedRequests[i];
            final completer = _completers[i];
            try {
              req.headers['Authorization'] = 'Bearer $newToken';
              req.extra[_kRetry401Key] = true; // mark
              final response = await dio.fetch(req);
              completer.complete(response);
            } on DioException catch (e) {
              completer.completeError(e);
            }
          }
          _queuedRequests.clear();
          _completers.clear();

          // retry the original
          final original = err.requestOptions;
          original.headers['Authorization'] = 'Bearer $newToken';
          original.extra[_kRetry401Key] = true;
          try {
            final response = await dio.fetch(original);
            _isRefreshing = false;
            return handler.resolve(response);
          } on DioException catch (e) {
            _isRefreshing = false;
            _clearQueueAndRedirect(e, handler);
            return;
          }
        } else {
          _isRefreshing = false;
          _clearQueueAndRedirect(err, handler);
          return;
        }
      } else {
        // already refreshing: queue if replayable
        if (_isReplayable(err.requestOptions)) {
          final completer = Completer<Response>();
          _queuedRequests.add(err.requestOptions);
          _completers.add(completer);
          try {
            final result = await completer.future;
            return handler.resolve(result);
          } on DioException catch (e) {
            return handler.reject(e);
          }
        } else {
          // not safely replayable — fail fast so UI can react
          _clearQueueAndRedirect(err, handler);
          return;
        }
      }
    }

    // otherwise pass through
    return handler.next(err);
  }

  void _clearQueueAndRedirect(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    for (final completer in _completers) {
      if (!completer.isCompleted) {
        completer.completeError(err);
      }
    }
    _queuedRequests.clear();
    _completers.clear();
    _isRefreshing = false;

    // Navigation: consider pushing this via a callback instead of here.
    if (navigatorKey.currentContext != null) {
      GoRouter.of(navigatorKey.currentContext!).go('/login');
    }
    handler.reject(err);
  }

  bool _isReplayable(RequestOptions req) {
    // Avoid retrying when there's a stream body (e.g., file upload)
    final hasStreamBody = req.data is Stream;
    return !hasStreamBody;
  }
}
