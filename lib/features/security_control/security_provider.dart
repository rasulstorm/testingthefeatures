// lib/features/security/security_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ISS/core/network/dio_provider.dart'; // Ensure this import is correct
import 'package:ISS/models/hub_models.dart';

// Helper function to refresh access token and get a new one
// This function needs to be robust against refresh token expiry as well.
Future<String> _refreshAccessToken() async {
  final prefs = await SharedPreferences.getInstance();
  final refreshToken = prefs.getString('refreshToken');
  if (refreshToken == null || refreshToken.isEmpty) {
    // Handle case where refresh token is missing or empty, maybe force re-login
    throw Exception('Refresh token not found. Please log in again.');
  }

  try {
    // Use the global dio instance or create a new one to avoid interceptor recursion
    final refreshDio = Dio(BaseOptions(
      baseUrl: 'https://cms.iss-control.kz:8443/api/v1',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    final refreshResponse = await refreshDio.post(
      '/account-management/refresh',
      data: {'refreshToken': refreshToken},
    );

    if (refreshResponse.statusCode == 200) {
      final data = refreshResponse.data['data'];
      final newAccessToken = data['accessToken'];
      final newRefreshToken = data['refreshToken'];

      await prefs.setString('accessToken', newAccessToken);
      await prefs.setString('refreshToken', newRefreshToken);
      return newAccessToken;
    } else {
      throw DioException(
        requestOptions: refreshResponse.requestOptions,
        response: refreshResponse,
        type: DioExceptionType.badResponse,
        error: "Failed to refresh token: ${refreshResponse.statusCode}",
      );
    }
  } catch (e) {
    print('Error refreshing token: $e');
    // Consider clearing tokens and navigating to login on persistent refresh failures
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    rethrow; // Re-throw to propagate the error
  }
}

// Helper function for making GET requests with automatic token refresh
Future<Response> dioGetWithRefresh(String path) async {
  try {
    final token = await _refreshAccessToken(); // Always refresh before request
    final response = await dio.get( // Uses the global dio instance
      path,
      options: Options(headers: {'Authorization': 'Bearer $token'}), // Ensure 'Bearer' prefix
    );
    return response;
  } on DioException catch (e) {
    // You can add more specific error handling here if needed
    print('Dio error on GET $path: $e');
    rethrow;
  } catch (e) {
    print('Error on GET $path: $e');
    rethrow;
  }
}

// Helper function for making POST requests with automatic token refresh
Future<Response> dioPostWithRefresh(
  String path, {
  Map<String, dynamic>? data,
}) async {
  try {
    final token = await _refreshAccessToken(); // Always refresh before request
    final response = await dio.post( // Uses the global dio instance
      path,
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}), // Ensure 'Bearer' prefix
    );
    return response;
  } on DioException catch (e) {
    // You can add more specific error handling here if needed
    print('Dio error on POST $path: $e');
    rethrow;
  } catch (e) {
    print('Error on POST $path: $e');
    rethrow;
  }
}

// Provider to fetch a list of HubObjects
final objectsProvider = FutureProvider<List<HubObject>>((ref) async {
  try {
    // CORRECTED: Use dioGetWithRefresh for /hub/getObjects as it's a GET request
    final response = await dioGetWithRefresh('/hub/getObjects');

    if (response.data != null && response.data['data'] is List) {
      return (response.data['data'] as List)
          .map((e) => HubObject.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  } catch (e) {
    print('Error fetching objects: $e');
    rethrow; // Re-throw to let the UI handle the error state
  }
});

// Provider for security command services
final securityCommandProvider = Provider((ref) => SecurityCommandService());

class SecurityCommandService {
  Future<Response> sendCommand(String hubId, String command) async {
    // Assuming sendCommand is a POST operation
    // Adjust path if necessary, e.g., if it needs /api/v1/mobile/...
    return dioPostWithRefresh(
      '/mobile/hub/$hubId/sendCommand?command=$command',
    );
  }

  Future<Response> triggerAlarm(String hubId) async {
    // Assuming triggerAlarm is a POST operation
    // Note: This URL looks like a full URL, not relative to baseUrl.
    // If it's always a full URL, ensure your dioPostWithRefresh can handle it,
    // or call Dio directly with full URL. For now, assuming dio can handle full URL.
    return await dioPostWithRefresh(
      'https://signal-receiver.iss-control.kz:8443/api/hub/$hubId/alarm',
    );
  }

  Future<Response> attachHub(String hubId) async {
    // Assuming attach is a POST operation based on common API patterns for 'attach'
    // You mentioned a previous GET for this, but POST is more typical for such actions.
    // Double-check your API spec for /hub/$hubId/attach if it's GET or POST.
    // If it's GET, use dioGetWithRefresh.
    return dioPostWithRefresh(
      '/mobile/hub/$hubId/attach', // Relative path to baseUrl
    );
  }
}