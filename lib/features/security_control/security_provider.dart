import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> _refreshAccessToken() async {
  final prefs = await SharedPreferences.getInstance();
  final refreshToken = prefs.getString('refreshToken');
  if (refreshToken == null) throw Exception('Refresh token not found');

  final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
  final refreshResponse = await refreshDio.post(
    '/account-management/refresh',
    data: {'refreshToken': refreshToken},
  );

  final data = refreshResponse.data['data'];
  final newAccessToken = data['accessToken'];
  final newRefreshToken = data['refreshToken'];

  await prefs.setString('accessToken', newAccessToken);
  await prefs.setString('refreshToken', newRefreshToken);

  return newAccessToken;
}

Future<Response> dioGetWithRefresh(String path) async {
  final token = await _refreshAccessToken();
  final response = await dio.get(
    path,
    options: Options(headers: {'Authorization': '$token'}),
  );
  return response;
}

Future<Response> dioPostWithRefresh(
  String path, {
  Map<String, dynamic>? data,
}) async {
  final token = await _refreshAccessToken();
  final response = await dio.post(
    path,
    data: data,
    options: Options(headers: {'Authorization': '$token'}),
  );
  return response;
}

final objectsProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await dioGetWithRefresh('/mobile/hub/getByUser');
  return List<Map<String, dynamic>>.from(response.data);
});

final securityCommandProvider = Provider((ref) => SecurityCommandService());

class SecurityCommandService {
  Future<Response> sendCommand(String hubId, String command) async {
    return dioPostWithRefresh(
      '/mobile/hub/$hubId/sendCommand?command=$command',
    );
  }

  Future<Response> triggerAlarm(String hubId) async {
    return await dioPostWithRefresh(
      'https://signal-receiver.iss-control.kz:8443/api/hub/$hubId/alarm',
    );
  }
}
