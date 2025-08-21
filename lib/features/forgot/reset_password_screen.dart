import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ISS/core/network/dio_provider.dart';

// Import new design system
import 'package:ISS/appcolor.dart';
import 'package:ISS/appstyles.dart';

final resetPasswordControllerProvider = StateNotifierProvider.autoDispose<
    ResetPasswordController, AsyncValue<void>>(
  (ref) => ResetPasswordController(ref),
);

class ResetPasswordController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  ResetPasswordController(this.ref) : super(const AsyncValue.data(null));

  Future<bool> resetPassword(String phone, String password, String confirm) async {
    state = const AsyncValue.loading();
    try {
      await dio.post('/account-management/change-password', data: {
          "email": null,
          "phoneNumber": phone,
          "oldPassword": null,
          "newPassword": password,
          "confirmPassword": confirm
      });
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String phone;

  const ResetPasswordScreen({super.key, required this.phone});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  @override
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetPasswordControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context), // Apply new background color
      appBar: AppBar(
        title: Text(
          'Новый пароль',
          style: AppStyles.headline3(context), // Apply new headline style
        ),
        backgroundColor: AppColors.getCardBackgroundColor(context), // Apply new card background color
        iconTheme: IconThemeData(color: AppColors.getTextColor(context)), // Apply new text color for icons
        elevation: 0, // Remove shadow for cleaner look
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextFormField(
              context,
              controller: passwordController,
              obscureText: true,
              labelText: 'Новый пароль',
              icon: Icons.lock_open,
            ),
            const SizedBox(height: 16), // Adjusted spacing for consistency
            _buildTextFormField(
              context,
              controller: confirmController,
              obscureText: true,
              labelText: 'Повторите пароль',
              icon: Icons.lock_outline,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: state.isLoading
                  ? null
                  : () async {
                      if (passwordController.text != confirmController.text) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Пароли не совпадают',
                                style: AppStyles.bodyText2(context).copyWith(color: AppColors.textColorDark),
                              ),
                              backgroundColor: AppColors.error, // Use new error color
                            ),
                          );
                        }
                        return;
                      }

                      final success = await ref
                          .read(resetPasswordControllerProvider.notifier)
                          .resetPassword(widget.phone, passwordController.text, confirmController.text);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Пароль успешно изменён',
                              style: AppStyles.bodyText2(context).copyWith(color: AppColors.textColorDark),
                            ),
                            backgroundColor: AppColors.success, // Use new success color
                          ),
                        );
                        await Future.delayed(const Duration(seconds: 2));
                        if (context.mounted) {
                          context.go('/');
                        }
                      } else if (!success && mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Ошибка при смене пароля', // Generic error message for failed reset
                              style: AppStyles.bodyText2(context).copyWith(color: AppColors.textColorDark),
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
              style: AppStyles.primaryButtonStyle, // Apply new button style
              child: state.isLoading
                  ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.textColorDark, // Consistent with button foreground
                      ),
                    )
                  : const Text('Сменить пароль'),
            ),
          ],
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