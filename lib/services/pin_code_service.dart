// lib/services/pin_code_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart'; // Для debugPrint

class PinCodeService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _pinCodeKey = 'userPinCode';
  static const String _pinAttemptsKey =
      'pinAttempts'; // Ключ для хранения количества попыток
  static const int maxPinAttempts = 3; // Максимальное количество попыток

  /// Сохраняет пин-код в безопасном хранилище.
  Future<void> setPinCode(String pin) async {
    await _secureStorage.write(key: _pinCodeKey, value: pin);
    debugPrint('[PinCodeService] PIN code set successfully.');
    await resetPinAttempts(); // Сбрасываем счетчик попыток при установке нового пин-кода
  }

  /// Получает пин-код из безопасного хранилища.
  Future<String?> getPinCode() async {
    final pin = await _secureStorage.read(key: _pinCodeKey);
    debugPrint('[PinCodeService] Fetched PIN code (exists: ${pin != null}).');
    return pin;
  }

  /// Проверяет введенный пин-код.
  /// Возвращает true, если пин-код совпадает.
  Future<bool> verifyPinCode(String enteredPin) async {
    final storedPin = await getPinCode();
    debugPrint('[PinCodeService] Verifying PIN code...');
    if (storedPin == null) {
      debugPrint('[PinCodeService] No PIN code stored.');
      return false; // Нет сохраненного пин-кода
    }

    if (storedPin == enteredPin) {
      debugPrint('[PinCodeService] PIN code verification successful.');
      await resetPinAttempts(); // Сбрасываем счетчик при успешной попытке
      return true;
    } else {
      debugPrint(
        '[PinCodeService] PIN code verification failed. Incrementing attempts.',
      );
      await incrementPinAttempt();
      return false;
    }
  }

  /// Проверяет, установлен ли пин-код.
  Future<bool> hasPinCode() async {
    final pin = await getPinCode();
    return pin != null;
  }

  /// Удаляет пин-код.
  Future<void> deletePinCode() async {
    await _secureStorage.delete(key: _pinCodeKey);
    debugPrint('[PinCodeService] PIN code deleted.');
    await resetPinAttempts(); // Сбрасываем счетчик при удалении
  }

  /// Получает количество неудачных попыток ввода пин-кода.
  Future<int> getPinAttempts() async {
    final attemptsStr = await _secureStorage.read(key: _pinAttemptsKey);
    return int.tryParse(attemptsStr ?? '0') ?? 0;
  }

  /// Увеличивает количество неудачных попыток ввода пин-кода.
  Future<void> incrementPinAttempt() async {
    int attempts = await getPinAttempts();
    attempts++;
    await _secureStorage.write(
      key: _pinAttemptsKey,
      value: attempts.toString(),
    );
    debugPrint('[PinCodeService] PIN attempts: $attempts');
  }

  /// Сбрасывает количество неудачных попыток ввода пин-кода.
  Future<void> resetPinAttempts() async {
    await _secureStorage.write(key: _pinAttemptsKey, value: '0');
    debugPrint('[PinCodeService] PIN attempts reset to 0.');
  }

  /// Проверяет, заблокирован ли ввод пин-кода.
  Future<bool> isPinLockedOut() async {
    final attempts = await getPinAttempts();
    return attempts >= maxPinAttempts;
  }
}
