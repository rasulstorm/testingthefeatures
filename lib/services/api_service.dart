import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ISS/models/hub_models.dart'; // Import your HubObject and Device models
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  static const String _baseUrl =
      'https://app.iss-control.kz:443'; // Your base URL

  // Provider for ApiService (optional, but good practice with Riverpod)
  static final apiServiceProvider = Provider<ApiService>((ref) {
    final dio = Dio();
    return ApiService(dio);
  });

  Future<List<HubObject>> getHubs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token not found. Please log in.');
      }

      final response = await _dio.get(
        '$_baseUrl/api/v1/mobile/hub/getByUser', // Adjust this endpoint if needed
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => HubObject.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load hubs: ${response.statusCode} ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'API Error: ${e.response?.statusCode} - ${e.response?.data}',
        );
      } else {
        throw Exception('Network Error: ${e.message}');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
