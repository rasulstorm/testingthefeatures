import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/core/network/dio_provider.dart';

final hubServiceProvider = Provider<HubService>((ref) {
  return HubService();
});

class HubService {
  Future<bool> startPairing(String hubId) async {
    try {
      final response = await dio.post(
        '/mobile/hub/$hubId/pairing',
        data: {"command": "permit_join", "value": 120},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('❌ Error starting pairing: ${e.response?.data}');
      return false;
    } catch (e) {
      print('❓ Unexpected error during pairing: $e');
      return false;
    }
  }

  /// Отправляет команду на переименование хаба.
  Future<bool> renameHub(String hubId, String newName) async {
    if (newName.isEmpty) return false;
    try {
      final response = await dio.put(
        '/mobile/hub/$hubId/rename',
        data: {"facilityName": newName},
      );
      // API возвращает 200 при успехе
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('❌ Error renaming hub: ${e.response?.data}');
      return false;
    } catch (e) {
      print('❓ Unexpected error during rename: $e');
      return false;
    }
  }
}
