import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'whatsapp_code_controller.dart';

// Import new design system
import 'package:ISS/appcolor.dart';
import 'package:ISS/appstyles.dart';

class WhatsappCodeScreen extends ConsumerStatefulWidget {
  const WhatsappCodeScreen({super.key});

  @override
  ConsumerState<WhatsappCodeScreen> createState() => _WhatsappCodeScreenState();
}

class _WhatsappCodeScreenState extends ConsumerState<WhatsappCodeScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController codeController = TextEditingController();

  final phoneMaskFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  Timer? timer;
  int timerSeconds = 60;
  int resendAttempts = 0;
  bool canResend = false;
  bool _codeSent = false;
  bool _wasErrorShown = false;

  @override
  void dispose() {
    timer?.cancel();
    phoneController.dispose();
    codeController.dispose();
    super.dispose();
  }

  void startTimer() {
    timer?.cancel();
    timerSeconds = 60;
    canResend = false;
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (timerSeconds > 0) {
          timerSeconds--;
        } else {
          canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> handleSendCode({bool resend = false}) async {
    final rawPhone = phoneMaskFormatter.getUnmaskedText();
    final formattedPhone = '7$rawPhone';

    if (formattedPhone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Введите номер телефона',
              style: AppStyles.bodyText2(context).copyWith(color: AppColors.textColorDark),
            ),
            backgroundColor: AppColors.warning, // Use warning color
          ),
        );
      }
      return;
    }

    final controller = ref.read(whatsappCodeControllerProvider.notifier);
    resendAttempts++;

    final bool sendByEmail = resendAttempts >= 3;

    await controller.resendCode(formattedPhone, sendByEmail);
    final state = ref.read(whatsappCodeControllerProvider);
    if (!state.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sendByEmail
                ? 'Код отправлен на вашу почту'
                : resend
                    ? 'Код отправлен повторно на WhatsApp'
                    : 'Код отправлен на WhatsApp',
            style: AppStyles.bodyText2(context).copyWith(color: AppColors.textColorDark),
          ),
          backgroundColor: AppColors.success, // Use success color
        ),
      );
      setState(() {
        _codeSent = true;
      });
      startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(whatsappCodeControllerProvider);
    if (state.hasError && !_wasErrorShown) {
      _wasErrorShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.error.toString(),
                style: AppStyles.bodyText2(context).copyWith(color: AppColors.textColorDark),
              ),
              backgroundColor: AppColors.error, // Use error color
            ),
          );
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context), // Apply new background color
      appBar: AppBar(
        title: Text(
          'Сброс пароля',
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
              controller: phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [phoneMaskFormatter],
              labelText: 'Телефон',
              icon: Icons.phone,
            ),
            const SizedBox(height: 16),

            if (!_codeSent)
              ElevatedButton(
                onPressed: state.isLoading ? null : () => handleSendCode(),
                style: AppStyles.primaryButtonStyle, // Apply new button style
                child: state.isLoading
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textColorDark, // Consistent with button foreground
                        ),
                      )
                    : const Text('Отправить код'),
              ),

            if (_codeSent) ...[
              const SizedBox(height: 16),
              _buildTextFormField(
                context,
                controller: codeController,
                keyboardType: TextInputType.number,
                labelText: 'Код из WhatsApp',
                icon: Icons.vpn_key,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () async {
                        final rawPhone = phoneMaskFormatter.getUnmaskedText();
                        final formattedPhone = '7$rawPhone';

                        final ok = await ref
                            .read(whatsappCodeControllerProvider.notifier)
                            .verifyCode(formattedPhone, codeController.text);
                        if (ok && mounted) {
                          context.push('/reset-password', extra: formattedPhone);
                        } else if (!ok && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Неверный код',
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
                    : const Text('Подтвердить'),
              ),
              const SizedBox(height: 20),
              if (!canResend)
                Text(
                  'Отправить код снова можно через $timerSeconds секунд',
                  style: AppStyles.bodyText2(context), // Apply bodyText2 style
                ),
              if (canResend)
                TextButton(
                  onPressed: state.isLoading ? null : () => handleSendCode(resend: true),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryAccent, // Apply primary accent for text button
                  ),
                  child: Text(
                    resendAttempts >= 3
                        ? 'Отправить код на почту'
                        : 'Отправить код снова',
                    style: AppStyles.bodyText1(context).copyWith(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ]
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
    List<MaskTextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
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
    );
  }
}