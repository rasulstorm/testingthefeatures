// lib/features/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:ISS/services/firebase_messaging_service.dart';

final emailProvider = StateProvider<String?>((ref) => null);
final passwordProvider = StateProvider<String?>((ref) => null);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _rememberMe = true;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _loadUsers();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token != null && token.isNotEmpty) {
      if (context.mounted) {
        context.go('/main');
      }
    }
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');

    if (savedEmail != null && savedPassword != null) {
      ref.read(emailProvider.notifier).state = savedEmail;
      ref.read(passwordProvider.notifier).state = savedPassword;
      _emailController.text = savedEmail;
      _passwordController.text = savedPassword;
      setState(() {
        _rememberMe = true;
      });
    }
  }

  Future<void> _loadUsers() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/users.json',
      );
      final List<dynamic> data = json.decode(response);
      setState(() {
        _users = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      _showSnackbar("Ошибка загрузки пользователей из assets: $e");
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackbar('Введите email и пароль');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    if (kDebugMode) {
      final adapter = dio.httpClientAdapter as IOHttpClientAdapter;
      adapter.onHttpClientCreate = (client) {
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
    }

    try {
      final response = await dio.post(
        'https://app.iss-control.kz:443/api/v1/account-management/login',
        data: {"username": email, "password": password},
      );
      await _handleLoginResponse(response, email, password);
    } on DioException catch (e) {
      String errorMsg = 'Ошибка подключения';
      if (e.response != null) {
        final responseData = e.response!.data;
        if (responseData != null && responseData is Map<String, dynamic>) {
          errorMsg =
              responseData['error'] ?? responseData['message'] ?? errorMsg;
          if (errorMsg.contains('deleted') ||
              (responseData['code'] == 1 &&
                  responseData['message'].contains('deleted'))) {
            _showSnackbar('Ваш аккаунт был удален. Попытка восстановления...');
            await _restoreAccountAndLogin(email, password);
            return;
          }
        } else {
          errorMsg = 'Ошибка сервера: ${e.response!.statusCode}';
        }
      } else {
        errorMsg = 'Ошибка сети: ${e.message}';
      }
      _showSnackbar('Ошибка входа: $errorMsg');
    } catch (e) {
      _showSnackbar('Произошла непредвиденная ошибка: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLoginResponse(
    Response response,
    String email,
    String password,
  ) async {
    final responseData = response.data;

    if (responseData == null || responseData is! Map<String, dynamic>) {
      _showSnackbar('Ошибка: Неверный формат ответа сервера.');
      return;
    }

    final code = responseData['code'] as int?;
    final message = responseData['message'] as String?;

    if (code == 1) {
      if (message != null && message.contains('deleted')) {
        _showSnackbar('Ваш аккаунт был удален. Попытка восстановления...');
        await _restoreAccountAndLogin(email, password);
      } else {
        _showSnackbar('Ошибка: ${message ?? 'Неизвестная ошибка сервера'}');
      }
      return;
    }

    final accessToken = responseData['accessToken'] as String?;
    final refreshToken = responseData['refreshToken'] as String?;

    if (accessToken == null ||
        refreshToken == null ||
        accessToken.isEmpty ||
        refreshToken.isEmpty) {
      _showSnackbar('Ошибка: Ответ сервера не содержит данных авторизации.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', accessToken);
    await prefs.setString('refreshToken', refreshToken);
    await prefs.setString('saved_email', email);
    await prefs.setString('saved_password', password);

    // --- ИЗМЕНЕНИЕ ЗДЕСЬ ---
    // После успешного входа и сохранения токенов, отправляем FCM токен на сервер
    await ref.read(firebaseMessagingServiceProvider).sendFcmTokenToServer();
    // -------------------------

    _showSnackbar('Вход выполнен успешно');
    if (context.mounted) {
      context.go('/main');
    }
  }

  Future<void> _restoreAccountAndLogin(String email, String password) async {
    try {
      final restoreResponse = await dio.post(
        'https://app.iss-control.kz:443/api/v1/user/restore',
        data: {"username": email, "password": password},
      );

      final restoreData = restoreResponse.data;

      if (restoreData == null || restoreData is! Map<String, dynamic>) {
        _showSnackbar('Ошибка восстановления: Неверный формат ответа.');
        return;
      }

      final restoreCode = restoreData['code'] as int?;
      final restoreMessage = restoreData['message'] as String?;

      if (restoreCode == 0) {
        _showSnackbar('Аккаунт успешно восстановлен. Повторный вход...');
        final reLoginResponse = await dio.post(
          'https://app.iss-control.kz:443/api/v1/account-management/login',
          data: {"username": email, "password": password},
        );
        await _handleLoginResponse(reLoginResponse, email, password);
      } else {
        _showSnackbar(
          'Ошибка восстановления: ${restoreMessage ?? 'Неизвестная ошибка восстановления'}',
        );
      }
    } on DioException catch (e) {
      String errorMsg = 'Ошибка подключения при восстановлении';
      if (e.response != null) {
        final responseData = e.response!.data;
        if (responseData != null && responseData is Map<String, dynamic>) {
          errorMsg =
              responseData['error'] ?? responseData['message'] ?? errorMsg;
        } else {
          errorMsg =
              'Ошибка сервера при восстановлении: ${e.response!.statusCode}';
        }
      } else {
        errorMsg = 'Ошибка сети при восстановлении: ${e.message}';
      }
      _showSnackbar('Ошибка восстановления аккаунта: $errorMsg');
    } catch (e) {
      _showSnackbar('Произошла непредвиденная ошибка при восстановлении: $e');
    }
  }

  void _showSnackbar(String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Авторизация')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', height: 120),
            const SizedBox(height: 30),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Пароль'),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    context.push('/whatsapp-code');
                  },
                  child: const Text('Забыли пароль?'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text('Войти'),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('У вас нет аккаунта?'),
                TextButton(
                  onPressed: () {
                    context.push('/register');
                  },
                  child: const Text('Зарегистрируйтесь'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
