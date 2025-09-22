import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:ISS/services/firebase_messaging_service.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:flutter_svg/flutter_svg.dart';

final emailProvider = StateProvider<String?>((ref) => null);
final passwordProvider = StateProvider<String?>((ref) => null);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // --- BUSINESS LOGIC (UNCHANGED) ---
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
    if (token != null && token.isNotEmpty && mounted) {
      context.go('/main');
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
      setState(() => _rememberMe = true);
    }
  }

  Future<void> _loadUsers() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/users.json',
      );
      final List<dynamic> data = json.decode(response);
      setState(() => _users = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      _showSnackbar("Ошибка загрузки пользователей: $e");
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showSnackbar('Введите email и пароль');
      return;
    }
    setState(() => _isLoading = true);
    if (kDebugMode) {
      final adapter = dio.httpClientAdapter as IOHttpClientAdapter;
      adapter.onHttpClientCreate = (client) {
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
    }
    try {
      final response = await dio.post(
        'https://stage-app.iss-control.kz:443/api/v1/account-management/login',
        data: {"username": email, "password": password},
      );
      await _handleLoginResponse(response, email, password);
    } on DioException catch (e) {
      String errorMsg = 'Ошибка подключения';
      if (e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          errorMsg =
              responseData['error'] ?? responseData['message'] ?? errorMsg;
          if (errorMsg.contains('deleted') ||
              (responseData['code'] == 1 &&
                  responseData['message'].contains('deleted'))) {
            _showSnackbar('Ваш аккаунт был удален. Восстановление...');
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
      _showSnackbar('Непредвиденная ошибка: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLoginResponse(
    Response response,
    String email,
    String password,
  ) async {
    final responseData = response.data;
    if (responseData is! Map<String, dynamic>) {
      _showSnackbar('Ошибка: неверный формат ответа.');
      return;
    }
    final code = responseData['code'] as int?;
    final message = responseData['message'] as String?;
    if (code == 1) {
      if (message != null && message.contains('deleted')) {
        _showSnackbar('Ваш аккаунт был удален. Восстановление...');
        await _restoreAccountAndLogin(email, password);
      } else {
        _showSnackbar('Ошибка: ${message ?? 'Неизвестная ошибка'}');
      }
      return;
    }
    final accessToken = responseData['accessToken'] as String?;
    final refreshToken = responseData['refreshToken'] as String?;
    if (accessToken == null || refreshToken == null) {
      _showSnackbar('Ошибка: нет токенов в ответе.');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', accessToken);
    await prefs.setString('refreshToken', refreshToken);
    await prefs.setString('saved_email', email);
    await prefs.setString('saved_password', password);
    await ref.read(firebaseMessagingServiceProvider).sendFcmTokenToServer();
    _showSnackbar('Вход выполнен успешно');
    if (mounted) context.go('/main');
  }

  Future<void> _restoreAccountAndLogin(String email, String password) async {
    try {
      final restoreResponse = await dio.post(
        'https://stage-app.iss-control.kz:443/api/v1/user/restore',
        data: {"username": email, "password": password},
      );
      final restoreData = restoreResponse.data;
      if (restoreData is! Map<String, dynamic>) {
        _showSnackbar('Ошибка восстановления: неверный формат.');
        return;
      }
      final restoreCode = restoreData['code'] as int?;
      final restoreMessage = restoreData['message'] as String?;
      if (restoreCode == 0) {
        _showSnackbar('Аккаунт восстановлен. Повторный вход...');
        final reLoginResponse = await dio.post(
          'https://stage-app.iss-control.kz:443/api/v1/account-management/login',
          data: {"username": email, "password": password},
        );
        await _handleLoginResponse(reLoginResponse, email, password);
      } else {
        _showSnackbar('Ошибка восстановления: ${restoreMessage ?? '??'}');
      }
    } catch (e) {
      _showSnackbar('Ошибка восстановления аккаунта: $e');
    }
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // --- UI (REDESIGNED) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body is no longer behind the app bar
      backgroundColor: const Color(0xFFF5F5F5), // A soft background color
      body: Stack(
        fit: StackFit.expand,
        children: [
          // New Scandinavian-inspired background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-1, -1),
                radius: 1.5,
                colors: [
                  Color(0xFFFFFFFF), // Lighter top-left corner
                  Color(0xFFE8ECEF), // Softer greyish tone
                ],
              ),
            ),
          ),
          // Center the content with safe area to avoid system UI
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child:
                // Main content column for vertical arrangement
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Glassmorphism Container
                    _buildGlassContainer(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/images/logo.svg',
                            height: 80,
                            // A softer color for the logo to match the aesthetic
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF333333),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "Welcome Back 👋",
                            style: AppStyles.headline2(context).copyWith(
                              color: const Color(0xFF333333),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Login to manage your smart home",
                            textAlign: TextAlign.center,
                            style: AppStyles.bodyText2(
                              context,
                            ).copyWith(color: Colors.black54),
                          ),
                          const SizedBox(height: 32),
                          _buildTextField(
                            controller: _emailController,
                            hintText: "Email",
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _passwordController,
                            hintText: "Password",
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push('/whatsapp-code'),
                              child: Text(
                                "Forgot Password?",
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildLoginButton(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // "Don't have an account?" text button at the bottom
                    _buildRegisterButton(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for the Glassmorphism container to keep the build method clean
  Widget _buildGlassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.6),
                Colors.white.withOpacity(0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  // Helper widget for styled TextFields
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 20.0,
        ),
      ),
    );
  }

  // Helper widget for the Login Button
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 5,
          shadowColor: AppColors.primaryAccent.withOpacity(0.4),
        ),
        child:
            _isLoading
                ? const SizedBox(
                  height: 24.0,
                  width: 24.0,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
                : const Text(
                  "LOGIN",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
      ),
    );
  }

  // Helper widget for the Register text and button
  Widget _buildRegisterButton(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: TextStyle(color: Colors.grey.shade600),
        ),
        TextButton(
          onPressed: () => context.push('/register'),
          child: Text(
            "Register",
            style: TextStyle(
              color: AppColors.primaryAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
