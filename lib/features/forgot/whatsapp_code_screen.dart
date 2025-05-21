import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'whatsapp_code_controller.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите номер телефона')),
      );
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
          content: Text(sendByEmail
              ? 'Код отправлен на вашу почту'
              : resend
                  ? 'Код отправлен повторно на WhatsApp'
                  : 'Код отправлен на WhatsApp'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error.toString())),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Сброс пароля')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [phoneMaskFormatter],
              decoration: const InputDecoration(labelText: 'Телефон'),
            ),
            const SizedBox(height: 16),

            if (!_codeSent)
              ElevatedButton(
                onPressed: state.isLoading ? null : () => handleSendCode(),
                child: state.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Отправить код'),
              ),

            if (_codeSent) ...[
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Код из WhatsApp'),
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
                        }
                      },
                child: state.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Подтвердить'),
              ),
              const SizedBox(height: 20),
              if (!canResend)
                Text('Отправить код снова можно через $timerSeconds секунд'),
              if (canResend)
                TextButton(
                  onPressed: state.isLoading ? null : () => handleSendCode(resend: true),
                  child: Text(resendAttempts >= 3
                      ? 'Отправить код на почту'
                      : 'Отправить код снова'),
                ),
            ]
          ],
        ),
      ),
    );
  }
}
