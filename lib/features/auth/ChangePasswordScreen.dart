import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart'; // Keep this if it's used for debug mode SSL bypass
import 'package:ISS/core/network/dio_provider.dart'; // Assuming this path is correct

import 'package:ISS/appcolor.dart'; // Import AppColors
import 'package:ISS/appstyles.dart'; // Import AppStyles

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

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
        data: {
          "email": email,
          "oldPassword": oldPassword,
          "newPassword": newPassword,
          "confirmPassword": confirmPassword
        },
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Пароль успешно изменён',
              style: AppStyles.bodyText2(context).copyWith(color: AppColors.textColorDark),
            ),
            backgroundColor: AppColors.success, // Use new success color
          ),
        );
      }
      await prefs.remove('saved_password');
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');
      if (context.mounted) {
        context.go('/');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка при смене пароля: ${e}',
              style: AppStyles.bodyText2(context).copyWith(color: AppColors.textColorDark),
            ),
            backgroundColor: AppColors.error, // Use new error color
          ),
        );
      }
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
      backgroundColor: AppColors.getBackgroundColor(context), // Apply new background color
      appBar: AppBar(
        title: Text(
          'Сменить пароль',
          style: AppStyles.headline3(context), // Apply new headline style
        ),
        backgroundColor: AppColors.getCardBackgroundColor(context), // Apply new card background color
        iconTheme: IconThemeData(color: AppColors.getTextColor(context)), // Apply new text color for icons
        elevation: 0, // Remove shadow for cleaner look
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextFormField(
                context,
                controller: _currentController,
                obscureText: true,
                labelText: 'Текущий пароль',
                icon: Icons.lock,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Введите текущий пароль' : null,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                context,
                controller: _newController,
                obscureText: true,
                labelText: 'Новый пароль',
                icon: Icons.lock_open,
                validator: (value) =>
                    value == null || value.length < 6 ? 'Минимум 6 символов' : null,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                context,
                controller: _confirmController,
                obscureText: true,
                labelText: 'Подтвердите новый пароль',
                icon: Icons.lock_outline,
                validator: (value) =>
                    value != _newController.text ? 'Пароли не совпадают' : null,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryAccent, // Use primary accent for loader
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _changePassword,
                      style: AppStyles.primaryButtonStyle, // Apply new button style
                      child: Text('Сменить пароль'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for consistent TextFormField styling
  Widget _buildTextFormField(
    BuildContext context, {
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: AppStyles.bodyText1(context), // Apply bodyText1 style
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: AppStyles.bodyText2(context).copyWith(
          color: AppColors.getSecondaryTextColor(context), // Secondary text color for label
        ),
        prefixIcon: Icon(
          icon,
          color: AppColors.getLightGreyColor(context), // Light grey for icons
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.getBorderGrayColor(context), // Border color
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primaryAccent, // Accent color when focused
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.error, // Error color
            width: 1.0,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.error, // Error color when focused
            width: 2.0,
          ),
        ),
        fillColor: AppColors.getCardBackgroundColor(context), // Fill color
        filled: true,
      ),
      validator: validator,
    );
  }
}