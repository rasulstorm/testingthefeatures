// lib/core/network/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ISS/core/network/dio_provider.dart'; // Импортируем для использования базового URL

class AuthService {
  static const _accessTokenKey = 'accessToken';
  static const _refreshTokenKey = 'refreshToken';

  // Получить чистый токен из SharedPreferences (без Bearer)
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessTokenKey);
    if (token == null) return null;
    // Убедимся, что возвращаем чистый токен
    if (token.startsWith('Bearer ')) {
      return token.substring(7);
    }
    debugPrint('Получен Access Token: $token');
    return token;
  }

  // Сохранить токен в SharedPreferences без Bearer
  Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
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
  // Возвращает новый Access Token или null, если обновление не удалось
  Future<String?> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    debugPrint(
      '[AuthService] Attempting to refresh token. RefreshToken: $refreshToken',
    );

    if (refreshToken == null || refreshToken.isEmpty) {
      debugPrint(
        '[AuthService] Refresh token not found or empty. Clearing tokens.',
      );
      await clearTokens();
      return null; // Возвращаем null, так как нет refresh token для использования
    }

    // Используем отдельный Dio-инстанс БЕЗ ИНТЕРЦЕПТОРОВ для запроса обновления токена,
    // чтобы избежать рекурсии с AuthInterceptor.
    final Dio refreshDioInstance = Dio(
      BaseOptions(
        baseUrl: DioConfig.baseUrl, // Используем базовый URL из https_config
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    try {
      final response = await refreshDioInstance.post(
        '/account-management/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final newAccessToken = data['accessToken'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;

        if (newAccessToken != null && newRefreshToken != null) {
          await saveAccessToken(newAccessToken);
          await saveRefreshToken(newRefreshToken);
          debugPrint('[AuthService] Tokens successfully refreshed and saved.');
          return newAccessToken;
        } else {
          debugPrint(
            '[AuthService] Refresh response missing new tokens. Clearing tokens.',
          );
          await clearTokens();
          return null;
        }
      } else {
        // Если сервер вернул ошибку, это может означать, что refresh token недействителен.
        debugPrint(
          '[AuthService] Server returned error ${response.statusCode} during refresh. Clearing tokens.',
        );
        await clearTokens();
        return null;
      }
    } on DioException catch (e) {
      debugPrint(
        '[AuthService] DioException during refresh: ${e.message}. Clearing tokens.',
      );
      await clearTokens(); // Очищаем токены при сетевой ошибке или ошибке Dio
      return null;
    } catch (e) {
      debugPrint(
        '[AuthService] Unexpected error during refresh: $e. Clearing tokens.',
      );
      await clearTokens(); // Очищаем токены при любой другой ошибке
      return null;
    }
  }

  // Удалить токены (logout)
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    debugPrint('[AuthService] All tokens cleared.');
  }
}
