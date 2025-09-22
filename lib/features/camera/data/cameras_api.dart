// lib/features/camera/data/cameras_api.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/camera_models.dart';

class CamerasApi {
  final Dio _dio;

  /// пример: https://stage-app.iss-control.kz:443/live/api/v1
  final String camerasBase;

  CamerasApi(this._dio, {required this.camerasBase});

  String _u(String path) {
    if (path.startsWith('http')) return path;
    final p = path.startsWith('/') ? path : '/$path';
    return '$camerasBase$p';
  }

  Map<String, dynamic> _asMap(dynamic v) => (v as Map).cast<String, dynamic>();

  List<Camera> _parseListResponse(Response r) {
    final body = r.data;
    if (body is List) {
      return body.map((e) => Camera.fromJson(_asMap(e))).toList();
    }
    if (body is Map && body['data'] is List) {
      return (body['data'] as List)
          .map((e) => Camera.fromJson(_asMap(e)))
          .toList();
    }
    return const <Camera>[];
  }

  Camera _parseObjectResponse(Response r) {
    final body = r.data;
    if (body is Map && body['data'] is Map) {
      return Camera.fromJson(_asMap(body['data']));
    }
    return Camera.fromJson(_asMap(body));
  }

  /// Достаём токен из SharedPreferences
  Future<Options> _authOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return Options(headers: headers);
  }

  // GET /cameras/by-user
  Future<List<Camera>> byUser() async {
    final r = await _dio.get(
      _u('/cameras/by-user'),
      options: await _authOptions(),
    );
    return _parseListResponse(r);
  }

  // GET /cameras/{id}
  Future<Camera> getById(String id) async {
    final r = await _dio.get(_u('/cameras/$id'), options: await _authOptions());
    return _parseObjectResponse(r);
  }

  // POST /cameras
  Future<Camera> create(CameraRequest req) async {
    final r = await _dio.post(
      _u('/cameras'),
      data: req.toJson(),
      options: await _authOptions(),
    );
    return _parseObjectResponse(r);
  }

  // PUT /cameras/{id}
  Future<Camera> update(String id, CameraRequest req) async {
    final r = await _dio.put(
      _u('/cameras/$id'),
      data: req.toJson(),
      options: await _authOptions(),
    );
    return _parseObjectResponse(r);
  }

  // DELETE /cameras/{id}
  Future<void> delete(String id) async {
    await _dio.delete(_u('/cameras/$id'), options: await _authOptions());
  }

  // POST /cameras/{id}/activate
  Future<Camera> activate(String id) async {
    final r = await _dio.post(
      _u('/cameras/$id/activate'),
      options: await _authOptions(),
    );
    return _parseObjectResponse(r);
  }

  // POST /cameras/{id}/deactivate
  Future<Camera> deactivate(String id) async {
    final r = await _dio.post(
      _u('/cameras/$id/deactivate'),
      options: await _authOptions(),
    );
    return _parseObjectResponse(r);
  }
}
