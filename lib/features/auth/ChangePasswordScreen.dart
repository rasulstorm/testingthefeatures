import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:ISS/core/network/dio_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    final prefs = await SharedPreferences.getInstance();

    final email = prefs.getString('saved_email');
    final oldPassword = _currentController.text.trim();
    final newPassword = _newController.text.trim();
    final confirmPassword = _confirmController.text.trim();
    setState(() => _isLoading = true);

    try {
        
        final response = await dio.post(
            '/account-management/change-password',
            data:  {
                "email": email,
                "oldPassword": oldPassword,
                "newPassword": newPassword,
                "confirmPassword": confirmPassword
            }
        );      
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Пароль успешно изменён')),
        );
        await prefs.remove('saved_password');
        await prefs.remove('accessToken');
        await prefs.remove('refreshToken');
        context.go('/');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при смене пароля ${e}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Сменить пароль')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _currentController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Текущий пароль'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Введите текущий пароль' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _newController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Новый пароль'),
                validator: (value) =>
                    value == null || value.length < 6 ? 'Минимум 6 символов' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Подтвердите новый пароль'),
                validator: (value) =>
                    value != _newController.text ? 'Пароли не совпадают' : null,
              ),
              SizedBox(height: 32),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _changePassword,
                      child: Text('Сменить пароль'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
