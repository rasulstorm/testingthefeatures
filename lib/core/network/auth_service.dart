import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class AuthService {
  static const _accessTokenKey = 'accessToken';
  static const _refreshTokenKey = 'refreshToken';

  // Получить чистый токен из SharedPreferences (без Bearer)
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessTokenKey);
    if (token == null) return null;
    if (token.startsWith('Bearer ')) {
      return token.substring(7);
    }
    return token;
  }

  // Сохранить токен в SharedPreferences без Bearer
  Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    // Убедимся, что сохраняем без "Bearer "
    final cleanToken = token.startsWith('Bearer ') ? token.substring(7) : token;
    await prefs.setString(_accessTokenKey, cleanToken);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, token);
  }

  // Обновить токен, вызывая API
  Future<String> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('Refresh token not found. Please log in again.');
    }

    final dio = Dio(BaseOptions(
      baseUrl: 'https://cms.iss-control.kz:8443/api/v1',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    final response = await dio.post(
      '/account-management/refresh',
      data: {'refreshToken': refreshToken},
    );

    if (response.statusCode == 200) {
      final data = response.data['data'];
      final newAccessToken = data['accessToken'] as String;
      final newRefreshToken = data['refreshToken'] as String;

      await saveAccessToken(newAccessToken);
      await saveRefreshToken(newRefreshToken);

      return newAccessToken;
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: "Failed to refresh token: ${response.statusCode}",
      );
    }
  }

  // Удалить токены (logout)
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }
}
