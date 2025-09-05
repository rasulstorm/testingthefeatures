import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:ISS/core/network/dio_provider.dart';

final roomsServiceProvider = Provider((ref) => RoomsService());

class RoomsService {
  String _extractMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return fallback;
  }

  Future<void> createRoom(String spaceId, String name) async {
    try {
      await dio.post('/space/$spaceId/room', data: {'name': name});
    } on DioException catch (e) {
      throw _extractMessage(e, 'Error creating room');
    }
  }

  Future<void> updateRoomName(
    String spaceId,
    String roomId,
    String newName,
  ) async {
    try {
      await dio.put('/space/$spaceId/room/$roomId', data: {'name': newName});
    } on DioException catch (e) {
      throw _extractMessage(e, 'Error updating room');
    }
  }

  Future<void> deleteRoom(String spaceId, String roomId) async {
    try {
      await dio.delete('/space/$spaceId/room/$roomId');
    } on DioException catch (e) {
      throw _extractMessage(e, 'Error deleting room');
    }
  }

  Future<void> assignDeviceToRoom(String deviceId, String roomId) async {
    try {
      await dio.post('/device/$deviceId/assign-to-room/$roomId');
    } on DioException catch (e) {
      throw _extractMessage(e, 'Error assigning device');
    }
  }

  Future<List<Map<String, dynamic>>> getDevicesByRoom(String roomId) async {
    try {
      final res = await dio.get('/device/$roomId/find-by-room');
      final List data = res.data?['data'] ?? [];
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _extractMessage(e, 'Error loading devices by room');
    }
  }

  Future<List<Map<String, dynamic>>> getDevicesBySpace(String spaceId) async {
    try {
      final res = await dio.get('/device/$spaceId/find-by-space');
      final List data = res.data?['data'] ?? [];
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _extractMessage(e, 'Error loading devices by space');
    }
  }
}
