import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:ISS/models/hub_models.dart';

final objectsProvider = FutureProvider<List<HubObject>>((ref) async {
  try {
    final response = await dio.get('/hub/getObjects');
    if (response.data != null && response.data['data'] is List) {
      return (response.data['data'] as List)
          .map((e) => HubObject.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  } catch (e) {
    print('Error fetching objects: $e');
    rethrow;
  }
});

final securityCommandProvider = Provider((ref) => SecurityCommandService());

class SecurityCommandService {
  Future<Response> sendCommand(String hubId, String command) async {
    return dio.post('/mobile/hub/$hubId/sendCommand?command=$command');
  }

  Future<Response> triggerAlarm(String hubId) async {
    return dio.post(
      'https://signal-receiver.iss-control.kz:8443/api/hub/$hubId/alarm',
    );
  }

  Future<Response> attachHub(String hubId) async {
    return dio.post('/mobile/hub/$hubId/attach');
  }
}
