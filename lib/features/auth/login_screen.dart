import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:flutter/foundation.dart';

final emailProvider = StateProvider<String?>((ref) => null);
final passwordProvider = StateProvider<String?>((ref) => null);

class LoginScreen extends ConsumerStatefulWidget {
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
      context.go('/security-control');
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
      _showSnackbar("Ошибка загрузки пользователей");
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
      final adapter = IOHttpClientAdapter();
      adapter.onHttpClientCreate = (client) {
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
      dio.httpClientAdapter = adapter;
    }
    try {
      final response = await Dio().post(
        'https://cms.iss-control.kz:8443/api/v1/account-management/login',
        data: {"username": email, "password": password},
      );

      final data = response.data;

      final code = data['code'];
      final error = data['message'];

      if (code == 1) {
        _showSnackbar('Ошибка: $error');
        return;
      }

      final accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', accessToken);
      await prefs.setString('refreshToken', refreshToken);
      await prefs.setString('saved_email', email);
      await prefs.setString('saved_password', password);

      _showSnackbar('Вход выполнен успешно');
      context.go('/security-control');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final errorMsg =
          responseData?['error'] ??
          responseData?['message'] ??
          'Ошибка подключения';
      _showSnackbar('Ошибка 1: $errorMsg');
    } catch (e) {
      _showSnackbar('Произошла ошибка: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Авторизация')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', height: 120),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Пароль'),
              obscureText: true,
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    context.push('/whatsapp-code');
                  },
                  child: Text('Забыли пароль?'),
                ),
              ],
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child:
                    _isLoading
                        ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Text('Войти'),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(children: [Text('У вас нет аккаунта?')]),
                TextButton(
                  onPressed: () {
                    context.push('/register');
                  },
                  child: Text('Зарегистрируйтесь'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
