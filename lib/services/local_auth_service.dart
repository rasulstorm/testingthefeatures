import 'package:flutter/material.dart'; // Для debugPrint
import 'package:flutter/services.dart'; // Для PlatformException
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Импортируйте ваш AuthService и PinCodeService, если они нужны
import 'package:ISS/core/network/auth_service.dart';
import 'package:ISS/services/pin_code_service.dart';

class LocalAuthService {
  final LocalAuthentication _auth = LocalAuthentication();
  final AuthService _authService; // Зависимость от вашего AuthService
  final PinCodeService _pinCodeService; // Зависимость от вашего PinCodeService
  static const String _localAuthEnabledKey = 'localAuthEnabled';

  LocalAuthService(this._authService, this._pinCodeService);

  /// Проверяет, доступна ли биометрическая аутентификация или PIN-код/пароль устройства.
  Future<bool> canAuthenticate() async {
    debugPrint('[LocalAuthService] Checking if authentication is available...');
    try {
      final bool canCheckBiometricsResult = await _auth.canCheckBiometrics;
      final bool isDeviceSupportedResult = await _auth.isDeviceSupported();
      debugPrint(
        '[LocalAuthService] canCheckBiometrics: $canCheckBiometricsResult, isDeviceSupported: $isDeviceSupportedResult',
      );
      // Устройство может аутентифицироваться, если доступна биометрия или пароль устройства
      return canCheckBiometricsResult || isDeviceSupportedResult;
    } on PlatformException catch (e) {
      debugPrint(
        '[LocalAuthService] PlatformException in canAuthenticate: ${e.code} - ${e.message}',
      );
      // Обработка конкретных ошибок платформы, если необходимо
      return false;
    } catch (e) {
      debugPrint(
        '[LocalAuthService] Unexpected error caught during canAuthenticate(): $e',
      );
      return false;
    }
  }

  /// Проверяет, включена ли локальная аутентификация пользователем.
  Future<bool> isLocalAuthEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_localAuthEnabledKey) ?? false;
  }

  /// Устанавливает статус локальной аутентификации.
  Future<void> setLocalAuthEnabled(bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_localAuthEnabledKey, enable);
  }

  /// Выполняет локальную аутентификацию (биометрия или PIN-код/пароль устройства).
  Future<bool> authenticate() async {
    debugPrint('[LocalAuthService] Attempting to authenticate...');
    try {
      final bool authenticated = await _auth.authenticate(
        localizedReason:
            'Подтвердите свою личность для входа в приложение', // Причина запроса аутентификации
        options: const AuthenticationOptions(
          stickyAuth:
              true, // Позволяет продолжить аутентификацию после перезапуска приложения
          biometricOnly:
              false, // Разрешает использование PIN/пароля устройства в качестве запасного варианта
        ),
      );
      debugPrint('[LocalAuthService] Authenticated: $authenticated');
      return authenticated;
    } on PlatformException catch (e) {
      debugPrint(
        '[LocalAuthService] PlatformException during authenticate(): ${e.code} - ${e.message}',
      );
      // Обработка ошибок, специфичных для платформы
      if (e.code == 'notAvailable' ||
          e.code == 'notEnrolled' ||
          e.code == 'passcodeNotSet') {
        // Биометрия недоступна, не зарегистрирована или PIN-код не установлен
        // Можно показать пользователю сообщение и предложить альтернативный вход
        debugPrint(
          '[LocalAuthService] Biometric/Passcode not available or not set.',
        );
      } else if (e.code == 'otherOperatingSystem') {
        // Другие ошибки операционной системы
        debugPrint('[LocalAuthService] Other OS error.');
      }
      return false;
    } catch (e) {
      debugPrint(
        '[LocalAuthService] Unexpected error caught during authenticate(): $e',
      );
      return false;
    }
  }

  /// Проверяет токен после успешной локальной аутентификации.
  /// Если токен истек, пытается его обновить.
  /// Возвращает true, если есть валидный токен для продолжения работы.
  Future<bool> checkAndRefreshToken() async {
    debugPrint('[LocalAuthService] Checking and refreshing token...');
    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) {
      debugPrint('[LocalAuthService] Access Token is missing.');
      return false;
    }

    try {
      final refreshToken = await _authService.getRefreshToken();
      if (refreshToken != null) {
        debugPrint(
          '[LocalAuthService] Refresh Token found. Attempting to refresh Access Token...',
        );
        await _authService.refreshAccessToken();
        debugPrint('[LocalAuthService] Token successfully refreshed.');
        return true;
      } else {
        debugPrint(
          '[LocalAuthService] Refresh Token is missing. Cannot refresh Access Token.',
        );
        return false;
      }
    } catch (e) {
      debugPrint('[LocalAuthService] Error during token refresh: $e');
      return false;
    }
  }
}
