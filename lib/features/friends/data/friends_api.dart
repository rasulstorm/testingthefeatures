import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ISS/core/network/dio_provider.dart' as net;
import 'package:ISS/core/network/dio_provider.dart'
    show ServerUnavailableException;

import '../domain/friends_models.dart';

class FriendsApiException implements Exception {
  const FriendsApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.original,
  });

  final String message;
  final int? statusCode;
  final int? code;
  final DioException? original;

  @override
  String toString() =>
      'FriendsApiException(statusCode: $statusCode, code: $code, message: $message)';
}

class FriendsApi {
  FriendsApi({Dio? dio}) : _dio = dio ?? net.dio;

  final Dio _dio;

  static const _base = '/friends';

  Future<void> requestFriend(String friendEmail) =>
      _request<void>(() => _dio.post('$_base/request/$friendEmail'), (_) {});

  Future<void> acceptRequest(String requestId) =>
      _request<void>(() => _dio.post('$_base/accept/$requestId'), (_) {});

  Future<void> rejectRequest(String requestId) =>
      _request<void>(() => _dio.post('$_base/reject/$requestId'), (_) {});

  Future<void> removeFriend(String friendId) =>
      _request<void>(() => _dio.delete('$_base/remove/$friendId'), (_) {});

  Future<List<FriendRequest>> incoming() => _request(
    () => _dio.get('$_base/requests/incoming'),
    (data) =>
        (data as List? ?? const [])
            .map(
              (e) => FriendRequest.fromJson((e as Map).cast<String, dynamic>()),
            )
            .toList(),
  );

  Future<List<FriendRequest>> outgoing() => _request(
    () => _dio.get('$_base/requests/outgoing'),
    (data) =>
        (data as List? ?? const [])
            .map(
              (e) => FriendRequest.fromJson((e as Map).cast<String, dynamic>()),
            )
            .toList(),
  );

  Future<List<Friend>> list() => _request(
    () => _dio.get('$_base/list'),
    (data) =>
        (data as List? ?? const [])
            .map((e) => Friend.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
  );

  Future<List<FriendCoordinate>> coordinates() => _request(
    () => _dio.get('$_base/coordinates'),
    (data) =>
        (data as List? ?? const [])
            .map(
              (e) =>
                  FriendCoordinate.fromJson((e as Map).cast<String, dynamic>()),
            )
            .toList(),
  );

  Future<T> _request<T>(
    Future<Response<dynamic>> Function() call,
    T Function(dynamic data) parser,
  ) async {
    try {
      final response = await call();
      return _parseResponse(response, parser);
    } on DioException catch (e, stack) {
      debugPrint('[FriendsApi] DioException: ${e.message}');
      throw _mapDioException(e, stack);
    }
  }

  T _parseResponse<T>(Response response, T Function(dynamic data) parser) {
    final statusCode = response.statusCode ?? 0;
    dynamic payload = response.data;

    if (payload is Map &&
        payload.containsKey('code') &&
        payload.containsKey('message')) {
      final code = payload['code'] as int?;
      final message = (payload['message'] ?? '').toString();
      if (code == 0) {
        return parser(payload['data']);
      }
      throw FriendsApiException(
        statusCode: statusCode,
        code: code,
        message: message.isNotEmpty ? message : 'friends_error_unknown',
      );
    }

    if (statusCode >= 200 && statusCode < 300) {
      return parser(payload);
    }

    final statusKey = statusCode > 0 ? statusCode.toString() : 'unknown';
    throw FriendsApiException(
      statusCode: statusCode,
      message: 'friends_error_http_$statusKey',
    );
  }

  FriendsApiException _mapDioException(DioException error, StackTrace stack) {
    if (error.error is FriendsApiException) {
      return error.error as FriendsApiException;
    }

    final response = error.response;
    int? statusCode = response?.statusCode;
    int? code;
    String message = 'friends_error_generic';

    if (error.error is ServerUnavailableException) {
      message = (error.error as ServerUnavailableException).message;
      return FriendsApiException(
        message: message,
        statusCode: statusCode,
        code: code,
        original: error,
      );
    }

    if (response?.data is Map) {
      final map = response!.data as Map;
      code = map['code'] as int?;
      final serverMessage = map['message']?.toString();
      if (serverMessage != null && serverMessage.isNotEmpty) {
        message = serverMessage;
      }
    } else if (error.message != null && error.message!.isNotEmpty) {
      message = error.message!;
    }

    // Map known HTTP codes to friendly keys
    switch (statusCode) {
      case 401:
        message = 'friends_error_unauthorized';
        break;
      case 403:
        message = 'friends_error_forbidden';
        break;
      case 404:
        message = 'friends_error_not_found';
        break;
      case 409:
        message = 'friends_error_conflict';
        break;
      default:
        break;
    }

    return FriendsApiException(
      message: message,
      statusCode: statusCode,
      code: code,
      original: error,
    );
  }
}
