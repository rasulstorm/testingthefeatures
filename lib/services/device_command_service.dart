import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:ISS/core/network/dio_provider.dart';

final deviceCommandServiceProvider = Provider<DeviceCommandService>(
  (ref) => DeviceCommandService(dio),
);

class DeviceCommandService {
  DeviceCommandService(this._dio);

  final Dio _dio;
  final Uuid _uuid = const Uuid();

  Future<void> sendCommand({
    required String hubId,
    required String deviceName,
    required Map<String, dynamic> payload,
    String? correlationId,
  }) async {
    final body = <String, dynamic>{
      'correlationId': correlationId ?? _uuid.v4(),
      'hubId': hubId,
      'deviceName': deviceName,
      'payload': payload,
    };

    debugPrint(
      '[DeviceCommand] POST /device/send-command body=$body',
    );

    try {
      final response = await _dio.post('/device/send-command', data: body);
      final code = response.data is Map ? response.data['code'] as int? : null;
      if (response.statusCode != null &&
          (response.statusCode! < 200 || response.statusCode! >= 300)) {
        throw DeviceCommandException(
          message: 'device_command_error_http_${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
      if (code != null && code != 0) {
        final serverMessage =
            (response.data['message'] ?? 'device_command_error_generic')
                .toString();
        throw DeviceCommandException(
          message:
              serverMessage.isNotEmpty
                  ? serverMessage
                  : 'device_command_error_generic',
          statusCode: response.statusCode,
          code: code,
        );
      }
    } on DeviceCommandException {
      rethrow;
    } on DioException catch (e) {
      debugPrint('[DeviceCommand] DioException: ${e.message}');
      final status = e.response?.statusCode;
      final serverMessage =
          (e.response?.data is Map ? e.response?.data['message'] : null)
              ?.toString();
      throw DeviceCommandException(
        message:
            serverMessage?.isNotEmpty == true
                ? serverMessage!
                : 'device_command_error_generic',
        statusCode: status,
      );
    } catch (e) {
      debugPrint('[DeviceCommand] Unexpected error: $e');
      throw const DeviceCommandException(
        message: 'device_command_error_generic',
      );
    }
  }
}

class DeviceCommandException implements Exception {
  const DeviceCommandException({
    required this.message,
    this.statusCode,
    this.code,
  });

  final String message;
  final int? statusCode;
  final int? code;

  @override
  String toString() =>
      'DeviceCommandException(statusCode: $statusCode, code: $code, message: $message)';
}
